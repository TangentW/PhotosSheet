//
//  PhotosDisplayController.swift
//  PhotosSheet
//
//  Created by Tan on 2017/8/14.
//

import UIKit
import Photos

// MARK: - PhotosDisplayController
extension PhotosSheet {
    final class PhotosDisplayController: UIViewController {
        init() {
            super.init(nibName: nil, bundle: nil)
        }

        override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
            super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        fileprivate(set) lazy var photosDisplayView: UICollectionView = {
            let view = UICollectionView(frame: .zero, collectionViewLayout: self._photosDisplayLayout)
            view.showsHorizontalScrollIndicator = false
            view.backgroundColor = UIColor.white.withAlphaComponent(0.9)
            return view
        }()

        fileprivate lazy var _photosDisplayLayout: UICollectionViewLayout = {
            let layout = UICollectionViewFlowLayout()
            layout.scrollDirection = .horizontal
            layout.minimumInteritemSpacing = 5
            layout.minimumLineSpacing = 0
            return layout
        }()
    }
}

extension PhotosSheet.PhotosDisplayController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.clear
        view.addSubview(photosDisplayView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 放在下一个Runloop周期，对所有显示出来的CollectionViewCell中的Checkbox进行布局
        DispatchQueue.main.async {
            self.photosDisplayView.delegate?.scrollViewDidScroll?(self.photosDisplayView)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        photosDisplayView.frame = view.bounds
    }
}

// MARK: - PhotoItemView
extension PhotosSheet.PhotosDisplayController {
    final class PhotoItemView: UICollectionViewCell {
        fileprivate var _preRequestId: PHImageRequestID?
        fileprivate var _hideCheckbox = false

        lazy private(set) var hideCheckbox: (Bool) -> () = {
            return { [weak self] hide in
                self?._hideCheckbox = hide
                if let model = self?.model, model.didSelected {
                    return
                }
                self?.checkbox.isHidden = hide
            }
        }()

        override init(frame: CGRect) {
            super.init(frame: frame)
            backgroundColor = UIColor.clear
            contentView.addSubview(mContentView)
            contentView.addSubview(checkbox)
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        var model: PhotosSheet.Model? {
            didSet {
                guard let model = model, oldValue != model else { return }
                // 加载缩略图
                _preRequestId = PhotosSheet.PhotosManager.shared.fetchPhoto(with: model.asset, type: .thumbnail(height: PhotosSheet.photoItemHeight), completion: { [weak self] image in
                    // 会走两次，第一次是获取本地质量略差的缩略图，第二次是获取Cloud质量不错的缩略图
                    self?.mContentView.image = image
                })
                _setupCheckbox(isModelSelected: model.didSelected)
                model.didChangedSelected = { [weak self] didSelected in
                    self?._setupCheckbox(isModelSelected: didSelected)
                    // TODO: 在WIFI环境下当用户选择照片后进行预下载
                    // 但是在普通环境下用户要先点击发送按钮才进行下载
                    // if didSelected { self?.model?.fetchAssetFromLocalOrCloud() }
                }
                checkbox.isHidden = !model.didSelected && _hideCheckbox
            }
        }

        fileprivate func _setupCheckbox(isModelSelected: Bool) {
            let checkboxImage = isModelSelected ? UIImage(named: "selection-mark-selected", in: Bundle.myBundle, compatibleWith: nil) : UIImage(named: "selection-mark-normal", in: Bundle.myBundle, compatibleWith: nil)
            checkbox.image = checkboxImage
        }

        override func prepareForReuse() {
            super.prepareForReuse()
            if let preRequestId = _preRequestId {
                PHImageManager.default().cancelImageRequest(preRequestId)
            }
        }

        deinit {
            if let preRequestId = _preRequestId {
                PHImageManager.default().cancelImageRequest(preRequestId)
            }
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            mContentView.frame = bounds
            checkbox.sizeToFit()
            checkbox.frame.origin = CGPoint(x: bounds.width - checkbox.bounds.width - PhotosSheet.photoItemCheckboxRightMargin, y: bounds.height - checkbox.bounds.height - PhotosSheet.photoItemCheckboxBottomMargin)
        }

        lazy private(set) var mContentView: UIImageView = {
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFill
            imageView.layer.masksToBounds = true
            return imageView
        }()

        lazy private(set) var checkbox: UIImageView = {
            let view = UIImageView()
            view.image = UIImage(named: "selection-mark-normal", in: Bundle.myBundle, compatibleWith: nil)
            return view
        }()
    }
}

extension PhotosSheet.PhotosDisplayController.PhotoItemView: PhotosDisplayViewContentOffsetObserver {
    func displayView(_ displayView: UICollectionView, onContentOffsetChange contentOffset: CGPoint) {
        let displayViewWidth = displayView.bounds.width
        let x = min(max(displayViewWidth - (frame.origin.x - contentOffset.x) - checkbox.bounds.width - PhotosSheet.photoItemCheckboxRightMargin, PhotosSheet.photoItemCheckboxRightMargin), bounds.width - checkbox.bounds.width - PhotosSheet.photoItemCheckboxBottomMargin)
        checkbox.frame.origin.x = x
    }
}
