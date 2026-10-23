import io, json, sys
from pathlib import Path
import pytest
from PIL import Image
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

LABELS = ["Bear","Bird","Cat","Cow","Deer","Dog","Elephant","Fox","Horse","Kangaroo","Lion","Panda","Tiger","Wolf","Zebra"]

def png_bytes(size=(200, 200), color=None, noise=True):
    import numpy as np
    if noise:
        arr = (np.random.default_rng(1).uniform(0, 255, (size[1], size[0], 3))).astype("uint8")
        img = Image.fromarray(arr)
    else:
        img = Image.new("RGB", size, color or (128, 128, 128))
    b = io.BytesIO(); img.save(b, "PNG"); return b.getvalue()

@pytest.fixture(scope="session")
def fixture_model(tmp_path_factory):
    """TEST FIXTURE ONLY: tiny random-weight CNN with 15 outputs. Predictions are meaningless;
    it exists to exercise load/preprocess/predict/rank code. It is NOT the user's model."""
    import tensorflow as tf
    d = tmp_path_factory.mktemp("fx")
    inp = tf.keras.Input((224, 224, 3))
    x = tf.keras.layers.Rescaling(1 / 127.5, offset=-1)(inp)
    x = tf.keras.layers.Conv2D(4, 3, strides=4, activation="relu")(x)
    x = tf.keras.layers.GlobalAveragePooling2D()(x)
    out = tf.keras.layers.Dense(15, activation="softmax")(x)
    m = tf.keras.Model(inp, out); mp = d / "fixture.h5"; m.save(mp)
    lp = d / "labels.json"; lp.write_text(json.dumps({"verified": False, "labels": LABELS}))
    return mp, lp
