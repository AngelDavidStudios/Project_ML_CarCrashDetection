# Crash Detection ML — Backend

FastAPI backend for the Crash Detection ML system. Runs a YOLO11m model (`model/best.pt`) over video footage, streams annotated frames and accident events over WebSocket, and saves accident images to disk.

## Model

- **Architecture:** YOLO11m (Ultralytics)
- **Classes (10):** `bike`, `bike_bike_accident`, `bike_object_accident`, `bike_person_accident`, `car`, `car_bike_accident`, `car_car_accident`, `car_object_accident`, `car_person_accident`, `person`
- **Weights:** `model/best.pt` (39 MB) — required at startup

## Requirements

- Python **3.11** strictly (coremltools 9.0 does not support Python 3.12+)
- PyTorch installed separately per platform (see root README)

## Setup

```bash
python3.11 -m venv venv
source venv/bin/activate          # macOS/Linux
# venv\Scripts\activate           # Windows

# macOS (Apple Silicon):
pip install torch torchvision torchaudio

# Linux/Windows NVIDIA:
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu126

pip install -r requirements.txt
```

## Run

```bash
source venv/bin/activate
export PYTORCH_ENABLE_MPS_FALLBACK=1   # macOS only
uvicorn app:app --host 0.0.0.0 --port 8000 --reload
```

## Endpoints

| Method | Path | Description |
|---|---|---|
| GET | `/health` | Health check |
| GET | `/images` | List saved accident images |
| POST | `/detect/image` | Run detection on a single image |
| POST | `/detect/video` | Run detection on a video file |
| WS | `/ws/detect` | Real-time detection stream |

## Package structure

```
crash_detection_ml/
├── components/model_trainer.py   # YOLO11m wrapper + device selection (CUDA → MPS → CPU)
├── pipeline/training_pipeline.py # Inference pipeline
├── logger/                       # Logging setup
├── exception/                    # Exception handling
└── utils/                        # Utility functions
```
