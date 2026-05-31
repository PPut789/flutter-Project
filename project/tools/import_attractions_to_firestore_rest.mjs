import { execFileSync } from 'node:child_process';
import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const projectId = 'travelrecommendation-851e9';
const databaseId = '(default)';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const projectRoot = path.resolve(__dirname, '..');
const defaultInputPath = path.join(
  projectRoot,
  'dataset',
  'attractions.json',
);

const args = new Map(
  process.argv.slice(2).map((arg) => {
    const [key, value] = arg.split('=');
    return [key.replace(/^--/, ''), value ?? 'true'];
  }),
);

const inputPath = path.resolve(args.get('input') ?? defaultInputPath);
const collectionName = args.get('collection') ?? 'attractions';
const limit = Number(args.get('limit') ?? 0);
const batchSize = Number(args.get('batch-size') ?? 100);
const delayMs = Number(args.get('delay-ms') ?? 700);
const dryRun = args.get('dry-run') === 'true';

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

function cleanText(value) {
  return typeof value === 'string' ? value.trim() : '';
}

function cleanStringList(value) {
  if (!Array.isArray(value)) return [];
  return value
    .filter((item) => typeof item === 'string')
    .map((item) => item.trim())
    .filter(Boolean);
}

function cleanNumber(value) {
  return Number.isFinite(value) ? value : null;
}

function normalizePlace(raw, index) {
  const rawId = cleanText(raw.id) || `row-${index + 1}`;
  const safeId = rawId.replaceAll('/', '_');
  const documentId = `att_${String(index + 1).padStart(4, '0')}_${safeId}`;

  return {
    documentId,
    data: {
      sourceRow: index + 1,
      id: rawId,
      nameTh: cleanText(raw.nameTh),
      nameEn: cleanText(raw.nameEn),
      description: cleanText(raw.description),
      telephone: cleanText(raw.telephone),
      email: cleanText(raw.email),
      highlight: cleanText(raw.highlight),
      location: cleanText(raw.location),
      latitude: cleanNumber(raw.latitude),
      longitude: cleanNumber(raw.longitude),
      region: cleanText(raw.region),
      province: cleanText(raw.province),
      district: cleanText(raw.district),
      subdistrict: cleanText(raw.subdistrict),
      category: cleanText(raw.category),
      type: cleanText(raw.type),
      activity: cleanText(raw.activity),
      images: cleanStringList(raw.images),
      youtubeUrl: cleanText(raw.youtubeUrl),
      youtubeUrls: cleanStringList(raw.youtubeUrls),
      tiktokUrls: cleanStringList(raw.tiktokUrls),
      videoUrls: cleanStringList(raw.videoUrls),
      tags: cleanStringList(raw.tags),
      updatedAt: new Date().toISOString(),
    },
  };
}

function toFirestoreValue(value) {
  if (value === null || value === undefined) return { nullValue: null };
  if (typeof value === 'string') {
    if (/^\d{4}-\d{2}-\d{2}T/.test(value)) return { timestampValue: value };
    return { stringValue: value };
  }
  if (typeof value === 'boolean') return { booleanValue: value };
  if (typeof value === 'number') {
    if (Number.isInteger(value)) return { integerValue: String(value) };
    return { doubleValue: value };
  }
  if (Array.isArray(value)) {
    return { arrayValue: { values: value.map(toFirestoreValue) } };
  }
  if (typeof value === 'object') {
    return {
      mapValue: {
        fields: Object.fromEntries(
          Object.entries(value).map(([key, nestedValue]) => [
            key,
            toFirestoreValue(nestedValue),
          ]),
        ),
      },
    };
  }
  return { stringValue: String(value) };
}

function toFirestoreFields(data) {
  return Object.fromEntries(
    Object.entries(data).map(([key, value]) => [key, toFirestoreValue(value)]),
  );
}

async function batchWrite(accessToken, rows, batchIndex) {
  const writes = rows.map((row) => {
    const fields = toFirestoreFields(row.data);
    return {
      update: {
        name: `projects/${projectId}/databases/${databaseId}/documents/${collectionName}/${row.documentId}`,
        fields,
      },
      updateMask: {
        fieldPaths: Object.keys(fields),
      },
    };
  });

  const response = await fetch(
    `https://firestore.googleapis.com/v1/projects/${projectId}/databases/${databaseId}/documents:batchWrite`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ writes }),
    },
  );

  const body = await response.json();
  if (!response.ok) {
    throw new Error(JSON.stringify(body, null, 2));
  }

  const failed = body.status?.filter((status) => status.code) ?? [];
  if (failed.length > 0) {
    throw new Error(`Batch ${batchIndex} failed: ${JSON.stringify(failed, null, 2)}`);
  }

  console.log(`Committed REST batch ${batchIndex}: ${rows.length} documents`);
}

async function countDocuments(accessToken) {
  const response = await fetch(
    `https://firestore.googleapis.com/v1/projects/${projectId}/databases/${databaseId}/documents:runAggregationQuery`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        structuredAggregationQuery: {
          structuredQuery: {
            from: [{ collectionId: collectionName }],
          },
          aggregations: [{ count: {}, alias: 'total' }],
        },
      }),
    },
  );

  const body = await response.json();
  if (!response.ok) {
    throw new Error(JSON.stringify(body, null, 2));
  }

  return body?.[0]?.result?.aggregateFields?.total?.integerValue ?? '0';
}

async function main() {
  const json = await fs.readFile(inputPath, 'utf8');
  const rawPlaces = JSON.parse(json);
  if (!Array.isArray(rawPlaces)) throw new Error(`Expected JSON array in ${inputPath}`);

  const selectedPlaces = limit > 0 ? rawPlaces.slice(0, limit) : rawPlaces;
  const places = selectedPlaces.map(normalizePlace);

  console.log(`Input: ${inputPath}`);
  console.log(`Collection: ${collectionName}`);
  console.log(`Documents prepared: ${places.length}`);

  if (dryRun) {
    console.log(JSON.stringify(places[0], null, 2));
    return;
  }

  const accessToken = getAccessToken();
  for (let start = 0, batchIndex = 1; start < places.length; start += batchSize) {
    await batchWrite(accessToken, places.slice(start, start + batchSize), batchIndex);
    batchIndex++;
    if (start + batchSize < places.length && delayMs > 0) await sleep(delayMs);
  }

  const total = await countDocuments(accessToken);
  console.log(`Done. Firestore ${collectionName} count: ${total}`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
