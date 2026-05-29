import 'dart:io';
import 'dart:typed_data';

/// A class representing image data for batch save operations.
class SaveImageData {
  final Uint8List bytes;
  final String fileName;
  final String? extension;
  final String? albumPath;

  SaveImageData({
    required this.bytes,
    required this.fileName,
    this.albumPath,
    this.extension,
  });
}

/// A class representing file data for batch save operations.
class SaveFileData {
  final String filePath;
  final String fileName;
  final String? albumPath;

  SaveFileData({required this.filePath, required this.fileName, this.albumPath});

  /// Creates a [SaveFileData] instance from a [File] object.
  factory SaveFileData.fromFile(File file, {String? albumPath}) {
    return SaveFileData(
      filePath: file.path,
      fileName: file.uri.pathSegments.last,
      albumPath: albumPath,
    );
  }
}

/// A class representing the result of a save operation.
class SaveResult {
  final bool isSuccess;
  final String? errorMessage;
  final String? savedUri;
  final List<String> savedUris;

  SaveResult(this.isSuccess, this.errorMessage, {this.savedUri, List<String>? savedUris})
    : savedUris = savedUris ?? (savedUri == null ? const <String>[] : <String>[savedUri]);

  /// Creates a [SaveResult] from a map.
  factory SaveResult.fromMap(Map<String, dynamic> json) {
    final savedUri = json['savedUri'] as String?;
    final savedUris = (json['savedUris'] as List?)?.whereType<String>().toList();
    return SaveResult(json['isSuccess'], json['errorMessage'], savedUri: savedUri, savedUris: savedUris);
  }

  @override
  String toString() {
    return 'SaveResult{isSuccess: $isSuccess, errorMessage: $errorMessage, savedUri: $savedUri, savedUris: $savedUris}';
  }
}
