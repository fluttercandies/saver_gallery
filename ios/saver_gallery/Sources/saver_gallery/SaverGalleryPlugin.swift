import Flutter
import UIKit
import Photos

enum AlbumPathContainer {
    case root
    case existing(PHCollectionList)
    case created(PHCollectionListChangeRequest)
}

public class SaverGalleryPlugin: NSObject, FlutterPlugin {
  let errorMessage = "Failed to save, please check whether the permission is enabled"
  private let photoChangesQueue = DispatchQueue(label: "com.fluttercandies.saver_gallery.photo_changes")

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "com.fluttercandies/saver_gallery", binaryMessenger: registrar.messenger())
    let instance = SaverGalleryPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
      if call.method == "saveImageToGallery" {
        let arguments = call.arguments as? [String: Any] ?? [String: Any]()
        saveImageToGallery(arguments, result: result)
      } else if (call.method == "saveFileToGallery") {
        guard let arguments = call.arguments as? [String: Any],
              let path = arguments["filePath"] as? String
              else {
            saveResult(isSuccess: false, error: "Invalid arguments", result: result)
            return
        }
        let albumPathResult = normalizedAlbumPath(arguments["albumPath"] as? String)
        if let error = albumPathResult.error {
            saveResult(isSuccess: false, error: error, result: result)
            return
        }
        if (isImageFile(fileName: path)) {
            saveImageAtFileUrl(path, albumPath: albumPathResult.value, result: result)
        } else {
            if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(path)) {
                saveVideo(path, albumPath: albumPathResult.value, result: result)
            } else {
                saveResult(isSuccess: false, error: "Unsupported file type", result: result)
            }
        }
      } else if (call.method == "saveFilesToGallery") {
        guard let arguments = call.arguments as? [String: Any],
              let files = arguments["files"] as? [[String: String]]
              else { 
            result(["isSuccess": false, "errorMessage": "Invalid arguments"])
            return 
        }
        saveFiles(files, result: result)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    func saveImageToGallery(_ arguments: [String: Any], result: @escaping FlutterResult) {
        guard let imageData = (arguments["image"] as? FlutterStandardTypedData)?.data,
              let quality = arguments["quality"] as? Int,
              let fileName = arguments["fileName"] as? String
              else {
            saveResult(isSuccess: false, error: "Invalid arguments", result: result)
            return
        }
        let albumPathResult = normalizedAlbumPath(arguments["albumPath"] as? String)
        if let error = albumPathResult.error {
            saveResult(isSuccess: false, error: error, result: result)
            return
        }

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
        performPhotoChanges({
            let req = PHAssetCreationRequest.forAsset()
            let options = PHAssetResourceCreationOptions()
            options.originalFilename = fileName
            req.addResource(with: .photo, data: dataToSave, options: options)
            let placeholder = req.placeholderForCreatedAsset
            if let imageId = placeholder?.localIdentifier {
                imageIds.append(imageId)
            }
            self.addAsset(placeholder, toAlbumPath: albumPathResult.value)
        }, completionHandler: { [unowned self] (success, error) in
            DispatchQueue.main.async {
                if (success && imageIds.count > 0) {
                    self.saveResult(isSuccess: true, result: result)
                } else {
                    self.saveResult(isSuccess: false, error: self.errorMessage, result: result)
                }
            }
        })
    }

    func saveFiles(_ files: [[String: String]], result: @escaping FlutterResult) {
        var successCount = 0
        var failureCount = 0
        var errors: [String] = []
        let totalFiles = files.count
        var processedCount = 0

        if totalFiles == 0 {
            saveResult(isSuccess: false, error: "File list is empty", result: result)
            return
        }

        func finishIfNeeded() {
            if processedCount == totalFiles {
                self.saveBatchResult(successCount: successCount, failureCount: failureCount, errors: errors, result: result)
            }
        }
        
        for fileData in files {
            guard let filePath = fileData["filePath"],
                  let fileName = fileData["fileName"] else {
                processedCount += 1
                failureCount += 1
                errors.append("Invalid file data")
                finishIfNeeded()
                continue
            }
            
            let albumPathResult = normalizedAlbumPath(fileData["albumPath"])
            if let error = albumPathResult.error {
                processedCount += 1
                failureCount += 1
                errors.append("\(fileName): \(error)")
                finishIfNeeded()
                continue
            }

            if isImageFile(fileName: filePath) {
                // Save image
                performPhotoChanges({
                    let req = PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: URL(fileURLWithPath: filePath))
                    self.addAsset(req?.placeholderForCreatedAsset, toAlbumPath: albumPathResult.value)
                }, completionHandler: { (success, error) in
                    DispatchQueue.main.async {
                        processedCount += 1
                        if success {
                            successCount += 1
                        } else {
                            failureCount += 1
                            errors.append("\(fileName): \(error?.localizedDescription ?? "Unknown error")")
                        }
                        
                        finishIfNeeded()
                    }
                })
            } else if UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(filePath) {
                // Save video
                performPhotoChanges({
                    let req = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: URL(fileURLWithPath: filePath))
                    self.addAsset(req?.placeholderForCreatedAsset, toAlbumPath: albumPathResult.value)
                }, completionHandler: { (success, error) in
                    DispatchQueue.main.async {
                        processedCount += 1
                        if success {
                            successCount += 1
                        } else {
                            failureCount += 1
                            errors.append("\(fileName): \(error?.localizedDescription ?? "Unknown error")")
                        }
                        
                        finishIfNeeded()
                    }
                })
            } else {
                processedCount += 1
                failureCount += 1
                errors.append("\(fileName): Unsupported file type")
                finishIfNeeded()
            }
        }
    }

    func saveVideo(_ path: String, albumPath: String?, result: @escaping FlutterResult) {
        var videoIds: [String] = []

        performPhotoChanges( {
            let req = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: URL.init(fileURLWithPath: path))
            let placeholder = req?.placeholderForCreatedAsset
            if let videoId = placeholder?.localIdentifier {
                videoIds.append(videoId)
            }
            self.addAsset(placeholder, toAlbumPath: albumPath)
        }, completionHandler: { [unowned self] (success, error) in
            DispatchQueue.main.async {
                if (success && videoIds.count > 0) {
                    self.saveResult(isSuccess: true, result: result)
                } else {
                    self.saveResult(isSuccess: false, error: self.errorMessage, result: result)
                }
            }
        })
    }

    func saveImageAtFileUrl(_ url: String, albumPath: String?, result: @escaping FlutterResult) {
  
        var imageIds: [String] = []

        performPhotoChanges( {
            let req = PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: URL(string: url)!)
            let placeholder = req?.placeholderForCreatedAsset
            if let imageId = placeholder?.localIdentifier {
                imageIds.append(imageId)
            }
            self.addAsset(placeholder, toAlbumPath: albumPath)
        }, completionHandler: { [unowned self] (success, error) in
            DispatchQueue.main.async {
                if (success && imageIds.count > 0) {
                    self.saveResult(isSuccess: true, result: result)
                } else {
                    self.saveResult(isSuccess: false, error: self.errorMessage, result: result)
                }
            }
        })
    }

    func performPhotoChanges(_ changes: @escaping () -> Void, completionHandler: @escaping (Bool, Error?) -> Void) {
        photoChangesQueue.async {
            let semaphore = DispatchSemaphore(value: 0)
            PHPhotoLibrary.shared().performChanges(changes, completionHandler: { success, error in
                completionHandler(success, error)
                semaphore.signal()
            })
            semaphore.wait()
        }
    }

    func normalizedAlbumPath(_ albumPath: String?) -> (value: String?, error: String?) {
        guard let value = albumPath?.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\\", with: "/"), !value.isEmpty else {
            return (nil, nil)
        }

        let normalizedPath = value.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let segments = normalizedPath.split(separator: "/", omittingEmptySubsequences: false).map(String.init)
        let isWindowsAbsolutePath = normalizedPath.range(of: #"^[A-Za-z]:"#, options: .regularExpression) != nil
        let isUnsafe = value.hasPrefix("/")
            || normalizedPath.isEmpty
            || isWindowsAbsolutePath
            || segments.contains { segment in segment.isEmpty || segment == "." || segment == ".." }
        if isUnsafe {
            return (nil, "albumPath must be a relative album hierarchy path")
        }

        return (normalizedPath, nil)
    }

    func addAsset(_ placeholder: PHObjectPlaceholder?, toAlbumPath albumPath: String?) {
        guard let placeholder = placeholder, let albumPath = albumPath else {
            return
        }

        var pathSegments = albumPath.split(separator: "/").map(String.init)
        guard let albumName = pathSegments.popLast() else {
            return
        }

        var container = AlbumPathContainer.root
        for folderName in pathSegments {
            container = resolveFolder(named: folderName, in: container)
        }

        addAsset(placeholder, toAlbumNamed: albumName, in: container)
    }

    func resolveFolder(named folderName: String, in container: AlbumPathContainer) -> AlbumPathContainer {
        switch container {
        case .root:
            if let folder = fetchFolder(named: folderName, in: nil) {
                return .existing(folder)
            }

            let request = PHCollectionListChangeRequest.creationRequestForCollectionList(withTitle: folderName)
            return .created(request)
        case .existing(let parent):
            if let folder = fetchFolder(named: folderName, in: parent) {
                return .existing(folder)
            }

            let request = PHCollectionListChangeRequest.creationRequestForCollectionList(withTitle: folderName)
            addCollection(request.placeholderForCreatedCollectionList, to: container)
            return .created(request)
        case .created(let parentRequest):
            let request = PHCollectionListChangeRequest.creationRequestForCollectionList(withTitle: folderName)
            parentRequest.addChildCollections([request.placeholderForCreatedCollectionList] as NSArray)
            return .created(request)
        }
    }

    func addAsset(_ placeholder: PHObjectPlaceholder, toAlbumNamed albumName: String, in container: AlbumPathContainer) {
        switch container {
        case .root:
            if let album = fetchAlbum(named: albumName, in: nil) {
                PHAssetCollectionChangeRequest(for: album)?.addAssets([placeholder] as NSArray)
                return
            }

            let request = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: albumName)
            request.addAssets([placeholder] as NSArray)
        case .existing(let parent):
            if let album = fetchAlbum(named: albumName, in: parent) {
                PHAssetCollectionChangeRequest(for: album)?.addAssets([placeholder] as NSArray)
                return
            }

            let request = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: albumName)
            request.addAssets([placeholder] as NSArray)
            addCollection(request.placeholderForCreatedAssetCollection, to: container)
        case .created(let parentRequest):
            let request = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: albumName)
            request.addAssets([placeholder] as NSArray)
            parentRequest.addChildCollections([request.placeholderForCreatedAssetCollection] as NSArray)
        }
    }

    func addCollection(_ placeholder: PHObjectPlaceholder, to container: AlbumPathContainer) {
        switch container {
        case .root:
            return
        case .existing(let parent):
            PHCollectionListChangeRequest(for: parent)?.addChildCollections([placeholder] as NSArray)
        case .created(let parentRequest):
            parentRequest.addChildCollections([placeholder] as NSArray)
        }
    }

    func fetchFolder(named folderName: String, in parent: PHCollectionList?) -> PHCollectionList? {
        let collections = fetchCollections(named: folderName, in: parent)
        var matchedFolder: PHCollectionList?
        collections.enumerateObjects { collection, _, stop in
            if let folder = collection as? PHCollectionList, folder.localizedTitle == folderName {
                matchedFolder = folder
                stop.pointee = true
            }
        }
        return matchedFolder
    }

    func fetchAlbum(named albumName: String, in parent: PHCollectionList?) -> PHAssetCollection? {
        let collections = fetchCollections(named: albumName, in: parent)
        var matchedAlbum: PHAssetCollection?
        collections.enumerateObjects { collection, _, stop in
            if let album = collection as? PHAssetCollection, album.localizedTitle == albumName {
                matchedAlbum = album
                stop.pointee = true
            }
        }
        return matchedAlbum
    }

    func fetchCollections(named collectionName: String, in parent: PHCollectionList?) -> PHFetchResult<PHCollection> {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "title = %@", collectionName)
        if let parent = parent {
            return PHCollection.fetchCollections(in: parent, options: options)
        }
        return PHCollectionList.fetchTopLevelUserCollections(with: options)
    }

    func saveResult(isSuccess: Bool, error: String? = nil, result: FlutterResult) {
        var saveResult = SaveResultModel()
        saveResult.isSuccess = isSuccess
        saveResult.errorMessage = error?.description
        result(saveResult.toDic())
    }

    func saveBatchResult(successCount: Int, failureCount: Int, errors: [String], result: FlutterResult) {
        var saveResult = SaveResultModel()
        if failureCount == 0 {
            saveResult.isSuccess = true
            saveResult.errorMessage = nil
        } else {
            saveResult.isSuccess = successCount > 0
            let errorMessage = "Saved \(successCount) files, failed \(failureCount) files. Errors: \(errors.joined(separator: "; "))"
            saveResult.errorMessage = errorMessage
        }
        result(saveResult.toDic())
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
