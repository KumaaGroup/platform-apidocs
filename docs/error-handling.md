# Error Handling

Every error response uses the [RFC 7807](https://datatracker.ietf.org/doc/html/rfc7807) Problem Details format, content type `application/problem+json` — whether the request failed schema validation or was rejected while being processed (a duplicate `externalId`, a missing resource, an authentication failure, a declined operation).

```json
{
  "status": 409,
  "title": "Conflict",
  "detail": "duplicate payment request"
}
```

| Field      | Type    | Description                                                              |
|------------|---------|--------------------------------------------------------------------------|
| `status`   | integer | HTTP status code                                                         |
| `title`    | string  | Short, human-readable summary of the problem type (the HTTP status text) |
| `detail`   | string  | Human-readable explanation specific to this occurrence                   |
| `type`     | string  | URI reference for the error type (optional, defaults to `about:blank`)   |
| `instance` | string  | URI reference identifying this specific occurrence (optional)            |
| `errors`   | array   | Field-level details, when applicable (optional)                          |

Requests that fail schema validation (missing required fields, pattern or type mismatches, malformed JSON) include the `errors` array, with each entry pinpointing an invalid field:

```json
{
  "status": 422,
  "title": "Unprocessable Entity",
  "detail": "validation failed",
  "errors": [
    {
      "location": "body.card.cvc",
      "message": "expected string to match pattern ^[0-9]{3,4}$",
      "value": "12"
    }
  ]
}
```

| Field      | Type   | Description                                        |
|------------|--------|----------------------------------------------------|
| `location` | string | Path of the invalid field, in dot notation         |
| `message`  | string | What is wrong with the field                       |
| `value`    | any    | The submitted value (omitted when not applicable)  |

For server errors (`5xx`), the `detail` is a generic status description — implementation details are never exposed.

## HTTP Status Codes

### Success Codes

| Code | Meaning     | Used By                                       |
|------|-------------|-----------------------------------------------|
| 200  | OK          | Successful GET, POST, PATCH requests (including refund submission) |
| 201  | Created     | Webhook created                               |
| 204  | No Content  | Webhook deleted successfully                  |

### Client Error Codes

| Code | Meaning              | Common Causes                                              |
|------|----------------------|------------------------------------------------------------|
| 400  | Bad Request          | Malformed JSON, invalid field values, unsupported currency, batch size exceeded |
| 401  | Unauthorized         | Missing, expired, or invalid access token                  |
| 403  | Forbidden            | IP not whitelisted (if [IP whitelisting](authentication.md#ip-whitelisting) is enabled) |
| 404  | Not Found            | Payment, webhook, or resource does not exist               |
| 409  | Conflict             | Duplicate `externalId` (see [Idempotency](idempotency.md)) |
| 422  | Unprocessable Entity | Request validation failed, payment declined, partial refund not supported, `useRefunds: true` |

### Server Error Codes

| Code | Meaning              | Action                                      |
|------|----------------------|---------------------------------------------|
| 500  | Internal Server Error| Retry with exponential backoff              |
| 502  | Bad Gateway          | Retry with exponential backoff              |
| 503  | Service Unavailable  | Retry with exponential backoff              |

## Retry Strategy

For `5xx` errors and network timeouts, retry with exponential backoff:

```
Attempt 1: wait 1 second
Attempt 2: wait 2 seconds
Attempt 3: wait 4 seconds
Attempt 4: wait 8 seconds
(stop after 4 retries)
```

For `4xx` errors, do **not** retry — fix the request first. The exception is `401 Unauthorized`, where you should refresh your access token and retry once (see [Authentication](authentication.md)).

## Common Error Scenarios

### Duplicate external ID (409)

```json
{
  "status": 409,
  "title": "Conflict",
  "detail": "duplicate payment request"
}
```

### Payment cannot be accepted (422)

```json
{
  "status": 422,
  "title": "Unprocessable Entity",
  "detail": "msb is not activated"
}
```

### Expired or invalid token (401)

```json
{
  "status": 401,
  "title": "Unauthorized",
  "detail": "missing or invalid authentication headers"
}
```

### Invalid test card (400)

Sandbox payments must use the [published test cards](card-payments.md#testing):

```json
{
  "status": 400,
  "title": "Bad Request",
  "detail": "card is not valid for test payments"
}
```

> **Note — decline reasons are not HTTP errors:** a payment that is accepted but later declined ends in status `DECLINED` with the reason in the `responseCode` field (`DO_NOT_HONOUR`, `INSUFFICIENT_FUNDS`, `THREE_DS_FAILED`, `CARD_NOT_WHITELISTED`, …), delivered via webhook and visible on the payment record. See the per-flow pages for the decline codes relevant to each lifecycle.
