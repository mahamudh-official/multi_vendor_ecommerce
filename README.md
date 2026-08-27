# Marketo — Multi-Vendor Marketplace

> A production-quality multi-vendor marketplace built with Flutter + FastAPI.

[![Flutter](https://img.shields.io/badge/Flutter-3.44.6-blue?logo=flutter)](https://flutter.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.115-green?logo=fastapi)](https://fastapi.tiangolo.com)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-blue?logo=postgresql)](https://www.postgresql.org)
[![Docker](https://img.shields.io/badge/Docker-Compose-blue?logo=docker)](https://docs.docker.com/compose)

---

## Overview

Marketo is a full-featured multi-vendor e-commerce platform where customers can browse products, sellers can manage their stores, and admins oversee the platform — all with a premium, polished mobile experience.

---

## ✅ Implemented (Step 1 — Foundation)

- **Monorepo structure** — `frontend/` (Flutter) + `backend/` (FastAPI)
- **Flutter premium design system** — Material 3 with custom color tokens, typography, spacing, shadows
- **Light + dark theme** — Full support, system-preference aware
- **Animated splash screen** — Fade + scale logo animation
- **Premium home preview** — Floating app bar, search, hero banner, category chips, product grid
- **Clean Architecture foundation** — Feature-first structure with BLoC/Cubit ready
- **go_router routing** — `/` (splash) → `/welcome` (home preview), extensible
- **Dio HTTP client** — Configurable timeouts, logging interceptor, error interceptor
- **Secure storage abstraction** — Token save/get/clear, no direct widget access
- **get_it dependency injection** — Lazy singletons for Dio, SecureStorage
- **FastAPI backend** — `/health` endpoint, CORS, lifespan DB connection check
- **PostgreSQL** — Docker Compose with healthcheck, async SQLAlchemy 2.x
- **Alembic** — Async-compatible, real `users` table migration
- **User model** — UUID PK, role enum (customer/seller/admin), timestamps
- **Security** — `pwdlib/argon2` password hashing, JWT with `python-jose`
- **Configuration** — `pydantic-settings`, no hardcoded secrets
- **Tests** — Flutter analyzer + smoke tests; Backend health + DB tests
- **Git** — Clean initial commit

---

## 🔜 Coming Next

| Step | Feature |
|------|---------|
| Step 2 | Auth (login, register, JWT refresh, role guards) |
| Step 3 | Product listing, search, filtering (real API) |
| Step 4 | Seller dashboard (CRUD products, orders) |
| Step 5 | Cart & checkout flow |
| Step 6 | Orders & order tracking |
| Step 7 | Payment integration |
| Step 8 | Reviews & ratings |
| Step 9 | Admin dashboard |
| Step 10 | Notifications (push, in-app) |

---

## Technology Stack

### Frontend
| Technology | Version | Purpose |
|---|---|---|
| Flutter | 3.44.6 | Cross-platform UI |
| Dart | 3.12.2 | Language |
| flutter_bloc | ^9.x | State management |
| go_router | ^18.x | Declarative routing |
| get_it | ^8.x | Dependency injection |
| dio | ^5.x | HTTP client |
| flutter_secure_storage | ^9.x | Token storage |
| equatable | ^2.x | Value equality |
| json_serializable | ^6.x | Code generation |

### Backend
| Technology | Version | Purpose |
|---|---|---|
| Python | 3.12 | Language (Docker) |
| FastAPI | 0.115 | REST API framework |
| SQLAlchemy | 2.x (async) | ORM |
| Alembic | 1.x | Database migrations |
| PostgreSQL | 16 | Primary database |
| asyncpg | 0.30 | Async PG driver |
| pydantic-settings | 2.x | Configuration |
| pwdlib[argon2] | 0.2 | Password hashing |
| python-jose | 3.x | JWT tokens |

### Infrastructure
| Technology | Purpose |
|---|---|
| Docker | Containerization |
| Docker Compose | Local orchestration |

---

## Architecture

### Flutter — Feature-First Clean Architecture

```
lib/
├── app/                    ← Root app widget (MaterialApp.router)
├── core/
│   ├── constants/          ← App-wide constants
│   ├── di/                 ← get_it dependency injection
│   ├── error/              ← Failures + Exceptions
│   ├── network/            ← Dio client
│   ├── router/             ← go_router config
│   ├── storage/            ← Secure storage abstraction
│   ├── theme/              ← Design system tokens
│   └── widgets/            ← Reusable UI components
└── features/
    └── <feature>/
        ├── data/
        │   ├── datasources/  ← API / local calls
        │   ├── models/       ← JSON serializable DTOs
        │   └── repositories/ ← Repository implementations
        ├── domain/
        │   ├── entities/     ← Pure Dart objects
        │   ├── repositories/ ← Abstract interfaces
        │   └── usecases/     ← Business logic
        └── presentation/
            ├── bloc/         ← BLoC / Cubit + States
            ├── pages/        ← Full screens
            └── widgets/      ← Feature-specific widgets
```

**Dependency flow:**
```
Page → BLoC/Cubit → UseCase → Repository (abstract) → Repository (impl) → DataSource → Dio
```

### Backend — Modular FastAPI

```
app/
├── main.py              ← FastAPI app, CORS, routers
├── core/
│   ├── config.py        ← pydantic-settings
│   ├── database.py      ← Async SQLAlchemy engine
│   └── security.py      ← JWT + pwdlib
├── common/
│   ├── exceptions/      ← Custom exception hierarchy
│   └── responses/       ← Standard response envelopes
└── modules/
    └── auth/            ← Auth feature module
        ├── models.py    ← SQLAlchemy User model
        ├── schemas.py   ← Pydantic v2 schemas
        ├── router.py    ← FastAPI router
        ├── repository.py← Data access layer
        ├── service.py   ← Business logic
        └── dependencies.py ← FastAPI dependencies
```

---

## Folder Structure

```
multi_vendor_ecommerce/
├── frontend/            ← Flutter application
├── backend/             ← FastAPI application
├── docs/                ← Architecture docs
├── docker-compose.yml
├── .gitignore
└── README.md
```

---

## Setup Instructions

### Prerequisites

- Flutter SDK 3.44.6+
- Docker Desktop
- Git

### 1. Clone

```bash
git clone <your-repo-url>
cd multi_vendor_ecommerce
```

### 2. Backend — Start with Docker

```bash
# Start PostgreSQL + FastAPI
docker compose up -d

# Check status
docker compose ps
docker compose logs backend
```

### 3. Run Alembic Migrations

```bash
# From the backend directory
cd backend
pip install -r requirements.txt
alembic upgrade head
```

Or exec into the running backend container:

```bash
docker compose exec backend alembic upgrade head
```

### 4. Flutter — Install Dependencies

```bash
cd frontend
flutter pub get
```

### 5. Run the App

```bash
flutter run
```

---

## Environment Variables

Copy `backend/.env.example` to `backend/.env` and fill in values:

| Variable | Description | Default |
|---|---|---|
| `DATABASE_URL` | PostgreSQL async URL | `postgresql+asyncpg://...` |
| `SECRET_KEY` | JWT signing key | *(change this!)* |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | Access token TTL | `30` |
| `REFRESH_TOKEN_EXPIRE_DAYS` | Refresh token TTL | `7` |
| `CORS_ORIGINS` | Allowed CORS origins | `http://localhost:3000` |
| `POSTGRES_USER` | DB username | `marketplace_user` |
| `POSTGRES_PASSWORD` | DB password | `marketplace_pass` |
| `POSTGRES_DB` | DB name | `marketplace_db` |
| `ENVIRONMENT` | `development` or `production` | `development` |

> **Never commit `.env` files.** The `.gitignore` excludes them.

---

## Flutter Commands

```bash
# From frontend/
flutter pub get          # Install dependencies
flutter run              # Run on connected device
flutter analyze          # Static analysis
flutter test             # Run tests
flutter build apk        # Build Android APK
flutter build ios        # Build iOS
flutter build web        # Build web
```

## Backend Commands

```bash
# From backend/ (with virtualenv activated or in Docker)
uvicorn app.main:app --reload    # Dev server
alembic upgrade head             # Apply migrations
alembic revision --autogenerate -m "description"  # New migration
pytest tests/ -v                 # Run tests
```

## Docker Commands

```bash
docker compose up -d             # Start all services (background)
docker compose up                # Start with logs
docker compose down              # Stop services
docker compose down -v           # Stop + remove volumes
docker compose logs -f backend   # Follow backend logs
docker compose ps                # Service status
docker compose exec backend bash # Shell into backend
```

---

## Testing

### Flutter

```bash
cd frontend
flutter analyze    # Zero issues expected
flutter test       # Smoke tests
```

### Backend

```bash
# With Docker running:
cd backend
pip install -r requirements.txt
pytest tests/ -v

# Health check:
curl http://localhost:8000/health
```

---

## API Documentation

When backend is running in development mode:

- **Swagger UI:** http://localhost:8000/docs
- **ReDoc:** http://localhost:8000/redoc
- **Health:** http://localhost:8000/health

---

## Git Workflow

```bash
# Feature branch workflow (starting Step 2):
git checkout -b feat/step-2-auth
# ... make changes ...
git add .
git commit -m "feat: implement authentication (Step 2)"
git push origin feat/step-2-auth
# Create PR → review → merge to main
```

### Commit Convention

| Prefix | Usage |
|---|---|
| `feat:` | New feature |
| `fix:` | Bug fix |
| `refactor:` | Code improvement |
| `test:` | Tests only |
| `docs:` | Documentation |
| `chore:` | Build/tooling |

---

## License

Private — All rights reserved.
