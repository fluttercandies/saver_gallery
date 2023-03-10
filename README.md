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
     <!--  if androidExistNotSave = true -->
     <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />   
 ```

## Example
Access permission(use [permission_handler](https://pub.dev/packages/permission_handler))
``` dart
    bool statuses;
    if (Platform.isAndroid) {
      final deviceInfoPlugin = DeviceInfoPlugin();
      final deviceInfo = await deviceInfoPlugin.androidInfo;
      final sdkInt = deviceInfo.version.sdkInt;
      /// [androidExistNotSave]
      /// On Android, if true, the save path already exists, it is not saved. Otherwise, it is saved
      /// 在安卓平台上,如果是true,则保存路径已存在就不在保存,否则保存
      /// is androidExistNotSave = true,write as follows:
      ///  statuses = await Permission.storage.request().isGranted;
      /// is androidExistNotSave = false,write as follows:
      statuses =
          sdkInt < 29 ? await Permission.storage.request().isGranted : true;
    } else {
      statuses = await Permission.photosAddOnly.request().isGranted;
    }
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
        androidRelativePath: "Pictures/appName/xx",
        androidExistNotSave: false,
        );
    debugPrint(result.toString());
    _toastInfo("$result");
  }
```

Saving file(ig: video/others) from the internet
``` dart
_saveVideo() async {
    var appDocDir = await getTemporaryDirectory();
    String savePath = appDocDir.path + "/temp.mp4";
    await Dio().download("http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4", savePath);
    final result = await SaverGallery.saveFile(file: savePath,androidExistNotSave: true, name: '123.mp4',androidRelativePath: "Movies");
    print(result);
 }
```
