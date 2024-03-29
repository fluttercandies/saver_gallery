import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class SaverGallery {
  static const MethodChannel _channel = MethodChannel('saver_gallery');

  static var uuid = Uuid();

  /// save image to Gallery
  /// imageBytes can't null
  /// return Map type
  /// for example:{"isSuccess":true, "errorMessage":String?}
  /// [androidExistNotSave]
  /// On Android, if true, the save path already exists, it is not saved. Otherwise, it is saved
  /// 在安卓平台上,如果是true,则保存路径已存在就不在保存,否则保存
  /// [androidRelativePath]
  /// So for example androidRelativePath is Pictures/abc, so the save path is sdcard/Pictures/abc/${name}
  /// 例如androidRelativePath是 Pictures/abc,那么保存路径就是 sdcard/Pictures/abc/${name}
  static Future<SaveResult> saveImage(
    Uint8List imageBytes, {
    int quality = 100,
    String? fileExtension,
    required String name,
    String androidRelativePath = "Pictures",
    required bool androidExistNotSave,
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
          '${(await getTemporaryDirectory()).path}/saver_gallery/${uuid.v4()}.gif');
      await tempPath.create(recursive: true);
      await tempPath.writeAsBytes(imageBytes);
      return saveFile(
          file: tempPath.path,
          name: name,
          androidRelativePath: androidRelativePath,
          androidExistNotSave: androidExistNotSave);
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
      'androidExistNotSave': androidExistNotSave,
    }))!);
  }

  /// Save the PNG，JPG，JPEG image or video located at [file] to the local device media gallery.
  static Future<SaveResult> saveFile({
    required String file,
    required String name,
    String androidRelativePath = "Download",
    required bool androidExistNotSave,
  }) async {
    final result = await _channel.invokeMapMethod<String, dynamic>(
      'saveFileToGallery',
      <String, dynamic>{
        'path': file,
        'name': name,
        'relativePath': androidRelativePath,
        'androidExistNotSave': androidExistNotSave,
      },
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
