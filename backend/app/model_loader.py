"""Loads the user's Keras model and reports verifiable facts about it."""
from __future__ import annotations

import json
import os
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional

BASE = Path(__file__).resolve().parent.parent
DEFAULT_MODEL = BASE / "models" / "high_accuracy_animal_classifier.h5"
DEFAULT_LABELS = BASE / "models" / "labels.json"


@dataclass
class ModelBundle:
    model: object
    labels: list[str]
    input_size: tuple[int, int]
    preprocess: str
    labels_verified: bool
    preprocess_verified: bool
    notes: list[str] = field(default_factory=list)
    version: str = "unknown"


def inspect_model(model) -> dict:
    """Facts read directly from the model object. No assumptions."""
    shape = model.input_shape
    layer_types = [type(l).__name__ for l in model.layers]
    first = layer_types[:6]
    has_builtin_preprocessing = any(
        t in ("Rescaling", "Normalization", "TFOpLambda", "Lambda") for t in first
    ) or any("preprocess" in l.name.lower() or "rescal" in l.name.lower() for l in model.layers[:6])
    last = model.layers[-1]
    act = getattr(getattr(last, "activation", None), "__name__", None)
    return {
        "input_shape": list(shape) if shape and not isinstance(shape, list) else str(shape),
        "output_shape": list(model.output_shape),
        "num_layers": len(model.layers),
        "first_layers": first,
        "last_layer": type(last).__name__,
        "last_activation": act,
        "builtin_preprocessing_detected": has_builtin_preprocessing,
        "custom_layers": sorted({t for t in layer_types if not hasattr(__import__("tensorflow").keras.layers, t)}),
    }


def load_labels(path: Path) -> tuple[list[str], bool]:
    """labels.json: {"labels": [...], "verified": bool}  (list index == output index)."""
    data = json.loads(path.read_text(encoding="utf-8"))
    return list(data["labels"]), bool(data.get("verified", False))


def load_bundle() -> ModelBundle:
    import tensorflow as tf  # imported lazily so pure-function tests stay light

    model_path = Path(os.environ.get("SAFE_MODEL_PATH", DEFAULT_MODEL))
    labels_path = Path(os.environ.get("SAFE_LABELS_PATH", DEFAULT_LABELS))
    if not model_path.exists():
        raise FileNotFoundError(f"Model file not found: {model_path}")
    if not labels_path.exists():
        raise FileNotFoundError(f"Labels file not found: {labels_path}")

    model = tf.keras.models.load_model(str(model_path), compile=False)
    info = inspect_model(model)
    labels, labels_verified = load_labels(labels_path)
    out_dim = model.output_shape[-1]
    if out_dim != len(labels):
        raise ValueError(f"Model outputs {out_dim} classes but labels.json has {len(labels)}.")

    ishape = model.input_shape
    if len(ishape) != 4 or ishape[1] is None or ishape[2] is None or ishape[3] != 3:
        raise ValueError(f"Unsupported input shape {ishape}; expected (None, H, W, 3).")
    size = (int(ishape[1]), int(ishape[2]))

    notes: list[str] = []
    env_mode = os.environ.get("SAFE_PREPROCESS", "auto").lower()
    if env_mode != "auto":
        mode, pre_verified = env_mode, True  # explicit operator decision
        notes.append(f"Preprocessing set explicitly to '{mode}' via SAFE_PREPROCESS.")
    elif info["builtin_preprocessing_detected"]:
        mode, pre_verified = "none", False
        notes.append("Model appears to contain its own preprocessing layer; raw 0-255 RGB is fed in. Confirm with inspect_model.py --image.")
    else:
        mode, pre_verified = "mobilenet_v2", False
        notes.append("No built-in preprocessing found; assuming MobileNetV2 [-1,1] scaling. NOT verified - run inspect_model.py with known images.")
    if not labels_verified:
        notes.append("Class order in labels.json is NOT verified against training.")
    return ModelBundle(model, labels, size, mode, labels_verified, pre_verified, notes,
                       version=f"{model_path.name}")
