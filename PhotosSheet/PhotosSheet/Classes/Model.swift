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
        _cancelTask()
        var ret: (PHAsset, UIImage)? = nil
        // If asset type is video, fetch first frame image
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

    // !!Synchronous!! Do not call in main thread
    func fetchVideoFromLocalOrCloud() -> (PHAsset, AVAsset)? {
        _semaphore.wait()
        defer {
            _semaphore.signal()
        }
        _cancelTask()
        var ret: (PHAsset, AVAsset)? = nil
        // If mediaType not is video, callback nil.
        guard asset.mediaType == .video else { return ret }
        let group = DispatchGroup()
        group.enter()
        _downloadTask = PhotosSheet.PhotosManager.shared.fetchVideo(with: asset, progressHandler: { [weak self] progress, _ in
            DispatchQueue.main.async {
                self?.downloadProgressCallback?(progress)
            }
        }) { [weak self] avAsset in
            guard let `self` = self else { return }
            ret = (self.asset, avAsset)
            group.leave()
        }
        group.wait()
        return ret
    }

    func _cancelTask() {
        if let task = _downloadTask {
            PHImageManager.default().cancelImageRequest(task)
        }
    }
}

// Fetch photos from models
extension Array where Element == PhotosSheet.Model {
    func fetchVideosAndPhotos(completionHandler: @escaping ([(PHAsset, UIImage, AVAsset?)]) ->()) -> DispatchWorkItem {
        let workItem = DispatchWorkItem {
            let videosAndPhotos: [(PHAsset, UIImage, AVAsset?)] = self.flatMap {
                let video = $0.fetchVideoFromLocalOrCloud()
                guard let photo = $0.fetchPhotoFromLocalOrCloud() else { return nil }
                return (photo.0, photo.1, video?.1)
            }
            DispatchQueue.main.async(execute: {
                completionHandler(videosAndPhotos)
            })
        }
        DispatchQueue.global().async(execute: workItem)
        return workItem
    }
}
