import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// A utility class for saving images and files to the device's media gallery.
class SaverGallery {
  static const MethodChannel _channel = MethodChannel('saver_gallery');
  static final Uuid _uuidGenerator = Uuid();

  /// Saves the given image bytes to the gallery.
  ///
  /// [imageBytes] cannot be null.
  /// [quality] specifies the quality of the image (for JPG files).
  /// [fileExtension] is optional; if not provided, it will be inferred from the file name.
  /// [name] is the name of the file to save.
  /// [androidRelativePath] is the folder path for Android devices.
  /// [skipIfExists] if true, skips saving if the file already exists.
  ///
  /// Returns a [SaveResult] indicating success or failure.
  static Future<SaveResult> saveImage(
      Uint8List imageBytes, {
        int quality = 100,
        String? fileExtension,
        required String name,
        String androidRelativePath = "Pictures",
        required bool skipIfExists,
      }) async {
    // Determine the MIME type and file extension.
    String? mimeType = lookupMimeType(name, headerBytes: imageBytes);
    fileExtension ??= _extractFileExtension(mimeType, name);

    // Handle special case for GIF files on iOS.
    if ((fileExtension.toLowerCase() == 'gif') && Platform.isIOS) {
      File tempFile = await _createTempFile('gif', imageBytes);
      return saveFile(
        file: tempFile.path,
        name: name,
        androidRelativePath: androidRelativePath,
        skipIfExists: skipIfExists,
      );
    }

    // Append the file extension if missing.
    if (!name.contains('.')) {
      name += '.$fileExtension';
    }

    try {
      // Call the native method to save the image to the gallery.
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'saveImageToGallery',
        <String, dynamic>{
          'imageBytes': imageBytes,
          'quality': quality,
          'name': name,
          'extension': fileExtension,
          'relativePath': androidRelativePath,
          'skipIfExists': skipIfExists,
        },
      );

      return SaveResult.fromMap(result!);
    } catch (e) {
      // Return a failure result in case of an error.
      return SaveResult(false, e.toString());
    }
  }

  /// Saves the specified file to the local device media gallery.
  ///
  /// [file] is the path of the file to be saved.
  /// [name] is the name of the file to save in the gallery.
  /// [androidRelativePath] is the folder path for Android devices.
  /// [skipIfExists] if true, skips saving if the file already exists.
  ///
  /// Returns a [SaveResult] indicating success or failure.
  static Future<SaveResult> saveFile({
    required String file,
    required String name,
    String androidRelativePath = "Download",
    required bool skipIfExists,
  }) async {
    try {
      // Call the native method to save the file to the gallery.
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'saveFileToGallery',
        <String, dynamic>{
          'path': file,
          'name': name,
          'relativePath': androidRelativePath,
          'skipIfExists': skipIfExists,
        },
      );

      return SaveResult.fromMap(result!);
    } catch (e) {
      // Return a failure result in case of an error.
      return SaveResult(false, e.toString());
    }
  }

  /// Extracts the file extension from the MIME type or falls back to the file name.
  ///
  /// If the MIME type is null, it attempts to extract the extension from the file name.
  static String _extractFileExtension(String? mimeType, String fileName) {
    return mimeType != null ? extensionFromMime(mimeType) ?? '' : extension(fileName).replaceFirst(".", '');
  }

  /// Creates a temporary file with the specified extension and writes the given bytes to it.
  ///
  /// [extension] is the file extension to use.
  /// [bytes] is the data to be written to the temporary file.
  static Future<File> _createTempFile(String extension, Uint8List bytes) async {
    final tempPath = '${(await getTemporaryDirectory()).path}/saver_gallery/${_uuidGenerator.v4()}.$extension';
    final tempFile = File(tempPath)..createSync(recursive: true);
    await tempFile.writeAsBytes(bytes);
    return tempFile;
  }
}

/// A class representing the result of a save operation.
class SaveResult {
  final bool isSuccess;
  final String? errorMessage;

  SaveResult(this.isSuccess, this.errorMessage);

  /// Creates a [SaveResult] from a map.
  factory SaveResult.fromMap(Map<String, dynamic> json) {
    return SaveResult(json['isSuccess'], json['errorMessage']);
  }

  @override
  String toString() {
    return 'SaveResult{isSuccess: $isSuccess, errorMessage: $errorMessage}';
  }
}
