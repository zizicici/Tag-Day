//
//  AppColor.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/4/29.
//

import UIKit

struct AppColor {
    static let main = UIColor.main
    static let text = UIColor.text
    static let tintedText = UIColor.tintedText
    static let action = UIColor.action
    static let paper = UIColor.paper
    static let background = UIColor.background
    static let navigationBar = UIColor.navigationBar
    static let toolbar = UIColor.toolBar
    static let today = UIColor.today
    
    static var dynamicColor: UIColor {
        get {
            return UIColor { _ in
                if let dynamicColor = DataManager.shared.currentBook?.dynamicColor {
                    if dynamicColor.isSimilar(to: Self.background) || dynamicColor.isSimilar(to: Self.paper) {
                        return Self.main
                    } else {
                        return dynamicColor
                    }
                } else {
                    return Self.main
                }
            }
        }
    }
}
