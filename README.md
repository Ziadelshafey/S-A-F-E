# SAFE

AI-powered animal recognition and safety assistant (Flutter app + FastAPI inference backend).
SAFE gives a *classification suggestion* with raw model scores, general species information and cautious safety guidance. It cannot judge aggression, illness or rabies from a photo and is not a substitute for professional wildlife guidance or emergency services.

## Architecture decision
Server-side inference with the **original** Keras model. The `.h5` file was not available when this project was generated, so on-device TFLite conversion could not be validated. `backend/convert_to_tflite.py` is provided (it prints the numeric difference vs. the original) for a future on-device mode.

```
safe/
├── lib/                        Flutter app (app/, core/, features/, services/, shared/)
├── assets/data/animals.json    local species knowledge base
├── backend/                    FastAPI: app/pipeline.py (pure functions), model_loader.py, main.py
├── docs/ESP32_PROTOCOL.md
└── test/                       Dart tests
```

## Setup

### 1. Put your model in place
Copy `high_accuracy_animal_classifier.h5` to `backend/models/`, then verify input size, preprocessing and class order:

```
cd backend
pip install -r requirements.txt
python inspect_model.py --image path/to/dog.jpg path/to/cat.jpg
```

`inspect_model.py` prints architecture facts and top-3 predictions under each preprocessing mode (`mobilenet_v2` = [-1,1], `rescale_01`, `none`). Choose the mode that gives sensible results on images of known class and set it:

```
export SAFE_PREPROCESS=mobilenet_v2
```

Default is `auto`: uses `none` if the model contains a Rescaling/preprocessing layer, otherwise assumes MobileNetV2 scaling. Either way it is reported as **unverified** until you set the variable explicitly.

Edit `backend/models/labels.json` with your real class order (list index = output index) and set `"verified": true`. The shipped order is alphabetical (Keras `flow_from_directory` default) and is **unverified**. Startup fails if the label count differs from the model output size.

### 2. Run the backend
```
cd backend
uvicorn app.main:app --host 0.0.0.0 --port 8000
curl http://localhost:8000/health
```
`/health` reports `ready`, `unavailable` (file missing) or `failed`. `POST /predict` (multipart field `image`) returns top-3 raw scores, ambiguity flag, inference ms and quality warnings. Optional env vars: `SAFE_MODEL_PATH`, `SAFE_LABELS_PATH`, `SAFE_PREPROCESS`.

### 3. Flutter app
Platform folders are not included; generate them once:

```
flutter create --project-name safe --org com.example.safe .
flutter pub get
```

Android: in `android/app/src/main/AndroidManifest.xml` add `<uses-permission android:name="android.permission.CAMERA"/>` and `<uses-permission android:name="android.permission.INTERNET"/>`; for plain-HTTP LAN testing add `android:usesCleartextTraffic="true"` to `<application>` (use HTTPS in production). iOS: add `NSCameraUsageDescription` and `NSPhotoLibraryUsageDescription` to Info.plist.

```
flutter run --dart-define=SAFE_API_URL=http://<your-computer-LAN-IP>:8000
flutter build apk --release
```
Use your computer's LAN IP on a physical phone (never `localhost`), or `10.0.2.2` on the Android emulator. The address is also editable in Settings.

## Tests
```
cd backend && python -m pytest -q     # backend pipeline + API
flutter test                          # models, services, persistence, hardware protocol
```

## Known limitations
- Closed-set 15-class model: any image is forced into one of the classes; no out-of-distribution detector (only simple brightness/contrast warnings).
- Scores are raw softmax outputs, not calibrated probabilities.
- No accuracy evaluation has been run (no dataset). Dog vs. Wolf confusion is likely.
- Not implemented: live-frame classification, history thumbnails, BLE, real ESP32 control.

## Troubleshooting
- "Model Unavailable" on Home: open `http://<server>:8000/health` from the phone's browser; check that phone and computer share a network and the firewall allows port 8000.
- Backend `failed`: read the `error` field in `/health` (typically label-count mismatch or a Keras version different from the one used for training).
