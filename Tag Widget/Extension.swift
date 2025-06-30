//
//  Extension.swift
//  Tag Widget
//
//  Created by Ci Zi on 2025/6/30.
//

import SwiftUI
import UIKit

extension Tag {
    var widgetColor: Color {
        return Color(uiColor: UIColor(string: color) ?? UIColor.systemBackground)
    }
    
    var widgetTitleColor: Color {
        let newUIColor: UIColor
        if let titleColor = titleColor {
            newUIColor = UIColor(string: titleColor) ?? UIColor.label
        } else {
            newUIColor = UIColor { traitCollection in
                let widgetUIColor = UIColor(string: color) ?? UIColor.systemBackground
                if widgetUIColor.resolvedColor(with: traitCollection).isLight {
                    return UIColor(hex: "000000CC") ?? .black
                } else {
                    return UIColor(hex: "FFFFFFF1") ?? .white
                }
            }
        }
        return Color(uiColor: newUIColor)
    }
}
