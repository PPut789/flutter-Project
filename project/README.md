# Personalized Tourist Attraction Recommendation System

ระบบแนะนำสถานที่ท่องเที่ยวตามความสนใจส่วนบุคคลโดยใช้เทคนิคปัญญาประดิษฐ์

## Overview

Flutter mobile app for recommending tourist attractions in Thailand.
The app loads attraction data from Firebase Cloud Firestore collection
`attractions` and uses a trained Content-Based KNN model through a FastAPI
recommendation service.

## Main Structure

```text
lib/
  data/        Firestore repositories
  models/      App data models
  pages/       App screens
  widgets/     Shared UI and platform widgets

assets/
  backgrounds/ Start page background
  images/      Local fallback images
  logos/       App logo
  video/       Prototype short-video asset

dataset/
  analytics/      Dataset summary and feature tables
  model_results/  KNN/cosine experiment outputs
  youtube/        YouTube enrichment batch files

tools/
  Dataset enrichment and Firestore import scripts

backend/
  FastAPI service and trained KNN `.pkl` model

diagrams/
  System flowcharts and project diagrams
```

## Data Source

- Runtime app data: Firebase Firestore `attractions`
- Local dataset reference: `dataset/attractions.json`
- Enriched Excel dataset: `dataset/#5 finish_attraction_enriched.xlsx`

The old Flutter asset JSON file has been removed. Attraction data is no longer
registered under `assets/data/`.

## Run

```powershell
flutter pub get
flutter run
```

Run on web:

```powershell
flutter run -d chrome
```

Run the trained recommendation backend before opening Home recommendations:

```powershell
uv run --python 3.12 --with-requirements backend\requirements.txt uvicorn backend.main:app --host 127.0.0.1 --port 8000
```

## Validate

```powershell
flutter analyze
flutter test
```
