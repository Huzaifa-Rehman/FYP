# SpeedyGrocer

**AI-Powered Hyperlocal Grocery Delivery Platform**

A cross-platform Flutter + Firebase application connecting local grocery stores, customers, and delivery riders in one role-based system — built as a Final Year Project at COMSATS University Islamabad, Abbottabad Campus.

---

## 📦 Overview

SpeedyGrocer brings four distinct roles into a single codebase:

- **Customers** — browse nearby stores, order groceries, track delivery live on a map, and pay via multiple methods
- **Vendors** — manage inventory, process incoming orders, and view AI-based demand forecasts for restocking
- **Riders** — go online to receive automatically assigned deliveries, navigate via optimised routes, and track earnings
- **Admin** — manage users, moderate vendor ads, oversee platform analytics, and process vendor/rider payouts

---

## ✨ Key Features

- 🔐 Role-based authentication (Email/Password + Google Sign-In)
- 🏪 Store discovery, product search, and category browsing
- 🛒 Persistent cart with real-time stock validation
- 💳 Multi-method checkout — Cash on Delivery, mocked JazzCash/EasyPaisa, and a live Safepay sandbox integration
- 🚴 Automated nearest-rider dispatch based on real GPS distance
- 🗺️ Live order tracking with real road-network routing (Google Maps Directions API)
- 🔔 Push notifications via Firebase Cloud Messaging
- 📊 AI-based inventory demand forecasting (scikit-learn microservice)
- ⭐ Vendor and rider ratings & customer feedback
- 🛠️ Full admin console — user management, ad moderation, analytics, payouts

---

## 🏗️ Architecture

SpeedyGrocer follows a layered architecture:

```
┌──────────────────────────────────────────────┐
│   Client Layer — Flutter (Android/Web)        │
│   Role-based UI: Customer / Vendor / Rider /  │
│   Admin dashboards                            │
├──────────────────────────────────────────────┤
│   Service Layer — Dart                        │
│   AuthService · ProductService · OrderService │
│   DeliveryEngine · RouteOptimizer             │
│   PaymentService · InventoryPredictor         │
│   NotificationService                         │
├──────────────────────────────────────────────┤
│   Backend — Firebase                          │
│   Authentication · Cloud Firestore            │
│   Cloud Storage · Cloud Messaging             │
├──────────────────────────────────────────────┤
│   Supporting Microservices (Flask, on Render) │
│   speedygrocer_ml — ML demand forecasting     │
│   backend — Safepay payment orchestration     │
└──────────────────────────────────────────────┘
```

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Client | Flutter 3.x / Dart 3.0+ |
| State Management | Provider |
| Backend-as-a-Service | Firebase (Auth, Firestore, Storage, Cloud Messaging) |
| Maps & Location | Google Maps Platform (Directions + Geocoding API), Geolocator |
| Payments | Safepay sandbox, mocked EasyPaisa/JazzCash |
| ML Microservice | Python 3, Flask, scikit-learn, pandas |
| Hosting | Firebase Hosting (web), Render (microservices) |

---

## 📁 Project Structure

```
speedygrocer/
├── lib/
│   ├── models/          # Data models (User, Product, Order, Feedback, etc.)
│   ├── services/         # Business logic (Auth, Order, Payment, Delivery, etc.)
│   ├── providers/         # App-wide state (Cart, Location, Theme, Favorites)
│   ├── screens/           # Role-based UI screens
│   └── widgets/           # Reusable widgets
├── android/               # Android build configuration
├── web/                   # Web build configuration
├── speedygrocer_ml/        # Flask ML microservice (demand forecasting)
├── backend/                # Flask payment microservice (Safepay)
├── functions/               # Firebase Cloud Functions (webhook/refund)
├── firestore.rules          # Firestore security rules
└── pubspec.yaml
```

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.x
- A Firebase project with Authentication, Firestore, Storage, and Cloud Messaging enabled
- A Google Maps Platform API key (Directions + Geocoding APIs enabled)
- (Optional) A Safepay sandbox account for payment testing
- Python 3 (only needed if running the ML microservice locally)

### Installation

```bash
git clone https://github.com/Huzaifa-Rehman/FYP.git
cd FYP
flutter pub get
```

Add your `google-services.json` to `android/app/`.

### Running the app

```bash
flutter run \
  --dart-define=MAPS_API_KEY=your_maps_api_key \
  --dart-define=SAFEPAY_API_KEY=your_safepay_key \
  --dart-define=SAFEPAY_SECRET_KEY=your_safepay_secret
```

### Building for release

```bash
# Android APK
flutter build apk --release --dart-define=MAPS_API_KEY=... --dart-define=SAFEPAY_API_KEY=... --dart-define=SAFEPAY_SECRET_KEY=...

# Web
flutter build web --release --no-tree-shake-icons --dart-define=MAPS_API_KEY=... --dart-define=SAFEPAY_API_KEY=... --dart-define=SAFEPAY_SECRET_KEY=...
firebase deploy --only hosting
```

### Running the ML microservice locally

```bash
cd speedygrocer_ml
pip install -r requirements.txt --break-system-packages
python train_model.py
python app.py
```

---

## 🔑 Environment Variables / Secrets

| Variable | Used for |
|---|---|
| `MAPS_API_KEY` | Google Maps Directions, Geocoding, and native map rendering |
| `SAFEPAY_API_KEY` | Safepay sandbox checkout |
| `SAFEPAY_SECRET_KEY` | Safepay HMAC request signing |

None of these should ever be committed directly to the repository — always pass them via `--dart-define` at build time, and keep `.env`, `key.properties`, and `google-services.json` out of version control (see `.gitignore`).

---

## 🌐 Deployment

- **Web:** Hosted on Firebase Hosting
- **ML Microservice:** Deployed on Render (`speedygrocer_ml`)
- **Android:** Distributed as a signed/unsigned release APK

---

## 👥 Team

| Name | Registration No. |
|---|---|
| Bilal Yousaf | FA22-BSE-024/ATD |
| Huzaifa Rehman | FA22-BSE-027/ATD |

**Supervisor:** Syed Shahab Zareen

Department of Computer Science, COMSATS University Islamabad, Abbottabad Campus
Bachelor of Science in Software Engineering (2022–2026)

---

## 📄 License

This project was developed as a Final Year Project for academic purposes. All rights reserved by the authors unless otherwise stated.
