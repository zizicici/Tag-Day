//
//  FetchError.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/5/12.
//

import Foundation

enum FetchError: Error, CustomLocalizedStringResourceConvertible {
    case notFound

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .notFound:
            return "intent.error.notFound"
        }
    }
}
