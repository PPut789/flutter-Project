import { execFileSync } from 'node:child_process';
import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const projectId = 'travelrecommendation-851e9';
const databaseId = '(default)';
const collectionName = 'attractions';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const projectRoot = path.resolve(__dirname, '..');
const outputRoot = path.join(projectRoot, 'assets', 'images', 'attractions');

const args = new Map(
  process.argv.slice(2).map((arg) => {
    const [key, ...valueParts] = arg.split('=');
    return [key.replace(/^--/, ''), valueParts.join('=') || 'true'];
  }),
);

const inputPath = path.resolve(args.get('input') ?? path.join(projectRoot, 'dataset', 'attractions.json'));
const startAfter = Number(args.get('start-after') ?? 0);
const limit = Number(args.get('limit') ?? 20);
const maxImages = Math.max(1, Number(args.get('max-images') ?? 1));
const delayMs = Math.max(0, Number(args.get('delay-ms') ?? 250));
const overwrite = args.get('overwrite') === 'true';
const dryRun = args.get('dry-run') === 'true';
const updateJson = args.get('update-json') !== 'false';

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function getAccessToken() {
  const raw = execFileSync('cmd', ['/c', 'firebase.cmd', 'login:list', '--json'], {
    encoding: 'utf8',
  });
  const parsed = JSON.parse(raw);
  const token = parsed?.result?.[0]?.tokens?.access_token;
  if (!token) {
    throw new Error('Firebase CLI access token not found. Run firebase.cmd login first.');
  }
  return token;
}

async function fetchWithTimeout(url, options = {}, timeoutMs = 30000) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMs);
  try {
    return await fetch(url, { ...options, signal: controller.signal });
  } finally {
    clearTimeout(timeout);
  }
}

function jsArrayToFirestoreStrings(values) {
  return {
    arrayValue: {
      values: values.map((value) => ({ stringValue: value })),
    },
  };
}

function extensionFromContentType(contentType) {
  if (contentType.includes('png')) return 'png';
  if (contentType.includes('webp')) return 'webp';
  if (contentType.includes('gif')) return 'gif';
  return 'jpg';
}

function cleanText(value) {
  return typeof value === 'string' ? value.trim() : '';
}

function documentIdFor(raw, index) {
  const rawId = cleanText(raw.id) || `row-${index + 1}`;
  const safeId = rawId.replaceAll('/', '_');
  return `att_${String(index + 1).padStart(4, '0')}_${safeId}`;
}

async function hasCachedFiles(documentId) {
  try {
    const files = await fs.readdir(path.join(outputRoot, documentId));
    return files.some((file) => /^image_\d+\.(jpg|jpeg|png|webp|gif)$/i.test(file));
  } catch (error) {
    if (error.code === 'ENOENT') return false;
    throw error;
  }
}

function isDownloadableImageUrl(value) {
  const url = String(value ?? '').trim();
  if (!url.startsWith('http://') && !url.startsWith('https://')) return false;

  const parsed = URL.canParse(url) ? new URL(url) : null;
  if (!parsed) return false;

  const host = parsed.hostname.toLowerCase();
  const looksLikePaidPlacesEndpoint =
    host === 'maps.googleapis.com' ||
    host === 'places.googleapis.com' ||
    parsed.searchParams.has('photo_reference') ||
    parsed.searchParams.has('photoreference');

  return !looksLikePaidPlacesEndpoint;
}

async function downloadImage(imageUrl) {
  const response = await fetchWithTimeout(imageUrl, {
    redirect: 'follow',
    headers: { 'User-Agent': 'travelthai-image-cache/1.0' },
  });
  if (!response.ok) throw new Error(`download failed HTTP ${response.status}`);

  const contentType = response.headers.get('content-type') ?? 'image/jpeg';
  if (!contentType.startsWith('image/')) {
    throw new Error(`not an image: ${contentType}`);
  }

  return {
    bytes: Buffer.from(await response.arrayBuffer()),
    contentType,
  };
}

async function updateAssetImages(accessToken, documentId, assetImages) {
  const url = new URL(
    `https://firestore.googleapis.com/v1/projects/${projectId}/databases/${databaseId}/documents/${collectionName}/${documentId}`,
  );
  url.searchParams.append('updateMask.fieldPaths', 'assetImages');
  url.searchParams.append('updateMask.fieldPaths', 'updatedAt');

  const response = await fetchWithTimeout(url, {
    method: 'PATCH',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      fields: {
        assetImages: jsArrayToFirestoreStrings(assetImages),
        updatedAt: { timestampValue: new Date().toISOString() },
      },
    }),
  });
  const body = await response.json();
  if (!response.ok) {
    throw new Error(`Firestore update failed: ${JSON.stringify(body)}`);
  }
}

function placeLabel(data, documentId) {
  return data.nameTh || data.nameEn || documentId;
}

async function main() {
  const rawPlaces = JSON.parse(await fs.readFile(inputPath, 'utf8'));
  if (!Array.isArray(rawPlaces)) throw new Error(`Expected JSON array in ${inputPath}`);

  const documents = rawPlaces.map((data, index) => ({
    index,
    documentId: documentIdFor(data, index),
    data: { ...data, sourceRow: index + 1 },
  }));

  const targetDocuments = [];
  for (const row of documents) {
    if (row.data.sourceRow <= startAfter) continue;
    if (!overwrite && Array.isArray(row.data.assetImages) && row.data.assetImages.length > 0) {
      continue;
    }
    if (!overwrite && (await hasCachedFiles(row.documentId))) {
      continue;
    }
    targetDocuments.push(row);
  }

  const accessToken = dryRun ? '' : getAccessToken();
  const selected = limit > 0 ? targetDocuments.slice(0, limit) : targetDocuments;
  let cached = 0;
  let skipped = 0;
  let failed = 0;

  await fs.mkdir(outputRoot, { recursive: true });

  for (const { index, documentId, data } of selected) {
    const label = placeLabel(data, documentId);
    const sourceImages = (Array.isArray(data.images) ? data.images : [])
      .filter(isDownloadableImageUrl)
      .slice(0, maxImages);

    if (!sourceImages.length) {
      skipped++;
      console.log(`[skip] ${data.sourceRow ?? '?'} ${label}: no safe downloadable image URL`);
      continue;
    }

    const assetPaths = [];
    const documentImageDir = path.join(outputRoot, documentId);

    try {
      for (let imageIndex = 0; imageIndex < sourceImages.length; imageIndex++) {
        const imageUrl = sourceImages[imageIndex];
        if (dryRun) {
          assetPaths.push(`assets/images/attractions/${documentId}/image_${String(imageIndex + 1).padStart(2, '0')}.jpg`);
          continue;
        }

        const image = await downloadImage(imageUrl);
        const extension = extensionFromContentType(image.contentType);
        const filename = `image_${String(imageIndex + 1).padStart(2, '0')}.${extension}`;
        const filePath = path.join(documentImageDir, filename);
        await fs.mkdir(documentImageDir, { recursive: true });
        await fs.writeFile(filePath, image.bytes);
        assetPaths.push(`assets/images/attractions/${documentId}/${filename}`);
      }

      if (!dryRun) {
        await updateAssetImages(accessToken, documentId, assetPaths);
        if (updateJson) {
          rawPlaces[index].assetImages = assetPaths;
        }
      }

      cached++;
      console.log(
        `[ok] ${data.sourceRow ?? '?'} ${label}: ${assetPaths.length} asset image(s)${dryRun ? ' (dry run)' : ''}`,
      );
    } catch (error) {
      failed++;
      console.error(`[error] ${data.sourceRow ?? '?'} ${label}: ${error.message}`);
    }

    if (delayMs > 0) await sleep(delayMs);
  }

  console.log(
    `Done. selected=${selected.length} cached=${cached} skipped=${skipped} failed=${failed} dryRun=${dryRun}`,
  );

  if (!dryRun && updateJson) {
    await fs.writeFile(inputPath, `${JSON.stringify(rawPlaces, null, 2)}\n`, 'utf8');
    console.log(`Updated local dataset: ${inputPath}`);
  }
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
