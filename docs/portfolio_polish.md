# Portfolio Polish & Advanced Production Features

This document highlights the advanced production features, security safeguards, and platform integrity integrations implemented to complete the **Multi-Vendor E-Commerce Marketplace** to a launch-ready standard.

---

## 1. Security Response Headers

All HTTP responses served by the backend include standard security headers to prevent common browser-side exploits:
* **X-Content-Type-Options**: Set to `nosniff` to prevent browsers from MIME-sniffing away from the declared Content-Type.
* **X-Frame-Options**: Set to `DENY` to prevent clickjacking attacks by blocking the API/documentation from being rendered within frames/iframes.
* **Referrer-Policy**: Set to `strict-origin-when-cross-origin` to ensure referrer details are sanitized when accessing third-party domains.
* **Content-Security-Policy**: Set strictly to `default-src 'none'; frame-ancestors 'none';` since the backend is a pure REST API and does not need to load remote assets or run inline scripts.
* **Strict-Transport-Security (HSTS)**: Active when running behind HTTPS/production configurations, forcing secure browser connections with `max-age=31536000; includeSubDomains`.

---

## 2. Distributed Sliding Window Rate Limiting (Redis-Backed)

To protect the platform from denial-of-service (DoS) attempts and credential stuffing:
* **Atomic Redis Lua Script**: Sliding-window rate limiting is implemented via an atomic Redis Lua script using sorted sets (`zsets`), ensuring race-free request counting under high concurrency.
* **Fail-Closed Security**: In production configurations, Redis failures fail-closed (returning HTTP 500) for security-sensitive routes (authentication, payments, reviews) to prevent brute-force attacks during outages.
* **Development Fallback**: In development mode, the rate limiter automatically falls back to a clean in-memory sliding window limiter if Redis is offline, maintaining a low-barrier setup environment.

---

## 3. Stripe Payments & Secure Webhooks

Real-world payment processing is supported via the Stripe API:
* **Multi-Threaded Execution**: Intent creation and cancellations call the Stripe API asynchronously using a Python thread pool executor, preventing blocking of the main event loop.
* **Signature Verification**: The webhook endpoint (`/api/v1/payments/stripe/webhook`) verifies signature headers using Stripe's cryptographically secure HMAC SHA256 v1 header signature checks.
* **Idempotent Webhooks**: Hook handlers inspect the database state before executing transitions, preventing double capture, redundant order processing, or duplicate customer notifications if Stripe retries delivery.

---

## 4. Platform Role Guards & State Authorization

* **GoRouter Route Guards**: Role-based access rules are implemented reactively in Flutter using a custom `RouterNotifier` that listens to `AuthBloc` changes. Unauthenticated users are redirected to `/auth/login`, and roles (Customer, Seller, Admin) are strictly confined to their authorized views.
* **Approved Seller Check**: Mutation operations on product and order objects are protected at the router-dependency injection level by enforcing a `require_approved_seller` check, instantly blocking suspended or onboarding sellers from making state modifications.
* **Review Uniqueness**: Database-level unique constraints on `reviews(user_id, order_item_id)` prevent verified purchase review stuffing or duplicate rating inflation.

