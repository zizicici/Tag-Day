//
//  DayDetailCell.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/5/9.
//

import UIKit
import SnapKit
import ZCCalendar

fileprivate extension UIConfigurationStateCustomKey {
    static let detailItem = UIConfigurationStateCustomKey("com.zizicici.tagday.detail.cell.item")
}

struct DayDetailItem: Hashable {
    var day: GregorianDay
    var tags: [Tag]
    var record: DayRecord
}

private extension UICellConfigurationState {
    var detailItem: DayDetailItem? {
        set { self[.detailItem] = newValue }
        get { return self[.detailItem] as? DayDetailItem }
    }
}

protocol DayDetailCellDelegate: NSObjectProtocol {
    func getButtonMenu(for record: DayRecord) -> UIMenu
}

class DayDetailBaseCell: UICollectionViewCell {
    private var detailItem: DayDetailItem? = nil
    
    weak var delegate: DayDetailCellDelegate?
    
    func update(with newDetail: DayDetailItem) {
        guard detailItem != newDetail else { return }
        detailItem = newDetail
        setNeedsUpdateConfiguration()
    }
    
    override var configurationState: UICellConfigurationState {
        var state = super.configurationState
        state.detailItem = self.detailItem
        return state
    }
}

class DayDetailCell: DayDetailBaseCell {
    private var tagButton: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.titleAlignment = .leading
        configuration.cornerStyle = .small
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer({ incoming in
            var outgoing = incoming
            outgoing.font = UIFont.preferredMonospacedFont(for: .body, weight: .medium)
            
            return outgoing
        })
        configuration.titleLineBreakMode = .byTruncatingTail
        configuration.subtitleLineBreakMode = .byTruncatingTail
        configuration.image = UIImage(systemName: "chevron.up.chevron.down", withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .regular))
        configuration.imagePlacement = .trailing
        configuration.imagePadding = 10.0
        configuration.contentInsets.trailing = 6.0
        let button = UIButton(configuration: configuration)
        button.showsMenuAsPrimaryAction = true
        return button
    }()
    
    private func setupViewsIfNeeded() {
        guard tagButton.superview == nil else { return }
        
        contentView.addSubview(tagButton)
        tagButton.snp.makeConstraints { make in
            make.top.leading.equalTo(contentView).inset(10)
            make.trailing.lessThanOrEqualTo(contentView).inset(100)
            make.bottom.equalTo(contentView).inset(80)
        }
    }
    
    override func updateConfiguration(using state: UICellConfigurationState) {
        super.updateConfiguration(using: state)
        setupViewsIfNeeded()
        
        if let detailItem = state.detailItem, let tag = detailItem.tags.first(where: { $0.id == detailItem.record.tagID }) {
            let title = tag.title
            let subtitle = tag.subtitle
            let tagColor = UIColor(string: tag.color)
            tagButton.configurationUpdateHandler = { button in
                var config = button.configuration
                
                config?.title = title
                config?.subtitle = subtitle
                config?.baseForegroundColor = tagColor?.isLight == true ? .black.withAlphaComponent(0.8) : .white.withAlphaComponent(0.95)
                button.configuration = config
            }
            tagButton.tintColor = tagColor
            tagButton.menu = delegate?.getButtonMenu(for: detailItem.record)
            
            backgroundConfiguration = DayDetailCellBackgroundConfiguration.configuration(for: state, color: AppColor.paper, strokeColor: tagColor)
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        tagButton.removeFromSuperview()
    }
}

struct DayDetailCellBackgroundConfiguration {
    static func configuration(for state: UICellConfigurationState, color: UIColor, strokeColor: UIColor?) -> UIBackgroundConfiguration {
        var background = UIBackgroundConfiguration.clear()
        background.cornerRadius = 10.0
        background.backgroundColor = color
//        background.strokeColor = strokeColor
//        background.strokeWidth = 1.5
        
        if state.isHighlighted || state.isSelected {

            if state.isHighlighted {
                background.backgroundColorTransformer = .init { $0.withAlphaComponent(0.8) }
            } else {
                background.backgroundColor = color.withAlphaComponent(0.8)
                background.backgroundColorTransformer = .init { $0.withAlphaComponent(0.64) }
            }
        }
        return background
    }
}
