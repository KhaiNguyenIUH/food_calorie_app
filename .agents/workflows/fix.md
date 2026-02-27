---
description: Fix build errors, resolve dependencies, and troubleshoot common issues
---

# Fix Issues

## Common Issues & Solutions

### SDK Version Mismatch

```
Error: Because food_calorie_app requires SDK version ^X.Y.Z, version solving failed.
```

**Fix**: Update `pubspec.yaml` environment > sdk to match installed version:

```bash
dart --version   # check current SDK
```

Then adjust the `sdk:` constraint in `pubspec.yaml`.

### Missing Imports

```
Error: The method 'X' isn't defined for the type 'Y'.
```

**Fix**: Add the missing import. Common ones:

- `import 'package:flutter/material.dart';` — for widgets
- `import 'package:get/get.dart';` — for GetX

### Dependency Issues

```bash
cd /Users/duydaudzu/Documents/food_calorie_app && flutter pub get
```

If that fails:

```bash
cd /Users/duydaudzu/Documents/food_calorie_app && flutter clean && flutter pub get
```

### iOS Signing Errors

```
Error: No profiles for 'com.example.foodCalorieApp' were found
```

**Fix**: Open Xcode, re-authenticate Apple ID, enable auto-signing:

```bash
open /Users/duydaudzu/Documents/food_calorie_app/ios/Runner.xcworkspace
```

### Hive Adapter Errors

If model fields changed, update the adapter and schema version in `HiveService`.

## Steps

1. **Analyze for errors**:

```
Use the `analyze_files` MCP tool on the project root.
```

1. **Auto-fix**:

```
Use the `dart_fix` MCP tool.
```

1. **Rebuild**:
// turbo

```bash
cd /Users/duydaudzu/Documents/food_calorie_app && flutter clean && flutter pub get
```
