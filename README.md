# Marketo — Production Multi-Vendor Marketplace

> A production-grade, full-stack multi-vendor marketplace built with **Flutter (Clean Architecture + BLoC)** and **FastAPI (SQLAlchemy 2.0 Async + PostgreSQL 16 + Alembic)**.

[![CI](https://github.com/mahamudh-official/multi_vendor_ecommerce/actions/workflows/ci.yml/badge.svg)](https://github.com/mahamudh-official/multi_vendor_ecommerce/actions)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter)](https://flutter.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.115-009688?logo=fastapi)](https://fastapi.tiangolo.com)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-336791?logo=postgresql)](https://www.postgresql.org)
[![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker)](https://docs.docker.com/compose)
[![Clean Architecture](https://img.shields.io/badge/Architecture-Clean%20%2B%20BLoC-orange)](#architecture)

---

## 🚀 Key Features & Subsystems

### 🛍️ Customer Experience
- **Advanced Product Discovery**: Full-text keyword search across title, SKU, and description with category filtering, price range bounds, stock availability toggles, and multi-parameter sorting.
- **Cart & Dynamic Checkout**: Real-time stock validation, persistent shopping cart, and seamless multi-vendor order placement.
- **Delivery Address Management**: Multi-address book with PostgreSQL database-level partial unique index (`uq_addresses_user_default`) guaranteeing a single default address.
- **Historical Order Snapshots**: Customer delivery addresses are permanently snapshotted into order records upon checkout, rendering historical receipts immune to subsequent address edits or deletions.
- **Verified Purchase Reviews**: 5-star rating system protected by server-side delivered-order verification guards.

### 🏪 Seller Storefront & Analytics
- **Inventory & Product Management**: Create, update, toggle visibility, and monitor stock thresholds with automated low-stock warnings.
- **Multi-Vendor Order Fulfillment**: Granular per-item fulfillment state machine (`PENDING` → `CONFIRMED` → `PROCESSING` → `SHIPPED` → `DELIVERED`) strictly isolated to the seller's owned items.
- **SQL Aggregated Analytics**: Real-time dashboard computing 8 core revenue KPIs, daily/weekly/monthly timeline sales trends (`date_trunc`), and top-performing product rankings.

### 🛡️ Platform Administration & Security
- **Vendor Moderation**: Review seller applications and transition seller account statuses (`pending` → `approved` / `rejected` / `suspended`).
- **Catalog Moderation**: Category tree taxonomy management and product moderation.
- **Immutable Audit Trail**: Append-only system audit logging tracking administrative decisions.
- **Security & RBAC**: Strict JWT Bearer token authentication, Argon2id password hashing, IDOR prevention, and sliding-window rate limiting on sensitive routes.

---

## 🏗️ Architecture

### Backend: FastAPI + SQLAlchemy Async + PostgreSQL
```
backend/app/
├── core/                  # Config, security, DB engine, middlewares, rate limiter
├── common/                # Global exception handlers and utility envelopes
└── modules/
    ├── auth/              # Registration, login, JWT refresh, RBAC dependencies
    ├── profile/           # User profile management with whitelisting guards
    ├── addresses/         # Delivery address CRUD & single-default constraint
    ├── products/          # Catalog browsing, search, and category taxonomy
    ├── cart/              # Cart item management and stock reservations
    ├── wishlist/          # Customer saved items
    ├── orders/            # Checkout, state machine, and historical snapshots
    ├── payments/          # Payment intent creation and mock provider confirmation
    ├── seller/            # Seller products, order fulfillment, and analytics
    ├── reviews/           # Verified-purchase ratings and review moderation
    ├── notifications/     # Event-driven customer/seller notification feeds
    ├── admin/             # Vendor approvals, moderation, and audit logs
    └── audit/             # Immutable audit log storage
```

### Frontend: Flutter Clean Architecture + BLoC
```
frontend/lib/
├── core/
│   ├── constants/         # Centralized environment-driven API URLs
│   ├── di/                # get_it dependency injection container
│   ├── network/           # DioClient with interceptors and error handling
│   ├── router/            # Declarative go_router route configuration
│   └── theme/             # Material 3 premium design system & token aliases
└── features/              # Feature modules (Domain -> Data -> Presentation)
    ├── auth/
    ├── profile/
    ├── addresses/
    ├── products/
    ├── search/
    ├── cart/
    ├── wishlist/
    ├── orders/
    ├── checkout/
    ├── payments/
    ├── seller/
    ├── seller_analytics/
    ├── reviews/
    ├── notifications/
    └── admin/
```

---

## 🛠️ Quickstart & Local Development

### 1. Prerequisites
- Docker & Docker Compose
- Python 3.12+ (optional for local host tools)
- Flutter 3.x SDK

### 2. Start Backend & Database
```bash
# Clone repository
git clone https://github.com/mahamudh-official/multi_vendor_ecommerce.git
cd multi_vendor_ecommerce

# Copy environment template
cp .env.example .env

# Start PostgreSQL and FastAPI containers
docker compose up -d

# Run database migrations
docker compose exec backend alembic upgrade head
```

The API will be available at `http://localhost:8000`.
Swagger interactive docs: `http://localhost:8000/docs`.

### 3. Run Flutter Application
```bash
cd frontend

# Install dependencies
flutter pub get

# Run application (Web / Desktop / Mobile)
flutter run -d chrome
```

---

## 🧪 Testing & Verification

### Backend Automated Tests (100% Passing)
```bash
docker compose exec backend pytest -v
```

### Frontend Static Analysis & Unit Tests
```bash
cd frontend
flutter analyze
flutter test
```

### Live End-to-End Verification
```bash
python backend/verify_step11.py
```

---

## 📚 Technical Documentation

- [Detailed Architecture Guide](docs/ARCHITECTURE.md)
- [REST API Reference](docs/API.md)
- [Production Deployment & Backups](docs/DEPLOYMENT.md)
- [Security Model & Threat Mitigations](docs/SECURITY.md)
- [Advanced Production & Portfolio Polish](docs/portfolio_polish.md)
- [Production Release & Migration Logs](docs/RELEASE.md)
- [Project Capabilities Scorecard](docs/PROJECT_STATUS.md)

---

## 📄 License
This project is open-source under the MIT License.
