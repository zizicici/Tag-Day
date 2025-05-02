//
//  UIColor+Extension.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/5/2.
//

import UIKit

extension UIColor {
    convenience init?(hex: String, alpha: CGFloat = 1.0) {
        var hexFormatted = hex.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).uppercased()

        if hexFormatted.hasPrefix("#") {
            hexFormatted.remove(at: hexFormatted.startIndex)
        }
        var hexValue: UInt64 = 0
        Scanner(string: hexFormatted).scanHexInt64(&hexValue)

        switch hexFormatted.count {
        case 6:
            self.init(red: CGFloat((hexValue & 0xFF0000) >> 16) / 255.0,
                      green: CGFloat((hexValue & 0x00FF00) >> 8) / 255.0,
                      blue: CGFloat(hexValue & 0x0000FF) / 255.0,
                      alpha: alpha)
        case 8:
            self.init(red: CGFloat((hexValue & 0xFF000000) >> 24) / 255.0,
                      green: CGFloat((hexValue & 0x00FF0000) >> 16) / 255.0,
                      blue: CGFloat((hexValue & 0x0000FF00) >> 8) / 255.0,
                      alpha: CGFloat(hexValue & 0x000000FF) / 255.0)
        default:
            return nil
        }
    }
    
    func toHexString() -> String? {
        guard let components = cgColor.components, components.count > 0 else {
            return nil
        }
        var r: Float = 0
        var g: Float = 0
        var b: Float = 0
        var a: Float = 0
        switch components.count {
        case 1:
            r = Float(components[0])
            g = Float(components[0])
            b = Float(components[0])
            a = 1.0
        case 2:
            r = Float(components[0])
            g = Float(components[0])
            b = Float(components[0])
            a = Float(components[1])
        case 3:
            r = Float(components[0])
            g = Float(components[1])
            b = Float(components[2])
            a = 1.0
        default:
            r = Float(components[0])
            g = Float(components[1])
            b = Float(components[2])
            a = Float(components[3])
        }
        
        let hexString = String(format: "%02lX%02lX%02lX%02lX",
                               lroundf(r * 255),
                               lroundf(g * 255),
                               lroundf(b * 255),
                               lroundf(a * 255))
        
        return hexString
    }
    
    func generateLightDarkString() -> String {
        let lightColorHexString = resolvedColor(with: UITraitCollection(userInterfaceStyle: .light)).toHexString() ?? ""
        let darkColorHexString = resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark)).toHexString() ?? ""
        return "\(lightColorHexString),\(darkColorHexString)"
    }
    
    convenience init?(string: String) {
        let lightDark = string.split(separator: ",")
        switch lightDark.count {
        case 1:
            self.init(hex: string, alpha: 1.0)
        case 2:
            if let first = lightDark.first, let last = lightDark.last, let light = UIColor(hex: "\(first)"), let dark = UIColor(hex: "\(last)") {
                self.init(dynamicProvider: { traitCollection -> UIColor in
                    switch traitCollection.userInterfaceStyle {
                    case .light, .unspecified:
                        return light
                    case .dark:
                        return dark
                    @unknown default:
                        fatalError()
                    }
                })
            } else {
                return nil
            }
        default:
            return nil
        }
    }
}
