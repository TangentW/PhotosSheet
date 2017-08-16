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
    func fetchImageFromLocalOrCloud() {
        _semaphore.wait()
        defer {
            _semaphore.signal()
        }
        _cancelTask()
        // If asset type is video, fetch first frame image
        _downloadTask = PhotosSheet.PhotosManager.shared.fetchPhoto(with: asset, type: .original, isSynchronous: true, progressHandler: { [weak self] progress, _ in
            DispatchQueue.main.async {
                self?.downloadProgressCallback?(progress)
            }
        }) { _ in }
    }

    // !!Synchronous!! Do not call in main thread
    func fetchVideoFromLocalOrCloud() {
        _semaphore.wait()
        defer {
            _semaphore.signal()
        }
        _cancelTask()
        // If mediaType not is video, callback nil.
        guard asset.mediaType == .video else { return }
        let group = DispatchGroup()
        group.enter()
        _downloadTask = PhotosSheet.PhotosManager.shared.fetchVideo(with: asset, progressHandler: { [weak self] progress, _ in
            DispatchQueue.main.async {
                self?.downloadProgressCallback?(progress)
            }
        }) { _ in group.leave() }
        group.wait()
    }

    func _cancelTask() {
        if let task = _downloadTask {
            PHImageManager.default().cancelImageRequest(task)
        }
    }
}

extension Array where Element == PhotosSheet.Model {
    /// Fetch videos and images
    ///
    /// - Parameter completionHandler: |Assets|
    /// - Returns: WorkItem
    func fetchVideosAndImages(completionHandler: @escaping ([PHAsset]) -> ()) -> DispatchWorkItem {
        let workItem = DispatchWorkItem {
            let assets: [PHAsset] = self.map { model in
                model.fetchVideoFromLocalOrCloud()
                model.fetchImageFromLocalOrCloud()
                return model.asset
            }
            DispatchQueue.main.async(execute: {
                completionHandler(assets)
            })
        }
        DispatchQueue.global().async(execute: workItem)
        return workItem
    }
}
