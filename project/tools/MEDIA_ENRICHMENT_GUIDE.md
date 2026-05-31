# Attraction Media Enrichment Guide

This script adds two columns to a copied Excel dataset:

- `IMAGE_URLS`
- `YOUTUBE_URLS`

Multiple URLs are separated with `|`.

## 1. Create Google API Key

1. Open Google Cloud Console: https://console.cloud.google.com/
2. Create or select a project.
3. Go to **APIs & Services > Library**.
4. Enable these APIs:
   - **Custom Search API**
   - **YouTube Data API v3**
5. Go to **APIs & Services > Credentials**.
6. Click **Create credentials > API key**.
7. Copy the API key.

## 2. Create Programmable Search Engine ID

1. Open https://programmablesearchengine.google.com/
2. Create a new search engine.
3. Set it to search the entire web.
4. Turn on image search if the setting is available.
5. Copy the **Search engine ID**. This is the `GOOGLE_CSE_ID`.

## 3. Create Local Env File

Copy:

```powershell
Copy-Item tools\media_enrichment.env.example tools\media_enrichment.env
```

Edit `tools/media_enrichment.env`:

```env
GOOGLE_API_KEY=your_api_key
GOOGLE_CSE_ID=your_search_engine_id
```

Do not commit or share this file.

## 4. Run 20-Row Test

```powershell
& 'C:\Users\poomp\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' tools\enrich_attraction_media.py `
  --input 'C:\Users\poomp\OneDrive - Rajamangala University of Technology Thanyaburi\Project\Chapter 1 2 3\Dataset\#5 finish_attraction.xlsx' `
  --output 'C:\Users\poomp\OneDrive - Rajamangala University of Technology Thanyaburi\Project\Chapter 1 2 3\Dataset\#5 finish_attraction_media_sample.xlsx' `
  --limit 20
```

Check the output file. If the links look good, increase `--limit`.

## 5. Run All Rows Later

```powershell
& 'C:\Users\poomp\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' tools\enrich_attraction_media.py `
  --input 'C:\Users\poomp\OneDrive - Rajamangala University of Technology Thanyaburi\Project\Chapter 1 2 3\Dataset\#5 finish_attraction.xlsx' `
  --output 'C:\Users\poomp\OneDrive - Rajamangala University of Technology Thanyaburi\Project\Chapter 1 2 3\Dataset\#5 finish_attraction_media_full.xlsx' `
  --limit 0
```

## YouTube-Only Batch Workflow

Use Thai search first to save quota. This uses only one YouTube request per row.

```powershell
& 'C:\Users\poomp\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' tools\enrich_attraction_media.py `
  --input 'C:\Users\poomp\OneDrive - Rajamangala University of Technology Thanyaburi\Project\Chapter 1 2 3\Dataset\#5 finish_attraction.xlsx' `
  --output 'C:\Users\poomp\OneDrive - Rajamangala University of Technology Thanyaburi\Project\Chapter 1 2 3\Dataset\#5 finish_attraction_youtube_batch_52_101.xlsx' `
  --start-row 52 `
  --limit 50 `
  --media youtube `
  --youtube-query-mode thai-only
```

After that, run English fallback only for rows that are still blank.

```powershell
& 'C:\Users\poomp\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' tools\enrich_attraction_media.py `
  --input 'C:\Users\poomp\OneDrive - Rajamangala University of Technology Thanyaburi\Project\Chapter 1 2 3\Dataset\#5 finish_attraction_youtube_batch_52_101.xlsx' `
  --output 'C:\Users\poomp\OneDrive - Rajamangala University of Technology Thanyaburi\Project\Chapter 1 2 3\Dataset\#5 finish_attraction_youtube_batch_52_101_fallback.xlsx' `
  --start-row 52 `
  --limit 50 `
  --media youtube `
  --youtube-query-mode english-only
```
