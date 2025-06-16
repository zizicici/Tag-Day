//
//  InfoCell.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/6/15.
//

import UIKit
import SnapKit

fileprivate extension UIConfigurationStateCustomKey {
    static let infoItem = UIConfigurationStateCustomKey("com.zizicici.tagday.cell.info.item")
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

class InfoCell: InfoBaseCell, HoverableCell {
    let tagView: TagView = TagView()
    
    let label: UILabel = {
        let label = UILabel()
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.font = UIFont.systemFont(ofSize: 12.0, weight: .medium)
        label.textColor = AppColor.text.withAlphaComponent(0.5)
        
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
        
        let width: CGFloat = DayGrid.itemWidth(in: contentView.window?.windowScene?.screen.bounds.width ?? 375.0 )
        
        contentView.addSubview(tagView)
        tagView.snp.makeConstraints { make in
            make.leading.equalTo(contentView).inset(3.0)
            make.centerY.equalTo(contentView)
            make.height.equalTo(20.0)
            make.top.greaterThanOrEqualTo(contentView).inset(3.0)
            make.width.equalTo(width - 6.0)
        }
        
        contentView.addSubview(label)
        label.snp.makeConstraints { make in
            make.top.bottom.equalTo(contentView)
            make.leading.equalTo(tagView.snp.trailing).offset(4.0)
            make.trailing.equalTo(contentView).inset(3.0)
        }
    }
    
    override func updateConfiguration(using state: UICellConfigurationState) {
        super.updateConfiguration(using: state)
        setupViewsIfNeeded()
        
        if let item = state.infoItem {
            tagView.update(tag: item.tag)
            
            label.text = String(format: "× %i", item.count)
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
