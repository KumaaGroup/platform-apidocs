# Webhooks

Webhooks notify your server in real time when events occur — such as a payment being completed or a refund finishing. Instead of polling the API, you register a URL and the platform sends HTTP POST requests to it whenever a relevant event happens.

> **Event types renamed (2026-08):** the webhook event types have been restructured. `CARD_PAYMENT` was renamed to `PAYMENT` — existing `CARD_PAYMENT` webhooks were migrated automatically and keep delivering. The `OPEN_BANKING` event type was **removed and its webhooks deleted** (open banking itself has since been removed from the API). Refunds, chargebacks, and push-to-card disbursements now have their own event types (`REFUND`, `CHARGEBACK`, `PUSH_TO_CARD`) instead of riding `CARD_PAYMENT` — create a webhook per event type you consume.

## Why Webhooks Are Essential

The Platform Merchants API is **asynchronous** in many scenarios. When you initialize a payment, the initial response confirms the request was accepted, but the final outcome (completed, declined, etc.) is determined later while the customer pays on the hosted page. A [server-to-server card payment](card-payments.md#server-to-server-card-payment) goes further: its create response carries no status at all, and even the 3D Secure redirect URL reaches you only by webhook. The same applies to refunds, disbursements, and other operations.

**Webhook configuration is required** to reliably know when a payment has been captured or declined. Without webhooks, you would need to continuously poll the API for status changes, which is inefficient and may miss time-sensitive updates.

### Automatic Re-delivery

If your webhook endpoint is temporarily unavailable or returns a non-2xx status code, the platform automatically retries delivery. This ensures you do not miss events due to intermittent failures on your side.

## Create a Webhook

```bash
curl -X POST https://sandbox-merchants-api.nonprod.paygate.systems/webhooks \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://your-server.com/webhooks/payments",
    "eventType": "PAYMENT",
    "enabled": true,
    "headers": [
      { "name": "X-Webhook-Secret", "value": "your-secret-value" }
    ]
  }'
```

### Request Fields

| Field       | Type    | Required | Description                                       |
|-------------|---------|----------|---------------------------------------------------|
| `url`       | string  | Yes      | HTTPS endpoint to receive notifications (max 2048 chars) |
| `eventType` | string  | Yes      | Event type: `PAYMENT`, `REFUND`, `CHARGEBACK`, `PUSH_TO_CARD`, or `WALLET_TRANSFER` |
| `enabled`   | boolean | Yes      | Whether the webhook is active                     |
| `headers`   | array   | No       | Custom headers sent with each notification (max 5) |

### Custom Headers

You can attach up to 5 custom headers to each webhook. These are included in every notification request. Use them for authentication or routing.

| Field   | Type   | Description                        |
|---------|--------|------------------------------------|
| `name`  | string | Header name (max 256 characters)   |
| `value` | string | Header value (max 4096 characters) |

### Response (201 Created)

```json
{
  "id": "wh_abc123",
  "url": "https://your-server.com/webhooks/payments",
  "eventType": "PAYMENT",
  "enabled": true,
  "headers": [
    { "name": "X-Webhook-Secret", "value": "your-secret-value" }
  ],
  "createdAt": "2026-03-04T12:00:00Z",
  "modifiedAt": "2026-03-04T12:00:00Z"
}
```

### Constraints

- Only **one webhook per event type** per merchant. If you need to handle several event types (e.g. payments and refunds), create a separate webhook for each.
- The URL **must use HTTPS**. Plain HTTP endpoints are rejected.

## Notification Payload

Every notification is an HTTP POST with a JSON body of the same shape, whatever the event type:

```json
{
  "objectId": "pay_550e8400-e29b-41d4-a716-446655440000",
  "externalId": "order-001",
  "eventType": "PAYMENT",
  "status": "DECLINED",
  "responseCode": "THREE_DS_FAILED",
  "timestamp": "2026-09-28T10:07:00Z"
}
```

| Field          | Type   | Present  | Description                                                                                     |
|----------------|--------|----------|-------------------------------------------------------------------------------------------------|
| `objectId`     | string | Always   | ID of the object the event is about — a payment, refund, chargeback or disbursement ID          |
| `externalId`   | string | Always   | The `externalId` you supplied when creating the object                                          |
| `eventType`    | string | Always   | One of the [event types](#event-types) below                                                    |
| `status`       | string | Always   | Current status of the object — see [Webhook Object Statuses](#webhook-object-statuses)          |
| `responseCode` | string | Declines | Reason code clarifying a `DECLINED` / `REJECTED` status                                         |
| `actionUrl`    | string | 3DS only | URL to redirect the customer to for a 3D Secure challenge. Sent only for [server-to-server card payments](card-payments.md#handling-3d-secure), and only in the notification issued while the card attempt is `AUTH_REQUESTED` |
| `timestamp`    | string | Always   | When the notification was generated (RFC 3339)                                                  |

## Event Types

| Event Type        | Triggered When                                          |
|-------------------|---------------------------------------------------------|
| `PAYMENT`         | A payment created via the [initialize flow](crypto-payments.md) or [`POST /payment/card/create`](card-payments.md#server-to-server-card-payment) reaches a terminal status — `COMPLETED` or `DECLINED` (with a `responseCode` for declines). For server-to-server card payments, additionally when the issuer requires a 3D Secure challenge — the payload then carries an `actionUrl` |
| `REFUND`          | A **refund** reaches a terminal status (`COMPLETED`, `DECLINED`, `REJECTED`) — see [Refunds — Webhook Notifications](refunds.md#webhook-notifications) |
| `CHARGEBACK`      | A **chargeback** recorded against one of your payments is processed — see [Chargebacks](refunds.md#chargebacks) |
| `PUSH_TO_CARD`    | A [push-to-card disbursement](card-payments.md#push-to-card) status changes |
| `WALLET_TRANSFER` | A [Crypto Payment](crypto-payments.md) wallet top-up is captured (`COMPLETED`) or expires unconfirmed (`EXPIRED`) — see [Crypto Payments — Webhooks](crypto-payments.md#webhooks) |

## Webhook Object Statuses

The `status` field in the payload reflects the current state of the underlying object. The exact set of values depends on the event type; see the per-object lifecycle docs for the full state machines:

- `PAYMENT` — [Payment Lifecycle](crypto-payments.md#payment-lifecycle); the webhook fires on the terminal statuses `COMPLETED` and `DECLINED`. Intermediate statuses, including the card attempt's own [sub-lifecycle](card-payments.md#card-attempt-lifecycle) transitions, do not trigger notifications — with one exception: a server-to-server card payment whose attempt reaches `AUTH_REQUESTED` triggers a notification carrying the 3DS `actionUrl` (see [Handling 3D Secure](card-payments.md#handling-3d-secure))
- `REFUND` / `CHARGEBACK` — [Refund Lifecycle](refunds.md#refund-lifecycle) / [Chargebacks](refunds.md#chargebacks)
- `PUSH_TO_CARD` — [Push-to-Card Lifecycle](card-payments.md#push-to-card-lifecycle)

Every webhook status corresponds to a stored object that you can fetch via `GET /payment/{objectId}` (or `GET /push-to-card/payment/{objectId}` for disbursements). Duplicate-`externalId` submissions never produce a webhook — they are rejected synchronously with `409 Conflict` from the create endpoint (see [Idempotency](idempotency.md)).

## List Webhooks

```bash
curl https://sandbox-merchants-api.nonprod.paygate.systems/webhooks \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

Returns all webhooks configured for your merchant account.

## Get a Webhook

```bash
curl https://sandbox-merchants-api.nonprod.paygate.systems/webhooks/wh_abc123 \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

## Update a Webhook

Use PATCH to partially update a webhook. Only include the fields you want to change.

```bash
curl -X PATCH https://sandbox-merchants-api.nonprod.paygate.systems/webhooks/wh_abc123 \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "enabled": false
  }'
```

### Updatable Fields

| Field     | Type    | Description                              |
|-----------|---------|------------------------------------------|
| `url`     | string  | New HTTPS endpoint URL                   |
| `enabled` | boolean | Enable or disable the webhook            |
| `headers` | array   | Replace custom headers (max 5)           |

The `eventType` cannot be changed after creation. To switch event types, delete the webhook and create a new one.

## Delete a Webhook

```bash
curl -X DELETE https://sandbox-merchants-api.nonprod.paygate.systems/webhooks/wh_abc123 \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

Returns `204 No Content` on success.

## Best Practices

- **Verify the source.** Use custom headers (e.g. a shared secret) to verify that incoming requests are from the platform, not a third party.
- **Respond with 2xx quickly.** Your webhook endpoint should return a `200` or `202` status code promptly. Perform any heavy processing asynchronously after acknowledging receipt.
- **Handle duplicates.** Your endpoint may receive the same event more than once. Use the payment or transaction `id` to deduplicate.
- **Use HTTPS with a valid certificate.** Self-signed certificates are not supported.
