//
//  ViewController.swift
//  Sample
//
//  Created by Tan on 2017/8/13.
//
//

import UIKit
import PhotosSheet

class ViewController: UIViewController {

    @IBOutlet weak var imagesCollectionView: UICollectionView!
    @IBOutlet weak var showBtn: UIButton!

    fileprivate var _images: [UIImage] = [] {
        didSet {
            imagesCollectionView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showBtn.addTarget(self, action: #selector(ViewController.showSheet), for: .touchUpInside)
        imagesCollectionView.delegate = self
        imagesCollectionView.dataSource = self
        imagesCollectionView.register(ImageItem.self, forCellWithReuseIdentifier: String(describing: ImageItem.self))
    }

    @objc func showSheet() {
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
    }
}

extension ViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let height: CGFloat = 200
        return CGSize(width: collectionView.bounds.width, height: height)
    }

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
