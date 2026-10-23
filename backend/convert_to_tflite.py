"""Optional: convert the .h5 model to TFLite for future on-device inference.
After converting, run compare mode to check numerical differences before use.
  python convert_to_tflite.py --model models/high_accuracy_animal_classifier.h5 --out ../assets/models/safe.tflite
"""
import argparse
import numpy as np, tensorflow as tf
ap = argparse.ArgumentParser(); ap.add_argument("--model", required=True); ap.add_argument("--out", required=True)
a = ap.parse_args()
m = tf.keras.models.load_model(a.model, compile=False)
tfl = tf.lite.TFLiteConverter.from_keras_model(m).convert()
open(a.out, "wb").write(tfl)
it = tf.lite.Interpreter(model_content=tfl); it.allocate_tensors()
d_in, d_out = it.get_input_details()[0], it.get_output_details()[0]
rng = np.random.default_rng(0)
worst = 0.0
for _ in range(10):
    x = rng.uniform(-1, 1, size=[1, *m.input_shape[1:]]).astype("float32")
    it.set_tensor(d_in["index"], x); it.invoke()
    worst = max(worst, float(np.abs(m.predict(x, verbose=0) - it.get_tensor(d_out["index"])).max()))
print(f"Max abs difference over 10 random inputs: {worst:.6g}")
