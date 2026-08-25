from __future__ import annotations

import pickle
import re
from pathlib import Path
from typing import Any

import numpy as np
import pandas as pd
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from scipy.sparse import csr_matrix, hstack


BACKEND_ROOT = Path(__file__).resolve().parent
MODEL_PATH = BACKEND_ROOT / "models" / "travel_recommendation_knn_model_v2.pkl"


class RecommendationRequest(BaseModel):
    regions: list[str] = Field(default_factory=list)
    provinces: list[str] = Field(default_factory=list)
    categories: list[str] = Field(default_factory=list)
    types: list[str] = Field(default_factory=list)
    activities: list[str] = Field(default_factory=list)
    keywords: list[str] = Field(default_factory=list)
    exclude_source_rows: list[int] = Field(default_factory=list)
    excluded_source_rows: list[int] = Field(default_factory=list)
    min_similarity: float | None = Field(default=None, ge=0, le=1)
    limit: int | None = Field(default=None, gt=0)
    candidate_pool: int | None = Field(default=None, gt=0)


def _clean_list(values: list[str]) -> list[str]:
    cleaned: list[str] = []
    seen: set[str] = set()
    for value in values:
        item = value.strip()
        if not item or item in seen:
            continue
        cleaned.append(item)
        seen.add(item)
    return cleaned


def _split_multi_value(value: object) -> list[str]:
    if value is None:
        return []
    if isinstance(value, list):
        raw_items = value
    else:
        raw_items = re.split(r"[,/|;]+", str(value))
    return [str(item).strip() for item in raw_items if str(item).strip()]


def _clean_multi_values(values: list[str]) -> list[str]:
    expanded: list[str] = []
    for value in values:
        expanded.extend(_split_multi_value(value))
    return _clean_list(expanded)


def _feature_weight(feature_name: str, weights: dict[str, float]) -> float:
    if feature_name.startswith("region_"):
        return weights.get("region", 1.0)
    if feature_name.startswith("province_"):
        return weights.get("province", 1.0)
    if feature_name.startswith("category_"):
        return weights.get("category", 1.0)
    if feature_name.startswith("type_"):
        return weights.get("type", 1.0)
    if feature_name.startswith("activity_"):
        return weights.get("activity", 1.0)
    if feature_name.startswith("tfidf_"):
        return weights.get("text", 1.0)
    return 1.0


class TrainedRecommender:
    def __init__(self, model_path: Path):
        if not model_path.exists():
            raise FileNotFoundError(f"Model artifact not found: {model_path}")

        self.model_path = model_path
        with model_path.open("rb") as file:
            self.artifact: dict[str, Any] = pickle.load(file)

        self.version = str(self.artifact.get("version", "unknown"))
        self.model_with_province = self.artifact["model_with_province"]
        self.model_without_province = self.artifact["model_without_province"]
        self.metadata_df: pd.DataFrame = self.artifact["metadata"].reset_index(
            drop=True
        )
        self.onehot_encoder = self.artifact["onehot_encoder"]
        self.activity_encoder = self.artifact["activity_encoder"]
        self.tfidf_vectorizer = self.artifact["tfidf_vectorizer"]
        self.feature_names: list[str] = list(self.artifact["feature_names"])
        self.no_province_indices = np.asarray(
            self.artifact["no_province_indices"], dtype=int
        )
        self.weights: dict[str, float] = dict(self.artifact["weights"])
        self.single_feature_columns: list[str] = list(
            self.artifact["single_feature_columns"]
        )
        self.tfidf_feature_count = len(self.tfidf_vectorizer.get_feature_names_out())
        self.structured_feature_count = len(self.feature_names) - self.tfidf_feature_count
        self.feature_index_by_name = {
            name: index for index, name in enumerate(self.feature_names)
        }
        self.weight_vector = np.array(
            [_feature_weight(name, self.weights) for name in self.feature_names],
            dtype=np.float32,
        )

    def _set_structured_features(
        self,
        values: np.ndarray,
        feature_prefix: str,
        selected_values: list[str],
    ) -> None:
        for selected_value in selected_values:
            feature_name = f"{feature_prefix}_{selected_value}"
            feature_index = self.feature_index_by_name.get(feature_name)
            if feature_index is None or feature_index >= self.structured_feature_count:
                continue
            values[0, feature_index] = 1.0

    def _build_user_vector(self, request: RecommendationRequest):
        regions = _clean_list(request.regions)
        provinces = _clean_list(request.provinces)
        categories = _clean_list(request.categories)
        place_types = _clean_list(request.types)
        activities = _clean_multi_values(request.activities)
        keywords = _clean_list(request.keywords)

        if not regions:
            raise ValueError("Select at least one region.")
        if not categories and not place_types and not activities and not keywords:
            raise ValueError("Select at least one interest.")

        structured_values = np.zeros((1, self.structured_feature_count), dtype=np.float32)
        self._set_structured_features(structured_values, "region", regions)
        self._set_structured_features(structured_values, "province", provinces)
        self._set_structured_features(structured_values, "category", categories)
        self._set_structured_features(structured_values, "type", place_types)
        self._set_structured_features(structured_values, "activity", activities)
        structured_vector = csr_matrix(structured_values)

        query_text = " ".join(
            [
                *regions,
                *provinces,
                *categories,
                *place_types,
                *activities,
                *keywords,
            ]
        ).strip()
        text_vector = self.tfidf_vectorizer.transform([query_text])
        full_vector = hstack([structured_vector, text_vector], format="csr")
        full_vector = full_vector.multiply(self.weight_vector).tocsr()

        if provinces:
            return full_vector, True
        return full_vector[:, self.no_province_indices].tocsr(), False

    def recommend(self, request: RecommendationRequest) -> dict[str, Any]:
        user_vector, has_province = self._build_user_vector(request)
        model = self.model_with_province if has_province else self.model_without_province

        limit = request.limit
        candidate_pool = request.candidate_pool or len(self.metadata_df)
        n_neighbors = min(candidate_pool, len(self.metadata_df))
        excluded_rows = set(request.exclude_source_rows) | set(
            request.excluded_source_rows
        )
        allowed_regions = set(_clean_list(request.regions))
        allowed_provinces = set(_clean_list(request.provinces))

        distances, indices = model.kneighbors(user_vector, n_neighbors=n_neighbors)

        results: list[dict[str, Any]] = []
        for distance, index in zip(distances[0], indices[0]):
            row_index = int(index)
            row = self.metadata_df.iloc[row_index]
            source_row = int(row.get("sourceRow", row_index + 1))
            if source_row in excluded_rows:
                continue
            if allowed_regions and str(row.get("region", "")) not in allowed_regions:
                continue
            if allowed_provinces and str(row.get("province", "")) not in allowed_provinces:
                continue

            similarity = float(1 - distance)
            if (
                request.min_similarity is not None
                and similarity < request.min_similarity
            ):
                continue

            results.append(
                {
                    "sourceRow": source_row,
                    "nameTh": str(row.get("nameTh", "")),
                    "province": str(row.get("province", "")),
                    "region": str(row.get("region", "")),
                    "category": str(row.get("category", "")),
                    "type": str(row.get("type", "")),
                    "activity": str(row.get("activity", "")),
                    "similarity": round(similarity, 6),
                    "modelMode": "with_province"
                    if has_province
                    else "without_province",
                }
            )
            if limit is not None and len(results) >= limit:
                break

        return {
            "method": "Content-Based KNN with One-hot + TF-IDF",
            "modelFile": self.model_path.name,
            "modelVersion": self.version,
            "modelMode": "with_province" if has_province else "without_province",
            "total": len(results),
            "results": results,
        }

    def status(self) -> dict[str, Any]:
        feature_matrix = self.artifact.get("feature_matrix")
        without_province_matrix = self.artifact.get("feature_matrix_without_province")
        return {
            "ok": True,
            "service": "Tourist Attraction KNN Recommendation API",
            "modelFile": self.model_path.name,
            "modelVersion": self.version,
            "sklearnVersion": self.artifact.get("sklearn_version"),
            "totalAttractions": len(self.metadata_df),
            "features": getattr(feature_matrix, "shape", [None, None])[1],
            "featuresWithoutProvince": getattr(
                without_province_matrix, "shape", [None, None]
            )[1],
            "weights": self.weights,
        }


recommender = TrainedRecommender(MODEL_PATH)

app = FastAPI(title="Tourist Attraction Recommendation API", version="2.0.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
@app.get("/health")
def health() -> dict[str, Any]:
    return recommender.status()


@app.post("/recommend")
def recommend(request: RecommendationRequest) -> dict[str, Any]:
    try:
        return recommender.recommend(request)
    except ValueError as error:
        raise HTTPException(status_code=400, detail=str(error)) from error


if __name__ == "__main__":
    import uvicorn

    uvicorn.run("main:app", host="127.0.0.1", port=8000, reload=False)
