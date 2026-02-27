import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../../core/constants/app_config.dart';

class ImageProcessingService {
  Future<Uint8List> resizeAndCompress(String path) async {
    final bytes = await File(path).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return bytes;
    }

    final resized = img.copyResize(
      decoded,
      width: decoded.width > decoded.height ? AppConfig.maxImageSize : null,
      height: decoded.height >= decoded.width ? AppConfig.maxImageSize : null,
    );

    return Uint8List.fromList(
      img.encodeJpg(resized, quality: AppConfig.jpegQuality),
    );
  }

  String toDataUrl(Uint8List bytes) {
    final base64 = base64Encode(bytes);
    return 'data:image/jpeg;base64,$base64';
  }
}
