//
//  ImpactGenerator.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/4/29.
//

import UIKit

struct ImpactGenerator {
    static func impact(intensity: CGFloat = 0.5, style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred(intensity: intensity)
    }
}
