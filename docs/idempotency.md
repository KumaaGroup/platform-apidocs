# Idempotency

The Platform Merchants API uses the `externalId` field to guarantee idempotency and prevent duplicate transactions. Every payment, refund, and disbursement requires a unique `externalId` provided by you.

## How It Works

When you submit a request with an `externalId`, the API checks whether a transaction with that identifier already exists for your merchant account:

- **New `externalId`** — the transaction is created normally.
- **Duplicate `externalId`** — the API returns a `409 Conflict` error. The original transaction is not affected.

This means you can safely retry a request after a network failure without risking a double charge. If the original request succeeded, the retry returns a conflict. If it didn't, the retry creates the transaction.

## Format Requirements

| Rule            | Detail                                                    |
|-----------------|-----------------------------------------------------------|
| Pattern         | `^[a-zA-Z0-9_-]+$` (alphanumeric, hyphens, underscores)  |
| Max length      | 255 characters                                            |
| Uniqueness      | Must be unique per merchant account                       |
| Case-sensitive  | `order-001` and `Order-001` are treated as different IDs  |

## Recommended Patterns

Choose an `externalId` format that is meaningful to your system and guaranteed to be unique:

| Pattern                        | Example                                  | Use case                     |
|--------------------------------|------------------------------------------|------------------------------|
| Order ID                       | `order-48291`                            | One payment per order        |
| Order ID + attempt             | `order-48291_attempt-2`                  | Retries after declines       |
| UUID                           | `a1b2c3d4-e5f6-7890-abcd-ef1234567890`  | System-generated identifiers |
| Prefixed ID                    | `pay_20260304_00042`                     | Date-based sequential IDs    |

## Usage Across Endpoints

The `externalId` is required on the following endpoints:

| Endpoint                               | Purpose                                |
|----------------------------------------|----------------------------------------|
| `POST /payment/crypto/initialize`      | Initialize a crypto payment            |
| `POST /payment/fiat/initialize`        | Initialize a fiat payment              |
| `POST /payment/{id}/refund/initialize` | Request a refund                       |
| `POST /push-to-card/initialize`        | Create a push-to-card disbursement     |

## Filtering by External ID

You can look up a transaction using its `externalId` as a query parameter:

```bash
curl "https://sandbox-merchants-api.nonprod.paygate.systems/payment?externalId=order-48291" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

(The equivalent filter exists on `GET /push-to-card/payment` for disbursements.)

This is useful for reconciliation and verifying whether a transaction was already created before retrying.

## Safe Retry Pattern

```
1. Generate a unique externalId for the transaction
2. Send the API request
3. If you receive a network error or timeout:
   a. Query GET /payment?externalId=YOUR_ID to check if it was created
   b. If found, use the existing transaction
   c. If not found, retry the original request with the same externalId
4. If you receive a 409 Conflict, the transaction already exists — no action needed
```
