//
//  Tools.swift
//  PhotosSheet
//
//  Created by Tan on 2017/8/14.
//

import UIKit
import SystemConfiguration
import Photos

// MARK: - Tools
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

enum NetworkState {
    case offline
    case WIFI
    case WWAN
}

extension NetworkState {
    static func checkCurrentState() -> NetworkState {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        zeroAddress.sin_family = sa_family_t(AF_INET)

        guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        }) else { return .offline }

        var flags: SCNetworkReachabilityFlags = []
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
            return .offline
        }

        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        guard isReachable && !needsConnection else { return .offline }
        return flags.contains(.isWWAN) ? .WWAN : .WIFI
    }
}
