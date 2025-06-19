//
//  OptionCell.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/5/13.
//

import UIKit
import SnapKit

protocol OptionItem: Hashable, Equatable {
    static var noneTitle: String { get }
    static var sectionTitle: String { get }
    
    var title: String { get }
    var subtitle: String? { get }
}

enum TimeOption: OptionItem {
    case startAndEnd
    case startOnly
    case endOnly
    
    static var noneTitle = String(localized: "dayDetail.timeOption.none")
    static var sectionTitle = String(localized: "dayDetail.timeOption.title")
    
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

enum DurationOption: OptionItem {
    case custom
    case automatic
    
    static var noneTitle = String(localized: "dayDetail.durationOption.none")
    static var sectionTitle = String(localized: "dayDetail.durationOption.title")
    
    var title: String {
        switch self {
        case .custom:
            String(localized: "dayDetail.durationOption.custom.title")
        case .automatic:
            String(localized: "dayDetail.durationOption.automatic.title")
        }
    }
    
    var subtitle: String? {
        switch self {
        case .custom:
            return nil
        case .automatic:
            return String(localized: "dayDetail.durationOption.automatic.subtitle")
        }
    }
}

fileprivate extension UIConfigurationStateCustomKey {
    static let optionItem = UIConfigurationStateCustomKey("com.zizicici.tag.cell.option.item")
}

private extension UICellConfigurationState {
    var optionItem: (any OptionItem)? {
        set { self[.optionItem] = newValue as? AnyHashable }
        get { return self[.optionItem] as? (any OptionItem) }
    }
}

class OptionBaseCell<T: OptionItem>: UITableViewCell {
    private var optionItem: T? = nil
    
    func update(with newOption: T?) {
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

class OptionCell<T: OptionItem>: OptionBaseCell<T> {
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
    
    // 添加类型特定的默认值
    var defaultSectionTitle: String { T.sectionTitle }
    var defaultNoneTitle: String { T.noneTitle }
    
    func setupViewsIfNeeded() {
        guard tapButton.superview == nil else { return }
        
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
        content.text = defaultSectionTitle  // 使用泛型类型的 sectionTitle
        listContentView.configuration = content
        
        if let optionItem = state.optionItem as? T {  // 使用泛型类型 T
            valueButton.setTitle(optionItem.title, for: .normal)
        } else {
            valueButton.setTitle(defaultNoneTitle, for: .normal)  // 使用泛型类型的 noneTitle
        }
        
        isAccessibilityElement = true
        accessibilityTraits = .button
    }
}
