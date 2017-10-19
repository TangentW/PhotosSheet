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
                didSelectedOriginalAssets: @escaping ([PHAsset], Bool) -> ()) {
        // SetupUI
        if let options = options {
            PhotosSheet.setupUI(options: options)
        }
        self.actions = actions
        _contentController = ContentController(mediaOption: mediaOption,
                                               actions: actions,
                                               displayedPhotosLimit: displayedPhotosLimit,
                                               selectedPhotosLimit: selectedPhotosLimit)
        _contentController.didSelectedAssets = didSelectedOriginalAssets
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overCurrentContext
        modalTransitionStyle = .crossDissolve
    }

    /// Init an action sheet with photos on it.
    ///
    /// - Parameters:
    ///   - actions: Actions in action sheet.
    ///   - mediaOption: The media option of the asset you want to select.
    ///   - displayedPhotosLimit: The max count of photos displayed, default is `0`, means unlimited.
    ///   - selectedPhotosLimit: The max count of photos that can be selected, default is `9`.
    ///   - options: UI options. See `UIOption`
    ///   - didSelectedAssets: Called after you have selected the photos.
    public convenience init(actions: [PhotosSheet.Action],
                mediaOption: MediaOption = .all,
                displayedPhotosLimit: Int = 0,
                selectedPhotosLimit: Int = 9,
                options: Set<UIOption>? = nil,
                didSelectedAssets: @escaping ([PHAsset]) -> ()) {
        self.init(actions: actions, mediaOption: mediaOption, displayedPhotosLimit: displayedPhotosLimit, selectedPhotosLimit: selectedPhotosLimit, options: options) { assets, _ in didSelectedAssets(assets) }
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
            self._progressViewController.didMove(toParentViewController: self)
            self.view.addSubview(self._progressViewController.view)
            UIView.animate(withDuration: 0.25, animations: {
                self._progressViewController.view.alpha = 1
            })
        }

        _contentController.dismissProgressViewControllerCallback = { [weak self] in
            UIView.animate(withDuration: 0.25, animations: { 
                self?._progressViewController.view.alpha = 0
            }) { _ in
                self?._progressViewController.view.removeFromSuperview()
                self?._progressViewController.willMove(toParentViewController: nil)
                self?._progressViewController.removeFromParentViewController()
            }
        }

        _contentController.progressUpdateCallback = { [weak self] in
            self?._progressViewController.progress = $0
        }

        // Handle ProgressViewController callbacks
        _progressViewController.cancelCallback = { [weak self] _ in
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
public extension PhotosSheet {
    struct Action {
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

    enum ActionStyle {
        case normal
        case cancel
    }
}

// MARK: - Media Type
public extension PhotosSheet {
    struct MediaOption: OptionSet {
        public let rawValue: Int
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public static let photo = MediaOption(rawValue: 1 << 0)
        public static let video = MediaOption(rawValue: 1 << 1)
        public static let all: MediaOption = [.photo, .video]
    }
}

// MARK: - Sending Action
public extension PhotosSheet {
    typealias SendingActionFilter = ([PHAsset], Bool, @escaping () -> ()) -> ()
}
