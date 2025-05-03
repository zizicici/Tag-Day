//
//  DayGrid.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/4/29.
//

import Foundation

struct DayGrid {
    static let countInRow: Int = 7
    
    static func itemWidth(in containerWidth: CGFloat) -> CGFloat {
        if containerWidth <= 320 {
            return 40.0
        } else if containerWidth <= 375 {
            return 45.0
        } else if containerWidth <= 400 {
            return 47.0
        } else {
            return 50.0
        }
    }
    
    static func itemHeight(in containerWidth: CGFloat) -> CGFloat {
        if containerWidth <= 320 {
            return 64.0
        } else if containerWidth <= 375 {
            return 73.0
        } else if containerWidth <= 400 {
            return 76.0
        } else {
            return 82.0
        }
    }
    
    static let interSpacing: CGFloat = 3.0
}
