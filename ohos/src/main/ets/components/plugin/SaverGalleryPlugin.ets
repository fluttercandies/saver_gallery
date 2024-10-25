import {
  FlutterPlugin,
  FlutterPluginBinding
} from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/FlutterPlugin';
import MethodChannel, {
  MethodCallHandler,
  MethodResult
} from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';
import MethodCall from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodCall';
import { AbilityAware, AbilityPluginBinding } from '@ohos/flutter_ohos';
import Log from '@ohos/flutter_ohos/src/main/ets/util/Log'
import { HashMap } from '@kit.ArkTS';
import fs from "@ohos.file.fs"
import image from '@ohos.multimedia.image'
import { photoAccessHelper } from '@kit.MediaLibraryKit'
import FileMimeTypeUtil from './utils/FileMimeTypeUtil';

const TAG = "ImageGallerySaverPlugin"

/** SaverGalleryPlugin **/
export default class SaverGalleryPlugin implements FlutterPlugin, MethodCallHandler {
  private channel: MethodChannel | null = null;
  private applicationContext: Context | null = null;
  private binding: AbilityPluginBinding | null = null;
  private fileMimeType: FileMimeTypeUtil = new FileMimeTypeUtil();
  constructor() {
  }

  onAttachedToAbility(binding: AbilityPluginBinding): void {
    this.binding = binding;
  }

  getUniqueClassName(): string {
    return "SaverGalleryPlugin"
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), "saver_gallery");
    this.channel.setMethodCallHandler(this)
    this.applicationContext = binding.getApplicationContext();
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    if (this.channel != null) {
      this.channel.setMethodCallHandler(null)
    }
  }

  async onMethodCall(call: MethodCall, result: MethodResult) {
    switch (call.method) {
      case "saveImageToGallery":
        let image: Uint8Array = call.args.get("image");
        let quality: number = call.args.get("quality");
        let name: string = call.args.get("fileName");
        let extension: string = call.args.get("extension");
        return result.success(await this.saveImageToGallery(image, quality, name, extension));
      case "saveFileToGallery":
        let filePath: string = call.args.get("filePath");
        let fileName: string = call.args.get("fileName");
        return result.success(await this.saveFileToGallery(filePath, fileName));
      default:
        return result.success(SaveResultModel.toHashMap(false, null, 'Method is false'));
    }
  }

  async save(path: string, fileNameExtension: string, photoType: photoAccessHelper.PhotoType, title?: string) {
    let phAccessHelper = photoAccessHelper.getPhotoAccessHelper(this.binding?.getAbility().context);
    try {
      let srcFileUris: Array<string> = [path];
      let photoCreationConfigs: Array<photoAccessHelper.PhotoCreationConfig> = [
        {
          title,
          fileNameExtension,
          photoType,
          subtype: photoAccessHelper.PhotoSubtype.DEFAULT
        }
      ];

      let desFileUris: Array<string> = await phAccessHelper.showAssetsCreationDialog(srcFileUris, photoCreationConfigs);
      let srcFile: fs.File = await fs.open(srcFileUris[0], fs.OpenMode.READ_WRITE);
      let targetFile: fs.File = await fs.open(desFileUris[0], fs.OpenMode.READ_WRITE);
      fs.copyFileSync(srcFile.fd, targetFile.fd);
      fs.closeSync(srcFile);
      fs.closeSync(targetFile);
      return SaveResultModel.toHashMap(true, desFileUris[0], "success save");
    } catch (err) {
      return SaveResultModel.toHashMap(false, null, `save failed, errCode is ${err.code}, errMsg is ${err.message}`);
    }
  }

  // 保存图片
  async saveImageToGallery(bmp: Uint8Array, quality: number, name: string,
    extension: string): Promise<HashMap<String, ESObject>> {
    if (bmp == null || quality == null) {
      return SaveResultModel.toHashMap(false, null, 'parameters error');
    }

    if (this.applicationContext == null) {
      return SaveResultModel.toHashMap(false, null, 'applicationContext is null');
    }

    const path = await this.saveCacheDir(bmp, quality, extension);

    return await this.save(path, extension, photoAccessHelper.PhotoType.IMAGE, name ?? new Date().getTime().toString())
  }

  // 保存文件
  async saveFileToGallery(path: string, name: string): Promise<HashMap<String, ESObject>> {
    if (path == null) {
      return SaveResultModel.toHashMap(false, null, 'parameters error');
    }

    if (this.applicationContext == null) {
      return SaveResultModel.toHashMap(false, null, 'applicationContext is null');
    }

    if (!fs.accessSync(path)) {
      return SaveResultModel.toHashMap(false, null, `${path} does not exist`);
    }

    let fileNameExtension = path.split('.')[1];
    let fileName = name ?? new Date().getTime().toString();
    let photoType: photoAccessHelper.PhotoType | null = this.getMIMEType(fileName + '.' + fileNameExtension);

    if (!photoType) {
      return SaveResultModel.toHashMap(false, null, 'photoType is null');
    }

    return await this.save(path, fileNameExtension, photoType, fileName)
  }

  // 获取类型
  getMIMEType(fileName: string): photoAccessHelper.PhotoType | null {
    const MIMEType = this.fileMimeType.getFileMimeType(fileName);
    if (MIMEType.isVideo()) {
      return photoAccessHelper.PhotoType.VIDEO;
    } else if (MIMEType.isImage()) {
      return photoAccessHelper.PhotoType.IMAGE;
    } else {
      return null;
    }
  }

  // 将图片暂存到缓存压缩图片
  async saveCacheDir(bmp: Uint8Array, quality: number, extension: string) {
    let filePath: string = this.applicationContext?.cacheDir + '/image_source.jpg';
    let outputFile = fs.openSync(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE)
    if (extension == 'gif' || quality == 100) {
      await fs.write(outputFile.fd, bmp.buffer);
      await fs.close(outputFile.fd)
      return filePath;
    } else {
      await fs.write(outputFile.fd, bmp.buffer);
      let imageBuffer: ArrayBuffer | null = null;
      const imagePacker: image.ImagePacker = image.createImagePacker();
      const imageSource: image.ImageSource = image.createImageSource(outputFile.fd);
      imageBuffer = await imagePacker.packing(imageSource, {
        format: "image/jpeg", quality
      });
      await fs.close(outputFile.fd)

      let outputImage = fs.openSync(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC);
      await fs.write(outputImage.fd, imageBuffer);
      await fs.close(outputImage.fd)
      return filePath;
    }

  }
}

class SaveResultModel {
  static toHashMap(isSuccess: boolean, filePath: string | null, message: string | null): HashMap<String, ESObject> {
    let hashMap: HashMap<String, ESObject> = new HashMap();
    hashMap.set("isSuccess", isSuccess);
    hashMap.set("filePath", filePath);
    hashMap.set("message", message);
    isSuccess ? Log.d(TAG, message) : Log.e(TAG, message);

    return hashMap
  }
}