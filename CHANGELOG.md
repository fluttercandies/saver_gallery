## Unreleased

* **Breaking change**: Replace `androidRelativePath` with `albumPath`, enabling cross-platform album hierarchy support on Android and iOS (#23).
* Add iOS PhotoKit folder hierarchy support for nested `albumPath` values.
* Return saved URI(s) after saving (#23).

## 5.0.3

* Fix iOS parallel save requests overwriting pending results (#30).

## 5.0.2
* Require Flutter `>=3.44.0` and Dart `>=3.12.0 <4.0.0`.
* Add Swift Package Manager support for iOS while keeping CocoaPods support (#33, #34).
* Raise Android `compileSdkVersion` to 36.
* Migrate Android Gradle config to Gradle 9.1.0, AGP 9.0.1, and Kotlin Gradle plugin 2.3.20.
* Migrate Android app and plugin Gradle config to AGP 9 Built-in Kotlin.
* Fix Android Java 8 obsolete source/target warnings by setting Android Java/Kotlin targets to 17 (#31).
* Fix `androidRelativePath` being ignored on Android 9 and below (#26).
* Raise iOS platform from 11.0 to 13.0.
* Remove the example app's `fluttertoast` dependency and use Flutter `SnackBar` messages instead.
* Update example dependency overrides needed for Flutter 3.44 and Dart 3.12 compatibility.
* fix: support androidRelativePath on Android 9 and below


## 4.1.2

* Require Flutter `>=3.19.6` and Dart `>=3.3.0 <4.0.0`
* Raise Android `minSdkVersion` from 16 to 19
* Raise iOS podspec platform from 9.0 to 11.0
* Migrate Android Gradle config to Gradle 8.0.2, AGP 8.1.0, and Kotlin Gradle plugin 1.9.22
* Add a Gradle wrapper to the Android plugin project so opening `android/` uses Gradle 8.0.2
* Add direct AndroidX Core and Kotlin coroutines dependencies for the Android plugin
* Fix Android MediaStore URI creation crash by returning a failed save result instead of crashing (#17)
* Fix Android 10+ video/audio/image saves by using volume-specific MediaStore URIs (#18)
* Update example OHOS dependency overrides to GitCode paths and keep `example/ios/Podfile.lock`

## 4.1.1

* Fix iOS `saveImageToGallery()` to preserve the original image format instead of always saving as JPEG
* Fix iOS JPEG quality handling so compression is only applied to JPEG images
* Remove the iOS GIF workaround in Dart now that `saveImageToGallery()` handles GIF correctly

## 4.1.0

* **Feature**: Added batch saving support with `saveImages()` and `saveFiles()` methods across platforms
* **Feature**: Added `clearCache()` method to clean up temporary files
* **Refactor**: Updated channel name to `com.fluttercandies/saver_gallery` for consistency
* **Enhancement**: Reorganized code structure and optimized documentation

## 4.0.1

* fixed the problem that Android 10 and below cannot be saved
## 4.0.0

* ohos support
## 3.0.10

* fix ios save file failed

## 3.0.9

* merged pr https://github.com/fluttercandies/saver_gallery/pull/21

## 3.0.6

* attempt to repair ITMS-91108

## 3.0.5

* ios ITMS-91053

## 3.0.3

* gradle bugbix

## 3.0.2

* android support save audio 
## 3.0.1

* android 13 permission issue fix

## 2.0.1

* add skipIfExists param

## 1.0.8

* fix ios save gif bug(https://github.com/zhangruiyu/saver_gallery/issues/2)

## 1.0.6

* merged pr https://github.com/zhangruiyu/saver_gallery/pull/1
* fix ios save file bug 

## 1.0.5

* fix android<10 failed to save the multi-level directory

## 1.0.4


* remove ios photo read permission
* Determine the data type by Uint8List
