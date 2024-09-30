import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
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
  /// [extension] is optional; if not provided, it will be inferred from the file name.
  /// [fileName] is the name of the file to save.
  /// [androidRelativePath] is the folder path for Android devices. Defaults to the appropriate type-based path.
  /// [skipIfExists] if true, skips saving if the file already exists.
  ///
  /// Returns a [SaveResult] indicating success or failure.
  static Future<SaveResult> saveImage(
      Uint8List imageBytes, {
        int quality = 100,
        String? extension,
        required String fileName,
        String? androidRelativePath,
        required bool skipIfExists,
      }) async {
    // Determine the MIME type and file extension.
    String? mimeType = lookupMimeType(fileName, headerBytes: imageBytes);
    extension ??= _extractFileExtension(mimeType, fileName);

    // Handle special case for GIF files on iOS.
    if ((extension.toLowerCase() == 'gif') && Platform.isIOS) {
      File tempFile = await _createTempFile('gif', imageBytes);
      return saveFile(
        filePath: tempFile.path,
        fileName: fileName,
        androidRelativePath: androidRelativePath ?? _getDefaultRelativePathForType(mimeType),
        skipIfExists: skipIfExists,
      );
    }

    // Append the file extension if missing.
    if (!fileName.contains('.')) {
      fileName += '.$extension';
    }

    try {
      // Call the native method to save the image to the gallery.
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'saveImageToGallery',
        <String, dynamic>{
          'image': imageBytes,
          'quality': quality,
          'fileName': fileName,
          'extension': extension,
          'relativePath': androidRelativePath ?? _getDefaultRelativePathForType(mimeType),
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
  /// [filePath] is the path of the file to be saved.
  /// [fileName] is the name of the file to save in the gallery.
  /// [androidRelativePath] is the folder path for Android devices. Defaults to the appropriate type-based path.
  /// [skipIfExists] if true, skips saving if the file already exists.
  ///
  /// Returns a [SaveResult] indicating success or failure.
  static Future<SaveResult> saveFile({
    required String filePath,
    required String fileName,
    String? androidRelativePath,
    required bool skipIfExists,
  }) async {
    // Determine the MIME type based on the file path.
    String? mimeType = lookupMimeType(filePath);

    try {
      // Call the native method to save the file to the gallery.
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'saveFileToGallery',
        <String, dynamic>{
          'filePath': filePath,
          'fileName': fileName,
          'relativePath': androidRelativePath ?? _getDefaultRelativePathForType(mimeType),
          'skipIfExists': skipIfExists,
        },
      );

      return SaveResult.fromMap(result!);
    } catch (e) {
      // Return a failure result in case of an error.
      return SaveResult(false, e.toString());
    }
  }

  /// Determines the default relative path based on the MIME type of the file.
  ///
  /// [mimeType] is the MIME type of the file.
  /// Returns the default relative path as a string based on the type of file.
  static String _getDefaultRelativePathForType(String? mimeType) {
    if (mimeType == null) return "Download"; // Default path if MIME type is unknown.

    if (mimeType.startsWith("image/")) {
      return "Pictures"; // Corresponds to Environment.DIRECTORY_PICTURES
    } else if (mimeType.startsWith("video/")) {
      return "Movies"; // Corresponds to Environment.DIRECTORY_MOVIES
    } else if (mimeType.startsWith("audio/")) {
      return "Music"; // Corresponds to Environment.DIRECTORY_MUSIC
    } else {
      return "Documents"; // Corresponds to Environment.DIRECTORY_DOCUMENTS for other types.
    }
  }

  /// Extracts the file extension from the MIME type or falls back to the file name.
  ///
  /// If the MIME type is null, it attempts to extract the extension from the file name.
  static String _extractFileExtension(String? mimeType, String fileName) {
    if (mimeType != null) {
      String? ext = extensionFromMime(mimeType);
      return ext ?? path.extension(fileName).replaceFirst(".", '');
    }
    return path.extension(fileName).replaceFirst(".", '');
  }

  /// Creates a temporary file with the specified extension and writes the given bytes to it.
  ///
  /// [extension] is the file extension to use.
  /// [bytes] is the data to be written to the temporary file.
  static Future<File> _createTempFile(String extension, Uint8List bytes) async {
    final tempDir = await getTemporaryDirectory();
    final tempPath = '${tempDir.path}/saver_gallery/${_uuidGenerator.v4()}.$extension';
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
