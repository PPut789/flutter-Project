import crypto from 'node:crypto';
import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const projectId = 'travelrecommendation-851e9';
const databaseId = '(default)';
const collectionName = 'attractions';
const bucketName = 'travelrecommendation-851e9.firebasestorage.app';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const projectRoot = path.resolve(__dirname, '..');

const args = new Map(
  process.argv.slice(2).map((arg) => {
    const [key, ...valueParts] = arg.split('=');
    return [key.replace(/^--/, ''), valueParts.join('=') || 'true'];
  }),
);

const backupRoot = path.resolve(
  args.get('backup-root') ?? path.join(projectRoot, 'backup', 'attraction_images_full'),
);
const inputPath = path.resolve(
  args.get('input') ?? path.join(projectRoot, 'dataset', 'attractions.json'),
);
const serviceAccountPath = args.get('service-account') ?? process.env.GOOGLE_APPLICATION_CREDENTIALS;
const storagePrefix = args.get('storage-prefix') ?? 'attraction_images_local_backup';
const dryRun = args.get('dry-run') === 'true';
const overwrite = args.get('overwrite') === 'true';
const updateFirestore = args.get('update-firestore') !== 'false';
const updateDataset = args.get('update-dataset') !== 'false';
const concurrency = Math.max(1, Number(args.get('concurrency') ?? 4));
const limit = Math.max(0, Number(args.get('limit') ?? 0));

function base64Url(value) {
  return Buffer.from(value)
    .toString('base64')
    .replaceAll('+', '-')
    .replaceAll('/', '_')
    .replaceAll('=', '');
}

async function getAccessToken(scope) {
  if (!serviceAccountPath) {
    throw new Error(
      'Service account key is required. Pass --service-account=C:\\path\\key.json or set GOOGLE_APPLICATION_CREDENTIALS.',
    );
  }

  const serviceAccount = JSON.parse(await fs.readFile(path.resolve(serviceAccountPath), 'utf8'));
  if (!serviceAccount.client_email || !serviceAccount.private_key) {
    throw new Error('Invalid service account key: missing client_email or private_key.');
  }

  const now = Math.floor(Date.now() / 1000);
  const unsignedJwt = `${base64Url(JSON.stringify({ alg: 'RS256', typ: 'JWT' }))}.${base64Url(
    JSON.stringify({
      iss: serviceAccount.client_email,
      scope,
      aud: 'https://oauth2.googleapis.com/token',
      iat: now,
      exp: now + 3600,
    }),
  )}`;
  const signature = crypto
    .createSign('RSA-SHA256')
    .update(unsignedJwt)
    .sign(serviceAccount.private_key);
  const jwt = `${unsignedJwt}.${base64Url(signature)}`;

  const response = await fetchWithTimeout('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  });

  const body = await response.json();
  if (!response.ok || !body.access_token) {
    throw new Error(`OAuth token request failed: ${JSON.stringify(body)}`);
  }
  return body.access_token;
}

async function fetchWithTimeout(url, options = {}, timeoutMs = 60000) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMs);
  try {
    return await fetch(url, { ...options, signal: controller.signal });
  } finally {
    clearTimeout(timeout);
  }
}

async function walkMetadataFiles(root) {
  const output = [];

  async function walk(current) {
    const entries = await fs.readdir(current, { withFileTypes: true });
    for (const entry of entries) {
      const fullPath = path.join(current, entry.name);
      if (entry.isDirectory()) {
        await walk(fullPath);
      } else if (entry.isFile() && entry.name === 'metadata.json') {
        output.push(fullPath);
      }
    }
  }

  await walk(root);
  output.sort((a, b) => a.localeCompare(b, 'th'));
  return output;
}

function extensionContentType(filename, fallback = 'image/jpeg') {
  const extension = path.extname(filename).toLowerCase();
  if (extension === '.png') return 'image/png';
  if (extension === '.webp') return 'image/webp';
  if (extension === '.gif') return 'image/gif';
  if (extension === '.jpg' || extension === '.jpeg') return 'image/jpeg';
  return fallback;
}

function encodeStoragePath(objectPath) {
  return encodeURIComponent(objectPath);
}

function downloadUrlFor(objectPath, token) {
  return `https://firebasestorage.googleapis.com/v0/b/${bucketName}/o/${encodeStoragePath(objectPath)}?alt=media&token=${token}`;
}

async function uploadObject(storageToken, objectPath, filePath, contentType, downloadToken) {
  const bytes = await fs.readFile(filePath);
  const metadata = {
    name: objectPath,
    contentType,
    metadata: {
      firebaseStorageDownloadTokens: downloadToken,
      migratedFromLocalBackup: 'true',
    },
  };
  const boundary = `codex-${crypto.randomUUID()}`;
  const body = Buffer.concat([
    Buffer.from(
      `--${boundary}\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n${JSON.stringify(
        metadata,
      )}\r\n--${boundary}\r\nContent-Type: ${contentType}\r\n\r\n`,
    ),
    bytes,
    Buffer.from(`\r\n--${boundary}--\r\n`),
  ]);

  const url = new URL(`https://storage.googleapis.com/upload/storage/v1/b/${bucketName}/o`);
  url.searchParams.set('uploadType', 'multipart');
  url.searchParams.set('name', objectPath);

  const response = await fetchWithTimeout(url, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${storageToken}`,
      'Content-Type': `multipart/related; boundary=${boundary}`,
      'Content-Length': String(body.length),
    },
    body,
  });

  const result = await response.json();
  if (!response.ok) {
    throw new Error(`Storage upload failed: ${JSON.stringify(result).slice(0, 700)}`);
  }
  return {
    bytes: bytes.length,
    md5Hash: result.md5Hash ?? '',
  };
}

function toFirestoreImages(images) {
  return { arrayValue: { values: images.map((url) => ({ stringValue: url })) } };
}

async function updateFirestoreImages(firestoreToken, documentId, imageUrls) {
  const url = new URL(
    `https://firestore.googleapis.com/v1/projects/${projectId}/databases/${databaseId}/documents/${collectionName}/${documentId}`,
  );
  url.searchParams.append('updateMask.fieldPaths', 'images');
  url.searchParams.append('updateMask.fieldPaths', 'updatedAt');

  const response = await fetchWithTimeout(url, {
    method: 'PATCH',
    headers: {
      Authorization: `Bearer ${firestoreToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      fields: {
        images: toFirestoreImages(imageUrls),
        updatedAt: { timestampValue: new Date().toISOString() },
      },
    }),
  });

  const body = await response.json();
  if (!response.ok) {
    throw new Error(`Firestore update failed: ${JSON.stringify(body).slice(0, 700)}`);
  }
}

async function readJson(filePath) {
  return JSON.parse(await fs.readFile(filePath, 'utf8'));
}

async function pathExists(filePath) {
  try {
    await fs.access(filePath);
    return true;
  } catch {
    return false;
  }
}

async function processPlace(metadataPath, tokens) {
  const dir = path.dirname(metadataPath);
  const uploadManifestPath = path.join(dir, 'firebase_upload_manifest.json');
  const metadata = await readJson(metadataPath);

  if (!overwrite && (await pathExists(uploadManifestPath))) {
    const manifest = await readJson(uploadManifestPath);
    if (Array.isArray(manifest.firebaseImageUrls) && manifest.firebaseImageUrls.length > 0) {
      if (updateFirestore && !dryRun && !manifest.firestoreUpdatedAt) {
        await updateFirestoreImages(tokens.firestore, metadata.documentId, manifest.firebaseImageUrls);
        manifest.firestoreUpdatedAt = new Date().toISOString();
        await fs.writeFile(uploadManifestPath, `${JSON.stringify(manifest, null, 2)}\n`, 'utf8');
      }
      return {
        status: 'exists',
        documentId: metadata.documentId,
        nameTh: metadata.nameTh,
        imageCount: manifest.firebaseImageUrls.length,
        firebaseImageUrls: manifest.firebaseImageUrls,
      };
    }
  }

  const uploadedImages = [];
  for (const image of metadata.images ?? []) {
    const filename = image.filename;
    const filePath = path.join(dir, filename);
    const downloadToken = crypto.randomUUID();
    const objectPath = `${storagePrefix}/${metadata.documentId}/${filename}`;
    const contentType = image.contentType || extensionContentType(filename);
    const firebaseUrl = downloadUrlFor(objectPath, downloadToken);

    if (!dryRun) {
      const upload = await uploadObject(tokens.storage, objectPath, filePath, contentType, downloadToken);
      uploadedImages.push({
        filename,
        objectPath,
        firebaseUrl,
        contentType,
        sourceBackupBytes: image.bytes ?? upload.bytes,
        uploadedBytes: upload.bytes,
        sourceSha256: image.sha256 ?? '',
        gcsMd5Hash: upload.md5Hash,
      });
    } else {
      uploadedImages.push({
        filename,
        objectPath,
        firebaseUrl,
        contentType,
        sourceBackupBytes: image.bytes ?? 0,
        uploadedBytes: 0,
        sourceSha256: image.sha256 ?? '',
        gcsMd5Hash: '',
      });
    }
  }

  const firebaseImageUrls = uploadedImages.map((image) => image.firebaseUrl);
  const manifest = {
    documentId: metadata.documentId,
    sourceRow: metadata.sourceRow,
    id: metadata.id,
    nameTh: metadata.nameTh,
    nameEn: metadata.nameEn,
    region: metadata.region,
    province: metadata.province,
    storagePrefix,
    uploadedAt: dryRun ? null : new Date().toISOString(),
    firestoreUpdatedAt: null,
    firebaseImageUrls,
    uploadedImages,
  };

  if (updateFirestore && !dryRun) {
    await updateFirestoreImages(tokens.firestore, metadata.documentId, firebaseImageUrls);
    manifest.firestoreUpdatedAt = new Date().toISOString();
  }

  if (!dryRun) {
    await fs.writeFile(uploadManifestPath, `${JSON.stringify(manifest, null, 2)}\n`, 'utf8');
  }

  return {
    status: dryRun ? 'dry' : 'uploaded',
    documentId: metadata.documentId,
    nameTh: metadata.nameTh,
    imageCount: firebaseImageUrls.length,
    firebaseImageUrls,
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

function documentIdFor(raw, index) {
  const rawId = typeof raw.id === 'string' && raw.id.trim() ? raw.id.trim() : `row-${index + 1}`;
  return `att_${String(index + 1).padStart(4, '0')}_${rawId.replaceAll('/', '_')}`;
}

async function updateLocalDataset(uploadResults) {
  const rows = await readJson(inputPath);
  const urlsByDocumentId = new Map(
    uploadResults
      .filter((result) => result?.firebaseImageUrls?.length > 0)
      .map((result) => [result.documentId, result.firebaseImageUrls]),
  );
  let changed = 0;

  for (let index = 0; index < rows.length; index++) {
    const documentId = documentIdFor(rows[index], index);
    const urls = urlsByDocumentId.get(documentId);
    if (!urls) continue;
    rows[index].images = urls;
    changed++;
  }

  if (!dryRun) {
    const backupPath = `${inputPath}.before-local-backup-upload-${new Date()
      .toISOString()
      .replace(/[:.]/g, '-')}.bak`;
    await fs.copyFile(inputPath, backupPath);
    await fs.writeFile(inputPath, `${JSON.stringify(rows, null, 2)}\n`, 'utf8');
    console.log(`Updated local dataset images: ${changed}`);
    console.log(`Dataset backup: ${backupPath}`);
  }

  return changed;
}

async function main() {
  const metadataFiles = await walkMetadataFiles(backupRoot);
  const selectedMetadataFiles = limit > 0 ? metadataFiles.slice(0, limit) : metadataFiles;

  console.log(`Backup root: ${backupRoot}`);
  console.log(`Metadata files: ${metadataFiles.length}`);
  console.log(`Selected: ${selectedMetadataFiles.length}`);
  console.log(`Storage bucket: ${bucketName}`);
  console.log(`Storage prefix: ${storagePrefix}`);
  console.log(`Dry run: ${dryRun}`);
  console.log(`Update Firestore: ${updateFirestore}`);
  console.log(`Update dataset: ${updateDataset}`);

  const tokens = dryRun
    ? { storage: '', firestore: '' }
    : {
        storage: await getAccessToken('https://www.googleapis.com/auth/devstorage.read_write'),
        firestore: await getAccessToken('https://www.googleapis.com/auth/datastore'),
      };

  const failures = [];
  const results = await runPool(selectedMetadataFiles, concurrency, async (metadataPath, index) => {
    try {
      const result = await processPlace(metadataPath, tokens);
      const done = index + 1;
      if (done <= 10 || done % 50 === 0 || done === selectedMetadataFiles.length) {
        console.log(`${done}/${selectedMetadataFiles.length} ${result.status}: ${result.nameTh || result.documentId} (${result.imageCount})`);
      }
      return result;
    } catch (error) {
      const done = index + 1;
      const fallback = await readJson(metadataPath).catch(() => ({}));
      const failure = {
        index: done,
        metadataPath,
        documentId: fallback.documentId ?? '',
        nameTh: fallback.nameTh ?? '',
        error: error.message,
      };
      failures.push(failure);
      console.error(`${done}/${selectedMetadataFiles.length} failed: ${failure.nameTh || failure.documentId}: ${error.message}`);
      return { status: 'failed', ...failure };
    }
  });

  const datasetUpdated = updateDataset ? await updateLocalDataset(results) : 0;
  const summary = {
    selected: selectedMetadataFiles.length,
    uploaded: results.filter((result) => result?.status === 'uploaded').length,
    existing: results.filter((result) => result?.status === 'exists').length,
    dry: results.filter((result) => result?.status === 'dry').length,
    failed: failures.length,
    imageUrls: results.reduce((sum, result) => sum + (result?.firebaseImageUrls?.length ?? 0), 0),
    datasetUpdated,
    failures,
    completedAt: new Date().toISOString(),
  };

  const summaryPath = path.join(backupRoot, 'firebase_upload_summary.json');
  await fs.writeFile(summaryPath, `${JSON.stringify(summary, null, 2)}\n`, 'utf8');
  console.log(JSON.stringify(summary, null, 2));
  console.log(`Summary: ${summaryPath}`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
