import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class SaverGallery {
  static const MethodChannel _channel = MethodChannel('saver_gallery');

  /// save image to Gallery
  /// imageBytes can't null
  /// return Map type
  /// for example:{"isSuccess":true, "errorMessage":String?}
  static Future<SaveResult> saveImage(
    Uint8List imageBytes, {
    int quality = 100,
    String? fileExtension,
    required String name,
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
    if ((fileExtension == "gif" || fileExtension == "GIF") && Platform.isIOS) {
      File tempPath = File(
          '${(await getTemporaryDirectory()).path}/saver_gallery/${DateTime.now().microsecondsSinceEpoch}.gif');
      await tempPath.create(recursive: true);
      await tempPath.writeAsBytes(imageBytes);
      return saveFile(tempPath.path);
    }

    if (!name.contains('.')) {
      name += '.${fileExtension}';
    }
    return SaveResult.fromMap((await _channel.invokeMapMethod<String, dynamic>(
        'saveImageToGallery', <String, dynamic>{
      'imageBytes': imageBytes,
      'quality': quality,
      'name': name,
      'extension': fileExtension,
      'relativePath': androidRelativePath,
    }))!);
  }

  /// Save the PNG，JPG，JPEG image or video located at [file] to the local device media gallery.
  static Future<SaveResult> saveFile(String file) async {
    final result = await _channel.invokeMapMethod<String, dynamic>(
      'saveFileToGallery',
      <String, dynamic>{'path': file},
    );
    return SaveResult.fromMap(result!);
  }
}

class SaveResult {
  bool isSuccess;
  String? errorMessage;

  SaveResult(this.isSuccess, this.errorMessage);

  factory SaveResult.fromMap(Map<String, dynamic> json) {
    return SaveResult(json['isSuccess'], json['errorMessage']);
  }

  @override
  String toString() {
    return 'SaveResult{isSuccess: $isSuccess, errorMessage: $errorMessage}';
  }
}
