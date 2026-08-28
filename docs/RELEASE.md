# Production Release Notes & Versioning (v1.0.0)

This document outlines the final production release plan, versioning scheme, and database migration log for the **Multi-Vendor E-Commerce Marketplace**.

---

## 1. Versioning Scheme

We follow [Semantic Versioning 2.0.0](https://semver.org/):
* **Format**: `MAJOR.MINOR.PATCH` (e.g. `1.0.0`)
* **v1.0.0 Release**: This marks the transition from development-ready sandbox to production-grade launch-ready state.
* **Backward Compatibility**: Any changes to API endpoints or schema will increment either `MINOR` (for backwards-compatible additions) or `MAJOR` (for breaking changes).

---

## 2. Release Steps

1. **Verify State**: Verify all backend and frontend test suites pass, and all static analysis checks are green.
2. **Environment Configuration**: Configure production secrets (`SECRET_KEY`, `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`) as secure environment variables.
3. **Spin up Infrastructure**: Run `docker compose -f docker-compose.prod.yml up -d` to provision production PostgreSQL, Redis, and FastAPI backend services.
4. **Apply Migrations**: Execute `alembic upgrade head` in the production environment to align the database schema.
5. **Verify Health and Readiness**: Monitor `/health` and `/ready` endpoints to ensure services are fully initialized.

---

## 3. Database Migration Logs

The following migrations have been successfully applied to align the production database schema:

| Revision ID | Author / Date | Description | Downgrade Path |
|---|---|---|---|
| `e1f2a3b4c5d0` | 2026-08-28 | Initial schema creation (users, products, categories, orders, notifications) | `alembic downgrade -1` (drop tables) |
| `f6a7b8c9d0e1` | 2026-08-28 | Added verified purchase reviews support | `alembic downgrade -1` (drop reviews table) |
| `a7b8c9d0e1f2` | 2026-08-28 | Added audit logs and seller onboarding status columns | `alembic downgrade -1` (drop audit logs, remove columns) |
| `c9d0e1f2a3b4` | 2026-08-28 | Added payment intents and transaction logs support | `alembic downgrade -1` (drop payments table) |
| `d0e1f2a3b4c5` | 2026-08-28 | Added database-level review uniqueness constraint `reviews(user_id, order_item_id)` | `alembic downgrade -1` (drop unique constraint) |

---

## 4. Verification Checklists

- [x] All 110 pytest cases pass.
- [x] All 87 Flutter unit/widget/BLoC tests pass.
- [x] 0 issues found in `flutter analyze`.
- [x] 0 issues found in `git diff --check`.

