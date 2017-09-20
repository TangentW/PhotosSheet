//
//  Tools.swift
//  PhotosSheet
//
//  Created by Tan on 2017/8/14.
//

import UIKit
import Photos

// MARK: - Private
extension UIImage {
    func scaleTo(size: CGSize) -> UIImage? {
        if self.size.width > size.width {
            UIGraphicsBeginImageContext(size)
            self.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
            let retImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return retImage
        } else {
            return self
        }
    }
}

extension PHAsset {
    var imageFileSize: Int {
        assert(!Thread.current.isMainThread, "Do not call it in main thread!")
        var fileSize = 0
        PhotosSheet.PhotosManager.shared.fetchPhoto(with: self, type: .original, isSynchronous: true) {
            let data = UIImageJPEGRepresentation($0, 1)
            fileSize = data?.count ?? 0
        }
        return fileSize
    }

    var videoFileSize: Int {
        assert(!Thread.current.isMainThread, "Do not call it in main thread!")
        let options = PHVideoRequestOptions()
        options.version = .original
        var ret = 0
        let group = DispatchGroup()
        group.enter()
        PHImageManager.default().requestAVAsset(forVideo: self, options: options) { avAsset, _, _ in
            ret = (avAsset as? AVURLAsset)?.url.fileSize ?? 0
            group.leave()
        }
        group.wait()
        return ret
    }

    var fileSize: Int {
        assert(!Thread.current.isMainThread, "Do not call it in main thread!")
        switch mediaType {
        case .image:
            return imageFileSize
        case .video:
            return videoFileSize
        default:
            return 0
        }
    }
}

extension URL {
    var fileSize: Int {
        guard let resourceValues = try? resourceValues(forKeys: [.fileSizeKey, .totalFileSizeKey]) else { return 0 }
        return resourceValues.fileSize ?? resourceValues.totalFileSize ?? 0
    }
}

extension Int {
    var sizeString: String {
        let bcf = ByteCountFormatter()
        bcf.allowedUnits = [.useBytes, .useKB, .useMB]
        bcf.countStyle = .file
        return bcf.string(fromByteCount: Int64(self))
    }
}

extension Bundle {
    static var myBundle: Bundle {
        return Bundle(for: PhotosSheet.self)
    }
}

extension String {
    var localizedString: String {
        return NSLocalizedString(self, bundle: Bundle.myBundle, comment: "")
    }
}

// MARK: - Public
public extension Array where Element == PHAsset {
    func calcSize(completionHandler: @escaping (Int) -> ()) {
        DispatchQueue.global().async {
            let urls = self.map { me -> Int in
                var fileSize = 0
                autoreleasepool {
                    fileSize = me.fileSize
                }
                return fileSize
            }
            DispatchQueue.main.async {
                completionHandler(urls.reduce(0, +))
            }
        }
    }

    func calcSizeString(completionHandler: @escaping (String) -> ()) {
        calcSize {
            completionHandler($0.sizeString)
        }
    }
}
