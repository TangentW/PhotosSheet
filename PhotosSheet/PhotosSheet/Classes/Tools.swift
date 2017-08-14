//
//  Tools.swift
//  PhotosSheet
//
//  Created by Tan on 2017/8/14.
//

import UIKit

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
