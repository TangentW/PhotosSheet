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
                self?._checkbox.isHidden = hide
            }
        }()

        override init(frame: CGRect) {
            super.init(frame: frame)
            backgroundColor = UIColor.clear
            contentView.addSubview(_contentView)
            contentView.addSubview(_checkbox)
            contentView.addSubview(_videoMarkView)
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        var model: PhotosSheet.Model? {
            didSet {
                guard let model = model, oldValue != model else { return }
                // Loading thumbnail
                _preRequestId = PhotosSheet.PhotosManager.shared.fetchPhoto(with: model.asset, type: .thumbnail(height: PhotosSheet.photoItemHeight), completionHandler: { [weak self] image in
                    // Called twice.
                    // First callback low quality thumbnail, second callback high quality thumbnail.
                    self?._contentView.image = image
                })
                _setupCheckbox(isModelSelected: model.didSelected)
                _videoMarkView.isHidden = model.asset.mediaType != .video
                model.didChangedSelected = { [weak self] didSelected in
                    self?._setupCheckbox(isModelSelected: didSelected)
                }
                _checkbox.isHidden = !model.didSelected && _hideCheckbox
            }
        }

        fileprivate func _setupCheckbox(isModelSelected: Bool) {
            let checkboxImage = isModelSelected ? UIImage(named: "selection-mark-selected", in: Bundle.myBundle, compatibleWith: nil) : UIImage(named: "selection-mark-normal", in: Bundle.myBundle, compatibleWith: nil)
            _checkbox.image = checkboxImage
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
            _contentView.frame = bounds
            _checkbox.sizeToFit()
            _checkbox.frame.origin = CGPoint(x: bounds.width - _checkbox.bounds.width - PhotosSheet.photoItemCheckboxRightMargin, y: bounds.height - _checkbox.bounds.height - PhotosSheet.photoItemCheckboxBottomMargin)
            _videoMarkView.sizeToFit()
            _videoMarkView.frame.origin = CGPoint(x: PhotosSheet.photoItemVideoMarkerViewLeftMargin, y: bounds.height - _videoMarkView.bounds.height - PhotosSheet.photoItemVideoMarkerViewBottomMargin)
        }

        fileprivate lazy var _contentView: UIImageView = {
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFill
            imageView.layer.masksToBounds = true
            return imageView
        }()

        fileprivate lazy var _checkbox: UIImageView = {
            let view = UIImageView()
            view.image = UIImage(named: "selection-mark-normal", in: Bundle.myBundle, compatibleWith: nil)
            return view
        }()

        fileprivate lazy var _videoMarkView: UIImageView = {
            let view = UIImageView()
            view.tintColor = .white
            view.image = UIImage(named: "file-cate-list-video", in: Bundle.myBundle, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
            view.layer.shadowColor = UIColor.black.cgColor
            view.layer.shadowOffset = CGSize(width: 1, height: 1)
            view.layer.shadowRadius = 1
            view.layer.shadowOpacity = 0.5
            return view
        }()
    }
}

extension PhotosSheet.PhotosDisplayController.PhotoItemView: PhotosDisplayViewContentOffsetObserver {
    func displayView(_ displayView: UICollectionView, onContentOffsetChange contentOffset: CGPoint) {
        let displayViewWidth = displayView.bounds.width
        let x = min(max(displayViewWidth - (frame.origin.x - contentOffset.x) - _checkbox.bounds.width - PhotosSheet.photoItemCheckboxRightMargin, PhotosSheet.photoItemCheckboxRightMargin), bounds.width - _checkbox.bounds.width - PhotosSheet.photoItemCheckboxBottomMargin)
        _checkbox.frame.origin.x = x
    }
}
