import {
  FlutterPlugin,
  FlutterPluginBinding,
  AbilityPluginBinding,
  MethodChannel,
  MethodCall,
  MethodCallHandler,
  MethodResult,
  Log
} from '@ohos/flutter_ohos';
import { HashMap } from '@kit.ArkTS';
import { photoAccessHelper } from '@kit.MediaLibraryKit'
import FileMimeTypeUtil from './utils/FileMimeTypeUtil';
import { fileIo as fs, fileUri } from '@kit.CoreFileKit';
import { image } from '@kit.ImageKit';

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
    this.channel = new MethodChannel(binding.getBinaryMessenger(), "com.fluttercandies/saver_gallery");
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
        let _image: Uint8Array = call.args.get("image");
        let quality: number = call.args.get("quality");
        let name: string = call.args.get("fileName");
        let extension: string = call.args.get("extension");
        return result.success(await this.saveImageToGallery(_image, quality, name, extension));
      case "saveFileToGallery":
        let filePath: string = call.args.get("filePath");
        let fileName: string = call.args.get("fileName");
        return result.success(await this.saveFileToGallery(filePath, fileName));
      case "saveFilesToGallery":
        let files: Array<HashMap<string, ESObject>> = call.args.get("files");
        return result.success(await this.saveFilesToGallery(files));
      default:
        return result.success(SaveResultModel.toHashMap(false, 'Method is false'));
    }
  }

  async save(path: string, fileNameExtension: string, photoType: photoAccessHelper.PhotoType, title: string) {
    let phAccessHelper = photoAccessHelper.getPhotoAccessHelper(this.binding?.getAbility().context);
    try {
      let srcFileUris: Array<string> = [fileUri.getUriFromPath(path)];
      let photoCreationConfigs: Array<photoAccessHelper.PhotoCreationConfig> = [
        {
          title: this.fileMimeType.getFileName(title),
          fileNameExtension,
          photoType,
          subtype: photoAccessHelper.PhotoSubtype.DEFAULT
        }
      ];
      // 基于弹窗授权的方式获取媒体库的目标uri
      let desFileUris: Array<string> = await phAccessHelper.showAssetsCreationDialog(srcFileUris, photoCreationConfigs);
      // 将来源于应用沙箱的照片内容写入媒体库的目标uri
      let desFile: fs.File = await fs.open(desFileUris[0], fs.OpenMode.WRITE_ONLY);
      let srcFile: fs.File = await fs.open(srcFileUris[0], fs.OpenMode.READ_ONLY);
      await fs.copyFile(srcFile.fd, desFile.fd);
      fs.closeSync(srcFile);
      fs.closeSync(desFile);
      return SaveResultModel.toHashMap(true, null, desFileUris[0], [desFileUris[0]]);
    } catch (err) {
      return SaveResultModel.toHashMap(false, `save failed, errCode is ${err.code}, errMsg is ${err.message}`);
    }
  }

  // 保存图片
  async saveImageToGallery(bytes: Uint8Array, quality: number, name: string,
    extension: string): Promise<HashMap<String, ESObject>> {
    if (bytes == null || quality == null) {
      return SaveResultModel.toHashMap(false, 'parameters error');
    }

    if (this.applicationContext == null) {
      return SaveResultModel.toHashMap(false, 'applicationContext is null');
    }

    const path = await this.saveCacheDir(bytes, quality, extension);

    return await this.save(path, extension, photoAccessHelper.PhotoType.IMAGE, name ?? new Date().getTime().toString())
  }

  // 保存文件
  async saveFileToGallery(path: string, name: string): Promise<HashMap<String, ESObject>> {
    if (path == null) {
      return SaveResultModel.toHashMap(false, 'parameters error');
    }

    if (this.applicationContext == null) {
      return SaveResultModel.toHashMap(false, 'applicationContext is null');
    }

    if (!fs.accessSync(path)) {
      return SaveResultModel.toHashMap(false, `${path} does not exist`);
    }

    let fileNameExtension = path.split('.')[1];
    let fileName = name ?? new Date().getTime().toString();
    let photoType: photoAccessHelper.PhotoType | null = this.getMIMEType(fileName + '.' + fileNameExtension);

    if (!photoType) {
      return SaveResultModel.toHashMap(false, 'photoType is null');
    }

    return await this.save(path, fileNameExtension, photoType, fileName)
  }

  // 批量保存文件
  async saveFilesToGallery(files: Array<HashMap<string, ESObject>>): Promise<HashMap<String, ESObject>> {
    if (!files || files.length === 0) {
      return SaveResultModel.toHashMap(false, 'files is empty');
    }

    try {
      let phAccessHelper = photoAccessHelper.getPhotoAccessHelper(this.binding?.getAbility().context);

      // 准备批量保存的数据
      let srcFileUris: Array<string> = [];
      let photoCreationConfigs: Array<photoAccessHelper.PhotoCreationConfig> = [];

      // 构建批量保存所需的数组
      for (let i = 0; i < files.length; i++) {
        let fileData: HashMap<string, ESObject> = files[i];
        let filePath: string = fileData.get("filePath") as string;
        let fileName: string = fileData.get("fileName") as string;

        if (filePath == null || fileName == null) {
          return SaveResultModel.toHashMap(false, 'file data is incomplete');
        }

        if (!fs.accessSync(filePath)) {
          return SaveResultModel.toHashMap(false, `${filePath} does not exist`);
        }

        let fileNameExtension = filePath.split('.').pop() || '';
        let photoType: photoAccessHelper.PhotoType | null = this.getMIMEType(fileName + '.' + fileNameExtension);

        if (!photoType) {
          return SaveResultModel.toHashMap(false, `photoType is null for ${fileName}`);
        }

        srcFileUris.push(fileUri.getUriFromPath(filePath));
        photoCreationConfigs.push({
          title: this.fileMimeType.getFileName(fileName),
          fileNameExtension,
          photoType,
          subtype: photoAccessHelper.PhotoSubtype.DEFAULT
        });
      }

      // 批量弹窗授权并获取目标uri数组
      let desFileUris: Array<string> = await phAccessHelper.showAssetsCreationDialog(srcFileUris, photoCreationConfigs);

      // 批量复制文件到媒体库
      for (let i = 0; i < srcFileUris.length; i++) {
        let desFile: fs.File = await fs.open(desFileUris[i], fs.OpenMode.WRITE_ONLY);
        let srcFile: fs.File = await fs.open(srcFileUris[i], fs.OpenMode.READ_ONLY);
        await fs.copyFile(srcFile.fd, desFile.fd);
        fs.closeSync(srcFile);
        fs.closeSync(desFile);
      }

      return SaveResultModel.toHashMap(true, null, null, desFileUris);
    } catch (err) {
      return SaveResultModel.toHashMap(false, `batch save failed, errCode is ${err.code}, errMsg is ${err.message}`);
    }
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
  async saveCacheDir(bytes: Uint8Array, quality: number, extension: string) {
    let filePath: string = this.applicationContext?.cacheDir + '/image_source.jpg';
    let outputFile = fs.openSync(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE)
    if (extension == 'gif' || quality == 100) {
      await fs.write(outputFile.fd, bytes.buffer);
      await fs.close(outputFile.fd)
      return filePath;
    } else {
      await fs.write(outputFile.fd, bytes.buffer);
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
  static toHashMap(
    isSuccess: boolean,
    errorMessage: string | null,
    savedUri: string | null = null,
    savedUris: Array<string> = []
  ): HashMap<String, ESObject> {
    let hashMap: HashMap<String, ESObject> = new HashMap();
    hashMap.set("isSuccess", isSuccess);
    hashMap.set("errorMessage", errorMessage);
    hashMap.set("savedUri", savedUri);
    hashMap.set("savedUris", savedUris.length > 0 ? savedUris : (savedUri ? [savedUri] : []));
    if (errorMessage) {
      isSuccess ? Log.d(TAG, errorMessage) : Log.e(TAG, errorMessage);
    }

    return hashMap
  }
}
