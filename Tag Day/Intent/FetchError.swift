//
//  FetchError.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/5/12.
//

import Foundation

enum FetchError: Error, CustomLocalizedStringResourceConvertible {
    case notFound
    case bookFirst

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .notFound:
            return "intent.error.notFound"
        case .bookFirst:
            return "intent.error.bookFirst"
        }
    }
}
