import 'package:flutter_driver/driver_extension.dart';
import 'main.dart' as app;
import 'core/services/hive_service.dart';

Future<void> main() async {
  enableFlutterDriverExtension();
  await HiveService.init();
  app.main();
}
