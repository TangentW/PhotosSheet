# PhotosSheet
[![](https://img.shields.io/badge/language-Swift3.0-orange.svg)](https://github.com/TangentW/ChatMenu)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![CocoaPods](https://img.shields.io/cocoapods/v/PhotosSheet.svg)](https://github.com/TangentW/ChatMenu)

## Introduction
A photo selection control that has action sheet style. Support iCloud.

Photos are displayed in order of creation.

When you select a photo in iCloud, `PhotosSheet` will automatically download it from remote.
![PhotosSheet](http://7xsfp9.com1.z0.glb.clouddn.com/WechatIMG237.jpeg?imageView/3/w/280)
![PhotosSheet](http://7xsfp9.com1.z0.glb.clouddn.com/WechatIMG238.jpeg?imageView/3/w/280)
![PhotosSheet](http://7xsfp9.com1.z0.glb.clouddn.com/photos_sheet_gif.gif)

## Requirements
* iOS 9.0 or higher
* Swift 3.0

## Demo
`$ cd Sample/` and `$ pod install`, then run the `Sample` project in Xcode to see `PhotosSheet` in action.

## Installation
### Carthage
Add `PhotosSheet` in your `Cartfile`:
```
github "TangentW/PhotosSheet"
```
Run `carthage update` to build the framework and drag into your project.
###  Cocoapods
Add `PhotosSheet` in your `Profile`:
```
use_frameworks!

pod "PhotosSheet"
```
Then run the following command:
```
$ pod install
```
## Usage
### Example usage
```Swift
let openCamera = PhotosSheet.Action(title: "Open Camera", tintColor: .green) {
    print("Show Camera")
}
let openAlbum = PhotosSheet.Action(title: "Show Album", tintColor: .green) {
    print("Show Album")
}
let canel = PhotosSheet.Action(style: .cancel, title: "Cancel", tintColor: .red) {
    print("Cancel")
}

let photosSheet = PhotosSheet(actions: [openCamera, openAlbum, canel],
                              displayedPhotosLimit: 3,
                              selectedPhotosLimit: 2,
                              didSelectedImages: { [weak self] images in
                                self?._images = images
})
present(photosSheet, animated: true, completion: nil)
```

## Interface
```Swift
/// All actions in action sheet.
public let actions: [PhotosSheet.Action]

/// Init an action sheet with photos on it.
///
/// - Parameters:
///   - actions: Actions in action sheet.
///   - displayedPhotosLimit: The max count of photos displayed, default is `0`, means unlimited.
///   - selectedPhotosLimit: The max count of photos that can be selected, default is `9`.
///   - didSelectedAssets: Called after you have selected the photos, output assets.
///   - didSelectedImages: Called after you have selected the photos, output images.
public init(actions: [PhotosSheet.Action],
       displayedPhotosLimit: Int = 0,
       selectedPhotosLimit: Int = 9,
       didSelectedAssets: (([PHAsset]) -> ())? = nil,
       didSelectedImages: (([UIImage]) -> ())? = nil)
```

## To do
* Support more media type
* Optimize performance
* Open interface which can modify UI

## License
The MIT License (MIT)


