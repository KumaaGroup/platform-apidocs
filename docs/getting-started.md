# Getting Started

The platform serves two audiences through its REST API:

- **Merchants** accept payments through a hosted payments page, process refunds, send push-to-card disbursements, and manage webhooks.
- **KumaaGuard partners** send payments for ML-driven fraud risk scoring before submitting them to their own acquirer — see [KumaaGuard](kumaaguard.md).

Each role has its own onboarding, its own API credentials, and its own base URLs. Credentials are scoped to the role's endpoints: a merchant token is not valid on the KumaaGuard endpoints, and a partner token is not valid on the payment endpoints.

## Choose Your Path

|                  | Merchants                                               | KumaaGuard Partners                            |
|------------------|---------------------------------------------------------|------------------------------------------------|
| You want to      | Accept payments, issue refunds, receive webhooks        | Risk-score payments before processing them     |
| Sandbox API      | `https://sandbox-merchants-api.nonprod.paygate.systems` | `https://sandbox-api.nonprod.kumaaguard.com`   |
| Sandbox auth     | `https://sandbox-auth.nonprod.paygate.systems`          | `https://sandbox-auth.nonprod.kumaaguard.com`  |
| Onboarding       | [Self-service registration](#obtaining-your-credentials) | Onboarded by the platform; credentials arrive by email |
| Where to start   | [Quick Start](#quick-start) below                       | [For KumaaGuard Partners](#for-kumaaguard-partners) below, then the [KumaaGuard](kumaaguard.md) guide |

> **Warning — Sandbox Data Policy:** The sandbox environments are strictly for testing with **synthetic (fictitious) data only**. The use of real personally identifiable information (PII) or real cardholder data (CHD) is **forbidden**. Always use the provided [test card numbers](card-payments.md#testing), fabricated names, addresses, and email addresses. Violating this policy may result in account suspension.

## Prerequisites

Before you begin as a **merchant**, make sure you have:

- A merchant account with API credentials (`client_id` and `client_secret`)
- HTTPS capability for receiving webhooks

### Obtaining Your Credentials

API credentials are available only after your merchant account has been successfully onboarded. To start the onboarding process, visit:

**[https://sandbox-backoffice.nonprod.paygate.systems/onboarding/register](https://sandbox-backoffice.nonprod.paygate.systems/onboarding/register)**

Once your account is approved and active, you can access the **Merchant Backoffice Portal** at:

**[https://sandbox-backoffice.nonprod.paygate.systems](https://sandbox-backoffice.nonprod.paygate.systems)**

From the backoffice portal you can:

- Monitor transactions and payment activity
- Invite additional users to the dashboard

> **Note:** MFA is enabled by default for all users and cannot be disabled. API credentials are provided via email during onboarding and cannot be retrieved from the portal.

## Quick Start

The steps below take a merchant from credentials to a completed sandbox payment.

### 1. Obtain an access token

Exchange your credentials for a Bearer token using the OAuth2 client credentials flow.

```bash
curl -X POST https://sandbox-auth.nonprod.paygate.systems/oauth2/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET" \
  -d "grant_type=client_credentials"
```

Response:

```json
{
  "access_token": "eyJhbGciOiJSUzI1NiIs...",
  "expires_in": 3600,
  "token_type": "Bearer"
}
```

See [Authentication](authentication.md) for full details on token management.

### 2. Whitelist the customer's card

Card whitelisting is **mandatory**: register each card and allow approximately 72 hours for the cooldown period to expire before it can be used to pay. See [Card Whitelist](blocklist-and-whitelist.md#card-whitelist) for details.

### 3. Initialize a payment

Use the access token to initialize a payment. You never collect card data yourself — the response contains an `actionUrl` for the hosted payments page where your customer completes the payment.

```bash
curl -X POST https://sandbox-merchants-api.nonprod.paygate.systems/payment/crypto/initialize \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "externalId": "order-001",
    "customerEmail": "jane@example.com",
    "customerFirstName": "Jane",
    "customerLastName": "Doe",
    "currency": "EUR",
    "amount": 29.99,
    "successUrl": "https://your-shop.com/checkout/success",
    "failureUrl": "https://your-shop.com/checkout/failure"
  }'
```

Response:

```json
{
  "id": "pay_abc123",
  "externalId": "order-001",
  "status": "INITIALIZED",
  "actionUrl": "https://sandbox-topup.nonprod.kumaacrypto.com/cryptopublic/payments/page/eyJhbGciOi..."
}
```

Redirect your customer to the `actionUrl` (valid for 15 minutes). The full flow — including the wallet top-up step — is described in [Crypto Payments](crypto-payments.md).

> **Removed:** the direct card endpoints (`POST /payment`, `POST /payment/batch`, `POST /payment/crypto`, `POST /payment/google-pay`, `POST /payment/apple-pay`, `POST /payment/ptc`) and the open banking endpoints have been **removed** and return `404`. All payments go through the initialize flow above; disbursements use [`POST /push-to-card/initialize`](card-payments.md#push-to-card).

### 4. Check the payment

```bash
curl https://sandbox-merchants-api.nonprod.paygate.systems/payment/pay_abc123 \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

The payment record includes its status, the per-method `attempts` the customer made, and the wallet-transfer fields used for settlement — see [Payment Records and Attempts](crypto-payments.md#payment-records-and-attempts).

### 5. Set up webhooks

Receive real-time notifications when the payment and the wallet top-up progress.

```bash
curl -X POST https://sandbox-merchants-api.nonprod.paygate.systems/webhooks \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://your-server.com/webhooks/payments",
    "eventType": "PAYMENT",
    "enabled": true
  }'
```

Create a second webhook with `eventType: WALLET_TRANSFER` to be notified when the customer's wallet top-up is captured — settlement is based on it (see [Crypto Payments](crypto-payments.md#webhooks)).

## For KumaaGuard Partners

KumaaGuard partners are a separate role with their own credentials, auth host, and a dedicated endpoint set (`/risk-score`). Partner accounts are onboarded by the platform — onboarding starts in sandbox, and your API credentials arrive by email once it completes.

The token flow is the same OAuth2 client-credentials exchange as for merchants, on the KumaaGuard auth host:

```bash
curl -X POST https://sandbox-auth.nonprod.kumaaguard.com/oauth2/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET" \
  -d "grant_type=client_credentials"
```

Use the token against the KumaaGuard API host to request a risk score for a payment, then report its outcome as it develops. The full workflow, endpoint reference, and best practices are on the [KumaaGuard](kumaaguard.md) page.

The [Authentication](authentication.md) guidance on token lifecycle, refresh strategy, and credential handling applies to partners unchanged; only the hosts differ.

## Key Concepts

### External ID and Idempotency

Every payment, transaction, and risk score requires a caller-provided `externalId`. This identifier:

- Must be unique across your account
- Allows only alphanumeric characters, hyphens, and underscores (`^[a-zA-Z0-9_-]+$`)
- Is limited to 255 characters
- Prevents duplicate transactions — submitting the same `externalId` twice returns a conflict error

See [Idempotency](idempotency.md) for more details.

### Payment Lifecycle

A payment record moves through the following states:

```
INITIALIZED → PENDING → COMPLETED
           ↘         ↘ DECLINED
```

Each payment-method attempt within the payment (for example the card payment) has its own sub-lifecycle — see [Card Attempt Lifecycle](card-payments.md#card-attempt-lifecycle). Refunds, chargebacks, and push-to-card disbursements each have their own state machines, described on their pages.

### Error Format

Errors are returned in the [RFC 7807](https://datatracker.ietf.org/doc/html/rfc7807) Problem Details format (`application/problem+json`); request-validation failures additionally pinpoint the offending fields in an `errors` array. See [Error Handling](error-handling.md) for the exact shapes.

```json
{
  "status": 409,
  "title": "Conflict",
  "detail": "duplicate payment request"
}
```

## Next Steps

- [Authentication](authentication.md) — Token lifecycle, refresh strategy, and IP whitelisting
- [Idempotency](idempotency.md) — How `externalId` prevents duplicate transactions
- [Crypto Payments](crypto-payments.md) — The hosted-page payment flow with merchant wallet top-ups
- [Card Payments](card-payments.md) — Card attempt lifecycle, 3DS, push-to-card, and test cards
- [Refunds and Chargebacks](refunds.md) — Full and partial refund processing, chargeback notifications
- [Webhooks](webhooks.md) — Event notifications setup
- [Error Handling](error-handling.md) — Error codes and troubleshooting
- [Blocklist and Whitelist](blocklist-and-whitelist.md) — Managing blocked customers and allowed cards
- [KumaaGuard](kumaaguard.md) — Payment risk scoring for partners
