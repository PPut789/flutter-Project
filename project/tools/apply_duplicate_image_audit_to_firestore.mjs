import fs from 'node:fs/promises';
import crypto from 'node:crypto';
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

const reportPath = path.resolve(
  args.get('report') ??
    path.join(
      projectRoot,
      'dataset',
      'image_duplicate_audit',
      'duplicate_image_audit_2026-08-29T07-48-05Z.json',
    ),
);
const collectionName = args.get('collection') ?? 'attractions';
const dryRun = args.get('dry-run') !== 'false';
const skipFailed = args.get('skip-failed') !== 'false';
const serviceAccountPath = args.get('service-account') ?? process.env.GOOGLE_APPLICATION_CREDENTIALS;

function base64Url(value) {
  return Buffer.from(value)
    .toString('base64')
    .replaceAll('+', '-')
    .replaceAll('/', '_')
    .replaceAll('=', '');
}

async function getAccessTokenFromServiceAccount() {
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
  const header = { alg: 'RS256', typ: 'JWT' };
  const claimSet = {
    iss: serviceAccount.client_email,
    scope: 'https://www.googleapis.com/auth/datastore',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  };
  const unsignedJwt = `${base64Url(JSON.stringify(header))}.${base64Url(JSON.stringify(claimSet))}`;
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

async function fetchWithTimeout(url, options = {}, timeoutMs = 30000) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMs);
  try {
    return await fetch(url, { ...options, signal: controller.signal });
  } finally {
    clearTimeout(timeout);
  }
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

async function main() {
  const audit = JSON.parse(await fs.readFile(reportPath, 'utf8'));
  const candidates = audit.places.filter((item) => {
    if (item.duplicateImageCount <= 0) return false;
    if (!Array.isArray(item.keptUrls) || item.keptUrls.length === 0) return false;
    if (skipFailed && item.failedImageCount > 0) return false;
    return true;
  });

  console.log(`Report: ${path.relative(projectRoot, reportPath)}`);
  console.log(`Mode: ${dryRun ? 'dry-run' : 'apply'}`);
  console.log(`Candidates: ${candidates.length}`);

  if (dryRun) {
    for (const item of candidates.slice(0, 10)) {
      console.log(
        `[dry] ${item.documentId} ${item.nameTh}: ${item.originalImageCount} -> ${item.keptUrls.length}`,
      );
    }
    if (candidates.length > 10) {
      console.log(`[dry] ...and ${candidates.length - 10} more`);
    }
    return;
  }

  const accessToken = await getAccessTokenFromServiceAccount();
  let updated = 0;
  let failed = 0;

  for (const item of candidates) {
    try {
      await updateAttractionImages(accessToken, item.documentId, item.keptUrls);
      updated++;
      if (updated % 100 === 0 || updated === candidates.length) {
        console.log(`${updated}/${candidates.length} updated, latest=${item.nameTh}`);
      }
    } catch (error) {
      failed++;
      console.error(`[error] ${item.documentId} ${item.nameTh}: ${String(error.message).slice(0, 500)}`);
    }
  }

  console.log(JSON.stringify({ updated, failed }, null, 2));
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
