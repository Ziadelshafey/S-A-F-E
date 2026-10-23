"""SAFE inference API (FastAPI). Run: uvicorn app.main:app --host 0.0.0.0 --port 8000"""
from __future__ import annotations

import logging
import time
from datetime import datetime, timezone

import numpy as np
from fastapi import FastAPI, File, HTTPException, UploadFile

from . import model_loader, pipeline

log = logging.getLogger("safe")
logging.basicConfig(level=logging.INFO)

app = FastAPI(title="SAFE Inference API", version="1.0.0")
_state: dict = {"bundle": None, "error": None, "status": "loading"}


def init_model() -> None:
    try:
        _state["bundle"] = model_loader.load_bundle()
        _state.update(status="ready", error=None)
        log.info("Model ready: %s", _state["bundle"].version)
    except FileNotFoundError as e:
        _state.update(bundle=None, status="unavailable", error=str(e))
        log.error("%s", e)
    except Exception as e:  # keep technical detail in logs, summary in API
        _state.update(bundle=None, status="failed", error=f"{type(e).__name__}: {e}")
        log.exception("Model initialisation failed")


@app.on_event("startup")
def _startup() -> None:
    init_model()


@app.get("/health")
def health():
    b = _state["bundle"]
    body = {"status": _state["status"], "error": _state["error"]}
    if b:
        body.update(
            modelVersion=b.version,
            inputSize=list(b.input_size),
            preprocess=b.preprocess,
            labelsVerified=b.labels_verified,
            preprocessVerified=b.preprocess_verified,
            numClasses=len(b.labels),
            notes=b.notes,
        )
    return body


@app.post("/predict")
async def predict(image: UploadFile = File(...)):
    b = _state["bundle"]
    if b is None:
        raise HTTPException(503, detail={"code": "model_unavailable", "message": _state["error"] or "Model not loaded."})
    data = await image.read()
    try:
        img = pipeline.decode_image(data)
    except pipeline.InvalidImageError as e:
        raise HTTPException(422, detail={"code": "invalid_image", "message": str(e)})
    warnings = pipeline.quality_warnings(img)
    x = pipeline.preprocess_image(img, b.input_size, b.preprocess)
    try:
        t0 = time.perf_counter()
        raw = b.model.predict(x, verbose=0)
        ms = (time.perf_counter() - t0) * 1000
        result = pipeline.interpret_output(np.asarray(raw), b.labels)
    except pipeline.InvalidModelOutputError as e:
        log.error("Invalid model output: %s", e)
        raise HTTPException(500, detail={"code": "invalid_model_output", "message": "The model returned an invalid result."})
    except Exception:
        log.exception("Inference failure")
        raise HTTPException(500, detail={"code": "inference_failed", "message": "Inference failed."})
    return {
        "label": result.top[0][0],
        "score": result.top[0][1],
        "top": [{"label": l, "score": s} for l, s in result.top],
        "ambiguous": result.ambiguous,
        "outputKind": result.output_kind,
        "inferenceMs": round(ms, 1),
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "modelVersion": b.version,
        "labelsVerified": b.labels_verified,
        "preprocessVerified": b.preprocess_verified,
        "qualityWarnings": warnings,
    }
