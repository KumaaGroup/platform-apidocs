# Contributing

This repository is the Markdown source of the GitBook site **apidocs.kumaagroup.com**. GitBook syncs it; `SUMMARY.md` defines the page tree and only pages listed there are published. Merchants read the site, not this repo. This file is not in `SUMMARY.md`, so it stays internal.

Engineering rules for AI-assisted work are central: [KumaaGroup/central-ai](https://github.com/KumaaGroup/central-ai) (see `CLAUDE.md`).

## Where content comes from

- Guide pages: `docs/*.md` here, published under `/readme/<file-slug>`.
- API reference: rendered from the org-level GitBook spec `merchants-api`, uploaded by `platform`'s "Push OpenAPI spec to GitBook" workflow from `openapi/merchants/merchants.yaml`. This repo holds no OpenAPI file. Endpoint pages, tag names and their grouping (the `Partner API` / `Merchants API` sections via `x-parent` tags) are edited in `platform`.
- Reference page URLs: `/merchants-api/<tag-slug>` and `/partner-api/<tag-slug>`.

## Anchor links

GitBook generates heading ids differently from GitHub and a wrong fragment fails silently (the link renders, clicking scrolls nowhere):

- Punctuation, em-dashes included, collapses into a single hyphen: `## Step 1 — Initialize a Crypto Payment` → `#step-1-initialize-a-crypto-payment` (GitHub would give `#step-1--initialize-a-crypto-payment`).
- Digit-leading headings get an `id-` prefix: `## 3D Secure (3DS)` → `#id-3d-secure-3ds`. GitBook repairs same-page digit fragments but passes cross-page fragments through verbatim, so cross-page links are written in the `id-` form.

After adding or renaming headings or links, check fragments against the ids GitBook actually generated (they may lag until the next sync):

```bash
curl -sL https://apidocs.kumaagroup.com/readme/<page> | grep -oE 'href="#[^"]+"' | sort -u
```
