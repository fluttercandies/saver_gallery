---

# Saver Gallery

[![pub package](https://img.shields.io/pub/v/saver_gallery.svg)](https://pub.dartlang.org/packages/saver_gallery)  
[![license](https://img.shields.io/github/license/mashape/apistatus.svg)](https://choosealicense.com/licenses/mit/)

---

## Overview

The `saver_gallery` plugin enables you to save images and other media files (such as videos) directly to the Android and iOS gallery. While the `image_picker` plugin allows you to select images from the gallery, it does not support saving them back to the gallery. `saver_gallery` provides this essential functionality, making it easy to save media files in Flutter applications.

## already supported ohos next
[dev](https://github.com/fluttercandies/saver_gallery/tree/ohos)
```yaml
dependencies:
  saver_gallery: 
    git:
      url: https://github.com/fluttercandies/saver_gallery.git
      ref: ohos
```

---

## Features

- Save images of various formats (`png`, `jpg`, `gif`, etc.) to the gallery.
- Save video and other media files to the gallery.
- Handle conditional saving with the `skipIfExists` parameter.
- Compatible with both Android and iOS platforms.

---

## Installation

To include `saver_gallery` in your project, add it as a dependency in your `pubspec.yaml` file:

```yaml
dependencies:
  saver_gallery: ^3.0.9
```

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
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" tools:ignore="ScopedStorage" />
<!-- Required if skipIfExists is set to true -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
```

### Handling Permissions

To handle permissions properly, use the `permission_handler` package. Depending on the Android SDK version, permissions requirements vary. Here's how you can implement permission handling:

```dart
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

Future<bool> checkAndRequestPermissions({required bool skipIfExists}) async {
  if (!Platform.isAndroid && !Platform.isIOS) {
    return false; // Only Android and iOS platforms are supported
  }

  if (Platform.isAndroid) {
    final deviceInfo = await DeviceInfoPlugin().androidInfo;
    final sdkInt = deviceInfo.version.sdkInt;

    if (skipIfExists) {
      // Read permission is required to check if the file already exists
      return sdkInt >= 33
          ? await Permission.photos.request().isGranted
          : await Permission.storage.request().isGranted;
    } else {
      // No read permission required for Android SDK 29 and above
      return sdkInt >= 29 ? true : await Permission.storage.request().isGranted;
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
    - **SDK 33+**: Requires `Permission.photos` to check if a file exists.
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
    name: imageName,
    androidRelativePath: "Pictures/appName/images",
    skipIfExists: false,
  );

  print(result.toString());
  _showToast("$result");
}
```

**Explanation:**

- `quality`: Set the image quality (0-100) for compressing images. This only applies to `jpg` format.
- `name`: The name of the file being saved.
- `androidRelativePath`: Relative path in the Android gallery, e.g., `"Pictures/appName/images"`.
- `skipIfExists`: If `true`, skips saving the image if it already exists in the specified path.

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
    file: videoPath,
    skipIfExists: true,
    name: 'sample_video.mp4',
    androidRelativePath: "Movies",
  );

  print(result);
}
```

**Explanation:**

- `file`: Path to the file being saved.
- `skipIfExists`: If `true`, skips saving the file if it already exists.
- `name`: Desired name of the file in the gallery.
- `androidRelativePath`: Relative path in the Android gallery, e.g., `"Movies"`.

---

## Additional Information

For more advanced usage and detailed API documentation, refer to the [official documentation](https://pub.dev/packages/saver_gallery).

---

## License

This project is licensed under the MIT License. For more details, see the [LICENSE](https://choosealicense.com/licenses/mit/) file.

---