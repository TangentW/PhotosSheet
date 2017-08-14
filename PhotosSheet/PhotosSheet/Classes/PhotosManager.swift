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
        init() { }
    }
}

extension PhotosSheet.PhotosManager {
    // ResultImage, Info, IsDegraded
    typealias ImageRequestCompletion = (UIImage) -> ()
    // Progress, Stop
    typealias ImageDownloadProgressHandler = (Double, UnsafeMutablePointer<ObjCBool>) -> ()

    @discardableResult
    func fetchPhoto(with asset: PHAsset, type: PhotoFetchType, isSynchronous: Bool = false, progressHandler: ImageDownloadProgressHandler? = nil, completion: @escaping ImageRequestCompletion) -> PHImageRequestID {
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

        // resultHandler called in main thread
        if asset.representsBurst {
            return PHImageManager.default().requestImageData(for: asset, options: option, resultHandler: { data, _, _, info in
                guard let info = info else { return }
                let fetchSucceed = !(info[PHImageCancelledKey] as? Bool ?? false) && info[PHImageErrorKey] == nil
                guard let data = data, let image = UIImage(data: data), fetchSucceed else { return }
                if targetSize != PHImageManagerMaximumSize {
                    if let retImage = image.scaleTo(size: targetSize) {
                        completion(retImage)
                    }
                } else {
                    completion(image)
                }
            })
        } else {
            return PHImageManager.default().requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: option, resultHandler: { image, info in
                guard let info = info else { return }
                let fetchSucceed = !(info[PHImageCancelledKey] as? Bool ?? false) && info[PHImageErrorKey] == nil
                guard let image = image, fetchSucceed else { return }
                completion(image)
            })
        }
    }
}

extension PhotosSheet.PhotosManager {
    enum PhotoFetchType {
        case thumbnail(height: CGFloat)
        case original
    }
}

extension PhotosSheet.PhotosManager {
    func obtainRecentAssets(limit: Int = 0) -> [PHAsset] {
        let fetchOption = PHFetchOptions()
        fetchOption.includeAssetSourceTypes = [.typeUserLibrary]
        // TODO: Support more media type
        fetchOption.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchOption.sortDescriptors = [sortDescriptor]
        if limit > 0 {
            fetchOption.fetchLimit = limit
        }
        let results = PHAsset.fetchAssets(with: fetchOption)
        return results.objects(at: IndexSet(0 ..< results.count))
    }
}
