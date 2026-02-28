import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class ImageStorageService {
  final _uuid = const Uuid();

  Future<String> saveToCache(String sourcePath) async {
    final appDir = await getApplicationDocumentsDirectory();
    final scanDir = Directory(path.join(appDir.path, 'scans'));
    if (!await scanDir.exists()) {
      await scanDir.create(recursive: true);
    }
    final extension = path.extension(sourcePath).isEmpty
        ? '.jpg'
        : path.extension(sourcePath);
    final filename = 'scan_${_uuid.v4()}$extension';
    final destPath = path.join(scanDir.path, filename);

    final sourceFile = File(sourcePath);
    await sourceFile.copy(destPath);
    return destPath;
  }
}
