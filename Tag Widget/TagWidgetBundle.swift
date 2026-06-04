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
        MoreKit.configureForReadOnlyAccess(
            appGroupID: AppConfig.appGroupID,
            membershipKey: "com.zizicici.tag.Store.LifetimeMembership"
        )
    }

    var body: some Widget {
        TodayRecordsWidget()
    }
}
