"""SAFE inference pipeline: pure, independently testable functions.

Nothing here loads a model. Preprocessing and output interpretation are kept
separate from model loading so each stage can be unit tested.
"""
from __future__ import annotations

import io
import math
from dataclasses import dataclass
from typing import Sequence

import numpy as np
from PIL import Image, UnidentifiedImageError

PREPROCESS_MODES = ("mobilenet_v2", "rescale_01", "none")
MAX_IMAGE_BYTES = 12 * 1024 * 1024
MIN_SIDE_PX = 64


class InvalidImageError(ValueError):
    """Image is unreadable, unsupported, or unusable."""


class InvalidModelOutputError(ValueError):
    """Model output has the wrong shape or contains non-finite values."""


def decode_image(data: bytes) -> Image.Image:
    if not data:
        raise InvalidImageError("Empty image upload.")
    if len(data) > MAX_IMAGE_BYTES:
        raise InvalidImageError("Image is too large.")
    try:
        img = Image.open(io.BytesIO(data))
        img.load()
    except (UnidentifiedImageError, OSError) as e:
        raise InvalidImageError("Unsupported or corrupted image.") from e
    if img.format not in ("JPEG", "PNG", "WEBP", "BMP", "GIF"):
        raise InvalidImageError(f"Unsupported image format: {img.format}")
    if min(img.size) < MIN_SIDE_PX:
        raise InvalidImageError("Image resolution is too low.")
    return img.convert("RGB")  # RGB channel order, drops alpha


def quality_warnings(img: Image.Image) -> list[str]:
    """Cheap input-quality heuristics. NOT an out-of-distribution detector."""
    arr = np.asarray(img.convert("L"), dtype=np.float32)
    warnings: list[str] = []
    if arr.std() < 8:
        warnings.append("low_contrast_or_blank")
    if arr.mean() < 25:
        warnings.append("very_dark")
    if arr.mean() > 235:
        warnings.append("overexposed")
    return warnings


def preprocess_image(img: Image.Image, size: tuple[int, int], mode: str) -> np.ndarray:
    """Return float32 batch of shape (1, H, W, 3), channels-last RGB."""
    if mode not in PREPROCESS_MODES:
        raise ValueError(f"Unknown preprocess mode '{mode}'. Use one of {PREPROCESS_MODES}.")
    h, w = size
    resized = img.resize((w, h), Image.BILINEAR)
    x = np.asarray(resized, dtype=np.float32)
    if mode == "mobilenet_v2":
        x = x / 127.5 - 1.0  # keras mobilenet_v2.preprocess_input -> [-1, 1]
    elif mode == "rescale_01":
        x = x / 255.0
    return np.expand_dims(x, 0)


def _softmax(v: np.ndarray) -> np.ndarray:
    e = np.exp(v - np.max(v))
    return e / e.sum()


@dataclass
class Interpretation:
    top: list[tuple[str, float]]
    output_kind: str  # "softmax" | "logits_softmaxed"
    ambiguous: bool


def interpret_output(
    raw: np.ndarray, labels: Sequence[str], top_k: int = 3, ambiguity_margin: float = 0.15
) -> Interpretation:
    v = np.asarray(raw, dtype=np.float64).reshape(-1)
    if v.size != len(labels):
        raise InvalidModelOutputError(
            f"Model produced {v.size} outputs but {len(labels)} labels are configured."
        )
    if not np.all(np.isfinite(v)):
        raise InvalidModelOutputError("Model output contains NaN or infinite values.")
    in_range = bool(np.all(v >= 0) and np.all(v <= 1.0 + 1e-6))
    if in_range and math.isclose(float(v.sum()), 1.0, abs_tol=1e-2):
        scores, kind = v, "softmax"
    else:
        scores, kind = _softmax(v), "logits_softmaxed"
    order = np.argsort(-scores)[:top_k]
    top = [(labels[i], float(scores[i])) for i in order]
    ambiguous = len(top) > 1 and (top[0][1] - top[1][1]) < ambiguity_margin
    return Interpretation(top, kind, ambiguous)
