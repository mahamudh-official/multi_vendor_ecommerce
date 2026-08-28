# REST API Reference Documentation

**Base URL**: `http://localhost:8000/api/v1`  
**Interactive Swagger Docs**: `http://localhost:8000/docs` (Available in Development mode)

---

## 1. System & Observability Endpoints

### `GET /`
- **Description**: Root welcome message and API metadata.
- **Auth**: Public.
- **Response (200 OK)**:
  ```json
  {
    "message": "Welcome to Multi-Vendor Marketplace API",
    "version": "1.0.0",
    "environment": "development",
    "docs": "/docs"
  }
  ```

### `GET /health`
- **Description**: Container liveness probe. Does not query database.
- **Auth**: Public.
- **Response (200 OK)**:
  ```json
  {
    "status": "ok",
    "app": "Multi-Vendor Marketplace API",
    "version": "1.0.0",
    "environment": "development"
  }
  ```

### `GET /ready`
- **Description**: Readiness probe verifying PostgreSQL database query execution.
- **Auth**: Public.
- **Response (200 OK)**:
  ```json
  {
    "status": "ready",
    "database": "connected",
    "app": "Multi-Vendor Marketplace API",
    "version": "1.0.0",
    "environment": "development"
  }
  ```
- **Error (503 Service Unavailable)**: Returned if DB is unreachable within 3 seconds.

---

## 2. Authentication Module (`/auth`)

### `POST /api/v1/auth/register`
- **Description**: Register a new user (`customer` or `seller`). Password hashed using Argon2id.
- **Rate Limit**: 30 requests / minute.
- **Request Body**:
  ```json
  {
    "email": "user@example.com",
    "password": "Password123!",
    "full_name": "Alice Customer",
    "role": "customer"
  }
  ```
- **Response (201 Created)**: User profile object.

### `POST /api/v1/auth/login`
- **Description**: Authenticate with email and password to receive JWT tokens.
- **Rate Limit**: 30 requests / minute.
- **Request Body**:
  ```json
  {
    "email": "user@example.com",
    "password": "Password123!"
  }
  ```
- **Response (200 OK)**:
  ```json
  {
    "access_token": "eyJhbGciOi...",
    "refresh_token": "eyJhbGciOi...",
    "token_type": "bearer",
    "expires_in": 1800,
    "user": { "id": "...", "email": "user@example.com", "role": "customer" }
  }
  ```

### `GET /api/v1/auth/me`
- **Description**: Fetch current authenticated user.
- **Auth**: Bearer Token.

---

## 3. Customer Profile & Addresses (`/profile`, `/addresses`)

### `GET /api/v1/profile`
- **Description**: Retrieve customer/seller profile.
- **Auth**: Bearer Token.

### `PATCH /api/v1/profile`
- **Description**: Update whitelisted profile fields (`full_name`, `phone`, `avatar_url`).
- **Security**: Privileged fields (`role`, `is_active`, `email`) are rejected with `422`.

### `GET /api/v1/addresses`
- **Description**: List all delivery addresses for authenticated customer.
- **Auth**: Bearer Token (`customer`).

### `POST /api/v1/addresses`
- **Description**: Create delivery address. First address automatically becomes default.
- **Request Body**:
  ```json
  {
    "full_name": "Alice Primary",
    "phone": "+14155550001",
    "address_line_1": "100 Market St",
    "city": "San Francisco",
    "state": "CA",
    "postal_code": "94105",
    "country": "US",
    "is_default": true
  }
  ```

---

## 4. Products & Categories (`/products`, `/categories`)

### `GET /api/v1/products`
- **Description**: Search, filter, sort, and paginate active products.
- **Query Parameters**:
  - `search`: Filter by name, SKU, or description.
  - `category_id`: Filter by category UUID.
  - `min_price` / `max_price`: Price range filters.
  - `in_stock_only`: Boolean filter for available inventory.
  - `sort_by`: `created_at`, `price_asc`, `price_desc`, `rating`, `popularity`.
  - `page`: Page index (default: 1).
  - `page_size`: Page size (default: 20, max: 100).

---

## 5. Cart & Wishlist (`/cart`, `/wishlist`)

### `GET /api/v1/cart`
- **Description**: Retrieve customer's active cart with subtotal calculation.
- **Auth**: Bearer Token (`customer`).

### `POST /api/v1/cart/items`
- **Description**: Add product to cart with server-side stock validation.

---

## 6. Orders & Checkout (`/orders`)

### `POST /api/v1/orders/checkout`
- **Description**: Convert cart items into multi-vendor order with immutable shipping address snapshot.
- **Request Body**:
  ```json
  {
    "shipping_address": {
      "full_name": "Alice Customer",
      "phone": "+14155550001",
      "address_line1": "100 Market St",
      "city": "San Francisco",
      "state": "CA",
      "postal_code": "94105",
      "country": "US"
    }
  }
  ```
- **Response (201 Created)**: Order details with generated `order_number`.

### `GET /api/v1/orders`
- **Description**: Paginated customer order history with search and status filters.
- **Query Parameters**: `search`, `status`, `sort` (`newest` | `oldest`), `page`, `page_size`.

---

## 7. Payments (`/payments`)

### `POST /api/v1/payments/orders/{order_id}/create`
- **Description**: Initialize payment intent. Amount is strictly calculated server-side.
- **Rate Limit**: 20 requests / minute.

### `POST /api/v1/payments/{payment_id}/process`
- **Description**: Confirm mock payment. Idempotent state transitions.
- **Rate Limit**: 20 requests / minute.

---

## 8. Seller Dashboard & Analytics (`/seller`)

### `GET /api/v1/seller/analytics/overview`
- **Description**: 8 high-level KPIs (Total Revenue, Orders, Units Sold, AOV, Low Stock, etc.).
- **Auth**: Bearer Token (`seller`).

### `GET /api/v1/seller/analytics/sales`
- **Description**: Timeline sales aggregation (`period=daily|weekly|monthly`).
- **Auth**: Bearer Token (`seller`).

### `GET /api/v1/seller/analytics/products`
- **Description**: Top products leaderboard ranked by revenue and units sold.
- **Auth**: Bearer Token (`seller`).

---

## 9. Reviews & Ratings (`/reviews`)

### `POST /api/v1/products/{product_id}/reviews`
- **Description**: Submit verified purchase review. Enforces delivered order verification.
- **Rate Limit**: 30 requests / minute.
- **Request Body**:
  ```json
  {
    "rating": 5,
    "title": "Outstanding quality",
    "comment": "Very satisfied with this keyboard."
  }
  ```

---

## 10. Admin & Platform Management (`/admin`)

- `GET /api/v1/admin/users`: User management and role moderation.
- `PATCH /api/v1/admin/sellers/{seller_id}/status`: Approve or reject vendor applications.
- `GET /api/v1/admin/audit-logs`: Immutable system audit trail.
- `GET /api/v1/admin/reviews/pending`: Review moderation queue.

