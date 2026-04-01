import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import './model.dart';

/// A utility class for saving images and files to the device's media gallery.
class SaverGallery {
  static const MethodChannel _channel =
      MethodChannel('com.fluttercandies/saver_gallery');
  static final Uuid _uuidGenerator = Uuid();
  static Future<Directory> get _cacheDirectory async {
    final tempDir = await getTemporaryDirectory();
    final cacheDir = Directory('${tempDir.path}/saver_gallery');
    if (!(await cacheDir.exists())) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

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
          'relativePath':
              androidRelativePath ?? _getDefaultRelativePathForType(mimeType),
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
          'relativePath':
              androidRelativePath ?? _getDefaultRelativePathForType(mimeType),
          'skipIfExists': skipIfExists,
        },
      );

      return SaveResult.fromMap(result!);
    } catch (e) {
      // Return a failure result in case of an error.
      return SaveResult(false, e.toString());
    }
  }

  /// Saves multiple images to the gallery in batch.
  ///
  /// [images] is a list of [SaveImageData] objects containing image bytes and metadata.
  /// [quality] specifies the quality of the images (for JPG files).
  /// [skipIfExists] if true, skips saving if a file already exists.
  ///
  /// Returns a [SaveResult] indicating success or failure for the batch operation.
  static Future<SaveResult> saveImages(
    List<SaveImageData> images, {
    int quality = 100,
    required bool skipIfExists,
  }) async {
    if (images.isEmpty) {
      return SaveResult(false, 'Image list is empty');
    }

    // Write images to temp files first, then save as files
    final fileDataList = <SaveFileData>[];
    final tempFiles = <File>[];

    try {
      for (var imageData in images) {
        String? mimeType =
            lookupMimeType(imageData.fileName, headerBytes: imageData.bytes);
        String extension = imageData.extension ??
            _extractFileExtension(mimeType, imageData.fileName);

        String fileName = imageData.fileName;
        if (!fileName.contains('.')) {
          fileName += '.$extension';
        }

        // Create temp file
        final tempFile = await _createTempFile(extension, imageData.bytes);
        tempFiles.add(tempFile);

        // Use per-image androidRelativePath from ImageData
        fileDataList.add(SaveFileData(
          filePath: tempFile.path,
          fileName: fileName,
          androidRelativePath: imageData.androidRelativePath,
        ));
      }

      // Save all files in batch (saveFiles will handle individual paths)
      final result = await saveFiles(
        fileDataList,
        skipIfExists: skipIfExists,
      );

      return result;
    } finally {
      // Clean up temp files
      for (var tempFile in tempFiles) {
        try {
          if (tempFile.existsSync()) {
            tempFile.deleteSync();
          }
        } catch (e) {
          // Ignore cleanup errors
        }
      }
    }
  }

  /// Saves multiple files to the gallery in batch.
  ///
  /// [files] is a list of [SaveFileData] objects containing file paths and metadata.
  /// [skipIfExists] if true, skips saving if a file already exists.
  ///
  /// Returns a [SaveResult] indicating success or failure for the batch operation.
  static Future<SaveResult> saveFiles(
    List<SaveFileData> files, {
    required bool skipIfExists,
  }) async {
    if (files.isEmpty) {
      return SaveResult(false, 'File list is empty');
    }

    // Convert FileData list to maps for native method call
    final List<Map<String, dynamic>> _files = files.map((fileData) {
      String? mimeType = lookupMimeType(fileData.filePath);

      // Use FileData.androidRelativePath, or default based on MIME type
      String relativePath = fileData.androidRelativePath ??
          _getDefaultRelativePathForType(mimeType);

      return {
        'filePath': fileData.filePath,
        'fileName': fileData.fileName,
        'relativePath': relativePath,
      };
    }).toList();

    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'saveFilesToGallery',
        <String, dynamic>{
          'files': _files,
          'skipIfExists': skipIfExists,
        },
      );

      return SaveResult.fromMap(result!);
    } catch (e) {
      return SaveResult(false, e.toString());
    }
  }

  /// Determines the default relative path based on the MIME type of the file.
  ///
  /// [mimeType] is the MIME type of the file.
  /// Returns the default relative path as a string based on the type of file.
  static String _getDefaultRelativePathForType(String? mimeType) {
    if (mimeType == null)
      return "Download"; // Default path if MIME type is unknown.

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
    final tempPath =
        '${(await _cacheDirectory).path}/${_uuidGenerator.v4()}.$extension';
    final tempFile = File(tempPath)..createSync(recursive: true);
    await tempFile.writeAsBytes(bytes);
    return tempFile;
  }

  /// Clears all temporary files created by SaverGallery.
  ///
  /// This method deletes the temporary directory used by SaverGallery
  /// to store intermediate files during batch save operations.
  ///
  /// Returns `true` if the cleanup was successful, `false` otherwise.
  static Future<bool> clearCache() async {
    try {
      final saverGalleryTempDir = await _cacheDirectory;

      if (await saverGalleryTempDir.exists()) {
        await saverGalleryTempDir.delete(recursive: true);
        return true;
      }
      return true; // Directory doesn't exist, consider it as successful cleanup
    } catch (e) {
      return false;
    }
  }
}
