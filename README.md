# saver_gallery

[![pub package](https://img.shields.io/pub/v/saver_gallery.svg)](https://pub.dartlang.org/packages/saver_gallery)
[![license](https://img.shields.io/github/license/mashape/apistatus.svg)](https://choosealicense.com/licenses/mit/)

We use the `image_picker` plugin to select images from the Android and iOS image library, but it can't save images to the gallery. This plugin can provide this feature.

## Usage

To use this plugin, add `saver_gallery` as a dependency in your pubspec.yaml file. For example:
```yaml
dependencies:
  saver_gallery: ^1.0.5
```

## iOS
Your project need create with swift.
Add the following keys to your Info.plist file, located in 
<project root>/ios/Runner/Info.plist:
```
<key>NSPhotoLibraryAddUsageDescription</key>
<string>获取相册权限</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>获取相册权限</string>
```

##  Android
You need to ask for storage permission to save an image to the gallery. You can handle the storage permission using [flutter_permission_handler](https://github.com/BaseflowIT/flutter-permission-handler).
AndroidManifest.xml file need to add the following permission:
 ```
     <uses-permission
        android:name="android.permission.WRITE_EXTERNAL_STORAGE"
        tools:ignore="ScopedStorage" />
 ```

## Example
Access permission(use [permission_handler](https://pub.dev/packages/permission_handler))
``` dart
   bool statuses = await (Platform.isAndroid
            ? Permission.storage
            : Permission.photosAddOnly)
        .request()
        .isGranted;
```

Saving an image from the internet(ig: png/jpg/gif/others), quality and name is option
``` dart
  _saveGif() async {
    var response = await Dio().get(
        "https://hyjdoc.oss-cn-beijing.aliyuncs.com/hyj-doc-flutter-demo-run.gif",
        options: Options(responseType: ResponseType.bytes));
    String picturesPath = "test_jpg.gif";
    debugPrint(picturesPath);
    final result = await SaverGallery.saveImage(
        Uint8List.fromList(response.data),
        quality: 60,
        name: picturesPath,
        androidRelativePath: "Pictures/appName/xx");
    debugPrint(result.toString());
    _toastInfo("$result");
  }
```

Saving file(ig: video/gif/others) from the internet
``` dart
_saveVideo() async {
    var appDocDir = await getTemporaryDirectory();
    String savePath = appDocDir.path + "/temp.mp4";
    await Dio().download("http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4", savePath);
    final result = await SaverGallery.saveFile(savePath);
    print(result);
 }
```
