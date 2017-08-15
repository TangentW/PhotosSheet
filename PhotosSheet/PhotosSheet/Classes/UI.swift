//
//  UI.swift
//  PhotosSheet
//
//  Created by Tan on 2017/8/14.
//

import UIKit

// MARK: - UI Options
public extension PhotosSheet {
    enum UIOption: Hashable {
        case photoItemCheckboxRightMargin(CGFloat)
        case photoItemCheckboxBottomMargin(CGFloat)
        case photoItemVideoMarkerViewLeftMargin(CGFloat)
        case photoItemVideoMarkerViewBottomMargin(CGFloat)
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
            case .photoItemVideoMarkerViewLeftMargin: return 2
            case .photoItemVideoMarkerViewBottomMargin: return 3
            case .photoItemHeight : return 4
            case .actionSheetFont : return 5
            case .actionSheetCorners : return 6
            case .actionSheetHorizontalMargin : return 7
            case .actionSheetVerticalMargin : return 8
            case .actionSheetItemHeight : return 9
            }
        }

        public static func ==(lhs: PhotosSheet.UIOption, rhs: PhotosSheet.UIOption) -> Bool {
            return lhs.hashValue == rhs.hashValue
        }
    }
}

// MARK: - UI Setting
extension PhotosSheet {
    fileprivate(set) static var photoItemCheckboxRightMargin: CGFloat = 5
    fileprivate(set) static var photoItemCheckboxBottomMargin: CGFloat = 5
    fileprivate(set) static var photoItemVideoMarkerViewLeftMargin: CGFloat = 7
    fileprivate(set) static var photoItemVideoMarkerViewBottomMargin: CGFloat = 7
    fileprivate(set) static var photoItemHeight: CGFloat = (UIScreen.main.bounds.width - 2 * PhotosSheet.actionSheetHorizontalMargin) * 0.7
    fileprivate(set) static var actionSheetFont = UIFont.systemFont(ofSize: 20)
    fileprivate(set) static var actionSheetCorners: CGFloat = 12
    fileprivate(set) static var actionSheetHorizontalMargin: CGFloat = 10
    fileprivate(set) static var actionSheetVerticalMargin: CGFloat = 8
    fileprivate(set) static var actionSheetItemHeight: CGFloat = 57
}

extension PhotosSheet {
    static func setupUI(options: Set<UIOption>) {
        func pair(option: UIOption) {
            switch option {
            case .photoItemCheckboxRightMargin(let value):
                photoItemCheckboxRightMargin = value
            case .photoItemCheckboxBottomMargin(let value):
                photoItemCheckboxBottomMargin = value
            case .photoItemVideoMarkerViewLeftMargin(let value):
                photoItemVideoMarkerViewLeftMargin = value
            case .photoItemVideoMarkerViewBottomMargin(let value):
                photoItemVideoMarkerViewBottomMargin = value
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
