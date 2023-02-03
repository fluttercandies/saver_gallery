import 'dart:async';
import 'dart:typed_data';
import 'package:mime/mime.dart';
import 'package:path/path.dart';

import 'package:flutter/services.dart';

class SaverGallery {
  static const MethodChannel _channel = MethodChannel('saver_gallery');

  /// save image to Gallery
  /// imageBytes can't null
  /// return Map type
  /// for example:{"isSuccess":true, "errorMessage":String?}
  static Future<Map<String, dynamic>> saveImage(
    Uint8List imageBytes, {
    int quality = 100,
    String? fileExtension,
    required String name,
    bool isReturnImagePathOfIOS = false,
    String androidRelativePath = "Pictures",
  }) async {
    String? mimeType = lookupMimeType(name, headerBytes: imageBytes);
    if (mimeType != null) {
      fileExtension = extensionFromMime(mimeType);
    } else {
      if (fileExtension == null) {
        fileExtension = extension(name).replaceFirst(".", '');
      }
    }
    if (!name.contains('.')) {
      name += '.${fileExtension}';
    }
    return (await _channel.invokeMapMethod<String, dynamic>(
        'saveImageToGallery', <String, dynamic>{
      'imageBytes': imageBytes,
      'quality': quality,
      'name': name,
      'extension': fileExtension,
      'relativePath': androidRelativePath,
      'isReturnImagePathOfIOS': isReturnImagePathOfIOS
    }))!;
  }

  /// Save the PNG，JPG，JPEG image or video located at [file] to the local device media gallery.
  static Future saveFile(String file, {bool isReturnPathOfIOS = false}) async {
    final result = await _channel.invokeMethod(
      'saveFileToGallery',
      <String, dynamic>{
        'path': file,
        'isReturnPathOfIOS': isReturnPathOfIOS,
      },
    );
    return result;
  }
}
