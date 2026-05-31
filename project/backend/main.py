from __future__ import annotations

from pathlib import Path
from typing import Any

import joblib
import numpy as np
import pandas as pd
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field


BACKEND_ROOT = Path(__file__).resolve().parent
MODEL_PATH = BACKEND_ROOT / "models" / "travel_recommendation_knn_model_v1.pkl"


class RecommendationRequest(BaseModel):
    regions: list[str] = Field(default_factory=list)
    provinces: list[str] = Field(default_factory=list)
    categories: list[str] = Field(default_factory=list)
    types: list[str] = Field(default_factory=list)
    activities: list[str] = Field(default_factory=list)
    min_similarity: float | None = Field(default=None, ge=0, le=1)
    limit: int | None = Field(default=None, gt=0)


def _clean_values(values: list[str]) -> set[str]:
    return {value.strip() for value in values if value.strip()}


def _split_activities(value: object) -> set[str]:
    return {
        activity.strip()
        for activity in str(value).split(",")
        if activity.strip()
    }


class TrainedRecommender:
    def __init__(self, model_path: Path):
        if not model_path.exists():
            raise FileNotFoundError(f"Model artifact not found: {model_path}")

        self.model_path = model_path
        self.artifacts: dict[str, Any] = joblib.load(model_path)
        self.model_df: pd.DataFrame = self.artifacts["model_df"].reset_index(drop=True)
        self.metadata_df: pd.DataFrame = self.artifacts["metadata_df"].reset_index(
            drop=True
        )
        self.feature_matrix = np.asarray(self.artifacts["feature_matrix"], dtype=float)
        self.encoded_columns: list[str] = self.artifacts["encoded_columns"]
        self.feature_weights: dict[str, float] = self.artifacts["feature_weights"]
        self.normalized_matrix = self._normalize(self.feature_matrix)

    @staticmethod
    def _normalize(matrix: np.ndarray) -> np.ndarray:
        norms = np.linalg.norm(matrix, axis=1, keepdims=True)
        norms[norms == 0] = 1
        return matrix / norms

    def _query_vector(self, request: RecommendationRequest) -> np.ndarray:
        values_by_feature = {
            "region": _clean_values(request.regions),
            "province": _clean_values(request.provinces),
            "category": _clean_values(request.categories),
            "type": _clean_values(request.types),
            "activity": _clean_values(request.activities),
        }

        vector = np.zeros(len(self.encoded_columns), dtype=float)
        for index, column in enumerate(self.encoded_columns):
            for feature, values in values_by_feature.items():
                prefix = f"{feature}_"
                if column.startswith(prefix) and column[len(prefix) :] in values:
                    vector[index] = float(self.feature_weights[feature])
                    break

        norm = np.linalg.norm(vector)
        if norm == 0:
            raise ValueError("At least one valid preference is required.")
        return vector / norm

    def _candidate_mask(self, request: RecommendationRequest) -> pd.Series:
        regions = _clean_values(request.regions)
        provinces = _clean_values(request.provinces)
        categories = _clean_values(request.categories)
        types = _clean_values(request.types)
        activities = _clean_values(request.activities)

        if not regions:
            raise ValueError("Select at least one region.")

        location_mask = self.model_df["region"].isin(regions)
        if provinces:
            location_mask &= self.model_df["province"].isin(provinces)

        interest_mask = (
            self.model_df["category"].isin(categories)
            | self.model_df["type"].isin(types)
            | self.model_df["activity"].apply(
                lambda value: bool(_split_activities(value) & activities)
            )
        )
        return location_mask & interest_mask

    def recommend(self, request: RecommendationRequest) -> dict[str, Any]:
        candidate_mask = self._candidate_mask(request)
        candidate_indices = self.model_df.index[candidate_mask].to_numpy()
        query_vector = self._query_vector(request)

        if not len(candidate_indices):
            return {
                "method": "Content-Based KNN / Cosine Similarity (.pkl model)",
                "total": 0,
                "results": [],
            }

        similarities = self.normalized_matrix[candidate_indices] @ query_vector
        ranked_positions = np.argsort(similarities)[::-1]

        results: list[dict[str, Any]] = []
        for position in ranked_positions:
            similarity = float(similarities[position])
            if (
                request.min_similarity is not None
                and similarity < request.min_similarity
            ):
                continue

            row_index = int(candidate_indices[position])
            row = self.metadata_df.iloc[row_index]
            results.append(
                {
                    "sourceRow": row_index + 1,
                    "nameTh": str(row.get("nameTh", "")),
                    "province": str(row.get("province", "")),
                    "region": str(row.get("region", "")),
                    "category": str(row.get("category", "")),
                    "type": str(row.get("type", "")),
                    "activity": str(row.get("activity", "")),
                    "similarity": round(similarity, 6),
                }
            )
            if request.limit is not None and len(results) >= request.limit:
                break

        return {
            "method": "Content-Based KNN / Cosine Similarity (.pkl model)",
            "modelFile": self.model_path.name,
            "total": len(results),
            "results": results,
        }

    def status(self) -> dict[str, Any]:
        evaluation = {
            key: float(value) if isinstance(value, np.floating) else value
            for key, value in self.artifacts.get("evaluation_summary", {}).items()
        }
        return {
            "ok": True,
            "service": "Tourist Attraction KNN Recommendation API",
            "modelFile": self.model_path.name,
            "totalAttractions": len(self.model_df),
            "features": self.feature_matrix.shape[1],
            "evaluation": evaluation,
        }


recommender = TrainedRecommender(MODEL_PATH)

app = FastAPI(title="Tourist Attraction Recommendation API", version="1.0.0")
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
