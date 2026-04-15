//
//  WidgetBundle.swift
//  Widget
//
//  Created by Ci Zi on 2025/6/29.
//

import WidgetKit
import SwiftUI
import MoreKit

@main
struct TagWidgetBundle: WidgetBundle {
    init() {
        MoreKit.configure(
            productIDs: ["com.zizicici.tag.pro"],
            appGroupID: AppConfig.appGroupID,
            membershipKey: "com.zizicici.tag.Store.LifetimeMembership"
        )
    }

    var body: some Widget {
        TodayRecordsWidget()
    }
}
