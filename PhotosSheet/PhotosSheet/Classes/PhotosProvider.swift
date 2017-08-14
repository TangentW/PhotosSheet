//
//  PhotosProvider.swift
//  PhotosSheet
//
//  Created by Tan on 2017/8/14.
//

import UIKit
import Photos

// MARK: - PhotosProvider
fileprivate let photoItemHeight = PhotosSheet.photoItemHeight
extension PhotosSheet {
    final class PhotosProvider: NSObject, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
        fileprivate var _models: [Model] = []
        fileprivate var _selectedModels: [Model] = [] {
            didSet {
                changeSelectedModels?(_selectedModels)
            }
        }
        var changeSelectedModels: (([Model]) -> ())?
        fileprivate weak var _collectionView: UICollectionView?
        // Observers
        fileprivate var _contentOffsetObserbers: Set<PhotosDisplayController.PhotoItemView> = Set()
        // Hide CheckBox Event
        fileprivate var _hideCheckBoxEvents: [UICollectionViewCell: (Bool) -> ()] = [:]
        // PhotosCount
        fileprivate let _displayedPhotosLimit: Int
        fileprivate let _selectedPhotosLimit: Int

        init(collectionView: UICollectionView, displayedPhotosLimit: Int, selectedPhotosLimit: Int) {
            _displayedPhotosLimit = displayedPhotosLimit
            _selectedPhotosLimit = selectedPhotosLimit
            super.init()
            _setupCollectionView(collectionView: collectionView)
            _loadAssets()
        }
    }
}

fileprivate extension PhotosSheet.PhotosProvider {
    fileprivate func _setupCollectionView(collectionView: UICollectionView) {
        _collectionView = collectionView
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(PhotosSheet.PhotosDisplayController.PhotoItemView.self, forCellWithReuseIdentifier: "PhotoItem")
    }

    func _loadAssets() {
        DispatchQueue.global().async { [weak self] in
            let assets = PhotosSheet.PhotosManager.shared.obtainRecentAssets(limit: self?._displayedPhotosLimit ?? 0)
            DispatchQueue.main.async { [weak self] in
                self?._models = assets.map(PhotosSheet.Model.init)
                self?._collectionView?.reloadData()
            }
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
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoItem", for: indexPath) as! PhotosSheet.PhotosDisplayController.PhotoItemView
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

// MARK: - PhotosProvider.Event
extension PhotosSheet.PhotosProvider {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        _contentOffsetObserbers.forEach { $0.displayView(scrollView as! UICollectionView, onContentOffsetChange: scrollView.contentOffset) }
    }

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

// MARK: - PhotosProvider.Observer
protocol PhotosDisplayViewContentOffsetObserver: Hashable {
    func displayView(_ displayView: UICollectionView, onContentOffsetChange contentOffset: CGPoint)
}
