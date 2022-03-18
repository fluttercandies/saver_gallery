import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
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
    required String name,
    bool isReturnImagePathOfIOS = false,
    String relativePath = "Pictures",
  }) async {
    String fileExtension = extension(name).replaceFirst(".", '');
    if (fileExtension == "gif") {
      throw Exception("Gif can't save to Gallery,plase use saveFile");
    } else {
      return (await _channel.invokeMapMethod<String, dynamic>(
          'saveImageToGallery', <String, dynamic>{
        'imageBytes': imageBytes,
        'quality': quality,
        'name': name,
        'extension': fileExtension,
        'relativePath': relativePath,
        'isReturnImagePathOfIOS': isReturnImagePathOfIOS
      }))!;
    }
  }

  /// Save the PNG，JPG，JPEG image or video located at [file] to the local device media gallery.
  static Future saveFile(String file, {bool isReturnPathOfIOS = false}) async {
    final result = await _channel.invokeMethod(
        'saveFileToGallery', <String, dynamic>{
      'path': file,
      'isReturnPathOfIOS': isReturnPathOfIOS
    });
    return result;
  }
}
