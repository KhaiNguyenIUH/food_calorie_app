---
description: Debug a running Flutter app — inspect widgets, check errors, hot reload
---

# Debug App

## Steps

1. **Check running apps**:

```
Use the `list_running_apps` MCP tool to find apps started by launch_app.
```

1. **Connect to Dart Tooling Daemon**:

```
Use the `connect_dart_tooling_daemon` MCP tool with the DTD URI from the running app.
```

1. **Check for runtime errors**:

```
Use the `get_runtime_errors` MCP tool.
```

1. **Inspect the widget tree**:

```
Use the `get_widget_tree` MCP tool with summaryOnly: true for user-created widgets only.
```

1. **Hot reload after code changes**:

```
Use the `hot_reload` MCP tool (preserves state).
Use the `hot_restart` MCP tool (resets state, applies const changes).
```

1. **Take a screenshot** (requires Flutter Driver):

```
Use the `flutter_driver` MCP tool with command: "screenshot".
Requires launching with target: lib/driver_main.dart
```

1. **Check app logs**:

```
Use the `get_app_logs` MCP tool with the PID from list_running_apps.
```

## Common Issues

- "Camera unavailable" on simulator is expected (no camera hardware)
- If hot reload fails, try hot restart
- If DTD connection lost, get a new URI from running apps
