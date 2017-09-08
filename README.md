# PhotosSheet
[![](https://img.shields.io/badge/language-Swift3.0-orange.svg)](https://github.com/TangentW/PhotosSheet)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![CocoaPods](https://img.shields.io/cocoapods/v/PhotosSheet.svg)](https://github.com/TangentW/PhotosSheet)

## Introduction
A photo selection control that has action sheet style. Support iCloud.

Photos are displayed in order of creation.

When you select a photo in iCloud, `PhotosSheet` will automatically download it from remote.

![PhotosSheet](https://raw.githubusercontent.com/TangentW/PhotosSheet/master/Screenshots/PhotosSheet.gif
)

![PhotosSheet](http://7xsfp9.com1.z0.glb.clouddn.com/2421502901884_.pic.jpg?imageView/3/w/280)
![PhotosSheet](http://7xsfp9.com1.z0.glb.clouddn.com/2431502901884_.pic.jpg?imageView/3/w/280)

## Requirements
* iOS 9.0 or higher.
* Swift 3.0.
* Make sure `photo library usage privacy` have added to you project's `Info.plist`.

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
Add `PhotosSheet` in your `Podfile`:

```
use_frameworks!

pod "PhotosSheet"
```

Then run the following command:

```
$ pod install
```

### Manually
1. Download the source code.
2. Drag folder **PhotosSheet** into your project.

## Usage
### Basic usage
```Swift
let openCamera = PhotosSheet.Action(title: "Open Camera", tintColor: .green) {
    print("Open Camera")
}
let openAlbum = PhotosSheet.Action(title: "Open Album", tintColor: .green) {
    print("Open Album")
}
let cancel = PhotosSheet.Action(style: .cancel, title: "Cancel", tintColor: .red) {
    print("Cancel")
}

let photosSheet = PhotosSheet(actions: [openCamera, openAlbum, cancel],
                              mediaOption: .photo,
                              displayedPhotosLimit: 50,
                              selectedPhotosLimit: 4) { [weak self] assets in
                                self?._sendAssets(assets)
}
present(photosSheet, animated: true, completion: nil)
```

`PhotosSheet` support multiple media options:

* all
* photo
* video

---

### Customization
You can use `UIOption` to customize UI for `PhotosSheet`.

```Swift
var options: Set<PhotosSheet.UIOption> {
    return [
        .photoItemCheckboxRightMargin(5),
        .actionSheetItemHeight(57),
        .actionSheetCorners(12),
        .actionSheetFont(.systemFont(ofSize: 20))
    ]
}
```

```Swift
let photosSheet = PhotosSheet(actions: [openCamera, openAlbum, cancel],
                              mediaOption: .photo,
                              displayedPhotosLimit: 50,
                              selectedPhotosLimit: 4,
                              options: options) { [weak self] assets in
                                self?._sendAssets(assets)
}
```

#### All properties
```Swift
photoItemCheckboxRightMargin(CGFloat)
```

```Swift
photoItemCheckboxBottomMargin(CGFloat)
```

```Swift
photoItemVideoMarkerViewLeftMargin(CGFloat)
```

```Swift
photoItemVideoMarkerViewBottomMargin(CGFloat)
```

```Swift
photoItemHeight(CGFloat)
```

```Swift
actionSheetFont(UIFont)
```

```Swift
actionSheetCorners(CGFloat)
```

```Swift
actionSheetHorizontalMargin(CGFloat)
```

```Swift
actionSheetVerticalMargin(CGFloat)
```

```Swift
actionSheetItemHeight(CGFloat)
```

---

### Send originals
`PhotosSheet` can display button for sending originals:

![PhotosSheet](http://7xsfp9.com1.z0.glb.clouddn.com/2411502881889_.pic_hd.jpg?imageView/3/w/300)

Just set `isShowSendOriginalsButton` to true:

```Swift
photosSheet.isShowSendOriginalsButton = true
```

If user presses the "Send Originals" button, `PhotosSheet` will call back to us:

```Swift
let photosSheet = PhotosSheet(actions: [openCamera, openAlbum, cancel],
                              mediaOption: .photo,
                              displayedPhotosLimit: 50,
                              selectedPhotosLimit: 4) { assets, isOriginl in
                                if isOriginl {
                                  // TODO...
                                } else {
                                  // TODO...
                                }
}
```

---

### Filter
You can filter the `PhotosSheet`'s sending operations after user presses the sending button：

```Swift
/// Filter before you have selected the photos.
///
///    let filter: SendingActionFilter = { assets, isOriginals, send in
///        assets.calcSize { size in
///            // Less than 10 MB
///            let canSend = size < 10 * 1024 * 1024
///            send()
///        }
///    }
///
public var sendingActionFilter: SendingActionFilter?
```

For example: 
```Swift
lazy var filter: PhotosSheet.SendingActionFilter = { [weak self] assets, isOriginal, send in
     assets.calcSize { [weak self] size in
         let canSend = size < 10 * 1024 * 1024
         if canSend {
             send()
         } else {
             let alertController = UIAlertController(title: "Warning", message: "Photos size is too large, still want to send?", preferredStyle: .alert)
             let confirmAction = UIAlertAction(title: "Yes", style: .default) { _ in
                 send()
             }
             let cancelAction = UIAlertAction(title: "No", style: .cancel)
             alertController.addAction(confirmAction)
             alertController.addAction(cancelAction)
             self?.present(alertController, animated: true, completion: nil)
         }
     }
 }

photosSheet.sendingActionFilter = filter
```

## Interface
```Swift
/// All actions in action sheet.
public let actions: [PhotosSheet.Action]

/// PhotosSheet is show send originals button.
public var isShowSendOriginalsButton: Bool = false {
    didSet {
        _contentController.isShowSendOriginalsButton = isShowSendOriginalsButton
    }
}

/// Filter before you have selected the photos.
///
///    let filter: SendingActionFilter = { assets, isOriginals, send in
///        assets.calcSize { size in
///            // Less than 10 MB
///            let canSend = size < 10 * 1024 * 1024
///            send()
///        }
///    }
///
public var sendingActionFilter: SendingActionFilter? = nil {
    didSet {
        _contentController.sendingActionFilter = sendingActionFilter
    }
}

/// Init an action sheet with photos on it.
///
/// - Parameters:
///   - actions: Actions in action sheet.
///   - mediaOption: The media option of the asset you want to select.
///   - displayedPhotosLimit: The max count of photos displayed, default is `0`, means unlimited.
///   - selectedPhotosLimit: The max count of photos that can be selected, default is `9`.
///   - options: UI options. See `UIOption`
///   - didSelectedAssets: Called after you have selected the photos. |Assets, Is send originals|
public init(actions: [PhotosSheet.Action],
       mediaOption: MediaOption = .all,
       displayedPhotosLimit: Int = 0,
       selectedPhotosLimit: Int = 9,
       options: Set<UIOption>? = nil,
       didSelectedAssets: @escaping ([PHAsset], Bool) -> ())
```

## To do
* Support `Live Photo`
* Optimize performance

## License
The MIT License (MIT)


