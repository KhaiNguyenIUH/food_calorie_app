# AGENTS Instructions (food_calorie_app)

## Agent Requirement
- Agents working on this repo must use senior-level Dart/Flutter skills and best practices.

## Architecture
- Feature-first structure: UI in `lib/presentation/`, domain logic in `lib/domain/`, data access in `lib/data/`, infra in `lib/core/`, routes/bindings in `lib/app/`.
- GetX for controllers, DI, and navigation.

## Backend + AI
- Never call OpenAI directly from Flutter. Use BE proxy `POST /v1/vision/analyze`.
- Mock is default. Prod is enabled with `--dart-define=USE_MOCK_API=false --dart-define=API_BASE_URL=...`.

## Data Invariants
- `MealLog` is source of truth.
- `DailySummary` is a cached aggregate; update on every add/delete and rebuild recent cache on schema changes.

## Persistence
- Hive adapters live in `lib/data/models/`. If fields change, update adapters and schema version handling.
- Images are cached locally and cleaned by `StorageCleanupService`.

## UI Conventions
- Use `AppTextStyles` and `AppColors` (avoid inline styles).
- Shared widgets go in `lib/presentation/shared/widgets/`.
- Avoid fixed widths when possible; prefer `Expanded`.

## Testing
- Update widget tests when UI changes.
- Unit tests for parsing and aggregation logic.
- Integration tests should mock BE responses.
