import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class ImageStorageService {
  final _uuid = const Uuid();

  Future<String> saveToCache(String sourcePath) async {
    final cacheDir = await getTemporaryDirectory();
    final extension = path.extension(sourcePath).isEmpty ? '.jpg' : path.extension(sourcePath);
    final filename = 'scan_${_uuid.v4()}$extension';
    final destPath = path.join(cacheDir.path, filename);

    final sourceFile = File(sourcePath);
    await sourceFile.copy(destPath);
    return destPath;
  }
}
