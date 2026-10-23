"""Inspect high_accuracy_animal_classifier.h5 and test preprocessing hypotheses.

  python inspect_model.py [--model path.h5] [--image sample.jpg ...]
With --image it prints top-3 for every preprocessing mode so you can see which one
gives sensible results on images whose true class you know.
"""
import argparse, json, sys
from pathlib import Path
import numpy as np
from app import model_loader, pipeline

ap = argparse.ArgumentParser()
ap.add_argument("--model", default=str(model_loader.DEFAULT_MODEL))
ap.add_argument("--labels", default=str(model_loader.DEFAULT_LABELS))
ap.add_argument("--image", nargs="*", default=[])
a = ap.parse_args()
if not Path(a.model).exists():
    sys.exit(f"Model not found: {a.model}")
import tensorflow as tf
m = tf.keras.models.load_model(a.model, compile=False)
print(json.dumps(model_loader.inspect_model(m), indent=2))
m.summary(line_length=100)
labels, verified = model_loader.load_labels(Path(a.labels))
size = (m.input_shape[1], m.input_shape[2])
for p in a.image:
    img = pipeline.decode_image(Path(p).read_bytes())
    print(f"\n== {p}")
    for mode in pipeline.PREPROCESS_MODES:
        out = m.predict(pipeline.preprocess_image(img, size, mode), verbose=0)
        r = pipeline.interpret_output(out, labels)
        print(f"  {mode:13s} {r.output_kind:17s}", [(l, round(s, 3)) for l, s in r.top])
