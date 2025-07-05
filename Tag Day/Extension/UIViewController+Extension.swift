//
//  UIViewController+Extension.swift
//  coco
//
//  Created by Ci Zi on 2025/4/29.
//

import UIKit
import SafariServices

extension UIViewController {
    func openSF(with url: URL) {
        let safariViewController = SFSafariViewController(url: url)
        navigationController?.present(safariViewController, animated: ConsideringUser.animated)
    }
}
