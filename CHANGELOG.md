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

