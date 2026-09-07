---
description: Start here. Quick start path, core concepts, and links to key guides.
---

# Platform Merchants API

Use the Merchants API to accept payments through the hosted payments page, issue refunds, initiate open banking transfers, and receive event notifications via webhooks. **KumaaGuard partners** — a separate role with its own credentials — use the API to risk-score payments before processing them; see [KumaaGuard](docs/kumaaguard.md).

### Key guides

<table data-view="cards"><thead><tr><th>Topic</th><th data-card-target data-type="content-ref">Link</th></tr></thead><tbody><tr><td>Getting Started</td><td><a href="docs/getting-started.md">getting-started.md</a></td></tr><tr><td>Authentication</td><td><a href="docs/authentication.md">authentication.md</a></td></tr><tr><td>Crypto Payments</td><td><a href="docs/crypto-payments.md">crypto-payments.md</a></td></tr><tr><td>Fiat Payments</td><td><a href="docs/fiat-payments.md">fiat-payments.md</a></td></tr><tr><td>Card Payments</td><td><a href="docs/card-payments.md">card-payments.md</a></td></tr><tr><td>Refunds and Chargebacks</td><td><a href="docs/refunds.md">refunds.md</a></td></tr><tr><td>Webhooks</td><td><a href="docs/webhooks.md">webhooks.md</a></td></tr><tr><td>Error Handling</td><td><a href="docs/error-handling.md">error-handling.md</a></td></tr><tr><td>Idempotency</td><td><a href="docs/idempotency.md">idempotency.md</a></td></tr><tr><td>Blocklist and Whitelist</td><td><a href="docs/blocklist-and-whitelist.md">blocklist-and-whitelist.md</a></td></tr><tr><td>KumaaGuard</td><td><a href="docs/kumaaguard.md">kumaaguard.md</a></td></tr></tbody></table>

### Conventions

* **Idempotency:** always send a unique `externalId`. See [Idempotency](docs/idempotency.md).
* **Errors:** returned in the RFC 7807 Problem Details format (`application/problem+json`). See [Error Handling](docs/error-handling.md).
* **Security:** keep credentials server-side. Consider IP whitelisting. See [Authentication](docs/authentication.md).
