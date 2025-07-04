//
//  TagInfoCell.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/6/15.
//

import UIKit
import SnapKit

fileprivate extension UIConfigurationStateCustomKey {
    static let infoItem = UIConfigurationStateCustomKey("com.zizicici.tag.cell.info.item")
}

private extension UICellConfigurationState {
    var infoItem: InfoItem? {
        set { self[.infoItem] = newValue }
        get { return self[.infoItem] as? InfoItem }
    }
}

class InfoBaseCell: UICollectionViewCell {
    private var infoItem: InfoItem? = nil
    
    func update(with newInfoItem: InfoItem) {
        guard infoItem != newInfoItem else { return }
        infoItem = newInfoItem
        setNeedsUpdateConfiguration()
    }
    
    override var configurationState: UICellConfigurationState {
        var state = super.configurationState
        state.infoItem = self.infoItem
        return state
    }
}

class TagInfoCell: InfoBaseCell, HoverableCell {
    let tagView: TagView = TagView()
    
    let label: UILabel = {
        let label = UILabel()
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.font = UIFont.systemFont(ofSize: 12.0, weight: .medium)
        label.textColor = AppColor.text.withAlphaComponent(0.6)
        
        return label
    }()
    
    var isHover: Bool = false {
        didSet {
            if oldValue != isHover {
                setNeedsUpdateConfiguration()
            }
        }
    }
    
    func update(isHover: Bool) {
        self.isHover = isHover
    }
    
    private func setupViewsIfNeeded() {
        guard tagView.superview == nil else { return }
        
        contentView.addSubview(tagView)
        contentView.addSubview(label)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let tagWidth: CGFloat = DayGrid.itemWidth(in: contentView.window?.bounds.width ?? 375.0 )
        
        let tagFrame = CGRect(x: 3.0, y: (bounds.height - 20.0) / 2.0, width: tagWidth - 6.0, height: 20.0)
        if !tagView.frame.equalTo(tagFrame) {
            tagView.frame = tagFrame
        }
        let labelFrame = CGRect(x: tagView.frame.maxX + 4.0, y: 0.0, width: bounds.width - tagView.frame.maxX - 7.0, height: bounds.height)
        if !label.frame.equalTo(labelFrame) {
            label.frame = labelFrame
        }
    }
    
    override func updateConfiguration(using state: UICellConfigurationState) {
        super.updateConfiguration(using: state)
        setupViewsIfNeeded()
        
        if let item = state.infoItem {
            tagView.update(tag: item.tag)
            
            label.text = String(format: "× %i", item.count)
            
            isAccessibilityElement = true
            accessibilityTraits = .button
            accessibilityLabel = String(format: "%@ × %i", item.tag.title, item.count)
        }
        
        if isHover {
            backgroundConfiguration = InfoCellBackgroundConfiguration.configuration()
        } else {
            backgroundConfiguration = InfoCellBackgroundConfiguration.configuration(for: state)
        }
    }
}

struct InfoCellBackgroundConfiguration {
    static func configuration(for state: UICellConfigurationState) -> UIBackgroundConfiguration {
        var background = UIBackgroundConfiguration.clear()
        background.cornerRadius = 5.0
        if state.isHighlighted || state.isSelected {
            background.backgroundColor = .gray
            
            if state.isHighlighted {
                background.backgroundColorTransformer = .init { $0.withAlphaComponent(0.3) }
            } else {
                background.backgroundColorTransformer = .init { $0.withAlphaComponent(0.5) }
            }
        } else {
            background.backgroundColor = .clear
        }
        return background
    }
    
    static func configuration() -> UIBackgroundConfiguration {
        var background = UIBackgroundConfiguration.clear()
        background.cornerRadius = 5.0
        background.backgroundColor = .gray
        background.backgroundColorTransformer = .init { $0.withAlphaComponent(0.3) }

        return background
    }
}
