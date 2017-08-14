//
//  PhotosSheet.swift
//  PhotosSheet
//
//  Created by Tan on 2017/8/13.
//
//

import UIKit
import Photos

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
    ///   - didSelectedPhotos: Called after you have selected the photos.
    public init(actions: [PhotosSheet.Action],
                displayedPhotosLimit: Int = 0,
                selectedPhotosLimit: Int = 9,
                options: Set<UIOption>? = nil,
                didSelectedPhotos: @escaping ([(PHAsset, UIImage)]) -> ()) {
        // SetupUI
        if let options = options {
            PhotosSheet.setupUI(options: options)
        }
        self.actions = actions
        _contentController = ContentController(actions: actions, displayedPhotosLimit: displayedPhotosLimit, selectedPhotosLimit: selectedPhotosLimit)
        _contentController.didSelectedPhotos = didSelectedPhotos
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overCurrentContext
        modalTransitionStyle = .crossDissolve
    }

    /// Init an action sheet with photos on it.
    ///
    /// - Parameters:
    ///   - actions: Actions in action sheet.
    ///   - displayedPhotosLimit: The max count of photos displayed, default is `0`, means unlimited.
    ///   - selectedPhotosLimit: The max count of photos that can be selected, default is `9`.
    ///   - options: UI options. See `UIOption`
    ///   - didSelectedAssets: Called after you have selected the photos. Output `PHAssets`
    public convenience init(actions: [PhotosSheet.Action],
                displayedPhotosLimit: Int = 0,
                selectedPhotosLimit: Int = 9,
                options: Set<UIOption>? = nil,
                didSelectedAssets: @escaping ([PHAsset]) -> ()) {
        self.init(actions: actions, displayedPhotosLimit: displayedPhotosLimit, selectedPhotosLimit: selectedPhotosLimit, options: options) { didSelectedAssets($0.map { $0.0 }) }
    }

    /// Init an action sheet with photos on it.
    ///
    /// - Parameters:
    ///   - actions: Actions in action sheet.
    ///   - displayedPhotosLimit: The max count of photos displayed, default is `0`, means unlimited.
    ///   - selectedPhotosLimit: The max count of photos that can be selected, default is `9`.
    ///   - options: UI options. See `UIOption`
    ///   - didSelectedPhotos: Called after you have selected the photos. Output `UIImage`
    public convenience init(actions: [PhotosSheet.Action],
                displayedPhotosLimit: Int = 0,
                selectedPhotosLimit: Int = 9,
                options: Set<UIOption>? = nil,
                didSelectedImages: @escaping ([UIImage]) -> ()) {
        self.init(actions: actions, displayedPhotosLimit: displayedPhotosLimit, selectedPhotosLimit: selectedPhotosLimit, options: options) { didSelectedImages($0.map { $0.1 }) }
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        actions = []
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Controllers & Views
    fileprivate var _contentController: ContentController!

    fileprivate lazy var _progressViewController: ProgressViewController = {
        let viewController = ProgressViewController()
        viewController.view.alpha = 0
        return viewController
    }()

    fileprivate lazy var _backgroundView: UIButton = {
        let view = UIButton()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        view.addTarget(self, action: #selector(PhotosSheet._dismiss), for: .touchUpInside)
        return view
    }()

    @objc fileprivate func _dismiss() {
        dismiss(animated: true, completion: nil)
    }
}

public extension PhotosSheet {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(_backgroundView)

        // Handle ContentController callbacks
        _contentController.dismissCallback = { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }

        _contentController.showProgressViewControllerCallback = { [weak self] in
            guard let `self` = self else { return }
            self.addChildViewController(self._progressViewController)
            self.view.addSubview(self._progressViewController.view)
            UIView.animate(withDuration: 0.25, animations: {
                self._progressViewController.view.alpha = 1
            })
        }

        _contentController.progressUpdateCallback = { [weak self] in
            self?._progressViewController.progress = $0
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
}
