import Flutter
import UIKit
import Photos

public class SwiftSaverGalleryPlugin: NSObject, FlutterPlugin {
  let errorMessage = "Failed to save, please check whether the permission is enabled"
       
  var result: FlutterResult?;

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "saver_gallery", binaryMessenger: registrar.messenger())
    let instance = SwiftSaverGalleryPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
      self.result = result
      if call.method == "saveImageToGallery" {
        let arguments = call.arguments as? [String: Any] ?? [String: Any]()
        guard let imageData = (arguments["image"] as? FlutterStandardTypedData)?.data,
            let image = UIImage(data: imageData),
            let quality = arguments["quality"] as? Int,
            let _ = arguments["fileName"]
            else { return }
        let newImage = image.jpegData(compressionQuality: CGFloat(quality / 100))!
        saveImage(UIImage(data: newImage) ?? image)
      } else if (call.method == "saveFileToGallery") {
        guard let arguments = call.arguments as? [String: Any],
              let path = arguments["path"] as? String
              else { return }
        if (isImageFile(fileName: path)) {
            saveImageAtFileUrl(path)
        } else {
            if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(path)) {
                saveVideo(path)
            }
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    func saveVideo(_ path: String) {
        var videoIds: [String] = []

        PHPhotoLibrary.shared().performChanges( {
            let req = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: URL.init(fileURLWithPath: path))
            if let videoId = req?.placeholderForCreatedAsset?.localIdentifier {
                videoIds.append(videoId)
            }
        }, completionHandler: { [unowned self] (success, error) in
            DispatchQueue.main.async {
                if (success && videoIds.count > 0) {
                    self.saveResult(isSuccess: true)
                } else {
                    self.saveResult(isSuccess: false, error: self.errorMessage)
                }
            }
        })
    }

    func saveImage(_ image: UIImage) {
 
        var imageIds: [String] = []

        PHPhotoLibrary.shared().performChanges( {
            let req = PHAssetChangeRequest.creationRequestForAsset(from: image)
            if let imageId = req.placeholderForCreatedAsset?.localIdentifier {
                imageIds.append(imageId)
            }
        }, completionHandler: { [unowned self] (success, error) in
            DispatchQueue.main.async {
                if (success && imageIds.count > 0) {
                    self.saveResult(isSuccess: true)
                } else {
                    self.saveResult(isSuccess: false, error: self.errorMessage)
                }
            }
        })
    }

    func saveImageAtFileUrl(_ url: String) {
  
        var imageIds: [String] = []

        PHPhotoLibrary.shared().performChanges( {
            let req = PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: URL(string: url)!)
            if let imageId = req?.placeholderForCreatedAsset?.localIdentifier {
                imageIds.append(imageId)
            }
        }, completionHandler: { [unowned self] (success, error) in
            DispatchQueue.main.async {
                if (success && imageIds.count > 0) {
                    self.saveResult(isSuccess: true)
                } else {
                    self.saveResult(isSuccess: false, error: self.errorMessage)
                }
            }
        })
    }

    /// finish saving，if has error，parameters error will not nill
    @objc func didFinishSavingImage(image: UIImage, error: NSError?, contextInfo: UnsafeMutableRawPointer?) {
        saveResult(isSuccess: error == nil, error: error?.description)
    }

    @objc func didFinishSavingVideo(videoPath: String, error: NSError?, contextInfo: UnsafeMutableRawPointer?) {
        saveResult(isSuccess: error == nil, error: error?.description)
    }

    func saveResult(isSuccess: Bool, error: String? = nil) {
        var saveResult = SaveResultModel()
        saveResult.isSuccess = error == nil
        saveResult.errorMessage = error?.description
        result?(saveResult.toDic())
    }

    func isImageFile(fileName: String) -> Bool {
        return fileName.hasSuffix(".jpg")
            || fileName.hasSuffix(".png")
            || fileName.hasSuffix(".jpeg")
            || fileName.hasSuffix(".JPEG")
            || fileName.hasSuffix(".JPG")
            || fileName.hasSuffix(".PNG")
            || fileName.hasSuffix(".gif")
            || fileName.hasSuffix(".GIF")
            || fileName.hasSuffix(".heic")
            || fileName.hasSuffix(".HEIC")
    }
    
    func isImageGifFile(fileName: String) -> Bool {
        return fileName.hasSuffix(".gif")
        || fileName.hasSuffix(".GIF")
    }
}

public struct SaveResultModel: Encodable {
    var isSuccess: Bool!
    var errorMessage: String?

    func toDic() -> [String:Any]? {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(self) else { return nil }
        if (!JSONSerialization.isValidJSONObject(data)) {
            return try! JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String:Any]
        }
        return nil
    }
}
