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

extension UIViewController {
    func showAlert(title: String?, message: String?) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: String(localized: "button.ok"), style: .cancel)
        alertController.addAction(cancelAction)

        present(alertController, animated: true, completion: nil)
    }
}
