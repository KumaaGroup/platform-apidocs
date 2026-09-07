# Fiat Payments

Fiat Payments are the sibling of [Crypto Payments](crypto-payments.md): the same server-to-server initialize contract and the same Hosted Payments Page (HPP), but the flow ends with the card payment itself — there is **no crypto wallet top-up step**.

> **Availability:** Fiat Payments are implemented but currently **disabled for all merchant accounts** while the platform completes the fiat acquirer rollout. Until your account is enabled, calls to `POST /payment/fiat/initialize` are rejected with `422`. Contact the platform team if you want this flow activated for you.

## How It Differs from Crypto Payments

| Crypto Payments                                                   | Fiat Payments                                          |
|-------------------------------------------------------------------|--------------------------------------------------------|
| Two-step: card payment, then wallet transfer to your merchant wallet | Single step: card payment only                         |
| Customer confirms the wallet top-up on the HPP                    | Customer is redirected to your `successUrl` / `failureUrl` right after the payment outcome |
| `PAYMENT` webhook **plus** `WALLET_TRANSFER` webhook              | `PAYMENT` webhook only                                 |
| Settlement based on `walletTransferAmount`                        | No wallet-transfer fields on the payment record        |

Everything else works as described on the [Crypto Payments](crypto-payments.md) page: the request and response shapes, the 15-minute `actionUrl` token, the [payment lifecycle](crypto-payments.md#payment-lifecycle) (`INITIALIZED → PENDING → COMPLETED / DECLINED`), reading the payment back via [`GET /payment/{id}`](crypto-payments.md#payment-records-and-attempts), and [card whitelisting](crypto-payments.md#card-whitelisting).

## Initialize a Fiat Payment

```bash
curl -X POST https://sandbox-merchants-api.nonprod.paygate.systems/payment/fiat/initialize \
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

The request and response fields are identical to [`POST /payment/crypto/initialize`](crypto-payments.md#step-1-initialize-a-crypto-payment). Redirect the customer to the returned `actionUrl`; after the payment completes (including 3D Secure if required), the customer lands on your `successUrl` or `failureUrl` and your server receives the `PAYMENT` [webhook](webhooks.md).

### Status Codes

| Code | Meaning                                                     |
|------|-------------------------------------------------------------|
| 200  | Payment initialized successfully                            |
| 400  | Invalid request (e.g. unsupported currency, malformed field) |
| 409  | Duplicate `externalId` (see [Idempotency](idempotency.md))  |
| 422  | Payment cannot be accepted (e.g. merchant account not active, or fiat payments not enabled for your account) |
