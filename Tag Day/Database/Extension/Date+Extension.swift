//
//  Date+Extension.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/4/29.
//

import Foundation

extension Date {
    var nanoSecondSince1970: Int64 {
        return Int64(timeIntervalSince1970 * 1000.0)
    }
    
    init(nanoSecondSince1970: Int64) {
        self.init(timeIntervalSince1970: Double(nanoSecondSince1970) / 1000.0)
    }
}
