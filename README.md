<h1 align="center">Crash Detection ML: Real-Time Road Accident Detection System using YOLO11m and CCTV Surveillance</h1>

**Crash Detection ML** is an AI-powered real-time accident detection system designed to revolutionize road safety. By leveraging advanced computer vision technology, Crash Detection ML detects vehicle collisions and accident events through CCTV footage and instantly notifies highway authorities, enabling swift emergency responses.

The model was trained on a combined dataset of **~10,000 images** from three Roboflow Universe sources and detects **10 granular classes** of vehicles and accident types, surpassing the benchmark established by Mane et al. (2023) in Precision, mAP@0.5 and F1-Score.

## 📝 Table of Contents

1. [Key Features](#key-features-)
2. [Built With](#built-with)
3. [Model — Classes and Performance](#model--classes-and-performance-)
4. [Getting Started Guide](#-getting-started-guide)
5. [Running the Application](#️-running-the-application)
6. [How It Works](#how-it-works-)
7. [System Architecture](#system-architecture)
8. [Methodology](#methodology)
9. [Performance Highlights](#performance-highlights-)
10. [Repository Structure](#️-repository-structure)
11. [License](#-license)
12. [Credits & Acknowledgments](#-credits--acknowledgments)
13. [Support & Contact Information](#-support--contact-information)

## Key Features ✨

- **10-Class Granular Detection:** Identifies not just crashes, but specific accident types between cars, bikes, and pedestrians.
- **Real-Time Processing:** Powered by YOLO11m — achieves >34 FPS on Apple Silicon via CoreML Neural Engine.
- **Instant Alerts:** Sends immediate notifications to control centers upon accident confirmation.
- **Temporal Validation:** Anti-noise filter that suppresses 98% of spurious detections, emitting only confirmed events.
- **Structured JSON Report:** Every confirmed event is serialized with timestamp, frame, confidence, tracker_id and bounding box coordinates.
- **Scalable Design:** Seamlessly integrates with existing CCTV infrastructure for widespread deployment.

## Built With

<p>
  <img src="https://skillicons.dev/icons?i=fastapi,aws,swift,graphql,pytorch" alt="Tech Stack" />
  <img src="https://thesvg.org/icons/aws-aws-amplify/default.svg" alt="Tech Stack" width="47px" hspace="7" style="border-radius: 10px;"/>
  <img src="https://thesvg.org/icons/aws-amazon-cognito/default.svg" alt="Tech Stack" width="47px" style="border-radius: 10px;"/>
  <img src="https://thesvg.org/icons/dynamodb/default.svg" alt="Tech Stack" width="47px" hspace="7" style="border-radius: 10px;"/>
  <img src="https://thesvg.org/icons/aws-amazon-simple-storage-service/default.svg" alt="Tech Stack" width="47px" style="border-radius: 10px;"/>
  <img src="https://thesvg.org/icons/aws-amazon-sagemaker-ai/default.svg" alt="Tech Stack" width="47px" hspace="7" style="border-radius: 10px;"/>
</p>


**Full stack:** YOLO11m (Ultralytics) · CoreML (Apple Neural Engine) · OpenCV · Supervision (Roboflow) · PyTorch · FastAPI · Swift · SwiftUI · AWS Amplify · AWS Cognito · AWS DynamoDB · AWS S3 · AWS SageMaker (training)

---

## Model — Classes and Performance 📊

### Detected Classes (10 total)

The model classifies every detected object into one of 10 categories:

| class_id | Class | Description |
|---|---|---|
| 0 | `bike` | Bicycle or motorcycle — no accident |
| 1 | `bike_bike_accident` | Collision between two bikes/motorcycles |
| 2 | `bike_object_accident` | Bike/motorcycle collision with static object |
| 3 | `bike_person_accident` | Bike/motorcycle collision with pedestrian |
| 4 | `car` | Motor vehicle — no accident |
| 5 | `car_bike_accident` | Vehicle collision with bike/motorcycle |
| 6 | `car_car_accident` | Collision between two vehicles |
| 7 | `car_object_accident` | Vehicle collision with static object |
| 8 | `car_person_accident` | Vehicle collision with pedestrian |
| 9 | `person` | Pedestrian — no accident |

### Training Configuration

| Parameter | Value |
|---|---|
| Architecture | **YOLO11m** (Ultralytics) |
| Dataset | ~10,000 images — 3 combined sources (see Credits) |
| Epochs | 81 (of 100 configured) |
| Image size | 640 × 640 px |
| Batch size | 32 |
| Optimizer | AdamW (lr0 = 0.0005) |
| Training platform | **AWS SageMaker ml.g5.xlarge (NVIDIA A10G — 24 GB VRAM)** |
| Training time | ~1.70 hours |

### Final Metrics (Epoch 81/81)

| Metric | This model | Mane et al. (2023) | Difference |
|---|---|---|---|
| **Precision** | **97.45%** | 93.8% | +3.65 pp ✅ |
| Recall | 96.42% | 98.0% | −1.58 pp |
| **mAP@0.50** | **99.05%** | 96.1% | +2.95 pp ✅ |
| **mAP@0.50:0.95** | **89.58%** | ~76.0% | +13.58 pp ✅ |
| **F1-Score** | **96.93%** | 95.8% | +1.13 pp ✅ |

> Mane et al. (2023) used 2 classes (`car` + `crash`) on 2,525 images with YOLOv8. This model extends to **10 classes** on **~10,000 images** with YOLO11m, surpassing the benchmark in 4 out of 5 metrics. The Recall gap (−1.58 pp) is expected given the increased number of classes and dataset heterogeneity.


---

## 🚀 Getting Started Guide

Follow these steps to set up the project on your local machine.

### 📦 Prerequisites

Ensure you have the following tools installed:

- ✅ **macOS 26.5 (Tahoe) + Xcode 26.5** — required to build and run the native macOS app (`frontend-mac/`).
- ✅ **Node.js** (v18 or later) — used by the AWS Amplify Gen 2 backend tooling (`npx ampx`).
- ✅ **Python 3.11** (strictly required — coremltools 9.0 does not provide wheels for Python 3.12 or later) — for the FastAPI detection backend.
- ✅ **AWS account** with credentials configured — the macOS app uses Amplify (Cognito, AppSync/DynamoDB, S3).
- ⚡ **GPU acceleration** (optional): NVIDIA **CUDA Toolkit** on Linux/Windows, or **MPS** on Apple Silicon Macs (built into PyTorch, no extra install).

> 💡 *Tip: Keep your packages up-to-date for best results.*
>
> **macOS users:** CUDA is not supported on macOS. On Apple Silicon Macs (M1/M2/M3/M4), the backend automatically uses the **MPS (Metal Performance Shaders)** GPU backend — no CUDA install required. The device is selected automatically in this order: **CUDA → MPS → CPU**.

### 🔧 Installing CUDA (Linux/Windows with NVIDIA only)

For GPU acceleration on NVIDIA hardware, install CUDA on your system. [Watch Tutorial](https://www.youtube.com/watch?v=nATRPPZ5dGE) for step-by-step guidance.
Ensure your CUDA version matches your PyTorch build. **Skip this step on macOS** — Apple Silicon uses MPS instead.

## 🛠️ Installation Steps

### 1. 📁 Clone the Repository

```bash
git clone <your-repo-url>
cd crash-car-project
```

### 2. 🖥️ Set Up the Frontend (native macOS app)

The frontend is a **native macOS app** (`frontend-mac/`, SwiftUI + AWS Amplify Gen 2). It replaces the deprecated Next.js dashboard.

1. **Deploy the Amplify Gen 2 backend** (Cognito, AppSync/DynamoDB, S3). From `frontend-mac/`:
   ```bash
   cd frontend-mac
   npx ampx sandbox --once --outputs-out-dir CrashCar-MacUI/CrashCar-MacUI
   ```
   This deploys the dev stack and refreshes the `amplify_outputs.json` bundled with the app.

2. **Open the project in Xcode** and run it:
   ```bash
   open CrashCar-MacUI/CrashCar-MacUI.xcodeproj   # then ⌘R
   ```
   The first build is slow (Amplify Swift SPM graph).

> 🔐 **Auth** uses AWS Cognito **Managed Login** with federated Google sign-in — there is no `.env` / NextAuth / Prisma / PostgreSQL setup anymore. Cognito is configured from the AWS Console; the Google OAuth redirect URI must point to Cognito (`https://<domain>.auth.<region>.amazoncognito.com/oauth2/idpresponse`).
>
> 📖 For the full setup (prerequisites, Keychain/sandbox entitlements, tests, production notes) see [`frontend-mac/README.md`](frontend-mac/README.md).

### 3. 🔌 Set Up the Backend

1. **Create a Virtual Environment**

   > Use **Python 3.11** specifically. Python 3.12+ will fail when loading `.mlpackage` models (coremltools requirement).

   ```bash
   cd ../backend

   # macOS / Linux:
   python3.11 -m venv venv
   source venv/bin/activate

   # Windows:
   py -3.11 -m venv venv
   venv\Scripts\activate
   ```

2. **Install PyTorch in Virtual Environment**

   **On macOS (Apple Silicon, M1/M2/M3/M4):**
   ```bash
   pip install torch torchvision torchaudio
   ```
   Then export the MPS fallback flag (recommended, so any op not yet implemented in MPS falls back to CPU instead of crashing):
   ```bash
   export PYTORCH_ENABLE_MPS_FALLBACK=1
   ```

   **On Linux/Windows with NVIDIA GPU:**
   ```bash
   pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu126
   ```

   **CPU-only (any platform):**
   ```bash
   pip install torch torchvision torchaudio
   ```

3. **Install Backend Dependencies**
   ```bash
   pip install -r requirements.txt
   ```

   > The model file `backend/model/best.pt` is required at startup. It will be loaded automatically when the backend starts.

## ▶️ Running the Application

### 1. 🔙 Start the Backend (FastAPI)

```bash
cd backend
source venv/bin/activate           # macOS/Linux
# venv\Scripts\activate            # Windows
export PYTORCH_ENABLE_MPS_FALLBACK=1   # macOS only
uvicorn app:app --host 0.0.0.0 --port 8000 --reload
```

The backend will be available at `http://localhost:8000`.

### 2. 🖥️ Launch the macOS App

With the Amplify dev stack deployed (see setup) and the backend running, open and run the app from Xcode:

```bash
cd ../frontend-mac
open CrashCar-MacUI/CrashCar-MacUI.xcodeproj   # then ⌘R
```

The app connects to the FastAPI backend over WebSocket (`ws://localhost:8000/ws/detect`) and persists incidents in AWS (AppSync/DynamoDB) with accident images in S3. Sign in with Google via Cognito Managed Login.

## How It Works 🚦

Crash Detection ML is an AI-powered accident detection system that leverages advanced computer vision technology to identify vehicle collisions in real-time and facilitate rapid emergency response. Here's how it works:

### Step-by-Step Process

1. **Accident Happens**
   A crash occurs on the road, captured by CCTV cameras installed at strategic locations.

2. **CCTV Captures Footage**
   The video feed is processed frame by frame. The YOLO11m model classifies each frame detecting objects across 10 classes — from regular vehicles and pedestrians to specific accident types.

3. **Temporal Validation**
   A TemporalValidator confirms only accidents that persist for at least 10 consecutive frames (~0.33 s at 30 FPS), suppressing 98% of spurious detections.

4. **Instant Alert Sent**
   Upon confirming an accident event, the backend sends an immediate alert to highway authorities and serializes the event to a structured JSON report with timestamp, confidence score, tracker ID and bounding box coordinates.

5. **Verification and Response**
   Authorities verify the incident through the native macOS app and dispatch emergency services to the scene.

## System Architecture

<p align="center">
  <img src="https://github.com/AngelDavidStudios/Project_ML_CarCrashDetection/blob/main/assets/Diagrama-Arquitectura-CarCrash.jpg" alt="System Architecture">
</p>

## Methodology

<p align="center">
  <img src="https://github.com/AngelDavidStudios/Project_ML_CarCrashDetection/blob/main/assets/Diagrama-Procesos.jpg" alt="Methodology">
</p>

## Performance Highlights 📊

<img src="https://github.com/AngelDavidStudios/Project_ML_CarCrashDetection/blob/main/assets/Resultados-Training.png" alt="YOLO11m Performance" style="width:100%; max-width:900px;"/>

### 🔍 Key Performance Metrics

- **mAP@0.50:** 99.05% — excellent object detection accuracy
- **mAP@0.50:0.95:** 89.58% — strong performance at stricter IoU thresholds
- **Precision:** 97.45% — very low false positive rate
- **Recall:** 96.42% — high true positive rate
- **F1-Score:** 96.93% — balanced precision/recall

### 💡 Class Performance Highlights

- All 10 classes achieve ~99% mAP@0.50
- Strongest performance: `car_object_accident` (97.6% mAP@0.50:0.95)
- Surpasses Mane et al. (2023) benchmark in 4 out of 5 metrics

---

## 🗂️ Repository Structure

The project is divided into two main parts:

1. **Frontend — native macOS app** (`/frontend-mac`):
   - Built with **SwiftUI** (macOS 26 Tahoe, LiquidGlass) and **AWS Amplify Gen 2**.
   - Handles the user interface, authentication (AWS Cognito Managed Login + federated Google), and incident management.
   - Persists data in **AppSync/DynamoDB** and accident images in **S3**; consumes the FastAPI backend over WebSocket.
   - Key paths:
     - `CrashCar-MacUI/CrashCar-MacUI.xcodeproj`: the Xcode project (bundle `com.adstudios.CrashCar-MacUI`).
     - `CrashCar-MacUI/`: SwiftUI views, view models, and services.
     - `amplify/`: Amplify Gen 2 backend definition (auth, data, storage).
     - `amplify_outputs.json`: generated AWS config bundled with the app.
     - `README.md` · `E2E_CHECKLIST.md`: setup and end-to-end verification guides.

   > ⚠️ The earlier **Next.js 15 + Prisma + PostgreSQL** dashboard (`/frontend`) is **deprecated and no longer used** — kept in the repo for reference only.

2. **Backend** (`/backend`):
   - Built with **FastAPI** + **PyTorch** + **Ultralytics YOLO11m**.
   - Runs the accident detection pipeline and streams results over WebSocket.
   - Key files:
     - `app.py`: Main entry point — WebSocket `/ws/detect`, REST endpoints `/health`, `/detect/image`, `/detect/video`.
     - `model/best.pt`: YOLO11m weights (39 MB) — loaded at startup.
     - `crash_detection_ml/components/model_trainer.py`: Device selection (CUDA → MPS → CPU) and inference.
     - `requirements.txt`: Python dependencies (PyTorch installed separately — see setup).

## 📄 License

This project is licensed under the [MIT License](LICENSE). See the LICENSE file for details.

## 🙌 Credits & Acknowledgments

**Training datasets** (combined, ~10,000 images total, Roboflow Universe):

- **Crash Car Detection v3** — Mada Study Team (CC-BY 4.0). The same dataset used by Mane et al. (2023) as the primary benchmark. [Roboflow Universe](https://universe.roboflow.com/mada-study/crash-car-detection)
- **Traffic Accident YOLO8 v4** — University Gunadarma. Additional accident scenarios and traffic conditions. [Roboflow Universe](https://universe.roboflow.com/angel-david/traffic-accident-yolo8)
- **Detección de Accidentes** — Roboflow Universe. Complementary instances of bikes, pedestrians and mixed accident types.

**Reference paper:**
Mane, D. T., Sangve, S., Kandhare, S., Mohole, S., Sonar, S., & Tupare, S. (2023). Real-time vehicle accident recognition from traffic video surveillance using YOLOV8 and OpenCV. *International Journal on Recent and Innovation Trends in Computing and Communication, 11*(5s), 250–258. https://doi.org/10.17762/ijritcc.v11i5s.6651

## 📬 Support & Contact Information

For any queries, feedback, or support, feel free to reach out at: **angeldavidstudios@outlook.com**