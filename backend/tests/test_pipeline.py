import numpy as np, pytest
from PIL import Image
from app import pipeline as p
from conftest import png_bytes, LABELS

def test_decode_ok_and_rgb():
    img = p.decode_image(png_bytes())
    assert img.mode == "RGB"

@pytest.mark.parametrize("data", [b"", b"not an image", b"\x89PNG\r\n\x1a\ngarbage"])
def test_decode_rejects_bad(data):
    with pytest.raises(p.InvalidImageError):
        p.decode_image(data)

def test_decode_rejects_tiny():
    with pytest.raises(p.InvalidImageError):
        p.decode_image(png_bytes((20, 20)))

@pytest.mark.parametrize("mode,lo,hi", [("mobilenet_v2", -1, 1), ("rescale_01", 0, 1), ("none", 0, 255)])
def test_preprocess_shape_dtype_range(mode, lo, hi):
    x = p.preprocess_image(p.decode_image(png_bytes()), (224, 224), mode)
    assert x.shape == (1, 224, 224, 3) and x.dtype == np.float32
    assert x.min() >= lo - 1e-6 and x.max() <= hi + 1e-6

def test_preprocess_unknown_mode():
    with pytest.raises(ValueError):
        p.preprocess_image(Image.new("RGB", (100, 100)), (224, 224), "bogus")

def test_channel_order_rgb():
    img = Image.new("RGB", (100, 100), (255, 0, 0))
    x = p.preprocess_image(img, (8, 8), "none")
    assert x[0, 0, 0, 0] == 255 and x[0, 0, 0, 2] == 0

def test_interpret_ranking_and_label_mapping():
    v = np.zeros(15); v[5] = 0.7; v[13] = 0.2; v[2] = 0.1
    r = p.interpret_output(v, LABELS)
    assert [l for l, _ in r.top] == ["Dog", "Wolf", "Cat"]
    assert r.output_kind == "softmax" and not r.ambiguous

def test_interpret_ambiguous():
    v = np.zeros(15); v[5] = 0.45; v[13] = 0.40; v[2] = 0.15
    assert p.interpret_output(v, LABELS).ambiguous

def test_interpret_logits_are_softmaxed():
    v = np.linspace(-3, 3, 15)
    r = p.interpret_output(v, LABELS)
    assert r.output_kind == "logits_softmaxed" and 0 < r.top[0][1] < 1

@pytest.mark.parametrize("bad", [np.zeros(14), np.full(15, np.nan), np.full(15, np.inf)])
def test_interpret_invalid_output(bad):
    with pytest.raises(p.InvalidModelOutputError):
        p.interpret_output(bad, LABELS)

def test_quality_warnings():
    assert "low_contrast_or_blank" in p.quality_warnings(Image.new("RGB", (100, 100), (128, 128, 128)))
    assert "very_dark" in p.quality_warnings(Image.new("RGB", (100, 100), (0, 0, 0)))
