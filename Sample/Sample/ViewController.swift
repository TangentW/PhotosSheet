//
//  ViewController.swift
//  Sample
//
//  Created by Tan on 2017/8/13.
//
//

import UIKit
import PhotosSheet
import Photos

fileprivate let margin: CGFloat = 8

class ViewController: UIViewController {

    @IBOutlet weak var imagesCollectionView: UICollectionView!
    @IBOutlet weak var imagesLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var showBtn: UIButton!

    fileprivate var _images: [UIImage?] = [] {
        didSet {
            imagesCollectionView.reloadData()
        }
    }

    let itemSize: CGSize = {
        let countPerRow: CGFloat = 2
        let sizeValue = (UIScreen.main.bounds.width - (countPerRow - 1) * margin) / countPerRow
        return CGSize(width: sizeValue, height: sizeValue)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showBtn.addTarget(self, action: #selector(ViewController.showSheet), for: .touchUpInside)
        imagesCollectionView.dataSource = self
        imagesCollectionView.register(ImageItem.self, forCellWithReuseIdentifier: String(describing: ImageItem.self))
        imagesLayout.itemSize = itemSize
        imagesLayout.minimumLineSpacing = margin
        imagesLayout.minimumInteritemSpacing = margin
    }

    lazy var options: Set<PhotosSheet.UIOption> = [
        .photoItemCheckboxRightMargin(5),
        .actionSheetItemHeight(57),
        .actionSheetCorners(12),
        .actionSheetFont(.systemFont(ofSize: 20))
    ]

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

    @objc func showSheet() {
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
                                      selectedPhotosLimit: 4,
                                      options: options) { [weak self] assets in
                                        self?._sendAssets(assets)
        }
//        photosSheet.isShowSendOriginalsButton = true
        photosSheet.sendingActionFilter = filter
        present(photosSheet, animated: true, completion: nil)
    }

    fileprivate func _sendAssets(_ assets: [PHAsset]) {
        _images = assets.flatMap {
            var image: UIImage?
            PhotosSheet.PhotosManager.shared.fetchPhoto(with: $0, type: .thumbnail(height: self.itemSize.height), isSynchronous: true, completionHandler: { result in
                image = result
            })
            return image
        }

    }
}

extension ViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return _images.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ImageItem.self), for: indexPath) as! ImageItem
        cell.image = _images[indexPath.item]
        return cell
    }
}

final class ImageItem: UICollectionViewCell {
    var image: UIImage? {
        didSet {
            _contentImageView.image = image
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(_contentImageView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    fileprivate lazy var _contentImageView: UIImageView = {
        let imageView = UIImageView(frame: self.bounds)
        imageView.contentMode = .scaleAspectFill
        imageView.layer.masksToBounds = true
        return imageView
    }()
}
