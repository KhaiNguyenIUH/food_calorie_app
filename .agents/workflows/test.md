---
description: Run tests and analyze code for errors
---

# Test & Analyze

## Steps

1. **Analyze for errors**:

```
Use the `analyze_files` MCP tool with root: file:///Users/duydaudzu/Documents/food_calorie_app
```

1. **Run all tests**:

```
Use the `run_tests` MCP tool with root: file:///Users/duydaudzu/Documents/food_calorie_app
```

1. **Run specific test file**:

```
Use the `run_tests` MCP tool with paths: ["test/<specific_test>.dart"]
```

1. **Auto-fix lint issues**:

```
Use the `dart_fix` MCP tool on the project root.
```

1. **Format code**:

```
Use the `dart_format` MCP tool on the project root.
```

## Testing Conventions

- Widget tests for screens: `HomeScreen`, `MacroCard`, `ActivityCard`
- Unit tests for parsing: `NutritionResult` and aggregation logic
- Integration tests: mock BE responses, validate scan flow + save
- Test files mirror source: `lib/presentation/home/` → `test/presentation/home/`
