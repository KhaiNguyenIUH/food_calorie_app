---
description: Add a new feature or screen to the food calorie app
---

# Add Feature

## Steps

// turbo-all

1. **Plan the feature** — Identify which layers need changes:
   - `lib/presentation/<feature>/` — Screen + Controller
   - `lib/data/models/` — New or updated Hive models
   - `lib/data/repositories/` — Data access
   - `lib/domain/services/` — Business logic
   - `lib/core/` — Constants, theme, utils

2. **Create the screen**:
   - Add `<feature>_screen.dart` in `lib/presentation/<feature>/`
   - Add `<feature>_controller.dart` using GetX `GetxController`
   - Use `AppTextStyles` and `AppColors` — no inline styles
   - Reuse shared widgets from `lib/presentation/shared/widgets/`

3. **Create the binding** (if new route):
   - Add binding in `lib/app/bindings/<feature>_binding.dart`
   - Register controller and inject dependencies

4. **Add the route**:
   - Add route constant in `lib/app/routes.dart`
   - Add `GetPage` entry in `lib/main.dart`

5. **Add data layer** (if needed):
   - Create/update models in `lib/data/models/`
   - Create/update repositories in `lib/data/repositories/`
   - Register Hive adapters in `lib/core/services/hive_service.dart`

6. **Wire up in InitialBinding**:
   - Register new services/repositories in `lib/app/bindings/initial_binding.dart`

7. **Run analysis**:

```
Use the `analyze_files` MCP tool on the project root.
```

1. **Test**:

```
Use the `run_tests` MCP tool.
```

## Checklist

- [ ] Screen + Controller created
- [ ] Route added in `routes.dart` and `main.dart`
- [ ] Binding registered
- [ ] Uses `AppTextStyles`/`AppColors`
- [ ] Shared widgets reused where possible
- [ ] No direct OpenAI calls (use BE proxy)
- [ ] Tests added/updated
