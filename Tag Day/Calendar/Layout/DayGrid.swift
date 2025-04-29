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
        } else {
            return 45.0            
        }
    }
    
    static let itemHeight: CGFloat = 72.0
    
    static let interSpacing: CGFloat = 2.0
}
