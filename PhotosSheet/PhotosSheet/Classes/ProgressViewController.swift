//
//  ProgressViewController.swift
//  PhotosSheet
//
//  Created by Tan on 2017/8/14.
//

import UIKit

fileprivate let progressContentViewSize = CGSize(width: 140, height: 140)
fileprivate let progressViewSize = CGSize(width: 100, height: 100)

final class ProgressViewController: UIViewController {
    init() {
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overCurrentContext
        modalTransitionStyle = .crossDissolve
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    fileprivate lazy var _contentView: UIVisualEffectView = {
        let view = UIVisualEffectView(effect: self._contentViewEffect)
        view.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        view.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin, .flexibleLeftMargin, .flexibleRightMargin]
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 9
        return view
    }()

    fileprivate lazy var _cancelBtn: UIButton = {
        let button = UIButton()
        button.setTitle("Cancel".localizedString, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16)
        button.addTarget(self, action: #selector(ProgressViewController._cancel), for: .touchUpInside)
        button.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
        return button
    }()

    fileprivate lazy var _contentViewEffect: UIVisualEffect = {
        return UIBlurEffect(style: .light)
    }()

    fileprivate lazy var _progressView = DownloadProgressView(frame: CGRect(origin: .zero, size: progressViewSize), lineWidth: 5)

    fileprivate lazy var _blurView: UIView = {
        let view = UIView()
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.backgroundColor = .black
        view.alpha = 0.4
        return view
    }()

    var progress: Double = 0 {
        didSet {
            _progressView.progress = progress
        }
    }

    var cancelCallback: ((ProgressViewController) -> ())?

    @objc fileprivate func _cancel() {
        cancelCallback?(self)
    }
}

extension ProgressViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        view.addSubview(_blurView)
        view.addSubview(_contentView)
        view.addSubview(_cancelBtn)
        _contentView.contentView.addSubview(_progressView)
        _contentView.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        _blurView.frame = view.bounds
        _contentView.frame.size = progressContentViewSize
        _contentView.center = CGPoint(x: 0.5 * view.bounds.width, y: 0.5 * view.bounds.height)
        _progressView.center = CGPoint(x: 0.5 * _contentView.bounds.width, y: 0.5 * _contentView.bounds.height)
        _cancelBtn.sizeToFit()
        _cancelBtn.center.x = 0.5 * view.bounds.width
        _cancelBtn.frame.origin.y = _contentView.frame.maxY + 8
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIView.animate(withDuration: 0.25) {
            self._contentView.transform = .identity
        }
    }
}

// MARK: - DownloadProgressView
extension ProgressViewController {
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
