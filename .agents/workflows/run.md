---
description: Run the Flutter app in debug mode on a simulator or device
---

# Run App

## Steps

1. List available devices:

```
Use the `list_devices` MCP tool to find available devices.
```

1. Launch the app on the chosen device:

```
Use the `launch_app` MCP tool with:
  - root: /Users/duydaudzu/Documents/food_calorie_app
  - device: <device_id from step 1>
```

1. Connect to the Dart Tooling Daemon using the DTD URI returned from launch.

## Mock vs Prod

- **Mock (default)**: Just run normally, mock API is enabled by default.
- **Prod**: Use `--dart-define=USE_MOCK_API=false --dart-define=API_BASE_URL=https://your-backend`

## Notes

- Prefer MCP tools (`launch_app`, `hot_reload`, `hot_restart`) over shell commands.
- For Flutter Driver support, use `lib/driver_main.dart` as the target entrypoint.
