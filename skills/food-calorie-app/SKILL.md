---
name: food-calorie-app
description: Architecture, folder structure, backend contract, data model invariants, and testing conventions for the Food Calorie App Flutter project. Use when modifying features, scanning flow, persistence, networking, or tests in this repo.
---

# Food Calorie App

## Overview
Use this skill to keep changes aligned with the app’s feature-first structure, GetX architecture, BE proxy contract, and data invariants. For detailed reference, read `references/architecture.md` when editing flows, models, repositories, or tests.

## Quick Rules
- Keep UI in `presentation/`, domain logic in `domain/`, data access in `data/`, and infra in `core/`.
- All AI analysis must go through the BE proxy (`/v1/vision/analyze`). No direct OpenAI calls in Flutter.
- `MealLog` is the source of truth; `DailySummary` is a cached aggregate updated on every write/delete.
- Use mock API by default; prod is enabled with `--dart-define=USE_MOCK_API=false`.
- Update tests when UI or data contracts change.

## When Editing
- **Scanner flow**: verify consent gate, image compression, data URL creation, and error handling.
- **Persistence**: update Hive adapters and rebuild cache logic if fields change.
- **UI changes**: reuse shared widgets and `AppTextStyles`; avoid inline styling.
- **Navigation**: keep routes in `lib/app/routes.dart` and bindings in `lib/app/bindings`.

## References
- `references/architecture.md` (folder structure, BE contract, data invariants, testing conventions)
