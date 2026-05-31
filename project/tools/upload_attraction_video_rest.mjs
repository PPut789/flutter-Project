import { execFileSync } from 'node:child_process';
import { randomUUID } from 'node:crypto';
import fs from 'node:fs/promises';
import path from 'node:path';

const projectId = 'travelrecommendation-851e9';
const databaseId = '(default)';
const bucket = 'travelrecommendation-851e9.firebasestorage.app';

const args = new Map(
  process.argv.slice(2).map((arg) => {
    const [key, ...valueParts] = arg.split('=');
    return [key.replace(/^--/, ''), valueParts.join('=') || 'true'];
  }),
);

const inputPath = path.resolve(args.get('file') ?? '');
const documentId = args.get('document-id') ?? '';
const objectName = args.get('object-name') ?? path.basename(inputPath);
const objectPath = `attraction_videos/${objectName}`;

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

function toFirestoreValue(value) {
  if (Array.isArray(value)) {
    return { arrayValue: { values: value.map((item) => ({ stringValue: item })) } };
  }
  return { timestampValue: value };
}

async function uploadVideo(accessToken) {
  const fileData = await fs.readFile(inputPath);
  const downloadToken = randomUUID();
  const url = new URL(`https://firebasestorage.googleapis.com/v0/b/${bucket}/o`);
  url.searchParams.set('uploadType', 'media');
  url.searchParams.set('name', objectPath);

  const response = await fetch(url, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'video/mp4',
      'X-Goog-Meta-FirebaseStorageDownloadTokens': downloadToken,
    },
    body: fileData,
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

  const verification = await fetch(downloadUrl, { method: 'HEAD' });
  if (!verification.ok) {
    throw new Error(`Uploaded file URL could not be verified: HTTP ${verification.status}`);
  }

  return { downloadUrl: downloadUrl.toString(), size: fileData.length };
}

async function updateAttraction(accessToken, downloadUrl) {
  const fields = {
    videoUrls: toFirestoreValue([downloadUrl]),
    updatedAt: toFirestoreValue(new Date().toISOString()),
  };
  const url = new URL(
    `https://firestore.googleapis.com/v1/projects/${projectId}/databases/${databaseId}/documents/attractions/${documentId}`,
  );
  url.searchParams.append('updateMask.fieldPaths', 'videoUrls');
  url.searchParams.append('updateMask.fieldPaths', 'updatedAt');

  const response = await fetch(url, {
    method: 'PATCH',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ fields }),
  });
  const body = await response.json();
  if (!response.ok) {
    throw new Error(`Firestore update failed: ${JSON.stringify(body, null, 2)}`);
  }
}

async function main() {
  if (!inputPath || !documentId) {
    throw new Error(
      'Usage: node tools/upload_attraction_video_rest.mjs --file=PATH --document-id=DOCUMENT_ID --object-name=FILE.mp4',
    );
  }

  await fs.access(inputPath);
  const accessToken = getAccessToken();
  const uploaded = await uploadVideo(accessToken);
  await updateAttraction(accessToken, uploaded.downloadUrl);

  console.log(`Uploaded: ${objectPath}`);
  console.log(`Size: ${uploaded.size} bytes`);
  console.log(`Updated attraction: ${documentId}`);
  console.log(`Download URL: ${uploaded.downloadUrl}`);
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
