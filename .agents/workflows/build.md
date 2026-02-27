---
description: Build the Flutter app for release or check build status
---

# Build App

## Steps

// turbo-all

1. **Clean previous build**:
// turbo

```bash
cd /Users/duydaudzu/Documents/food_calorie_app && flutter clean
```

1. **Get dependencies**:
// turbo

```bash
cd /Users/duydaudzu/Documents/food_calorie_app && flutter pub get
```

1. **Build for iOS** (requires code signing):

```bash
cd /Users/duydaudzu/Documents/food_calorie_app && flutter build ios --release
```

1. **Build for Android**:

```bash
cd /Users/duydaudzu/Documents/food_calorie_app && flutter build apk --release
```

1. **Build with prod API**:

```bash
flutter build ios --release --dart-define=USE_MOCK_API=false --dart-define=API_BASE_URL=https://your-backend
```

## Pre-build Checklist

- [ ] `flutter analyze` passes with no errors
- [ ] All tests pass
- [ ] SDK constraint in `pubspec.yaml` matches installed SDK
- [ ] iOS signing configured in Xcode (for physical devices)
