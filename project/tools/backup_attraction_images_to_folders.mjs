import crypto from 'node:crypto';
import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

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
const outputRoot = path.resolve(
  args.get('output') ?? path.join(projectRoot, 'backup', 'attraction_images_full'),
);
const concurrency = Math.max(1, Number(args.get('concurrency') ?? 8));
const limit = Math.max(0, Number(args.get('limit') ?? 0));
const overwrite = args.get('overwrite') === 'true';
const dryRun = args.get('dry-run') === 'true';

const windowsReservedNames = new Set([
  'CON',
  'PRN',
  'AUX',
  'NUL',
  'COM1',
  'COM2',
  'COM3',
  'COM4',
  'COM5',
  'COM6',
  'COM7',
  'COM8',
  'COM9',
  'LPT1',
  'LPT2',
  'LPT3',
  'LPT4',
  'LPT5',
  'LPT6',
  'LPT7',
  'LPT8',
  'LPT9',
]);

function cleanText(value, fallback = 'unknown') {
  const text = typeof value === 'string' ? value.trim() : '';
  return text || fallback;
}

function sanitizePathSegment(value, fallback = 'unknown') {
  let segment = cleanText(value, fallback)
    .replace(/[<>:"/\\|?*\u0000-\u001f]/g, '_')
    .replace(/\s+/g, ' ')
    .replace(/[. ]+$/g, '')
    .slice(0, 90)
    .trim();

  if (!segment) segment = fallback;
  if (windowsReservedNames.has(segment.toUpperCase())) segment = `_${segment}`;
  return segment;
}

function documentIdFor(raw, index) {
  const rawId = cleanText(raw.id, `row-${index + 1}`);
  const safeId = rawId.replaceAll('/', '_');
  return `att_${String(index + 1).padStart(4, '0')}_${safeId}`;
}

function isSafeExistingImageUrl(value) {
  const url = String(value ?? '').trim();
  if (!url.startsWith('http://') && !url.startsWith('https://')) return false;
  if (!URL.canParse(url)) return false;

  const parsed = new URL(url);
  const host = parsed.hostname.toLowerCase();
  const looksLikePaidPlacesEndpoint =
    host === 'maps.googleapis.com' ||
    host === 'places.googleapis.com' ||
    parsed.searchParams.has('photo_reference') ||
    parsed.searchParams.has('photoreference');

  return !looksLikePaidPlacesEndpoint;
}

function extensionFromContentType(contentType) {
  const normalized = String(contentType ?? '').toLowerCase();
  if (normalized.includes('png')) return 'png';
  if (normalized.includes('webp')) return 'webp';
  if (normalized.includes('gif')) return 'gif';
  return 'jpg';
}

async function fetchWithTimeout(url, options = {}, timeoutMs = 45000) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMs);
  try {
    return await fetch(url, { ...options, signal: controller.signal });
  } finally {
    clearTimeout(timeout);
  }
}

async function downloadImage(imageUrl) {
  const response = await fetchWithTimeout(imageUrl, {
    redirect: 'follow',
    headers: { 'User-Agent': 'travelthai-image-backup/1.0' },
  });

  if (!response.ok) {
    throw new Error(`HTTP ${response.status}`);
  }

  const contentType = response.headers.get('content-type') ?? 'image/jpeg';
  if (!contentType.toLowerCase().startsWith('image/')) {
    throw new Error(`not an image: ${contentType}`);
  }

  const bytes = Buffer.from(await response.arrayBuffer());
  return {
    bytes,
    contentType,
    sha256: crypto.createHash('sha256').update(bytes).digest('hex'),
  };
}

function placeDirectoryFor(place, index, documentId) {
  const region = sanitizePathSegment(place.region, 'unknown-region');
  const province = sanitizePathSegment(place.province, 'unknown-province');
  const name = sanitizePathSegment(place.nameTh || place.nameEn, documentId);
  const placeFolder = `${String(index + 1).padStart(4, '0')}_${name}_${documentId}`;
  return path.join(outputRoot, region, province, placeFolder);
}

async function pathExists(filePath) {
  try {
    await fs.access(filePath);
    return true;
  } catch {
    return false;
  }
}

async function backupPlace(place, index) {
  const documentId = documentIdFor(place, index);
  const imageUrls = (Array.isArray(place.images) ? place.images : []).filter(isSafeExistingImageUrl);
  const outputDir = placeDirectoryFor(place, index, documentId);
  const metadataPath = path.join(outputDir, 'metadata.json');
  const label = place.nameTh || place.nameEn || documentId;

  if (imageUrls.length === 0) {
    return {
      status: 'skipped',
      documentId,
      nameTh: place.nameTh ?? '',
      reason: 'no downloadable image URL',
      imageCount: 0,
      bytes: 0,
    };
  }

  if (!overwrite && (await pathExists(metadataPath))) {
    const metadata = JSON.parse(await fs.readFile(metadataPath, 'utf8'));
    return {
      status: 'exists',
      documentId,
      nameTh: place.nameTh ?? '',
      imageCount: metadata.images?.length ?? 0,
      bytes: metadata.images?.reduce((sum, item) => sum + (item.bytes ?? 0), 0) ?? 0,
    };
  }

  if (dryRun) {
    return {
      status: 'dry',
      documentId,
      nameTh: place.nameTh ?? '',
      outputDir,
      imageCount: imageUrls.length,
      bytes: 0,
    };
  }

  await fs.mkdir(outputDir, { recursive: true });

  const images = [];
  let totalBytes = 0;
  for (let imageIndex = 0; imageIndex < imageUrls.length; imageIndex++) {
    const sourceUrl = imageUrls[imageIndex];
    const image = await downloadImage(sourceUrl);
    const extension = extensionFromContentType(image.contentType);
    const filename = `image_${String(imageIndex + 1).padStart(2, '0')}.${extension}`;
    const filePath = path.join(outputDir, filename);

    await fs.writeFile(filePath, image.bytes);
    totalBytes += image.bytes.length;
    images.push({
      index: imageIndex + 1,
      filename,
      sourceUrl,
      contentType: image.contentType,
      bytes: image.bytes.length,
      sha256: image.sha256,
    });
  }

  await fs.writeFile(
    metadataPath,
    `${JSON.stringify(
      {
        documentId,
        sourceRow: index + 1,
        id: place.id ?? '',
        nameTh: place.nameTh ?? '',
        nameEn: place.nameEn ?? '',
        region: place.region ?? '',
        province: place.province ?? '',
        district: place.district ?? '',
        category: place.category ?? '',
        backedUpAt: new Date().toISOString(),
        images,
      },
      null,
      2,
    )}\n`,
    'utf8',
  );

  return {
    status: 'downloaded',
    documentId,
    nameTh: place.nameTh ?? '',
    label,
    imageCount: images.length,
    bytes: totalBytes,
  };
}

async function runPool(items, workerCount, worker) {
  const results = new Array(items.length);
  let cursor = 0;

  async function runWorker() {
    while (cursor < items.length) {
      const current = cursor++;
      results[current] = await worker(items[current], current);
    }
  }

  await Promise.all(Array.from({ length: workerCount }, runWorker));
  return results;
}

async function main() {
  const places = JSON.parse(await fs.readFile(inputPath, 'utf8'));
  if (!Array.isArray(places)) {
    throw new Error(`Expected JSON array in ${inputPath}`);
  }

  const selected = limit > 0 ? places.slice(0, limit) : places;
  const totals = {
    selectedPlaces: selected.length,
    downloadedPlaces: 0,
    existingPlaces: 0,
    skippedPlaces: 0,
    failedPlaces: 0,
    dryRunPlaces: 0,
    downloadedImages: 0,
    totalBytes: 0,
  };
  const failures = [];

  console.log(`Input: ${inputPath}`);
  console.log(`Output: ${outputRoot}`);
  console.log(`Places: ${selected.length}`);
  console.log(`Concurrency: ${concurrency}`);
  console.log(`Dry run: ${dryRun}`);

  await fs.mkdir(outputRoot, { recursive: true });

  await runPool(selected, concurrency, async (place, selectedIndex) => {
    const originalIndex = selectedIndex;
    try {
      const result = await backupPlace(place, originalIndex);
      if (result.status === 'downloaded') totals.downloadedPlaces++;
      if (result.status === 'exists') totals.existingPlaces++;
      if (result.status === 'skipped') totals.skippedPlaces++;
      if (result.status === 'dry') totals.dryRunPlaces++;
      totals.downloadedImages += result.imageCount ?? 0;
      totals.totalBytes += result.bytes ?? 0;

      const done = selectedIndex + 1;
      if (done <= 10 || done % 100 === 0 || done === selected.length) {
        console.log(
          `${done}/${selected.length} ${result.status}: ${result.nameTh || result.documentId} (${result.imageCount ?? 0})`,
        );
      }
      return result;
    } catch (error) {
      const documentId = documentIdFor(place, originalIndex);
      totals.failedPlaces++;
      failures.push({
        row: originalIndex + 1,
        documentId,
        nameTh: place.nameTh ?? '',
        error: error.message,
      });
      console.error(`${originalIndex + 1}/${selected.length} failed: ${place.nameTh || documentId}: ${error.message}`);
      return { status: 'failed', documentId, error: error.message };
    }
  });

  const summary = {
    ...totals,
    totalMegabytes: Number((totals.totalBytes / 1024 / 1024).toFixed(2)),
    failures,
    completedAt: new Date().toISOString(),
  };

  await fs.writeFile(
    path.join(outputRoot, 'backup_summary.json'),
    `${JSON.stringify(summary, null, 2)}\n`,
    'utf8',
  );

  console.log(JSON.stringify(summary, null, 2));
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
