import { execFileSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const projectId = 'travelrecommendation-851e9';
const databaseId = '(default)';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const projectRoot = path.resolve(__dirname, '..');

const args = new Map(
  process.argv.slice(2).map((arg) => {
    const [key, ...valueParts] = arg.split('=');
    return [key.replace(/^--/, ''), valueParts.join('=') || 'true'];
  }),
);

const inputPath = path.resolve(
  args.get('input') ?? path.join(projectRoot, 'dataset', 'attractions.json'),
);
const outputDir = path.resolve(
  args.get('output') ??
    path.join(projectRoot, 'dataset', 'image_duplicate_audit'),
);
const collectionName = args.get('collection') ?? 'attractions';
const limit = Number(args.get('limit') ?? 0);
const concurrency = Math.max(1, Number(args.get('concurrency') ?? 4));
const placeConcurrency = Math.max(1, Number(args.get('place-concurrency') ?? 8));
const verbose = args.get('verbose') === 'true';
const applyDataset = args.get('apply-dataset') === 'true';
const applyFirestore = args.get('apply-firestore') === 'true';

function documentIdFor(raw, index) {
  const rawId = String(raw.id || `row-${index + 1}`).trim();
  const safeId = rawId.replaceAll('/', '_');
  return `att_${String(index + 1).padStart(4, '0')}_${safeId}`;
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

async function hashImage(imageUrl) {
  const response = await fetchWithTimeout(imageUrl, {
    redirect: 'follow',
    headers: { 'User-Agent': 'travelthai-image-duplicate-audit/1.0' },
  });
  if (!response.ok) throw new Error(`HTTP ${response.status}`);

  const contentType = response.headers.get('content-type') ?? '';
  if (!contentType.startsWith('image/')) {
    throw new Error(`not an image: ${contentType || 'unknown content type'}`);
  }

  const bytes = Buffer.from(await response.arrayBuffer());
  return {
    hash: createHash('sha256').update(bytes).digest('hex'),
    bytes: bytes.length,
    contentType,
  };
}

function toFirestoreImages(images) {
  return { arrayValue: { values: images.map((url) => ({ stringValue: url })) } };
}

async function updateAttractionImages(accessToken, documentId, images) {
  const url = new URL(
    `https://firestore.googleapis.com/v1/projects/${projectId}/databases/${databaseId}/documents/${collectionName}/${documentId}`,
  );
  url.searchParams.append('updateMask.fieldPaths', 'images');
  url.searchParams.append('updateMask.fieldPaths', 'updatedAt');

  const response = await fetchWithTimeout(url, {
    method: 'PATCH',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      fields: {
        images: toFirestoreImages(images),
        updatedAt: { timestampValue: new Date().toISOString() },
      },
    }),
  });

  const body = await response.json();
  if (!response.ok) {
    throw new Error(`Firestore update failed: ${JSON.stringify(body, null, 2)}`);
  }
}

async function mapWithConcurrency(items, worker) {
  const results = new Array(items.length);
  let nextIndex = 0;

  async function runWorker() {
    while (nextIndex < items.length) {
      const index = nextIndex++;
      results[index] = await worker(items[index], index);
    }
  }

  await Promise.all(
    Array.from({ length: Math.min(concurrency, items.length) }, runWorker),
  );
  return results;
}

function csvCell(value) {
  const text = String(value ?? '');
  return `"${text.replaceAll('"', '""')}"`;
}

async function main() {
  const places = JSON.parse(await fs.readFile(inputPath, 'utf8'));
  const candidates = places
    .map((place, index) => ({ place, index }))
    .filter(({ place }) => Array.isArray(place.images) && place.images.length > 0)
    .slice(0, limit > 0 ? limit : undefined);

  await fs.mkdir(outputDir, { recursive: true });

  const accessToken = applyFirestore ? getAccessToken() : '';
  let completed = 0;
  let firestoreUpdated = 0;
  let firestoreFailed = 0;

  const report = await mapWithConcurrency(candidates, async ({ place, index }) => {
    const images = place.images.filter(Boolean);
    const documentId = place.documentId || documentIdFor(place, index);
    const imageResults = await mapWithConcurrency(images, async (url, imageIndex) => {
      try {
        return {
          imageIndex,
          url,
          ok: true,
          ...(await hashImage(url)),
        };
      } catch (error) {
        return {
          imageIndex,
          url,
          ok: false,
          error: error.message,
        };
      }
    });

    const seenHashes = new Set();
    const keptUrls = [];
    const duplicateUrls = [];
    const failedUrls = [];

    for (const result of imageResults) {
      if (!result.ok) {
        failedUrls.push(result.url);
        continue;
      }

      if (seenHashes.has(result.hash)) {
        duplicateUrls.push(result.url);
      } else {
        seenHashes.add(result.hash);
        keptUrls.push(result.url);
      }
    }

    const hasDuplicates = duplicateUrls.length > 0;
    if (applyDataset && hasDuplicates) {
      place.images = keptUrls;
    }

    let firestoreStatus = 'not_requested';
    if (applyFirestore && hasDuplicates) {
      try {
        await updateAttractionImages(accessToken, documentId, keptUrls);
        firestoreUpdated++;
        firestoreStatus = 'updated';
      } catch (error) {
        firestoreFailed++;
        firestoreStatus = `failed: ${error.message}`;
      }
    }

    const item = {
      row: index + 1,
      documentId,
      id: place.id ?? '',
      nameTh: place.nameTh ?? place.name ?? '',
      region: place.region ?? '',
      province: place.province ?? '',
      originalImageCount: images.length,
      uniqueImageCount: keptUrls.length,
      duplicateImageCount: duplicateUrls.length,
      failedImageCount: failedUrls.length,
      keptUrls,
      duplicateUrls,
      failedUrls,
      firestoreStatus,
    };

    completed++;
    if (verbose || completed % 100 === 0 || completed === candidates.length) {
      console.log(
        `${completed}/${candidates.length} checked, duplicates=${item.duplicateImageCount}, failed=${item.failedImageCount}, latest=${item.nameTh}`,
      );
    }

    return item;
  }, placeConcurrency);

  if (applyDataset) {
    await fs.writeFile(inputPath, `${JSON.stringify(places, null, 2)}\n`, 'utf8');
  }

  const summary = {
    input: path.relative(projectRoot, inputPath),
    checkedPlaces: report.length,
    placesWithDuplicates: report.filter((item) => item.duplicateImageCount > 0).length,
    originalImages: report.reduce((sum, item) => sum + item.originalImageCount, 0),
    uniqueImages: report.reduce((sum, item) => sum + item.uniqueImageCount, 0),
    duplicateImages: report.reduce((sum, item) => sum + item.duplicateImageCount, 0),
    failedImages: report.reduce((sum, item) => sum + item.failedImageCount, 0),
    applyDataset,
    applyFirestore,
    firestoreUpdated,
    firestoreFailed,
  };

  const timestamp = new Date().toISOString().replaceAll(':', '-').replace(/\.\d+Z$/, 'Z');
  const jsonPath = path.join(outputDir, `duplicate_image_audit_${timestamp}.json`);
  const csvPath = path.join(outputDir, `duplicate_image_audit_${timestamp}.csv`);

  await fs.writeFile(
    jsonPath,
    `${JSON.stringify({ summary, places: report }, null, 2)}\n`,
    'utf8',
  );

  const csvRows = [
    [
      'row',
      'documentId',
      'id',
      'nameTh',
      'region',
      'province',
      'originalImageCount',
      'uniqueImageCount',
      'duplicateImageCount',
      'failedImageCount',
      'firestoreStatus',
    ],
    ...report.map((item) => [
      item.row,
      item.documentId,
      item.id,
      item.nameTh,
      item.region,
      item.province,
      item.originalImageCount,
      item.uniqueImageCount,
      item.duplicateImageCount,
      item.failedImageCount,
      item.firestoreStatus,
    ]),
  ];
  await fs.writeFile(
    csvPath,
    `${csvRows.map((row) => row.map(csvCell).join(',')).join('\n')}\n`,
    'utf8',
  );

  console.log('\nSummary');
  console.log(JSON.stringify(summary, null, 2));
  console.log(`Report JSON: ${jsonPath}`);
  console.log(`Report CSV: ${csvPath}`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
