//
//  OptionCell.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/5/13.
//

import UIKit
import SnapKit

enum TimeOption {
    case startAndEnd
    case startOnly
    case endOnly
    
    static var none = String(localized: "dayDetail.timeOption.none")
    static var title = String(localized: "dayDetail.timeOption.title")
    
    var title: String {
        switch self {
        case .startAndEnd:
            String(localized: "dayDetail.timeOption.startAndEnd.title")
        case .startOnly:
            String(localized: "dayDetail.timeOption.startOnly.title")
        case .endOnly:
            String(localized: "dayDetail.timeOption.endOnly.title")
        }
    }
    
    var subtitle: String? {
        switch self {
        case .startAndEnd:
            return String(localized: "dayDetail.timeOption.startAndEnd.subtitle")
        case .startOnly:
            return nil
        case .endOnly:
            return nil
        }
    }
}

fileprivate extension UIConfigurationStateCustomKey {
    static let optionItem = UIConfigurationStateCustomKey("com.zizicici.tagday.cell.option.item")
}

private extension UICellConfigurationState {
    var optionItem: TimeOption? {
        set { self[.optionItem] = newValue }
        get { return self[.optionItem] as? TimeOption}
    }
}

class OptionBaseCell: UITableViewCell {
    private var optionItem: TimeOption? = nil
    
    func update(with newOption: TimeOption?) {
        guard optionItem != newOption else { return }
        optionItem = newOption
        setNeedsUpdateConfiguration()
    }
    
    override var configurationState: UICellConfigurationState {
        var state = super.configurationState
        state.optionItem = self.optionItem
        return state
    }
}

class OptionCell: OptionBaseCell {
    private func defaultListContentConfiguration() -> UIListContentConfiguration { return .valueCell() }
    private lazy var listContentView = UIListContentView(configuration: defaultListContentConfiguration())
    
    var tapButton: UIButton = {
        var configuration = UIButton.Configuration.plain()
        
        let button = UIButton(configuration: configuration)

        return button
    }()
    
    var valueButton: UIButton = {
        var configuration = UIButton.Configuration.plain()
        configuration.title = "Test"
        configuration.imagePadding = 10.0
        let config = UIImage.SymbolConfiguration(pointSize: 12, weight: .regular)
        configuration.image = UIImage(systemName: "chevron.up.chevron.down", withConfiguration: config)
        configuration.imagePlacement = .trailing
        configuration.contentInsets = .zero
        configuration.baseForegroundColor = .secondaryLabel
        
        let button = UIButton(configuration: configuration)
        button.isAccessibilityElement = false

        return button
    }()
    
    func setupViewsIfNeeded() {
        guard tapButton.superview == nil else {
            return
        }
        
        contentView.addSubview(listContentView)
        listContentView.snp.makeConstraints { make in
            make.leading.top.bottom.trailing.equalTo(contentView)
        }
        
        contentView.addSubview(valueButton)
        valueButton.snp.makeConstraints { make in
            make.centerY.equalTo(contentView)
            make.trailing.equalTo(contentView).inset(12)
        }
        
        contentView.addSubview(tapButton)
        tapButton.snp.makeConstraints { make in
            make.edges.equalTo(contentView)
        }
        tapButton.showsMenuAsPrimaryAction = true
    }
    
    override func updateConfiguration(using state: UICellConfigurationState) {
        setupViewsIfNeeded()
        var content = defaultListContentConfiguration().updated(for: state)
        content.text = TimeOption.title
        listContentView.configuration = content
        valueButton.setTitle(state.optionItem?.title ?? TimeOption.none, for: .normal)
        
        isAccessibilityElement = true
        accessibilityTraits = .button
    }
}
