# System Architecture & Technical Specifications

## 1. High-Level Architecture Overview

The Multi-Vendor Marketplace is structured as a scalable, modern micro-monolith backend paired with a cross-platform Clean Architecture Flutter frontend.

```
┌────────────────────────────────────────────────────────────────────────┐
│                        Flutter Client Application                      │
│   (Presentation: BLoC / Widgets  -> Domain: UseCases -> Data: Dio)     │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ HTTPS / REST (JSON) + Bearer JWT
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                         FastAPI Backend Layer                          │
│                                                                        │
│   ┌────────────────────────────────────────────────────────────────┐   │
│   │ Middleware: Correlation ID, CORS, Security Headers             │   │
│   └────────────────────────────────┬───────────────────────────────┘   │
│                                    ▼                                   │
│   ┌────────────────────────────────────────────────────────────────┐   │
│   │ Rate Limiting: Redis Sliding Window Lua script (Fallback: Mem) │   │
│   └────────────────────────────────┬───────────────────────────────┘   │
│   ┌────────────────────────────────────────────────────────────────┐   │
│   │ Routers: Auth, Profile, Addresses, Products, Orders, etc.      │   │
│   └────────────────────────────────┬───────────────────────────────┘   │
│                                    ▼                                   │
│   ┌────────────────────────────────────────────────────────────────┐   │
│   │ Service Layer: Business Rules, State Machines, Authz Checks    │   │
│   └────────────────────────────────┬───────────────────────────────┘   │
│                                    ▼                                   │
│   ┌────────────────────────────────────────────────────────────────┐   │
│   │ Repository Layer: SQLAlchemy 2.0 Async ORM / SQL Aggregations  │   │
│   └────────────────────────────────┬───────────────────────────────┘   │
└────────────────────────────────────┼───────────────────────────────────┘
                                     │ asyncpg Driver
                                     ▼
┌────────────────────────────────────────────────────────────────────────┐
│                      PostgreSQL 16 Database                            │
│  - Partial Unique Indexes (One default address per user)               │
│  - Immutable historical order shipping snapshots                       │
│  - Alembic forward/backward schema migration management                │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Backend Architectural Principles

### 2.1 Layered Architecture Pattern
1. **Routers (`app/modules/*/router.py`)**:
   - HTTP protocol translation, request validation via Pydantic schemas, dependency injection, and HTTP status code mappings.
2. **Services (`app/modules/*/service.py`)**:
   - Pure domain business logic, state machine transitions, authorization enforcement, and cross-module event dispatching (e.g. notifications).
3. **Repositories (`app/modules/*/repository.py`)**:
   - Async database access, transactional boundary handling, SQL aggregation optimization, and query construction.
4. **Models (`app/modules/*/models.py`)**:
   - SQLAlchemy 2.0 declarative database entities with typed columns and relationship mappings.

### 2.2 Security & Financial Authority
- **Zero Trust on Client Financial Inputs**:
  - The client NEVER passes total amounts, unit prices, discounts, or commission rates during checkout or payment creation.
  - All financial calculations are derived directly from database product prices and recorded in immutable snapshots.
- **Role-Based Access Control (RBAC) & Vendor Suspension**:
  - Three distinct roles: `customer`, `seller`, `admin`.
  - Enforced via FastAPI dependency injection guards: `get_current_active_user`, `require_seller_role`, `require_admin_role`.
  - Mutation endpoints on seller resources additionally require `require_approved_seller` check to block suspended or onboarding vendors.
- **Multi-Vendor Isolation**:
  - Sellers can only view, modify, and fulfill `OrderItems` matching their own `seller_id`.
  - Customers can only access their own orders, cart items, addresses, and wishlist entries.
- **Payment Gateway Abstraction**:
  - Seamlessly integrates either `MockPaymentProvider` or `StripeProvider` based on environment configurations, executing non-blocking asynchronous calls alongside signature-verified, idempotent webhook transaction captures.
- **Review Integrity Guard**:
  - Database-level unique constraints on `reviews(user_id, order_item_id)` block review flooding and rating spamming.

---

## 3. Frontend Architectural Principles

### 3.1 Clean Architecture + BLoC Pattern
The Flutter application strictly isolates UI logic from external dependencies:

```
frontend/lib/features/<feature>/
├── domain/
│   ├── entities/          # Pure Dart models (Equatable, immutable)
│   ├── repositories/      # Repository interface contracts
│   └── usecases/          # Granular, single-responsibility use case classes
├── data/
│   ├── models/            # JSON serialization (fromJson/toJson)
│   ├── datasources/       # Remote HTTP APIs (DioClient) & Local storage
│   └── repositories/      # Concrete repository implementations
└── presentation/
    ├── bloc/              # BLoC, Events, and States
    ├── pages/             # Stateful/Stateless screen widgets
    └── widgets/           # Reusable feature-specific components
```

### 3.2 State Management Rules
- All user actions and lifecycle triggers dispatch strongly typed `Event` objects to BLoCs.
- BLoCs invoke `UseCase` instances and emit immutable `State` objects.
- Presentation widgets react exclusively via `BlocBuilder`, `BlocListener`, or `BlocConsumer`.
- Dio HTTP clients and repositories are never directly referenced in the presentation layer.

---

## 4. Key Subsystem Workflows

### 4.1 Order Checkout & Historical Snapshotting
1. Customer selects a saved address or enters new shipping details.
2. The checkout service copies the address snapshot into immutable order columns:
   - `shipping_full_name`, `shipping_phone`, `shipping_address_line1`, `shipping_city`, `shipping_postal_code`, etc.
3. If the user later edits or deletes their saved address in the address book, existing order snapshots remain untouched.

### 4.2 Verified Purchase Review Flow
1. Customer submits a rating & review for a `product_id`.
2. Review service verifies server-side that the customer has at least one order containing that product with `FulfillmentStatus.DELIVERED`.
3. If verified, the review is marked `is_verified_purchase = true` and `is_approved = true`, immediately updating aggregate product ratings.

### 4.3 Seller Analytics Aggregation
- Timeline sales aggregations (Daily, Weekly, Monthly) utilize PostgreSQL `date_trunc` with single-pass SQL aggregations filtering by:
  - `OrderItem.seller_id == authenticated_seller.id`
  - `Order.payment_status == PaymentStatus.PAID`
  - `Order.status != OrderStatus.CANCELLED`
- Prevents N+1 in-memory computations and scales efficiently.

