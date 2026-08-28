# Deployment & Production Operations Guide

## 1. Production Docker Deployment

### 1.1 Prerequisites
- Docker Engine 24.0+
- Docker Compose v2.20+
- A provisioned PostgreSQL 16 instance (or compose-managed container)

### 1.2 Environment File Configuration
Create a secure `.env` file from `.env.example`:

```bash
cp .env.example .env
```

Generate a secure production secret key:
```bash
python -c "import secrets; print(secrets.token_hex(32))"
```

Configure the following production variables in `.env`:
```ini
ENVIRONMENT=production
SECRET_KEY=<generated-64-character-token>
POSTGRES_USER=prod_db_user
POSTGRES_PASSWORD=<strong-database-password>
POSTGRES_DB=marketplace_production
DATABASE_URL=postgresql+asyncpg://prod_db_user:<password>@postgres:5432/marketplace_production
CORS_ORIGINS=https://your-domain.com,https://app.your-domain.com
```

---

## 2. Launching Services with Production Compose

```bash
# Build and run containers in detached mode
docker compose -f docker-compose.prod.yml up -d --build

# Run database migrations
docker compose -f docker-compose.prod.yml exec backend alembic upgrade head

# Verify migration state
docker compose -f docker-compose.prod.yml exec backend alembic current
```

---

## 3. Health & Readiness Verification

### 3.1 Process Liveness Probe
```bash
curl -f http://localhost:8000/health
# Response: {"status": "ok", "app": "Multi-Vendor Marketplace API", ...}
```

### 3.2 Database Readiness Probe
```bash
curl -f http://localhost:8000/ready
# Response: {"status": "ready", "database": "connected", ...}
```

---

## 4. PostgreSQL Backup & Restore Strategy

### 4.1 Database Backup
Execute standard `pg_dump` snapshot:
```bash
docker compose exec postgres pg_dump -U $POSTGRES_USER -d $POSTGRES_DB -Fc > backup_$(date +%Y%m%d_%H%M%S).dump
```

### 4.2 Database Restore
```bash
# Stop application backend to prevent writes
docker compose stop backend

# Restore dump
docker compose exec -T postgres pg_restore -U $POSTGRES_USER -d $POSTGRES_DB --clean --if-exists < backup_file.dump

# Restart backend
docker compose start backend
```

---

## 5. Scaling & Multi-Instance Considerations

- **Rate Limiting**:
  The default in-memory rate limiter provides single-worker burst protection. For multi-container / Kubernetes replica deployments, transition to a Redis-backed distributed limiter by configuring `aioredis` or Redis token-bucket middleware.
- **Worker Configuration**:
  Production Dockerfile runs `uvicorn app.main:app --workers 4` by default. Adjust worker count based on CPU core availability: `(2 x $NUM_CORES) + 1`.

