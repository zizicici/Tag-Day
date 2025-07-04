import UIKit
import SwiftUI
import SymbolPicker

extension UIViewController {
    func presentSymbolPicker(currentSymbol: String, onSelect: @escaping (String) -> Void) {
        var symbol = currentSymbol
        let symbolPicker = SymbolPicker(symbol: Binding(
            get: { symbol },
            set: {
                symbol = $0
                onSelect($0)
            }
        ))
        
        let hostingController = UIHostingController(rootView: symbolPicker)
        hostingController.isModalInPresentation = true

        present(hostingController, animated: ConsideringUser.animated)
    }
}
