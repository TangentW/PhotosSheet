//
//  PhotosManager.swift
//  PhotosSheet
//
//  Created by Tan on 2017/8/14.
//

import UIKit
import Photos

// MARK: - PhotosManager
extension PhotosSheet {
    final class PhotosManager {
        static let shared = PhotosManager()
        private init() { }
    }
}

// For Photos
extension PhotosSheet.PhotosManager {
    // ResultImage
    typealias ImageRequestCompletionHandler = (UIImage) -> ()
    // Progress, Stop
    typealias DownloadProgressHandler = (Double, UnsafeMutablePointer<ObjCBool>) -> ()
    // videoAsset
    typealias VideoRequestCompletionHandler = (AVAsset) -> ()

    @discardableResult
    func fetchPhoto(with asset: PHAsset,
                    type: PhotoFetchType,
                    isSynchronous: Bool = false,
                    progressHandler: DownloadProgressHandler? = nil, // Called not in main thread!
                    completionHandler: @escaping ImageRequestCompletionHandler) -> PHImageRequestID {
        let option = PHImageRequestOptions()
        option.isSynchronous = isSynchronous
        option.progressHandler = { progress, _, stop, _ in
            progressHandler?(progress, stop)
        }
        let targetSize: CGSize
        switch type {
        case .thumbnail(let height):
            let ratio = CGFloat(asset.pixelWidth) / CGFloat(asset.pixelHeight)
            let scale = UIScreen.main.scale
            targetSize = CGSize(width: height * ratio * scale, height: height * scale)
            option.resizeMode = .fast
            option.deliveryMode = .opportunistic
            option.isNetworkAccessAllowed = true
        case .original:
            option.deliveryMode = .highQualityFormat
            option.isNetworkAccessAllowed = true
            targetSize = PHImageManagerMaximumSize
        }

        if asset.representsBurst {
            return PHImageManager.default().requestImageData(for: asset, options: option, resultHandler: { data, _, _, info in
                guard let info = info else { return }
                let fetchSucceed = !(info[PHImageCancelledKey] as? Bool ?? false) && info[PHImageErrorKey] == nil
                guard let data = data, let image = UIImage(data: data), fetchSucceed else { return }
                if targetSize != PHImageManagerMaximumSize {
                    if let retImage = image.scaleTo(size: targetSize) {
                        completionHandler(retImage)
                    }
                } else {
                    completionHandler(image)
                }
            })
        } else {
            return PHImageManager.default().requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: option, resultHandler: { image, info in
                guard let info = info else { return }
                let fetchSucceed = !(info[PHImageCancelledKey] as? Bool ?? false) && info[PHImageErrorKey] == nil
                guard let image = image, fetchSucceed else { return }
                completionHandler(image)
            })
        }
    }
}

// For Video
extension PhotosSheet.PhotosManager {
    @discardableResult
    func fetchVideo(with asset: PHAsset, // Media type must be video, This function do not judge.
                    progressHandler: DownloadProgressHandler?,
                    completionHandler: @escaping VideoRequestCompletionHandler) -> PHImageRequestID? {
        let option = PHVideoRequestOptions()
        option.deliveryMode = .highQualityFormat
        option.isNetworkAccessAllowed = true
        option.progressHandler = { progress, _, stop, _ in
            progressHandler?(progress, stop)
        }
        return PHImageManager.default().requestAVAsset(forVideo: asset, options: option, resultHandler: { avAsset, _, _ in
            if let avAsset = avAsset {
                completionHandler(avAsset)
            }
        })
    }
}

extension PhotosSheet.PhotosManager {
    enum PhotoFetchType {
        case thumbnail(height: CGFloat)
        case original
    }
}

extension PhotosSheet.PhotosManager {
    func obtainRecentAssets(mediaOption: PhotosSheet.MediaOption = .all, limit: Int = 0) -> [PHAsset] {
        let fetchOption = PHFetchOptions()
        if let predicate = NSPredicate(mediaOption: mediaOption) {
            fetchOption.predicate = predicate
        }
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchOption.sortDescriptors = [sortDescriptor]
        if limit > 0 {
            fetchOption.fetchLimit = limit
        }
        let results = PHAsset.fetchAssets(with: fetchOption)
        return results.objects(at: IndexSet(0 ..< results.count))
    }
}

fileprivate extension NSPredicate {
    convenience init?(mediaOption: PhotosSheet.MediaOption) {
        switch mediaOption {
        case .photo:
            self.init(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        case .video:
            self.init(format: "mediaType == %d", PHAssetMediaType.video.rawValue)
        case .all:
            self.init(format: "mediaType == %d || mediaType == %d", PHAssetMediaType.image.rawValue, PHAssetMediaType.video.rawValue)
        default:
            return nil
        }
    }
}
