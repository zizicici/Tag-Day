//
//  InfoItem.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/7/4.
//

import Foundation
import ZCCalendar

struct InfoItem: Hashable {
    var tag: Tag
    var count: Int
    var month: GregorianMonth?
}
