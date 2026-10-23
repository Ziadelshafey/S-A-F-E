import os, pytest
from fastapi.testclient import TestClient
from conftest import png_bytes

@pytest.fixture()
def client(fixture_model, monkeypatch):
    mp, lp = fixture_model
    monkeypatch.setenv("SAFE_MODEL_PATH", str(mp)); monkeypatch.setenv("SAFE_LABELS_PATH", str(lp))
    from app import main
    main.init_model()
    return TestClient(main.app)

def test_health_ready_reports_unverified(client):
    h = client.get("/health").json()
    assert h["status"] == "ready" and h["numClasses"] == 15 and h["inputSize"] == [224, 224]
    assert h["labelsVerified"] is False and h["preprocess"] == "none"  # Rescaling layer detected

def test_predict_structure(client):
    r = client.post("/predict", files={"image": ("a.png", png_bytes(), "image/png")})
    assert r.status_code == 200
    j = r.json()
    assert len(j["top"]) == 3 and j["label"] == j["top"][0]["label"] and j["inferenceMs"] > 0
    assert j["top"][0]["score"] >= j["top"][1]["score"] >= j["top"][2]["score"]

def test_predict_rejects_corrupt(client):
    r = client.post("/predict", files={"image": ("a.jpg", b"garbage", "image/jpeg")})
    assert r.status_code == 422 and r.json()["detail"]["code"] == "invalid_image"

def test_model_missing_is_reported_not_faked(monkeypatch, tmp_path):
    monkeypatch.setenv("SAFE_MODEL_PATH", str(tmp_path / "nope.h5"))
    from app import main
    main.init_model()
    c = TestClient(main.app)
    assert c.get("/health").json()["status"] == "unavailable"
    r = c.post("/predict", files={"image": ("a.png", png_bytes(), "image/png")})
    assert r.status_code == 503 and r.json()["detail"]["code"] == "model_unavailable"

def test_label_count_mismatch_fails_init(fixture_model, monkeypatch, tmp_path):
    import json
    mp, _ = fixture_model
    bad = tmp_path / "l.json"; bad.write_text(json.dumps({"labels": ["a", "b"]}))
    monkeypatch.setenv("SAFE_MODEL_PATH", str(mp)); monkeypatch.setenv("SAFE_LABELS_PATH", str(bad))
    from app import main
    main.init_model()
    assert main._state["status"] == "failed"
