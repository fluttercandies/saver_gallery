import Flutter
import UIKit
import Photos

public class SwiftSaverGalleryPlugin: NSObject, FlutterPlugin {
  let errorMessage = "Failed to save, please check whether the permission is enabled"
       
  var result: FlutterResult?;

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "com.fluttercandies/saver_gallery", binaryMessenger: registrar.messenger())
    let instance = SwiftSaverGalleryPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
      self.result = result
      if call.method == "saveImageToGallery" {
        let arguments = call.arguments as? [String: Any] ?? [String: Any]()
        saveImageToGallery(arguments)
      } else if (call.method == "saveFileToGallery") {
        guard let arguments = call.arguments as? [String: Any],
              let path = arguments["filePath"] as? String
              else { return }
        if (isImageFile(fileName: path)) {
            saveImageAtFileUrl(path)
        } else {
            if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(path)) {
                saveVideo(path)
            }
        }
      } else if (call.method == "saveFilesToGallery") {
        guard let arguments = call.arguments as? [String: Any],
              let files = arguments["files"] as? [[String: String]]
              else { 
            result(["isSuccess": false, "errorMessage": "Invalid arguments"])
            return 
        }
        saveFiles(files)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    func saveImageToGallery(_ arguments: [String: Any]) {
        guard let imageData = (arguments["image"] as? FlutterStandardTypedData)?.data,
              let quality = arguments["quality"] as? Int,
              let fileName = arguments["fileName"] as? String
              else { return }

        let extFromArgs = (arguments["extension"] as? String)?.lowercased()
        let extFromFileName = URL(fileURLWithPath: fileName).pathExtension.lowercased()
        let normalizedExt = extFromArgs ?? extFromFileName

        var dataToSave = imageData
        if ["jpg", "jpeg", "jpe"].contains(normalizedExt), let image = UIImage(data: imageData) {
            let clampedQuality = max(0, min(quality, 100))
            let compressionQuality = CGFloat(clampedQuality) / 100.0
            if let jpegData = image.jpegData(compressionQuality: compressionQuality) {
                dataToSave = jpegData
            }
        }

        var imageIds: [String] = []
        PHPhotoLibrary.shared().performChanges({
            let req = PHAssetCreationRequest.forAsset()
            let options = PHAssetResourceCreationOptions()
            options.originalFilename = fileName
            req.addResource(with: .photo, data: dataToSave, options: options)
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

    func saveFiles(_ files: [[String: String]]) {
        var successCount = 0
        var failureCount = 0
        var errors: [String] = []
        let totalFiles = files.count
        var processedCount = 0
        
        for fileData in files {
            guard let filePath = fileData["filePath"],
                  let fileName = fileData["fileName"] else {
                processedCount += 1
                failureCount += 1
                errors.append("Invalid file data")
                continue
            }
            
            if isImageFile(fileName: filePath) {
                // Save image
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: URL(fileURLWithPath: filePath))
                }, completionHandler: { (success, error) in
                    DispatchQueue.main.async {
                        processedCount += 1
                        if success {
                            successCount += 1
                        } else {
                            failureCount += 1
                            errors.append("\(fileName): \(error?.localizedDescription ?? "Unknown error")")
                        }
                        
                        if processedCount == totalFiles {
                            self.saveBatchResult(successCount: successCount, failureCount: failureCount, errors: errors)
                        }
                    }
                })
            } else if UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(filePath) {
                // Save video
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: URL(fileURLWithPath: filePath))
                }, completionHandler: { (success, error) in
                    DispatchQueue.main.async {
                        processedCount += 1
                        if success {
                            successCount += 1
                        } else {
                            failureCount += 1
                            errors.append("\(fileName): \(error?.localizedDescription ?? "Unknown error")")
                        }
                        
                        if processedCount == totalFiles {
                            self.saveBatchResult(successCount: successCount, failureCount: failureCount, errors: errors)
                        }
                    }
                })
            } else {
                processedCount += 1
                failureCount += 1
                errors.append("\(fileName): Unsupported file type")
                
                if processedCount == totalFiles {
                    self.saveBatchResult(successCount: successCount, failureCount: failureCount, errors: errors)
                }
            }
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

    func saveBatchResult(successCount: Int, failureCount: Int, errors: [String]) {
        var saveResult = SaveResultModel()
        if failureCount == 0 {
            saveResult.isSuccess = true
            saveResult.errorMessage = nil
        } else {
            saveResult.isSuccess = successCount > 0
            let errorMessage = "Saved \(successCount) files, failed \(failureCount) files. Errors: \(errors.joined(separator: "; "))"
            saveResult.errorMessage = errorMessage
        }
        result?(saveResult.toDic())
    }

    func isImageFile(fileName: String) -> Bool {
        let lowercasedFileName = fileName.lowercased()
        let imageExtensions = [
            ".jpg", ".jpeg", ".jpe", ".png", ".gif", ".heic", ".heif",
            ".bmp", ".wbmp", ".webp", ".tif", ".tiff", ".ico",
            ".cr2", ".psd", ".dng", ".arw"
        ]
        return imageExtensions.contains { lowercasedFileName.hasSuffix($0) }
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
