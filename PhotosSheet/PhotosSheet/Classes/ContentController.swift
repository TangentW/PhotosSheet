//
//  ContentController.swift
//  PhotosSheet
//
//  Created by Tan on 2017/8/14.
//

import UIKit
import Photos

// MARK: - ContentController
extension PhotosSheet {
    final class ContentController: UIViewController {
        fileprivate let _mediaOption: MediaOption
        fileprivate let _normalActionItems: [ActionItem]
        fileprivate let _cancelActionItems: [ActionItem]

        var isShowSendOriginalsButton = false
        var sendingActionFilter: PhotosSheet.SendingActionFilter?

        // Callback
        var dismissCallback: (() -> ())?
        var showProgressViewControllerCallback: (() -> ())?
        var dismissProgressViewControllerCallback: (() -> ())?
        var progressUpdateCallback: ((Double) -> ())?

        fileprivate var _selectedModels: [Model] = []
        var didSelectedAssets: (([PHAsset], Bool) -> ())?

        // WorkItem For Fetching Photos
        fileprivate var _photosFetchingWorkItem: DispatchWorkItem?

        fileprivate let _displayedPhotosLimit: Int
        fileprivate let _selectedPhotosLimit: Int

        fileprivate var _photosDisplayViewHeight: CGFloat = UIApplication.shared.statusBarOrientation == .portrait
            ? PhotosSheet.photoItemHeight : 0

        init(mediaOption: MediaOption, actions: [Action], displayedPhotosLimit: Int, selectedPhotosLimit: Int) {
            _mediaOption = mediaOption
            _displayedPhotosLimit = displayedPhotosLimit
            _selectedPhotosLimit = selectedPhotosLimit
            _normalActionItems = actions.filter { $0.style == .normal }.map(ActionItem.init)
            _cancelActionItems = actions.filter { $0.style == .cancel }.map(ActionItem.init)
            super.init(nibName: nil, bundle: nil)
        }

        deinit {
            _photosFetchingWorkItem?.cancel()
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
            view.autoresizingMask = [.flexibleTopMargin, .flexibleWidth]
            _setupViews()
            _setupGestureRecognizer()
            _photosProvider.changeSelectedModels = { [weak self] models in
                self?._switchToShowSendButton(models: models)
                self?._selectedModels = models
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

        // Send Photo Button
        fileprivate lazy var _sendPhotoBtn: ActionItem = {
            let firstItemColor = self._normalActionItems.first?._action.tintColor ?? .green
            let action = Action(title: "Send".localizedString, tintColor: firstItemColor, action: { [weak self] in
                self?._sendBtnAction(isSendingOriginals: false)
            })
            let view = ActionItem(action: action)
            view.isHidden = true
            return view
        }()

        fileprivate lazy var _sendOriginalsBtn: ActionItem = {
            let firstItemColor = self._normalActionItems.first?._action.tintColor ?? .green
            let action = Action(title: "Send Originals".localizedString, tintColor: firstItemColor, action: { [weak self] in
                self?._sendBtnAction(isSendingOriginals: true)
            })
            let view = ActionItem(action: action)
            view.isHidden = true
            view.titleLabel?.numberOfLines = 2
            view.titleLabel?.lineBreakMode = .byWordWrapping
            return view
        }()

        // PhotosDisplayController
        fileprivate lazy var _photosDisplayController: PhotosDisplayController = {
            return PhotosDisplayController()
        }()

        // PhotosProvider
        fileprivate lazy var _photosProvider: PhotosProvider = {
            return PhotosProvider(collectionView: self._photosDisplayController.photosDisplayView, mediaOption: self._mediaOption, displayedPhotosLimit: self._displayedPhotosLimit, selectedPhotosLimit: self._selectedPhotosLimit)
        }()

        // GestureReconizer, Handle Items's Event
        @objc fileprivate func _listenFor(panGestureReconizer: UIPanGestureRecognizer) {
            let location = panGestureReconizer.location(in: view)
            let items = (_normalActionItems + _cancelActionItems + [_sendPhotoBtn, _sendOriginalsBtn]).filter { !$0.isHidden }
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
        _photosDisplayController.didMove(toParentViewController: self)
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
            if isShowSendOriginalsButton {
                _contentViewForNormal.addSubview(_sendOriginalsBtn)
            }
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

        if isShowSendOriginalsButton {
            _sendPhotoBtn.frame = CGRect(x: 0, y: _photosDisplayViewHeight, width: 0.5 * view.bounds.width - 0.25, height: PhotosSheet.actionSheetItemHeight)
            _sendOriginalsBtn.frame = CGRect(x: 0.5 * view.bounds.width + 0.25, y: _photosDisplayViewHeight, width: 0.5 * view.bounds.width - 0.25, height: PhotosSheet.actionSheetItemHeight)
        } else {
            _sendPhotoBtn.frame = CGRect(x: 0, y: _photosDisplayViewHeight, width: view.bounds.width, height: PhotosSheet.actionSheetItemHeight)
        }
    }
}

// MARK: - Events
fileprivate extension PhotosSheet.ContentController {
    func _switchToShowSendButton(models: [PhotosSheet.Model]) {
        let assetsCount = models.count
        let isShow = assetsCount > 0
        // Show send button when actions count greater than zero
        if let firstItem = _normalActionItems.first {
            if !isShow {
                firstItem.isHidden = false
                _sendPhotoBtn.isHidden = true
                _sendOriginalsBtn.isHidden = true
            } else {
                firstItem.isHidden = true
                _sendPhotoBtn.isHidden = false
                _sendOriginalsBtn.isHidden = false
            }
            let assetsCountString = assetsCount > 1 ? "(\(assetsCount))" : ""
            _sendPhotoBtn.setTitle("Send".localizedString + assetsCountString, for: .normal)
            _sendOriginalsBtn.setTitle("Send Originals".localizedString + assetsCountString, for: .normal)
        }
    }

    func _sendBtnAction(isSendingOriginals: Bool) {
        showProgressViewControllerCallback?()
        _setupProgressListening()
        _photosFetchingWorkItem = _selectedModels.fetchVideosAndImages { [weak self] assets in
            self?.progressUpdateCallback?(1)
            self?.dismissProgressViewControllerCallback?()
            self?._sendPhotosAction(assets: assets, isSendingOriginals: isSendingOriginals)
        }
    }

    func _sendPhotosAction(assets: [PHAsset], isSendingOriginals: Bool) {
        // Create sending handler.
        let sendingHandler = { [weak self] in
            self?.didSelectedAssets?(assets, isSendingOriginals)
            self?._dismiss()
        }
        // Call filter.
        if let filter = sendingActionFilter {
            filter(assets, isSendingOriginals, sendingHandler)
        } else {
            sendingHandler()
        }
    }

    func _setupProgressListening() {
        var progressMap: [PhotosSheet.Model: Double] = _selectedModels.reduce([:]) {
            var p = $0; p[$1] = 0; return p
        }
        _selectedModels.forEach { model in
            model.downloadProgressCallback = { [weak self] in
                progressMap[model] = $0
                let totalProgress: Double = progressMap.reduce(0) { $0 + $1.value } / Double(progressMap.count)
                // Update Progress
                self?.progressUpdateCallback?(max(0.15, totalProgress))
            }
        }
    }
}

extension PhotosSheet.ContentController {
    func show(from viewController: UIViewController) {
        let height = _expectHeight
        var bottomSafeAreaInset: CGFloat = 0
        if #available(iOS 11, *) {
            bottomSafeAreaInset = viewController.presentingViewController?.view.safeAreaInsets.bottom ?? 0
        }
        let expireY = viewController.view.bounds.height - PhotosSheet.actionSheetVerticalMargin - height - bottomSafeAreaInset
        view.frame = CGRect(x: PhotosSheet.actionSheetHorizontalMargin, y: viewController.view.bounds.height, width: viewController.view.bounds.width - 2 * PhotosSheet.actionSheetHorizontalMargin, height: height)
        viewController.addChildViewController(self)
        didMove(toParentViewController: viewController)
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

// MARK: - ItemView
extension PhotosSheet.ContentController {
    final class ActionItem: UIButton {
        fileprivate let _action: PhotosSheet.Action

        init(action: PhotosSheet.Action) {
            _action = action
            super.init(frame: .zero)
            backgroundColor = UIColor.white.withAlphaComponent(0.9)
            setTitle(_action.title, for: .normal)
            setTitleColor(_action.tintColor, for: .normal)
            titleLabel?.font = PhotosSheet.actionSheetFont
            self.autoresizingMask = .flexibleWidth
            addTarget(self, action: #selector(ActionItem.doAction), for: .touchUpInside)
            addTarget(self, action: #selector(ActionItem.switchToActive), for: .touchDown)
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
