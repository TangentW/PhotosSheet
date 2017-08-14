//
//  Model.swift
//  PhotosSheet
//
//  Created by Tan on 2017/8/14.
//

import Foundation
import Photos

// MARK: - PhotosProvider.Model
extension PhotosSheet {
    class Model {
        let asset: PHAsset
        fileprivate(set) var size: Int = 0
        fileprivate let _semaphore = DispatchSemaphore(value: 1)
        fileprivate var _downloadTask: PHImageRequestID?

        var didSelected: Bool = false {
            didSet {
                didChangedSelected?(didSelected)
            }
        }

        var didChangedSelected: ((Bool) -> ())?
        var downloadProgressCallback: ((Double) -> ())?

        init(asset: PHAsset) {
            self.asset = asset
        }

        deinit {
            _cancelTask()
        }
    }
}

extension PhotosSheet.Model: Hashable {
    var hashValue: Int {
        return asset.hashValue
    }

    static func ==(lhs: PhotosSheet.Model, rhs: PhotosSheet.Model) -> Bool {
        return lhs.asset == rhs.asset
    }
}

extension PhotosSheet.Model {
    // !!Synchronous!! Do not call in main thread
    func fetchPhotoFromLocalOrCloud() -> (PHAsset, UIImage)? {
        _semaphore.wait()
        defer {
            _semaphore.signal()
        }
        guard _downloadTask == nil else { return nil }
        var ret: (PHAsset, UIImage)? = nil
        _downloadTask = PhotosSheet.PhotosManager.shared.fetchPhoto(with: asset, type: .original, isSynchronous: true, progressHandler: { [weak self] progress, _ in
            DispatchQueue.main.async {
                self?.downloadProgressCallback?(progress)
            }
        }) { [weak self] image in
            guard let `self` = self else { return }
            ret = (self.asset, image)
        }
        return ret
    }

    func _cancelTask() {
        if let task = _downloadTask {
            PHImageManager.default().cancelImageRequest(task)
        }
    }
}

extension Array where Element == PhotosSheet.Model {
    func fetchPhotos(completionHandler: @escaping ([(PHAsset, UIImage)]) -> ()) -> DispatchWorkItem {
        let workItem = DispatchWorkItem {
            let photos = self.flatMap { $0.fetchPhotoFromLocalOrCloud() }
            DispatchQueue.main.async {
                completionHandler(photos)
            }
        }
        DispatchQueue.global().async(execute: workItem)
        return workItem
    }
}
