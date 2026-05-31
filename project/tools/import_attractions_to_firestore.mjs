import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import { initializeApp } from 'firebase/app';
import {
  collection,
  doc,
  getCountFromServer,
  getFirestore,
  serverTimestamp,
  writeBatch,
} from 'firebase/firestore';

const firebaseConfig = {
  apiKey: 'AIzaSyDTA1zIbSBE5sg27fuJQPABEwm-lVZVYcU',
  authDomain: 'travelrecommendation-851e9.firebaseapp.com',
  projectId: 'travelrecommendation-851e9',
  storageBucket: 'travelrecommendation-851e9.firebasestorage.app',
  messagingSenderId: '1051392765409',
  appId: '1:1051392765409:web:943893d03705ea45c4b6a0',
};

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
const dryRun = args.get('dry-run') === 'true';
const batchSize = Number(args.get('batch-size') ?? 100);
const delayMs = Number(args.get('delay-ms') ?? 1200);

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
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
      updatedAt: serverTimestamp(),
    },
  };
}

async function commitBatch(db, rows, batchIndex) {
  const batch = writeBatch(db);
  for (const row of rows) {
    const ref = doc(collection(db, collectionName), row.documentId);
    batch.set(ref, row.data, { merge: true });
  }

  await batch.commit();
  console.log(
    `Committed batch ${batchIndex}: ${rows.length} documents to ${collectionName}`,
  );
}

async function main() {
  const json = await fs.readFile(inputPath, 'utf8');
  const rawPlaces = JSON.parse(json);

  if (!Array.isArray(rawPlaces)) {
    throw new Error(`Expected JSON array in ${inputPath}`);
  }

  const selectedPlaces = limit > 0 ? rawPlaces.slice(0, limit) : rawPlaces;
  const places = selectedPlaces.map(normalizePlace);

  console.log(`Input: ${inputPath}`);
  console.log(`Collection: ${collectionName}`);
  console.log(`Documents prepared: ${places.length}`);

  if (dryRun) {
    console.log('Dry run only. First document preview:');
    console.log(JSON.stringify(places[0], null, 2));
    return;
  }

  const app = initializeApp(firebaseConfig);
  const db = getFirestore(app);

  for (let start = 0, batchIndex = 1; start < places.length; start += batchSize) {
    const batchRows = places.slice(start, start + batchSize);
    await commitBatch(db, batchRows, batchIndex);
    if (start + batchSize < places.length && delayMs > 0) {
      await sleep(delayMs);
    }
    batchIndex++;
  }

  await sleep(5000);

  const snapshot = await getCountFromServer(collection(db, collectionName));
  console.log(
    `Done. Firestore ${collectionName} count: ${snapshot.data().count}`,
  );
}

main()
  .then(() => {
    process.exit(0);
  })
  .catch((error) => {
  console.error(error);
  process.exit(1);
  });
