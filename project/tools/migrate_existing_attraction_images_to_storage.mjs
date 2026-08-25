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

const inputPath = path.resolve(args.get('input') ?? path.join(projectRoot, 'dataset', 'attractions.json'));
const collectionName = args.get('collection') ?? 'attractions';
const maxImages = Math.max(1, Number(args.get('max-images') ?? 2));
const dryRun = args.get('dry-run') === 'true';

function getAccessToken() {
  const raw = execFileSync('cmd', ['/c', 'firebase.cmd', 'login:list', '--json'], {
    encoding: 'utf8',
  });
  const parsed = JSON.parse(raw);
  const token = parsed?.result?.[0]?.tokens?.access_token;
  if (!token) throw new Error('Firebase CLI access token not found. Run firebase.cmd login first.');
  return token;
}

function documentIdFor(raw, index) {
  const rawId = String(raw.id || `row-${index + 1}`).trim();
  const safeId = rawId.replaceAll('/', '_');
  return `att_${String(index + 1).padStart(4, '0')}_${safeId}`;
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

function extensionFromContentType(contentType) {
  if (contentType.includes('png')) return 'png';
  if (contentType.includes('webp')) return 'webp';
  return 'jpg';
}

async function downloadImage(imageUrl) {
  const response = await fetchWithTimeout(imageUrl, {
    redirect: 'follow',
    headers: { 'User-Agent': 'travelthai-existing-image-migration/1.0' },
  });
  if (!response.ok) throw new Error(`download failed HTTP ${response.status}`);
  const contentType = response.headers.get('content-type') ?? 'image/jpeg';
  if (!contentType.startsWith('image/')) throw new Error(`not an image: ${contentType}`);
  return {
    bytes: Buffer.from(await response.arrayBuffer()),
    contentType,
  };
}

async function uploadImage(accessToken, documentId, imageIndex, image) {
  const extension = extensionFromContentType(image.contentType);
  const objectPath = `attraction_images/${documentId}/migrated_${String(imageIndex + 1).padStart(2, '0')}.${extension}`;
  const downloadToken = randomUUID();
  const url = new URL(`https://firebasestorage.googleapis.com/v0/b/${bucket}/o`);
  url.searchParams.set('uploadType', 'media');
  url.searchParams.set('name', objectPath);

  const response = await fetchWithTimeout(url, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': image.contentType,
      'X-Goog-Meta-FirebaseStorageDownloadTokens': downloadToken,
    },
    body: image.bytes,
  });
  const body = await response.json();
  if (!response.ok) throw new Error(`upload failed: ${JSON.stringify(body, null, 2)}`);

  const token = body.downloadTokens ?? downloadToken;
  const downloadUrl = new URL(
    `https://firebasestorage.googleapis.com/v0/b/${bucket}/o/${encodeURIComponent(objectPath)}`,
  );
  downloadUrl.searchParams.set('alt', 'media');
  downloadUrl.searchParams.set('token', token);
  return downloadUrl.toString();
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
        images: { arrayValue: { values: images.map((image) => ({ stringValue: image })) } },
        updatedAt: { timestampValue: new Date().toISOString() },
      },
    }),
  });
  const body = await response.json();
  if (!response.ok) throw new Error(`Firestore update failed: ${JSON.stringify(body, null, 2)}`);
}

async function main() {
  const places = JSON.parse(await fs.readFile(inputPath, 'utf8'));
  const accessToken = dryRun ? '' : getAccessToken();
  let updated = 0;
  let failed = 0;

  for (let index = 0; index < places.length; index++) {
    const place = places[index];
    const images = Array.isArray(place.images) ? place.images : [];
    if (!images.length) continue;
    if (images.some((url) => String(url).includes('firebasestorage.googleapis.com'))) continue;

    const name = place.nameTh || place.nameEn || `row ${index + 1}`;
    const documentId = documentIdFor(place, index);
    const sourceImages = images.slice(0, maxImages);
    if (dryRun) {
      console.log(`[dry] ${index + 1}: ${name} images=${sourceImages.length}`);
      continue;
    }

    try {
      const storageUrls = [];
      for (let imageIndex = 0; imageIndex < sourceImages.length; imageIndex++) {
        const downloaded = await downloadImage(sourceImages[imageIndex]);
        storageUrls.push(await uploadImage(accessToken, documentId, imageIndex, downloaded));
      }
      await updateAttractionImages(accessToken, documentId, storageUrls);
      place.images = storageUrls;
      await fs.writeFile(inputPath, `${JSON.stringify(places, null, 2)}\n`, 'utf8');
      updated++;
      console.log(`[ok] ${index + 1}: ${name} images=${storageUrls.length}`);
    } catch (error) {
      failed++;
      console.error(`[error] ${index + 1}: ${name}: ${error.message}`);
    }
  }

  console.log(`Done. updated=${updated} failed=${failed}`);
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
