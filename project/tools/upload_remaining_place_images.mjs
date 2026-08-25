import { execFileSync } from 'node:child_process';
import { randomUUID } from 'node:crypto';
import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const projectId = 'travelrecommendation-851e9';
const databaseId = '(default)';
const bucket = 'travelrecommendation-851e9.firebasestorage.app';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const projectRoot = path.resolve(__dirname, '..');

const args = new Map(
  process.argv.slice(2).map((arg) => {
    const [key, ...valueParts] = arg.split('=');
    return [key.replace(/^--/, ''), valueParts.join('=') || 'true'];
  }),
);

const attractionsPath = path.resolve(args.get('input') ?? path.join(projectRoot, 'dataset', 'attractions.json'));
const remainingPath = path.resolve(
  args.get('remaining') ?? path.join(projectRoot, 'dataset', 'image_enrichment_logs', 'remaining_image_places.json'),
);
const foldersRoot = path.resolve(args.get('folders') ?? path.join(projectRoot, 'dataset', 'remaining_place_images'));
const collectionName = args.get('collection') ?? 'attractions';
const dryRun = args.get('dry-run') === 'true';

const imageExtensions = new Set(['.jpg', '.jpeg', '.png', '.webp']);

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

function documentIdFor(raw, index) {
  const rawId = String(raw.id || `row-${index + 1}`).trim();
  const safeId = rawId.replaceAll('/', '_');
  return `att_${String(index + 1).padStart(4, '0')}_${safeId}`;
}

function contentTypeFor(filePath) {
  const ext = path.extname(filePath).toLowerCase();
  if (ext === '.png') return 'image/png';
  if (ext === '.webp') return 'image/webp';
  return 'image/jpeg';
}

function storageExt(filePath) {
  const ext = path.extname(filePath).toLowerCase();
  if (ext === '.jpeg') return 'jpg';
  if (ext === '.png') return 'png';
  if (ext === '.webp') return 'webp';
  return 'jpg';
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

async function uploadImage(accessToken, documentId, imageIndex, filePath) {
  const bytes = await fs.readFile(filePath);
  const contentType = contentTypeFor(filePath);
  const objectPath = `attraction_images/${documentId}/manual_${String(imageIndex + 1).padStart(2, '0')}.${storageExt(filePath)}`;
  const downloadToken = randomUUID();
  const url = new URL(`https://firebasestorage.googleapis.com/v0/b/${bucket}/o`);
  url.searchParams.set('uploadType', 'media');
  url.searchParams.set('name', objectPath);

  const response = await fetchWithTimeout(url, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': contentType,
      'X-Goog-Meta-FirebaseStorageDownloadTokens': downloadToken,
    },
    body: bytes,
  });
  const body = await response.json();
  if (!response.ok) {
    throw new Error(`Storage upload failed: ${JSON.stringify(body, null, 2)}`);
  }

  const token = body.downloadTokens ?? downloadToken;
  const downloadUrl = new URL(
    `https://firebasestorage.googleapis.com/v0/b/${bucket}/o/${encodeURIComponent(objectPath)}`,
  );
  downloadUrl.searchParams.set('alt', 'media');
  downloadUrl.searchParams.set('token', token);
  return downloadUrl.toString();
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

function numberedFolderIndex(folderName) {
  const match = /^(\d{3})_/.exec(folderName);
  return match ? Number(match[1]) - 1 : -1;
}

async function main() {
  const attractions = JSON.parse(await fs.readFile(attractionsPath, 'utf8'));
  const remaining = JSON.parse(await fs.readFile(remainingPath, 'utf8'));
  const remainingItems = [
    ...(remaining.noImages || []).map((item) => ({ ...item, status: 'NO_IMAGE' })),
    ...(remaining.oldGoogleImages || []).map((item) => ({ ...item, status: 'OLD_GOOGLE_URL' })),
  ];

  const folders = (await fs.readdir(foldersRoot, { withFileTypes: true }))
    .filter((entry) => entry.isDirectory())
    .map((entry) => entry.name)
    .filter((name) => numberedFolderIndex(name) >= 0)
    .sort();

  const accessToken = dryRun ? '' : getAccessToken();
  let updated = 0;
  let skipped = 0;

  for (const folder of folders) {
    const item = remainingItems[numberedFolderIndex(folder)];
    if (!item) {
      skipped++;
      console.log(`[skip] ${folder}: no remaining item mapping`);
      continue;
    }

    const folderPath = path.join(foldersRoot, folder);
    const imageFiles = (await fs.readdir(folderPath))
      .filter((file) => imageExtensions.has(path.extname(file).toLowerCase()))
      .sort((a, b) => a.localeCompare(b, 'th'));

    if (!imageFiles.length) {
      skipped++;
      continue;
    }

    const attraction = attractions[item.row - 1];
    const documentId = item.documentId || documentIdFor(attraction, item.row - 1);
    if (dryRun) {
      console.log(`[dry] ${folder}: ${item.nameTh} files=${imageFiles.length}`);
      continue;
    }

    const storageUrls = [];
    for (let i = 0; i < imageFiles.length; i++) {
      storageUrls.push(await uploadImage(accessToken, documentId, i, path.join(folderPath, imageFiles[i])));
    }

    await updateAttractionImages(accessToken, documentId, storageUrls);
    attraction.images = storageUrls;
    updated++;
    console.log(`[ok] ${folder}: ${item.nameTh} images=${storageUrls.length}`);
  }

  if (!dryRun) {
    await fs.writeFile(attractionsPath, `${JSON.stringify(attractions, null, 2)}\n`, 'utf8');
  }

  console.log(`Done. updated=${updated} skipped=${skipped}`);
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
