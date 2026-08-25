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
const defaultInputPath = path.join(projectRoot, 'dataset', 'attractions.json');
const defaultEnvPath = path.join(projectRoot, 'tools', 'media_enrichment.env');

const args = new Map(
  process.argv.slice(2).map((arg) => {
    const [key, ...valueParts] = arg.split('=');
    return [key.replace(/^--/, ''), valueParts.join('=') || 'true'];
  }),
);

const inputPath = path.resolve(args.get('input') ?? defaultInputPath);
const envPath = path.resolve(args.get('env') ?? defaultEnvPath);
const collectionName = args.get('collection') ?? 'attractions';
const start = Math.max(1, Number(args.get('start') ?? 1));
const limit = Math.max(0, Number(args.get('limit') ?? 3));
const maxImages = Math.max(1, Number(args.get('max-images') ?? 3));
const maxWidth = Math.max(400, Number(args.get('max-width') ?? 1200));
const delayMs = Math.max(0, Number(args.get('delay-ms') ?? 500));
const overwrite = args.get('overwrite') === 'true';
const onlyNonStorage = args.get('only-non-storage') === 'true';
const quietSkips = args.get('quiet-skips') === 'true';
const dryRun = args.get('dry-run') === 'true';
const updateJson = args.get('update-json') !== 'false';

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function loadEnv(filePath) {
  try {
    const raw = await fs.readFile(filePath, 'utf8');
    for (const rawLine of raw.split(/\r?\n/)) {
      const line = rawLine.trim();
      if (!line || line.startsWith('#') || !line.includes('=')) continue;
      const [key, ...valueParts] = line.split('=');
      process.env[key.trim()] ??= valueParts.join('=').trim().replace(/^['"]|['"]$/g, '');
    }
  } catch (error) {
    if (error.code !== 'ENOENT') throw error;
  }
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

function cleanText(value) {
  return typeof value === 'string' ? value.trim() : '';
}

function documentIdFor(raw, index) {
  const rawId = cleanText(raw.id) || `row-${index + 1}`;
  const safeId = rawId.replaceAll('/', '_');
  return `att_${String(index + 1).padStart(4, '0')}_${safeId}`;
}

function buildQueries(place) {
  const nameTh = cleanText(place.nameTh);
  const nameEn = cleanText(place.nameEn);
  const province = cleanText(place.province);
  const district = cleanText(place.district);
  const subdistrict = cleanText(place.subdistrict);
  const type = cleanText(place.type);
  const category = cleanText(place.category);
  const location = cleanText(place.location);
  const queries = [
    [nameTh, district, province, 'Thailand'],
    [nameTh, province, 'Thailand'],
    [nameTh, subdistrict, district, province],
    [nameTh, type, province],
    [nameTh, category, province],
    [nameEn, province, 'Thailand'],
    [nameEn, district, province, 'Thailand'],
    [nameEn, 'Thailand'],
    [location, province, 'Thailand'],
  ]
    .map((parts) => parts.filter(Boolean).join(' '))
    .filter(Boolean);
  return [...new Set(queries)];
}

function getCoordinates(place) {
  const lat = Number(place.latitude);
  const lng = Number(place.longitude);
  if (!Number.isFinite(lat) || !Number.isFinite(lng)) return null;
  if (lat === 0 && lng === 0) return null;
  return { lat, lng };
}

function hasStorageImages(place) {
  const images = Array.isArray(place.images) ? place.images : [];
  return images.some((url) => String(url).includes('firebasestorage.googleapis.com'));
}

async function fetchWithTimeout(url, options = {}, timeoutMs = 20000) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMs);
  try {
    return await fetch(url, {
      ...options,
      signal: controller.signal,
    });
  } finally {
    clearTimeout(timeout);
  }
}

async function fetchJson(url) {
  const response = await fetchWithTimeout(url, {
    headers: {
      Accept: 'application/json',
      'User-Agent': 'travelthai-places-storage-images/1.0',
    },
  });
  const body = await response.json();
  if (!response.ok) {
    throw new Error(`HTTP ${response.status}: ${JSON.stringify(body)}`);
  }
  return body;
}

async function textSearchPlace(query, apiKey) {
  const url = new URL('https://maps.googleapis.com/maps/api/place/textsearch/json');
  url.searchParams.set('query', query);
  url.searchParams.set('key', apiKey);
  url.searchParams.set('language', 'th');
  url.searchParams.set('region', 'th');

  const data = await fetchJson(url);
  const status = data.status ?? '';
  if (status === 'ZERO_RESULTS') return { placeId: '', photoRefs: [] };
  if (status !== 'OK') {
    throw new Error(`Places Text Search status=${status}: ${data.error_message ?? ''}`);
  }

  const candidates = (data.results ?? []).slice(0, 5);
  if (!candidates.length) return { placeId: '', photoRefs: [] };
  for (const candidate of candidates) {
    const photoRefs = (candidate.photos ?? [])
      .map((photo) => photo.photo_reference)
      .filter(Boolean);
    if (photoRefs.length) {
      return {
        placeId: candidate.place_id ?? '',
        photoRefs,
      };
    }
  }

  const first = candidates[0];
  return {
    placeId: first.place_id ?? '',
    photoRefs: [],
  };
}

async function nearbySearchPlace(place, query, apiKey) {
  const coordinates = getCoordinates(place);
  if (!coordinates) return { placeId: '', photoRefs: [] };

  const url = new URL('https://maps.googleapis.com/maps/api/place/nearbysearch/json');
  url.searchParams.set('location', `${coordinates.lat},${coordinates.lng}`);
  url.searchParams.set('radius', '3500');
  url.searchParams.set('keyword', query);
  url.searchParams.set('key', apiKey);
  url.searchParams.set('language', 'th');

  const data = await fetchJson(url);
  const status = data.status ?? '';
  if (status === 'ZERO_RESULTS') return { placeId: '', photoRefs: [] };
  if (status !== 'OK') {
    throw new Error(`Places Nearby Search status=${status}: ${data.error_message ?? ''}`);
  }

  const candidates = (data.results ?? []).slice(0, 5);
  for (const candidate of candidates) {
    const photoRefs = (candidate.photos ?? [])
      .map((photo) => photo.photo_reference)
      .filter(Boolean);
    if (photoRefs.length) {
      return {
        placeId: candidate.place_id ?? '',
        photoRefs,
      };
    }
  }
  return { placeId: candidates[0]?.place_id ?? '', photoRefs: [] };
}

async function placeDetailsPhotos(placeId, apiKey) {
  const url = new URL('https://maps.googleapis.com/maps/api/place/details/json');
  url.searchParams.set('place_id', placeId);
  url.searchParams.set('fields', 'photos');
  url.searchParams.set('key', apiKey);
  url.searchParams.set('language', 'th');

  const data = await fetchJson(url);
  const status = data.status ?? '';
  if (status === 'ZERO_RESULTS') return [];
  if (status !== 'OK') {
    throw new Error(`Place Details status=${status}: ${data.error_message ?? ''}`);
  }

  return (data.result?.photos ?? [])
    .slice(0, maxImages)
    .map((photo) => photo.photo_reference)
    .filter(Boolean);
}

async function downloadPlacePhoto(photoReference, apiKey) {
  const url = new URL('https://maps.googleapis.com/maps/api/place/photo');
  url.searchParams.set('maxwidth', String(maxWidth));
  url.searchParams.set('photo_reference', photoReference);
  url.searchParams.set('key', apiKey);

  const response = await fetchWithTimeout(url, {
    redirect: 'follow',
    headers: { 'User-Agent': 'travelthai-places-storage-images/1.0' },
  });
  if (!response.ok) {
    throw new Error(`Photo download failed: HTTP ${response.status}`);
  }

  const contentType = response.headers.get('content-type') ?? 'image/jpeg';
  if (!contentType.startsWith('image/')) {
    throw new Error(`Photo endpoint returned ${contentType}`);
  }

  return {
    bytes: Buffer.from(await response.arrayBuffer()),
    contentType,
  };
}

function extensionFromContentType(contentType) {
  if (contentType.includes('png')) return 'png';
  if (contentType.includes('webp')) return 'webp';
  return 'jpg';
}

async function uploadImage(accessToken, documentId, imageIndex, image) {
  const extension = extensionFromContentType(image.contentType);
  const objectPath = `attraction_images/${documentId}/photo_${String(imageIndex + 1).padStart(2, '0')}.${extension}`;
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

function toFirestoreValue(value) {
  if (Array.isArray(value)) {
    return { arrayValue: { values: value.map((item) => ({ stringValue: item })) } };
  }
  if (typeof value === 'string' && /^\d{4}-\d{2}-\d{2}T/.test(value)) {
    return { timestampValue: value };
  }
  return { stringValue: String(value) };
}

async function updateAttractionImages(accessToken, documentId, images) {
  const fields = {
    images: toFirestoreValue(images),
    updatedAt: toFirestoreValue(new Date().toISOString()),
  };
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
    body: JSON.stringify({ fields }),
  });
  const body = await response.json();
  if (
    !response.ok &&
    (response.status === 401 || response.status === 403) &&
    process.env.GOOGLE_API_KEY
  ) {
    const apiKeyUrl = new URL(url);
    apiKeyUrl.searchParams.set('key', process.env.GOOGLE_API_KEY);
    const apiKeyResponse = await fetchWithTimeout(apiKeyUrl, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ fields }),
    });
    const apiKeyBody = await apiKeyResponse.json();
    if (!apiKeyResponse.ok) {
      throw new Error(`Firestore update failed: ${JSON.stringify(apiKeyBody, null, 2)}`);
    }
    return;
  }
  if (!response.ok) {
    throw new Error(`Firestore update failed: ${JSON.stringify(body, null, 2)}`);
  }
}

async function findPhotoRefs(place, apiKey) {
  for (const query of buildQueries(place)) {
    const result = await textSearchPlace(query, apiKey);
    if (!result.placeId) continue;
    const detailsRefs = await placeDetailsPhotos(result.placeId, apiKey);
    const photoRefs = [...new Set([...result.photoRefs, ...detailsRefs])].slice(0, maxImages);
    if (photoRefs.length) {
      return {
        placeId: result.placeId,
        photoRefs,
        query,
      };
    }
  }

  for (const query of buildQueries(place)) {
    const result = await nearbySearchPlace(place, query, apiKey);
    if (!result.placeId) continue;
    const detailsRefs = await placeDetailsPhotos(result.placeId, apiKey);
    const photoRefs = [...new Set([...result.photoRefs, ...detailsRefs])].slice(0, maxImages);
    if (photoRefs.length) {
      return {
        placeId: result.placeId,
        photoRefs,
        query: `nearby:${query}`,
      };
    }
  }

  return { placeId: '', photoRefs: [], query: '' };
}

async function main() {
  await loadEnv(envPath);
  const apiKey = (process.env.GOOGLE_PLACES_API_KEY ?? process.env.GOOGLE_API_KEY ?? '').trim();
  if (!apiKey) {
    throw new Error('Missing GOOGLE_API_KEY or GOOGLE_PLACES_API_KEY in tools/media_enrichment.env');
  }

  const accessToken = dryRun ? '' : getAccessToken();
  const places = JSON.parse(await fs.readFile(inputPath, 'utf8'));
  if (!Array.isArray(places)) throw new Error(`Expected JSON array: ${inputPath}`);

  const end = limit > 0 ? Math.min(places.length, start - 1 + limit) : places.length;
  let processed = 0;
  let updated = 0;
  let skipped = 0;

  console.log(`Input: ${inputPath}`);
  console.log(`Rows: ${start}-${end}`);
  console.log(`Dry run: ${dryRun}`);
  console.log(`Overwrite existing Storage images: ${overwrite}`);
  console.log(`Only non-Storage images: ${onlyNonStorage}`);
  console.log(`Quiet skips: ${quietSkips}`);

  for (let index = start - 1; index < end; index++) {
    const place = places[index];
    const documentId = documentIdFor(place, index);
    const placeName = cleanText(place.nameTh) || cleanText(place.nameEn) || documentId;

    if ((!overwrite || onlyNonStorage) && hasStorageImages(place)) {
      skipped++;
      if (!quietSkips) {
        console.log(`[skip] ${index + 1}: ${placeName} already has Storage images`);
      }
      continue;
    }

    try {
      const found = await findPhotoRefs(place, apiKey);
      processed++;
      if (!found.photoRefs.length) {
        console.log(`[none] ${index + 1}: ${placeName} no photo found`);
        await sleep(delayMs);
        continue;
      }

      if (dryRun) {
        console.log(
          `[dry] ${index + 1}: ${placeName} query="${found.query}" photos=${found.photoRefs.length}`,
        );
        await sleep(delayMs);
        continue;
      }

      const storageUrls = [];
      for (let photoIndex = 0; photoIndex < found.photoRefs.length; photoIndex++) {
        const image = await downloadPlacePhoto(found.photoRefs[photoIndex], apiKey);
        const storageUrl = await uploadImage(accessToken, documentId, photoIndex, image);
        storageUrls.push(storageUrl);
      }

      await updateAttractionImages(accessToken, documentId, storageUrls);
      if (updateJson) {
        place.images = storageUrls;
        await fs.writeFile(inputPath, `${JSON.stringify(places, null, 2)}\n`, 'utf8');
      }

      updated++;
      console.log(`[ok] ${index + 1}: ${placeName} images=${storageUrls.length}`);
      await sleep(delayMs);
    } catch (error) {
      console.error(`[error] ${index + 1}: ${placeName}: ${error.message}`);
      await sleep(delayMs);
    }
  }

  console.log(`Done. processed=${processed} updated=${updated} skipped=${skipped}`);
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
