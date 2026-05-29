# Saver Gallery

[![pub package](https://img.shields.io/pub/v/saver_gallery.svg)](https://pub.dartlang.org/packages/saver_gallery) [![GitHub stars](https://img.shields.io/github/stars/fluttercandies/saver_gallery)](https://github.com/fluttercandies/saver_gallery/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/fluttercandies/saver_gallery)](https://github.com/fluttercandies/saver_gallery/network)
[![GitHub license](https://img.shields.io/github/license/fluttercandies/saver_gallery)](https://github.com/fluttercandies/saver_gallery/blob/master/LICENSE)
[![GitHub issues](https://img.shields.io/github/issues/fluttercandies/saver_gallery)](https://github.com/fluttercandies/saver_gallery/issues) <a href="https://qm.qq.com/q/ZyJbSVjfSU">
![FlutterCandies QQ 群](https://img.shields.io/badge/dynamic/yaml?url=https%3A%2F%2Fraw.githubusercontent.com%2Ffluttercandies%2F.github%2Frefs%2Fheads%2Fmain%2Fdata.yml&query=%24.qq_group_number&label=QQ%E7%BE%A4&logo=qq&color=1DACE8)

## Overview

The `saver_gallery` plugin enables you to save images and other media files (such as videos) directly to the Android and iOS gallery. While the `image_picker` plugin allows you to select images from the gallery, it does not support saving them back to the gallery. `saver_gallery` provides this essential functionality, making it easy to save media files in Flutter applications.

> HarmonyOS support is also included starting from version `4.0.0`.

## Features

- Save images of various formats (`png`, `jpg`, `gif`, etc.) to the gallery.
- Save video and other media files to the gallery.
- Save media into named albums on Android and iOS.
- **Batch save multiple images or files at once.**
- Handle conditional saving with the `skipIfExists` parameter.
- Compatible with Android, iOS, and HarmonyOS platforms.

---

## Installation

To include `saver_gallery` in your project, add it as a dependency in your `pubspec.yaml` file:

```yaml
dependencies:
  saver_gallery: ^5.0.0
```

---

## Requirements

- Flutter `>=3.44.0`
- Dart `>=3.12.0 <4.0.0`
- JDK 17 for Android builds
- Android `compileSdkVersion 36`
- Android `minSdkVersion 19`
- iOS `13.0+`

Version `5.0.0` and later require Flutter `3.41.0+`. If your project still uses an older Flutter SDK, use `saver_gallery` `4.1.2`.

The iOS implementation supports Swift Package Manager on Flutter `3.44.0+` while keeping CocoaPods support.

---

## iOS Configuration

If you are targeting iOS, ensure that your project is configured to use Swift. Add the following keys to your `Info.plist` file located at `<project_root>/ios/Runner/Info.plist`:

```xml
<key>NSPhotoLibraryAddUsageDescription</key>
<string>We need access to your photo library to save images.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to your photo library to save images.</string>
```

**Explanation:**  
These keys provide descriptions for permission prompts shown to users when your app requests access to their photo library.

---

## Android Configuration

For Android, you need to handle storage permissions to save files to the gallery. Use the [`permission_handler`](https://pub.dev/packages/permission_handler) package to manage permissions.

### Required Permissions

Add the following permissions to your `AndroidManifest.xml` file:

```xml
<uses-permission
    android:name="android.permission.WRITE_EXTERNAL_STORAGE"
    android:maxSdkVersion="28"
    tools:ignore="ScopedStorage" />

<!-- Required if skipIfExists is set to true on Android 12 and below -->
<uses-permission
    android:name="android.permission.READ_EXTERNAL_STORAGE"
    android:maxSdkVersion="32" />

<!-- Required if skipIfExists is set to true on Android 13+ for the media types you save -->
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
<uses-permission android:name="android.permission.READ_MEDIA_AUDIO" />
```

If your manifest does not already declare the `tools` namespace, add `xmlns:tools="http://schemas.android.com/tools"` to the root `<manifest>` element.

### Handling Permissions

To handle permissions properly, use the `permission_handler` package. Depending on the Android SDK version, permissions requirements vary. Here's how you can implement permission handling:

```dart
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

enum MediaType {
  image,
  video,
  audio,
}

Future<bool> checkAndRequestPermissions({
  required bool skipIfExists,
  MediaType mediaType = MediaType.image,
}) async {
  if (!Platform.isAndroid && !Platform.isIOS) {
    return false; // Only Android and iOS platforms are supported
  }

  if (Platform.isAndroid) {
    final deviceInfo = await DeviceInfoPlugin().androidInfo;
    final sdkInt = deviceInfo.version.sdkInt;

    if (sdkInt < 29) {
      return await Permission.storage.request().isGranted;
    }

    if (!skipIfExists) {
      return true;
    }

    if (sdkInt < 33) {
      return await Permission.storage.request().isGranted;
    }

    switch (mediaType) {
      case MediaType.image:
        return await Permission.photos.request().isGranted;
      case MediaType.video:
        return await Permission.videos.request().isGranted;
      case MediaType.audio:
        return await Permission.audio.request().isGranted;
    }
  } else if (Platform.isIOS) {
    // iOS permission for saving images to the gallery
    return skipIfExists
        ? await Permission.photos.request().isGranted
        : await Permission.photosAddOnly.request().isGranted;
  }

  return false; // Unsupported platforms
}
```

**Explanation:**

- **For Android:**
  - **SDK 29+**: Does not require read permission for writing files.
  - **SDK 33+**: Requires `Permission.photos`, `Permission.videos`, or `Permission.audio` to check if a file exists.
  - **SDK < 29**: Requires `Permission.storage` for read and write operations.

- **For iOS:**
  - Uses `Permission.photos` to check if a file exists.
  - Uses `Permission.photosAddOnly` for saving files without needing full photo library access.

---

## Usage

### Saving an Image

To save an image (e.g., `png`, `jpg`, or `gif`) to the gallery from the internet:

```dart
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:saver_gallery/saver_gallery.dart';

_saveGif() async {
  var response = await Dio().get(
    "https://hyjdoc.oss-cn-beijing.aliyuncs.com/hyj-doc-flutter-demo-run.gif",
    options: Options(responseType: ResponseType.bytes),
  );

  String imageName = "test_image.gif";

  final result = await SaverGallery.saveImage(
    Uint8List.fromList(response.data),
    quality: 60,
    fileName: imageName,
    albumPath: "appName/images",
    skipIfExists: false,
  );

  print(result.toString());
  _showToast("$result");
}
```

**Explanation:**

- `quality`: Set the image quality (0-100) for compressing images. This only applies to `jpg` format.
- `fileName`: The name of the file being saved. This should be a file name, not an album path.
- `albumPath`: Album hierarchy path for Android and iOS, e.g. `"appName/images"` saves images to `"Pictures/appName/images"` on Android and `appName > images` in iOS Photos.
- `skipIfExists`: If `true`, skips saving the image if it already exists in the specified path.

---

### Saving to an Album

Use `albumPath` when you want Android and iOS to save into a named album:

```dart
final result = await SaverGallery.saveImage(
  imageBytes,
  fileName: 'album_image.jpg',
  albumPath: 'MyAlbum',
  skipIfExists: false,
);
```

On iOS, `albumPath` creates or reuses a PhotoKit user album. On Android, it maps to the default media directory for the file type, such as `"Pictures/MyAlbum"` for images or `"Movies/MyAlbum"` for videos.

Use nested `albumPath` when you need folder-like organization:

```dart
final result = await SaverGallery.saveImage(
  imageBytes,
  fileName: 'album_image.jpg',
  albumPath: 'appName/images',
  skipIfExists: false,
);
```

This saves to `Pictures/appName/images` on Android and `appName > images` in iOS Photos. The last segment is the iOS album; parent segments are iOS folders.

Android public-directory prefixes are also accepted for migration compatibility, for example `albumPath: 'Pictures/appName/images'`. `albumPath` must be a relative album hierarchy path, not an absolute filesystem path.

---

### Saved URI Result

`SaveResult` includes the saved media location returned by the platform:

```dart
final result = await SaverGallery.saveImage(
  imageBytes,
  fileName: 'album_image.jpg',
  albumPath: 'appName/images',
  skipIfExists: false,
);

print(result.savedUri);
print(result.savedUris);
```

- `savedUri`: The saved URI for single-file saves.
- `savedUris`: Saved URIs for batch saves. Single-file saves also mirror `savedUri` into this list.
- Android 10+ returns `content://...`.
- Android 9 and below returns `file://...`.
- iOS returns `ph://...`, based on the Photos asset local identifier.
- OHOS returns the media library URI from the asset creation dialog.

`savedUri` is a platform location identifier, not a guaranteed filesystem path.

---

### Saving a File (e.g., Video)

To save other types of files (e.g., videos) to the gallery:

```dart
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:saver_gallery/saver_gallery.dart';

_saveVideo() async {
  var tempDir = await getTemporaryDirectory();
  String videoPath = "${tempDir.path}/sample_video.mp4";

  await Dio().download(
    "http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4",
    videoPath,
  );

  final result = await SaverGallery.saveFile(
    filePath: videoPath,
    skipIfExists: true,
    fileName: 'sample_video.mp4',
    albumPath: "appName/videos",
  );

  print(result);
}
```

**Explanation:**

- `filePath`: Path to the file being saved.
- `skipIfExists`: If `true`, skips saving the file if it already exists.
- `fileName`: Desired name of the file in the gallery.
- `albumPath`: Album hierarchy path for Android and iOS. For videos, `"appName/videos"` saves to `"Movies/appName/videos"` on Android and `appName > videos` in iOS Photos.

---

### Batch Saving

Save multiple images or files at once:

```dart
import 'package:saver_gallery/saver_gallery.dart';

// Batch save images
_saveBatchImages() async {
  final images = [
    SaveImageData(bytes: imageBytes1, fileName: 'image1.jpg', albumPath: 'MyAlbum'),
    SaveImageData(bytes: imageBytes2, fileName: 'image2.png', albumPath: 'MyAlbum'),
  ];
  
  final result = await SaverGallery.saveImages(images, skipIfExists: false);
  print(result);
}

// Batch save files
_saveBatchFiles() async {
  final files = [
    SaveFileData(filePath: '/path/to/file1.mp4', fileName: 'video1.mp4', albumPath: 'MyAlbum'),
    SaveFileData(filePath: '/path/to/file2.mp4', fileName: 'video2.mp4', albumPath: 'MyAlbum'),
  ];
  
  final result = await SaverGallery.saveFiles(files, skipIfExists: false);
  print(result);
}
```

---

## Additional Information

For more advanced usage and detailed API documentation, refer to the [official documentation](https://pub.dev/packages/saver_gallery).

---

## License

This project is licensed under the MIT License. For more details, see the [LICENSE](https://choosealicense.com/licenses/mit/) file.

---
