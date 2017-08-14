//
//  PhotosSheet.swift
//  PhotosSheet
//
//  Created by Tan on 2017/8/13.
//
//

import UIKit
import Photos

// MARK: - UI Options
public extension PhotosSheet {
    enum UIOption: Hashable {
        case photoItemCheckboxRightMargin(CGFloat)
        case photoItemCheckboxBottomMargin(CGFloat)
        case photoItemHeight(CGFloat)
        case actionSheetFont(UIFont)
        case actionSheetCorners(CGFloat)
        case actionSheetHorizontalMargin(CGFloat)
        case actionSheetVerticalMargin(CGFloat)
        case actionSheetItemHeight(CGFloat)

        public var hashValue: Int {
            switch self {
            case .photoItemCheckboxRightMargin : return 0
            case .photoItemCheckboxBottomMargin : return 1
            case .photoItemHeight : return 2
            case .actionSheetFont : return 3
            case .actionSheetCorners : return 4
            case .actionSheetHorizontalMargin : return 5
            case .actionSheetVerticalMargin : return 6
            case .actionSheetItemHeight : return 7
            }
        }

        public static func ==(lhs: PhotosSheet.UIOption, rhs: PhotosSheet.UIOption) -> Bool {
            return lhs.hashValue == rhs.hashValue
        }
    }
}

public final class PhotosSheet: UIViewController {
    /// All actions in action sheet.
    public let actions: [PhotosSheet.Action]

    /// Init an action sheet with photos on it.
    ///
    /// - Parameters:
    ///   - actions: Actions in action sheet.
    ///   - displayedPhotosLimit: The max count of photos displayed, default is `0`, means unlimited.
    ///   - selectedPhotosLimit: The max count of photos that can be selected, default is `9`.
    ///   - options: UI options. See `UIOption`
    ///   - didSelectedAssets: Called after you have selected the photos, output assets.
    ///   - didSelectedImages: Called after you have selected the photos, output images.
    public init(actions: [PhotosSheet.Action],
                displayedPhotosLimit: Int = 0,
                selectedPhotosLimit: Int = 9,
                options: Set<UIOption>? = nil,
                didSelectedAssets: (([PHAsset]) -> ())? = nil,
                didSelectedImages: (([UIImage]) -> ())? = nil) {
        // SetupUI
        if let options = options {
            PhotosSheet._setupUI(options: options)
        }
        self.actions = actions
        _contentController = ContentController(actions: actions, displayedPhotosLimit: displayedPhotosLimit, selectedPhotosLimit: selectedPhotosLimit)
        _contentController.didSelectedAssets = didSelectedAssets
        _contentController.didSelectedImages = didSelectedImages
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overCurrentContext
        modalTransitionStyle = .crossDissolve
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        actions = []
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    fileprivate lazy var _backgroundView: UIButton = {
        let view = UIButton()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        view.addTarget(self, action: #selector(PhotosSheet._dismiss), for: .touchUpInside)
        return view
    }()

    @objc fileprivate func _dismiss() {
        dismiss(animated: true, completion: nil)
    }

    fileprivate var _contentController: ContentController!
}

public extension PhotosSheet {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(_backgroundView)
        _contentController.dismissCallback = { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        _backgroundView.frame = view.bounds
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        _contentController.show(from: self)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        _contentController.hide()
    }
}

// MARK: - Action
extension PhotosSheet {
    public struct Action {
        public let style: ActionStyle
        public let title: String
        public let tintColor: UIColor
        public let action: () -> ()

        public init(style: ActionStyle = .normal, title: String, tintColor: UIColor, action: @escaping () -> ()) {
            self.style = style
            self.title = title
            self.tintColor = tintColor
            self.action = action
        }
    }

    public enum ActionStyle {
        case normal
        case cancel
    }

    fileprivate final class _ActionItem: UIButton {
        fileprivate let _action: Action

        init(action: Action) {
            _action = action
            super.init(frame: .zero)
            backgroundColor = UIColor.white.withAlphaComponent(0.9)
            setTitle(_action.title, for: .normal)
            setTitleColor(_action.tintColor, for: .normal)
            titleLabel?.font = PhotosSheet.actionSheetFont
            self.autoresizingMask = .flexibleWidth
            addTarget(self, action: #selector(_ActionItem.doAction), for: .touchUpInside)
            addTarget(self, action: #selector(_ActionItem.switchToActive), for: .touchDown)
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        @objc func doAction() {
            _action.action()
            switchToUnActive()
        }

        @objc func switchToActive() {
            backgroundColor = UIColor.white.withAlphaComponent(0.6)
        }

        func switchToUnActive() {
            backgroundColor = UIColor.white.withAlphaComponent(0.9)
        }
    }
}

// MARK: - ContentController
extension PhotosSheet {
    final class ContentController: UIViewController {
        fileprivate let _normalActionItems: [_ActionItem]
        fileprivate let _cancelActionItems: [_ActionItem]

        var dismissCallback: (() -> ())?

        var didSelectedAssets: (([PHAsset]) -> ())?
        var didSelectedImages: (([UIImage]) -> ())?
        var selectedModels: [PhotosProvider.Model] = []

        fileprivate let _imagesLoadingQueue = DispatchQueue(label: "PhotosSheet.ContentController.ImagesLoadingQueue")

        fileprivate let _displayedPhotosLimit: Int
        fileprivate let _selectedPhotosLimit: Int

        fileprivate var _photosDisplayViewHeight: CGFloat = UIApplication.shared.statusBarOrientation == .portrait
            ? PhotosSheet.photoItemHeight : 0

        init(actions: [Action], displayedPhotosLimit: Int, selectedPhotosLimit: Int) {
            _displayedPhotosLimit = displayedPhotosLimit
            _selectedPhotosLimit = selectedPhotosLimit
            _normalActionItems = actions.filter { $0.style == .normal }.map(_ActionItem.init)
            _cancelActionItems = actions.filter { $0.style == .cancel }.map(_ActionItem.init)
            super.init(nibName: nil, bundle: nil)
            view.autoresizingMask = [.flexibleTopMargin, .flexibleWidth]
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            _layoutViews()
        }

        override func viewDidLoad() {
            super.viewDidLoad()
            _setupViews()
            _setupGestureRecognizer()
            _photosDisplayController.photosSelected = { [weak self] models in
                self?._switchToShowSendButton(assetsCount: models.count)
                self?.selectedModels = models
            }
        }

        override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
            _dismiss()
        }

        // Views
        fileprivate lazy var _blurViewForNormal: UIVisualEffectView = {
            let effect = UIBlurEffect(style: .light)
            let view = UIVisualEffectView(effect: effect)
            return view
        }()

        fileprivate lazy var _blurViewForCancel: UIVisualEffectView = {
            let effect = UIBlurEffect(style: .light)
            let view = UIVisualEffectView(effect: effect)
            return view
        }()

        fileprivate lazy var _contentViewForNormal: UIView = {
            let view = UIView()
            view.layer.masksToBounds = true
            view.layer.cornerRadius = PhotosSheet.actionSheetCorners
            view.autoresizingMask = .flexibleWidth
            return view
        }()

        fileprivate lazy var _contentViewForCancel: UIView = {
            let view = UIView()
            view.layer.masksToBounds = true
            view.layer.cornerRadius = PhotosSheet.actionSheetCorners
            view.autoresizingMask = .flexibleWidth
            return view
        }()

        // Send Photo
        fileprivate lazy var _sendPhotoBtn: _ActionItem = {
            let firstItemColor = self._normalActionItems.first?._action.tintColor ?? .green
            let action = Action(title: "", tintColor: firstItemColor, action: { [weak self] in
                self?._sendPhotosAction()
            })
            let view = _ActionItem(action: action)
            view.isHidden = true
            view.setTitle("Send"._localizedString, for: .normal)
            return view
        }()

        // PhotosDisplayController
        fileprivate lazy var _photosDisplayController: PhotosDisplayController = {
            return PhotosDisplayController(displayedPhotosLimit: self._displayedPhotosLimit, selectedPhotosLimit: self._selectedPhotosLimit)
        }()

        // GestureReconizer, Handle Items's Event
        @objc fileprivate func _listenFor(panGestureReconizer: UIPanGestureRecognizer) {
            let location = panGestureReconizer.location(in: view)
            let items = (_normalActionItems + _cancelActionItems + [_sendPhotoBtn]).filter { !$0.isHidden }
            switch panGestureReconizer.state {
            case .began, .changed:
                for actionItem in items {
                    let point = actionItem.convert(location, from: view)
                    if actionItem.point(inside: point, with: nil) {
                        actionItem.switchToActive()
                    } else {
                        actionItem.switchToUnActive()
                    }
                }
            case .ended:
                for actionItem in items {
                    let point = actionItem.convert(location, from: view)
                    if actionItem.point(inside: point, with: nil) {
                        actionItem.doAction()
                        dismissCallback?()
                    }
                }
            default:
                ()
            }
        }

        // dismiss
        @objc fileprivate func _dismiss() {
            dismissCallback?()
        }
    }
}

fileprivate extension PhotosSheet.ContentController {
    var _expectHeight: CGFloat {
        return _contentViewHeightForNormal + _contentViewHeightForCancel + PhotosSheet.actionSheetVerticalMargin
    }

    var _contentViewHeightForNormal: CGFloat {
        let itemCount = _normalActionItems.count
        return CGFloat(itemCount) * PhotosSheet.actionSheetItemHeight + CGFloat(itemCount - 1) * 0.5 + _photosDisplayViewHeight
    }

    var _contentViewHeightForCancel: CGFloat {
        let itemCount = _cancelActionItems.count
        return CGFloat(itemCount) * PhotosSheet.actionSheetItemHeight + CGFloat(itemCount - 1) * 0.5
    }

    func _setupGestureRecognizer() {
        let panGR = UIPanGestureRecognizer(target: self, action: #selector(PhotosSheet.ContentController._listenFor(panGestureReconizer:)))
        view.addGestureRecognizer(panGR)
    }

    func _setupViews() {
        view.backgroundColor = UIColor.clear
        view.addSubview(_contentViewForNormal)
        view.addSubview(_contentViewForCancel)
        _contentViewForNormal.addSubview(_blurViewForNormal)
        addChildViewController(_photosDisplayController)
        _contentViewForNormal.addSubview(_photosDisplayController.view)
        _contentViewForCancel.addSubview(_blurViewForCancel)

        _normalActionItems.forEach {
            $0.addTarget(self, action: #selector(PhotosSheet.ContentController._dismiss), for: .touchUpInside)
            _contentViewForNormal.addSubview($0)
        }
        _cancelActionItems.forEach {
            $0.addTarget(self, action: #selector(PhotosSheet.ContentController._dismiss), for: .touchUpInside)
            _contentViewForCancel.addSubview($0)
        }
        if _normalActionItems.count > 0 {
            _contentViewForNormal.addSubview(_sendPhotoBtn)
        }
    }

    func _layoutViews() {
        _photosDisplayController.view.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: _photosDisplayViewHeight)
        _contentViewForNormal.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: _contentViewHeightForNormal)
        _contentViewForCancel.frame = CGRect(x: 0, y: _contentViewForNormal.frame.maxY + PhotosSheet.actionSheetVerticalMargin, width: view.bounds.width, height: _contentViewHeightForCancel)
        _blurViewForNormal.frame = _contentViewForNormal.bounds
        _blurViewForCancel.frame = _contentViewForCancel.bounds
        _normalActionItems.enumerated().forEach { index, view in
            view.frame = CGRect(x: 0, y: CGFloat(index) * (PhotosSheet.actionSheetItemHeight + 0.5) + _photosDisplayViewHeight, width: self.view.bounds.width, height: PhotosSheet.actionSheetItemHeight)
        }
        _cancelActionItems.enumerated().forEach { index, view in
            view.frame = CGRect(x: 0, y: CGFloat(index) * (PhotosSheet.actionSheetItemHeight + 0.5), width: self.view.bounds.width, height: PhotosSheet.actionSheetItemHeight)
        }

        _sendPhotoBtn.frame = CGRect(x: 0, y: _photosDisplayViewHeight, width: view.bounds.width, height: PhotosSheet.actionSheetItemHeight)
    }
}

fileprivate extension PhotosSheet.ContentController {
    func _switchToShowSendButton(assetsCount: Int) {
        let isShow = assetsCount > 0
        // 必须当ActionSheet至少有一个Action的时候才显示发送按钮
        if let firstItem = _normalActionItems.first {
            if !isShow {
                firstItem.isHidden = false
                _sendPhotoBtn.isHidden = true
            } else {
                firstItem.isHidden = true
                _sendPhotoBtn.isHidden = false
            }
            let assetsCountString = assetsCount > 1 ? "(\(assetsCount))" : ""
            _sendPhotoBtn.setTitle("Send"._localizedString + assetsCountString, for: .normal)
        }
    }

    func _sendPhotosAction() {
        guard self._checkCanSendPhoto() else { return }
        let assets = selectedModels.map { $0.asset }
        didSelectedAssets?(assets)
        if let didSelectedImages = didSelectedImages {
            assets.fetchImages(on: _imagesLoadingQueue, completionHandle: { [weak self] in
                didSelectedImages($0)
                self?._dismiss()
            })
        } else {
            _dismiss()
        }
    }

    // Check
    func _checkCanSendPhoto() -> Bool {
        var isOK = true
        for model in selectedModels {
            if !model.isDownloadCompleted {
                isOK = false
                break
            }
        }
        if !isOK {
            let alertController = UIAlertController(title: "Fetching photos from iCloud"._localizedString, message: nil, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Confirm"._localizedString, style: .default, handler: nil))
            present(alertController, animated: true, completion: nil)
        }
        return isOK
    }
}

extension PhotosSheet.ContentController {
    func show(from viewController: UIViewController) {
        let height = _expectHeight
        let expireY = viewController.view.bounds.height - PhotosSheet.actionSheetVerticalMargin - height
        view.frame = CGRect(x: PhotosSheet.actionSheetHorizontalMargin, y: viewController.view.bounds.height, width: viewController.view.bounds.width - 2 * PhotosSheet.actionSheetHorizontalMargin, height: height)
        viewController.addChildViewController(self)
        viewController.view.addSubview(view)
        UIView.animate(withDuration: 0.25) {
            self.view.frame.origin.y = expireY
        }
    }

    func hide() {
        guard let superview = view.superview else { return }
        UIView.animate(withDuration: 0.25, animations: {
            self.view.frame.origin.y = superview.bounds.height
        }) { _ in
            self.view.removeFromSuperview()
        }
    }
}

// MARK: - PhotosDisplayController
extension PhotosSheet {
    final class PhotosDisplayController: UIViewController {
        var photosSelected: (([PhotosProvider.Model]) -> ())?

        fileprivate let _displayedPhotosLimit: Int
        fileprivate let _selectedPhotosLimit: Int

        init(displayedPhotosLimit: Int, selectedPhotosLimit: Int) {
            _displayedPhotosLimit = displayedPhotosLimit
            _selectedPhotosLimit = selectedPhotosLimit
            super.init(nibName: nil, bundle: nil)
        }

        override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
            _displayedPhotosLimit = 0
            _selectedPhotosLimit = 0
            super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        fileprivate lazy var _photosDisplayView: UICollectionView = {
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

        fileprivate lazy var _photosProvider: PhotosSheet.PhotosProvider = {
            let provider = PhotosProvider(collectionView: self._photosDisplayView, displayedPhotosLimit: self._displayedPhotosLimit, selectedPhotosLimit: self._selectedPhotosLimit)
            return provider
        }()
    }
}

extension PhotosSheet.PhotosDisplayController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.clear
        view.addSubview(_photosDisplayView)
        _photosProvider.changeSelectedModels = { [weak self] models in
            self?.photosSelected?(models)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 放在下一个Runloop周期，对所有显示出来的CollectionViewCell中的Checkbox进行布局
        DispatchQueue.main.async {
            self._photosDisplayView.delegate?.scrollViewDidScroll?(self._photosDisplayView)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        _photosDisplayView.frame = view.bounds
    }
}

// MARK: - PhotoItemView
extension PhotosSheet {
    final class PhotoItemView: UICollectionViewCell {

        fileprivate var _preRequestId: PHImageRequestID?
        fileprivate var _hideCheckbox = false

        lazy var hideCheckbox: (Bool) -> () = {
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
            contentView.addSubview(progressView)
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        var model: PhotosProvider.Model? {
            didSet {
                guard let model = model, oldValue != model else { return }
                // 加载缩略图
                _preRequestId = PhotosManager.shared.fetchPhoto(with: model.asset, type: .thumbnail(height: photoItemHeight, progressHandler: { _, _ in }), completion: { [weak self] image in
                    // 会走两次，第一次是获取本地质量略差的缩略图，第二次是获取Cloud质量不错的缩略图
                    self?.mContentView.image = image
                })
                _setupCheckbox(isModelSelected: model.didSelected)
                model.didChangedSelected = { [weak self] didSelected in
                    self?._setupCheckbox(isModelSelected: didSelected)
                    if didSelected { self?.model?.downloadAssetFromCloud() }
                }
                _listenAssetDownloadProgress()
                checkbox.isHidden = !model.didSelected && _hideCheckbox
            }
        }

        // 针对从ICloud下载原图
        fileprivate func _listenAssetDownloadProgress() {
            model?.downloadProgressCallback = { [weak self] downloadProgress in
                self?.progressView.progress = downloadProgress
                self?.progressView.isHidden = downloadProgress >= 1
            }
        }

        fileprivate func _cancelListenAssetDownloadProgress() {
            model?.downloadProgressCallback = nil
            progressView.progress = 0
            progressView.isHidden = false
        }

        fileprivate func _setupCheckbox(isModelSelected: Bool) {
            let checkboxImage = isModelSelected ? UIImage(named: "selection-mark-selected", in: Bundle._myBundle, compatibleWith: nil) : UIImage(named: "selection-mark-normal", in: Bundle._myBundle, compatibleWith: nil)
            checkbox.image = checkboxImage
        }

        override func prepareForReuse() {
            super.prepareForReuse()
            if let preRequestId = _preRequestId {
                PHImageManager.default().cancelImageRequest(preRequestId)
            }
            _cancelListenAssetDownloadProgress()
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
            progressView.center = CGPoint(x: 0.5 * bounds.width, y: 0.5 * bounds.height)
        }

        lazy private(set) var mContentView: UIImageView = {
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFill
            imageView.layer.masksToBounds = true
            return imageView
        }()

        lazy private(set) var checkbox: UIImageView = {
            let view = UIImageView()
            view.image = UIImage(named: "selection-mark-normal", in: Bundle._myBundle, compatibleWith: nil)
            return view
        }()

        lazy private(set) var progressView: DownloadProgressView = {
            let size = CGSize(width: 40, height: 40)
            return DownloadProgressView(frame: CGRect(origin: .zero, size: size), lineWidth: 4)
        }()
    }
}

// MARK: - DownloadProgressView
extension PhotosSheet {
    final class DownloadProgressView: UIView {
        fileprivate let _lineWidth: CGFloat

        init(frame: CGRect, lineWidth: CGFloat) {
            _lineWidth = lineWidth
            super.init(frame: frame)
            backgroundColor = .clear
            layer.shadowColor = UIColor.black.cgColor
            layer.shadowRadius = 2
            layer.shadowOpacity = 0.2
            layer.shadowOffset = CGSize(width: 1, height: 1)
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            layer.addSublayer(_circle)
        }

        var progress: Double = 0 {
            didSet {
                _circle.strokeEnd = CGFloat(self.progress)
            }
        }

        fileprivate lazy var _circlePath: UIBezierPath = {
            return UIBezierPath(arcCenter: CGPoint(x: 0.5 * self.bounds.size.width, y: 0.5 * self.bounds.size.height),
                                radius: 0.5 * (self.bounds.size.width - 2 * self._lineWidth),
                                startAngle: -0.5 * CGFloat.pi,
                                endAngle: 2 * CGFloat.pi - 0.5 * CGFloat.pi,
                                clockwise: true)
        }()

        fileprivate lazy var _circle: CAShapeLayer = {
            let circle = CAShapeLayer()
            circle.frame = self.layer.bounds
            circle.path = self._circlePath.cgPath
            circle.lineCap = kCALineCapRound
            circle.fillColor = UIColor.clear.cgColor
            circle.strokeColor = UIColor.white.cgColor
            circle.strokeStart = 0
            circle.strokeEnd = 0
            circle.zPosition = 1
            circle.lineWidth = self._lineWidth
            return circle
        }()
    }
}

extension PhotosSheet.PhotoItemView: PhotosDisplayViewContentOffsetObserver {
    func displayView(_ displayView: UICollectionView, onContentOffsetChange contentOffset: CGPoint) {
        let displayViewWidth = displayView.bounds.width
        let x = min(max(displayViewWidth - (frame.origin.x - contentOffset.x) - checkbox.bounds.width - PhotosSheet.photoItemCheckboxRightMargin, PhotosSheet.photoItemCheckboxRightMargin), bounds.width - checkbox.bounds.width - PhotosSheet.photoItemCheckboxBottomMargin)
        checkbox.frame.origin.x = x
    }
}

// MARK: - PhotosProvider
fileprivate let photoItemHeight = PhotosSheet.photoItemHeight
extension PhotosSheet {
    final class PhotosProvider: NSObject, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
        fileprivate var _models: [Model] = []
        fileprivate var _assets: [PHAsset] = []
        fileprivate var _selectedModels: [Model] = [] {
            didSet {
                changeSelectedModels?(_selectedModels)
            }
        }
        var changeSelectedModels: (([Model]) -> ())?
        fileprivate weak var _collectionView: UICollectionView?
        // Observers
        fileprivate var _contentOffsetObserbers: Set<PhotoItemView> = Set()
        // Hide CheckBox Event
        fileprivate var _hideCheckBoxEvents: [UICollectionViewCell: (Bool) -> ()] = [:]
        // PhotosCount
        fileprivate let _displayedPhotosLimit: Int
        fileprivate let _selectedPhotosLimit: Int

        init(collectionView: UICollectionView, displayedPhotosLimit: Int, selectedPhotosLimit: Int) {
            _displayedPhotosLimit = displayedPhotosLimit
            _selectedPhotosLimit = selectedPhotosLimit
            super.init()
            _collectionView = collectionView
            collectionView.dataSource = self
            collectionView.delegate = self
            collectionView.register(PhotosSheet.PhotoItemView.self, forCellWithReuseIdentifier: "PhotoItem")

            _loadAssets()
        }
    }
}

fileprivate extension PhotosSheet.PhotosProvider {
    func _loadAssets() {
        DispatchQueue.global().async { [weak self] in
            let assets = PhotosSheet.PhotosManager.shared.obtainRecentAssets(limit: self?._displayedPhotosLimit ?? 0)
            self?._assets = assets
            DispatchQueue.main.async { [weak self] in
                self?._models = assets.map(Model.init)
                self?._collectionView?.reloadData()
            }
        }
    }
}

// MARK: - PhotosProvider.Model
extension PhotosSheet.PhotosProvider {
    class Model {
        let asset: PHAsset
        fileprivate(set) var isDownloadCompleted: Bool = false
        fileprivate(set) var downloadTask: PHImageRequestID?
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
            cancelDownload()
        }
    }
}

extension PhotosSheet.PhotosProvider.Model: Hashable {
    var hashValue: Int {
        return asset.hashValue
    }

    static func ==(lhs: PhotosSheet.PhotosProvider.Model, rhs: PhotosSheet.PhotosProvider.Model) -> Bool {
        return lhs.asset == rhs.asset
    }
}

extension PhotosSheet.PhotosProvider.Model {
    func downloadAssetFromCloud() {
        guard downloadTask == nil else { return }
        downloadTask = PhotosSheet.PhotosManager.shared.fetchPhoto(with: asset, type: .original(progressHandler: { [weak self] progress, _ in
            DispatchQueue.main.async {
                self?.downloadProgressCallback?(progress)
            }
        })) { [weak self] _ in self?.isDownloadCompleted = true }
    }

    func cancelDownload() {
        if let downloadTask = downloadTask {
            PHImageManager.default().cancelImageRequest(downloadTask)
        }
    }
}

// MARK: - PhotosProvider.DataSource
extension PhotosSheet.PhotosProvider {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return _models.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoItem", for: indexPath) as! PhotosSheet.PhotoItemView
        cell.model = _models[indexPath.row]
        _contentOffsetObserbers.insert(cell)
        if _hideCheckBoxEvents[cell] == nil {
            _hideCheckBoxEvents[cell] = cell.hideCheckbox
        }
        return cell
    }
}

// MARK: - PhotosProvider.Layout
extension PhotosSheet.PhotosProvider {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let asset = _models[indexPath.row].asset
        let ratio = max(CGFloat(asset.pixelWidth) / CGFloat(asset.pixelHeight), 0)
        let maxWidth = collectionView.bounds.width - 20
        return CGSize(width: min(photoItemHeight * ratio, maxWidth), height: photoItemHeight)
    }
}

// MARK: - PhotosProvider.Delegate
protocol PhotosDisplayViewContentOffsetObserver: Hashable {
    func displayView(_ displayView: UICollectionView, onContentOffsetChange contentOffset: CGPoint)
}

extension PhotosSheet.PhotosProvider {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        _contentOffsetObserbers.forEach { $0.displayView(scrollView as! UICollectionView, onContentOffsetChange: scrollView.contentOffset) }
    }
}

// MARK: - PhotosProvider.Event
extension PhotosSheet.PhotosProvider {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let model = _models[indexPath.row]
        if !model.didSelected && _models.filter({ $0.didSelected }).count >= _selectedPhotosLimit { return }
        model.didSelected = !model.didSelected
        if model.didSelected {
            _selectedModels.append(model)
        } else {
            if let index = _selectedModels.index(of: model) {
                _selectedModels.remove(at: index)
            }
        }
        _hideCheckBoxEvents.values.forEach {
            $0(_selectedModels.count >= _selectedPhotosLimit)
        }
    }
}

// MARK: - PhotosManager
extension PhotosSheet {
    final class PhotosManager {
        static let shared = PhotosManager()
        init() { }
    }
}

extension PhotosSheet.PhotosManager {
    // ResultImage, Info, IsDegraded
    typealias ImageRequestCompletion = (UIImage) -> ()
    // Progress, Error, Stop, Info
    typealias ImageDownloadProgressHandler = (Double, UnsafeMutablePointer<ObjCBool>) -> ()

    @discardableResult
    func fetchPhoto(with asset: PHAsset, type: PhotoFetchType, isSynchronous: Bool = false, completion: @escaping ImageRequestCompletion) -> PHImageRequestID {
        let option = PHImageRequestOptions()
        option.isSynchronous = isSynchronous
        let targetSize: CGSize
        switch type {
        case let .thumbnail(height, progressHandler):
            let ratio = CGFloat(asset.pixelWidth) / CGFloat(asset.pixelHeight)
            let scale = UIScreen.main.scale
            targetSize = CGSize(width: height * ratio * scale, height: height * scale)
            option.resizeMode = .fast
            option.deliveryMode = .opportunistic
            option.isNetworkAccessAllowed = true
            option.progressHandler = { progress, _, stop, _ in
                progressHandler(progress, stop)
            }
        case let .original(progressHandler):
            option.deliveryMode = .highQualityFormat
            option.isNetworkAccessAllowed = true
            option.progressHandler = { progress, _, stop, _ in
                progressHandler(progress, stop)
            }
            targetSize = PHImageManagerMaximumSize
        }

        if asset.representsBurst {
            return PHImageManager.default().requestImageData(for: asset, options: option, resultHandler: { data, _, _, info in
                guard let info = info else { return }
                let fetchSucceed = !(info[PHImageCancelledKey] as? Bool ?? false) && info[PHImageErrorKey] == nil
                guard let data = data, let image = UIImage(data: data), fetchSucceed else { return }
                if targetSize != PHImageManagerMaximumSize {
                    if let retImage = image._scaleTo(size: targetSize) {
                        completion(retImage)
                    }
                } else {
                    completion(image)
                }
            })
        } else {
            return PHImageManager.default().requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: option, resultHandler: { image, info in
                guard let info = info else { return }
                let fetchSucceed = !(info[PHImageCancelledKey] as? Bool ?? false) && info[PHImageErrorKey] == nil
                guard let image = image, fetchSucceed else { return }
                completion(image)
            })
        }
    }
}

extension PhotosSheet.PhotosManager {
    enum PhotoFetchType {
        case thumbnail(height: CGFloat, progressHandler: ImageDownloadProgressHandler)
        case original(progressHandler: ImageDownloadProgressHandler)
    }
}

extension PhotosSheet.PhotosManager {
    func obtainRecentAssets(limit: Int = 0) -> [PHAsset] {
        let fetchOption = PHFetchOptions()
        fetchOption.includeAssetSourceTypes = [.typeUserLibrary]
        // TODO: Support more media type
        fetchOption.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchOption.sortDescriptors = [sortDescriptor]
        if limit > 0 {
            fetchOption.fetchLimit = limit
        }
        let results = PHAsset.fetchAssets(with: fetchOption)
        return results.objects(at: IndexSet(0 ..< results.count))
    }
}

// MARK: - UI Setting
fileprivate extension PhotosSheet {
    fileprivate(set) static var photoItemCheckboxRightMargin: CGFloat = 5
    fileprivate(set) static var photoItemCheckboxBottomMargin: CGFloat = 5
    fileprivate(set) static var photoItemHeight: CGFloat = (UIScreen.main.bounds.width - 2 * PhotosSheet.actionSheetHorizontalMargin) * 0.7
    fileprivate(set) static var actionSheetFont = UIFont.systemFont(ofSize: 20)
    fileprivate(set) static var actionSheetCorners: CGFloat = 12
    fileprivate(set) static var actionSheetHorizontalMargin: CGFloat = 10
    fileprivate(set) static var actionSheetVerticalMargin: CGFloat = 8
    fileprivate(set) static var actionSheetItemHeight: CGFloat = 57
}

fileprivate extension PhotosSheet {
    static func _setupUI(options: Set<UIOption>) {
        func pair(option: UIOption) {
            switch option {
            case .photoItemCheckboxRightMargin(let value):
                photoItemCheckboxRightMargin = value
            case .photoItemCheckboxBottomMargin(let value):
                photoItemCheckboxBottomMargin = value
            case .photoItemHeight(let value):
                photoItemHeight = value
            case .actionSheetFont(let value):
                actionSheetFont = value
            case .actionSheetCorners(let value):
                actionSheetCorners = value
            case .actionSheetHorizontalMargin(let value):
                actionSheetHorizontalMargin = value
            case .actionSheetVerticalMargin(let value):
                actionSheetVerticalMargin = value
            case .actionSheetItemHeight(let value):
                actionSheetItemHeight = value
            }
        }

        options.forEach(pair)
    }
}

// MARK: - Tools
fileprivate extension UIImage {
    func _scaleTo(size: CGSize) -> UIImage? {
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

fileprivate extension Array where Element == PHAsset {
    func fetchImages(on queue: DispatchQueue, completionHandle: @escaping ([UIImage]) -> ()) {
        queue.async {
            var images: [UIImage] = []
            self.forEach { asset in
                PhotosSheet.PhotosManager.shared.fetchPhoto(with: asset, type: .original(progressHandler: { _, _ in }), isSynchronous: true, completion: { image in
                    images.append(image)
                })
            }
            DispatchQueue.main.async {
                completionHandle(images)
            }
        }
    }
}

fileprivate extension Bundle {
    static var _myBundle: Bundle {
        return Bundle(for: PhotosSheet.self)
    }
}

fileprivate extension String {
    var _localizedString: String {
        return NSLocalizedString(self, bundle: Bundle._myBundle, comment: "")
    }
}
