# Changelog

## 0.1.0 (unreleased)

- First version of the SDK for the Oushodh API `/v1`.
- `Oushodh` client: `meta()`, `listMedicines()`, `medicines()` (a `Stream` that pages to the end), `search()`, `getMedicine()`, `imageUrl()` and `getImage()`.
- Models for every schema in the OpenAPI spec: `Medicine`, `MedicineDetail`, `Monograph`, `Page`, `SearchResult` and `Meta`. Each keeps its JSON, unknown fields included.
- One exception class per family, all extending `OushodhException`.
- Retries on `429 rate_limited` (after `Retry-After`), on `5xx` and on network errors.
- Runs on the Dart VM, in Flutter and on the web. `OUSHODH_API_KEY` is read where the platform has an environment.
