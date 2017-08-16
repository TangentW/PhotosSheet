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
    // Do not call in main thread
    var imageURL: URL? {
        // Only for image
        guard mediaType == .image else { return nil }
        var url: URL? = nil
        let group = DispatchGroup()
        group.enter()
        requestContentEditingInput(with: nil) { input, _ in
            url = input?.fullSizeImageURL
            group.leave()
        }
        group.wait()
        return url
    }

    // Do not call in main thread
    var videoURL: URL? {
        guard mediaType == .video else { return nil }
        let options = PHVideoRequestOptions()
        options.version = .original
        var ret: URL?
        let group = DispatchGroup()
        group.enter()
        PHImageManager.default().requestAVAsset(forVideo: self, options: options) { avAsset, _, _ in
            ret = (avAsset as? AVURLAsset)?.url
            group.leave()
        }
        group.wait()
        return ret
    }

    // Do not call in main thread
    var url: URL? {
        switch mediaType {
        case .image:
            return imageURL
        case .video:
            return videoURL
        default:
            return nil
        }
    }
}

extension URL {
    var fileSize: Int {
        let size = try? resourceValues(forKeys: [.fileSizeKey]).fileSize
        return (size ?? 0) ?? 0
    }
}

extension Int {
    var sizeString: String {
        let bcf = ByteCountFormatter()
        bcf.allowedUnits = [.useMB]
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
            let urls = self.map { $0.url }
            DispatchQueue.main.async {
                let size = urls.reduce(0) { p, n in
                    return p + (n?.fileSize ?? 0)
                }
                completionHandler(size)
            }
        }
    }

    func calcSizeString(completionHandler: @escaping (String) -> ()) {
        calcSize {
            completionHandler($0.sizeString)
        }
    }
}

