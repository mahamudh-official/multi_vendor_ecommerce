# Security Model & Policy

## 1. Authentication & Token Architecture

- **Password Storage**: Passwords are never stored in plaintext. Passwords are salted and hashed using **Argon2id** (via `passlib.context.CryptContext` with memory cost = 65536, time cost = 3, parallelism = 4).
- **JWT (JSON Web Tokens)**:
  - **Access Tokens**: Short-lived (30 minutes), signed with `HMAC-SHA256` (`HS256`).
  - **Refresh Tokens**: Long-lived (7 days), strictly validated for token type and subject validity.
  - User ID and role claims are encoded in the token payload and verified cryptographically on every authenticated request.

---

## 2. Authorization & RBAC

- Roles: `customer`, `seller`, `admin`.
- **Privilege Separation**:
  - `admin`: Full platform visibility, category lifecycle management, seller status approvals, audit log inspection, review moderation.
  - `seller`: Inventory management, product creation, order item fulfillment tracking, seller analytics dashboard.
  - `customer`: Profile editing, delivery address management, cart operations, checkout, payment initiation, verified review creation.

---

## 3. IDOR & Multi-Tenant Data Isolation

- **Server-Side Identity Authority**:
  - The API **never** accepts `user_id` or `seller_id` from client payloads as an authority.
  - The authenticated user's identity is derived exclusively from the verified JWT Bearer token (`current_user = Depends(get_current_active_user)`).
- **Address Book Isolation**:
  - Query filters strictly enforce `Address.user_id == current_user.id`. Accessing another user's address ID returns `404 Not Found`.
- **Order Details Isolation**:
  - Customers can only view orders where `Order.user_id == current_user.id`.
  - Sellers can only view `OrderItems` matching their own `seller_id`.
  - Platform administrators have global read-only monitoring access.

---

## 4. Financial Calculation Authority

- **Immutable Server-Side Authority**:
  - Total amounts, line totals, discounts, and item prices are computed strictly on the backend using authoritative database product records.
  - Payment intent creation verifies that the payment amount equals the exact server-calculated `Order.total_amount`.

---

## 5. Defense Against Common Vulnerabilities

| Vulnerability | Mitigation Strategy |
| :--- | :--- |
| **SQL Injection** | SQLAlchemy 2.0 parameterized queries with asyncpg binary protocol; zero raw string interpolation. |
| **Cross-Site Scripting (XSS)** | Flutter native text rendering auto-escapes UI strings; backend sanitizes string inputs. |
| **Brute Force & Flooding** | In-memory sliding-window rate limiter on `/auth/login`, `/auth/register`, `/payments`, and `/reviews`. |
| **Mass Assignment** | Pydantic strict schemas filter out privileged fields during profile updates and user registration. |
| **Credential Leaks in Logs** | Correlation ID middleware scrubs headers, passwords, and card information from application logs. |

