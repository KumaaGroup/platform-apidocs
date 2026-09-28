# Table of contents

* [API Guide](README.md)
  * [Getting Started](docs/getting-started.md)
  * [Idempotency](docs/idempotency.md)
  * [Authentication](docs/authentication.md)
  * [Webhooks](docs/webhooks.md)
  * [Error Handling](docs/error-handling.md)
  * [Card Payments](docs/card-payments.md)
    * [Crypto Payments](docs/crypto-payments.md)
    * [Fiat Payments](docs/fiat-payments.md)
    * [Server-to-Server Card Payments](docs/server-to-server-card-payments.md)
  * [Push-to-Card](docs/push-to-card.md)
  * [Refunds and Chargebacks](docs/refunds.md)
  * [Blocklist and Whitelist](docs/blocklist-and-whitelist.md)
  * [KumaaGuard](docs/kumaaguard.md)
* ```yaml
  type: builtin:openapi
  props:
    models: true
    downloadLink: true
  dependencies:
    spec:
      ref:
        kind: openapi
        spec: merchants-api
  ```
