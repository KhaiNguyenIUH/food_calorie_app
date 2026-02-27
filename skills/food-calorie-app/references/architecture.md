# Food Calorie App Architecture Reference

## Folder Structure (Feature-first)
- `lib/app/` routes and bindings
- `lib/core/` constants, theme, network, services, utils
- `lib/data/` Hive models + repositories
- `lib/domain/` services (nutrition, image processing)
- `lib/presentation/` home, scanner, scan_result, shared widgets

## Backend Contract (BE Proxy)
Endpoint: `POST /v1/vision/analyze`
Auth: `Authorization: Bearer <JWT>`
Request JSON:
- `image_base64`: data URL (`data:image/jpeg;base64,...`)
- `detail`: `"low" | "high" | "auto"` (default `low`)
- `client_timestamp`: ISO-8601
- `timezone`: IANA string

Response JSON (NutritionResult DTO):
- `name`: string
- `calories`: int
- `protein`: int
- `carbs`: int
- `fats`: int
- `health_score`: int (1–10)
- `confidence`: float (0–1)
- `warnings`: string[] (optional)

## Data Models + Invariants
- `MealLog` is the source of truth.
- `DailySummary` is a cached aggregate. Update on every add/delete and rebuild the last 7–14 days on app start.
- Cache drift should self-heal via `DailySummaryRepository.rebuildRecentCache`.

## Mock vs Prod
- Mock enabled by default: `AppConfig.useMockApi` (`USE_MOCK_API` dart define).
- Prod: `--dart-define=USE_MOCK_API=false --dart-define=API_BASE_URL=https://your-backend`

## Persistence + Migrations
- Hive adapters in `lib/data/models/`.
- Schema version stored in `settings` box. On mismatch, set new version and rebuild DailySummary cache.
- Image files stored in temp cache and cleaned after ~30 days (see `StorageCleanupService`).

## Testing Conventions
- Widget tests for `HomeScreen`, `MacroCard`, `ActivityCard`.
- Unit tests for NutritionResult parsing and aggregation logic.
- Integration tests mock BE responses and validate scan flow + save.

## UI/UX Notes
- Use `AppTextStyles` and `AppColors` instead of inline styles.
- Shared widgets live in `presentation/shared/widgets`.
- Avoid fixed widths when possible; use `Expanded` for cards/rows.
