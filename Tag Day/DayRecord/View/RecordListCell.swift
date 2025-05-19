//
//  RecordListCell.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/5/9.
//

import UIKit
import SnapKit
import ZCCalendar

fileprivate extension UIConfigurationStateCustomKey {
    static let dayDetailItem = UIConfigurationStateCustomKey("com.zizicici.tagday.detail.cell.item")
}

struct DayDetailItem: Hashable {
    var day: GregorianDay
    var tags: [Tag]
    var record: DayRecord
}

private extension UICellConfigurationState {
    var detailItem: DayDetailItem? {
        set { self[.dayDetailItem] = newValue }
        get { return self[.dayDetailItem] as? DayDetailItem }
    }
}

protocol RecordListCellDelegate: NSObjectProtocol {
    func getButtonMenu(for record: DayRecord) -> UIMenu
    func handle(tag: Tag, in button: UIButton, for record: DayRecord)
    func commentButton(for record: DayRecord)
    func timeButton(for record: DayRecord)
}

class RecordListBaseCell: UICollectionViewCell {
    private var detailItem: DayDetailItem? = nil
    
    weak var delegate: RecordListCellDelegate?
    
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

class RecordListCell: RecordListBaseCell {
    private var tagButton: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.titleAlignment = .leading
        configuration.cornerStyle = .fixed
        configuration.background.cornerRadius = 10.0
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer({ incoming in
            var outgoing = incoming
            outgoing.font = UIFont.preferredSystemFont(for: .body, weight: .medium)
            
            return outgoing
        })
        configuration.titleLineBreakMode = .byTruncatingTail
        configuration.subtitleLineBreakMode = .byTruncatingTail
        let button = UIButton(configuration: configuration)
        return button
    }()
    
    private var moreButton: UIButton = {
        var configuration = UIButton.Configuration.plain()
        configuration.image = UIImage(systemName: "ellipsis")
        let button = UIButton(configuration: configuration)
        button.tintColor = AppColor.text.withAlphaComponent(0.8)
        button.showsMenuAsPrimaryAction = true

        return button
    }()
    
    private var timeButton: UIButton = {
        var configuration = UIButton.Configuration.plain()
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer({ incoming in
            var outgoing = incoming
            outgoing.font = UIFont.preferredMonospacedFont(for: .footnote, weight: .semibold)
            
            return outgoing
        })
        configuration.titleLineBreakMode = .byTruncatingTail
        configuration.contentInsets.bottom = 3.0
        let button = UIButton(configuration: configuration)
        button.tintColor = AppColor.text
        
        return button
    }()
    
    private var commentButton: UIButton = {
        var configuration = UIButton.Configuration.plain()
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer({ incoming in
            var outgoing = incoming
            outgoing.font = UIFont.preferredSystemFont(for: .footnote, weight: .regular)
            
            return outgoing
        })
        configuration.titleLineBreakMode = .byTruncatingTail
        let button = UIButton(configuration: configuration)
        button.tintColor = AppColor.text.withAlphaComponent(0.8)

        return button
    }()
    
    private func setupViewsIfNeeded(using state: UICellConfigurationState) {
        guard tagButton.superview == nil else { return }
        
        if let detailItem = state.detailItem {
            contentView.addSubview(tagButton)
            tagButton.snp.makeConstraints { make in
                make.leading.equalTo(contentView).inset(10)
                make.trailing.equalTo(contentView).inset(44)
                make.height.equalTo(44.0)
            }
            
            contentView.addSubview(moreButton)
            moreButton.snp.makeConstraints { make in
                make.width.equalTo(34.0)
                make.height.equalTo(44.0)
                make.top.equalTo(tagButton)
                make.trailing.equalTo(contentView)
            }
            
            if detailItem.record.getTime() != nil {
                contentView.addSubview(timeButton)
                timeButton.snp.makeConstraints { make in
                    make.leading.equalTo(contentView).inset(6)
                    make.trailing.lessThanOrEqualTo(contentView).inset(44)
                    make.top.equalTo(contentView)
                }
                tagButton.snp.makeConstraints { make in
                    make.top.equalTo(timeButton.snp.bottom)
                }
            } else {
                tagButton.snp.makeConstraints { make in
                    make.top.equalTo(contentView)
                }
            }
            
            if detailItem.record.comment != nil {
                contentView.addSubview(commentButton)
                commentButton.snp.makeConstraints { make in
                    make.leading.equalTo(contentView).inset(6)
                    make.trailing.lessThanOrEqualTo(tagButton)
                    make.top.equalTo(tagButton.snp.bottom)
                    make.bottom.equalTo(contentView)
                }
            } else {
                tagButton.snp.makeConstraints { make in
                    make.bottom.equalTo(contentView)
                }
            }
        }

        timeButton.addTarget(self, action: #selector(timeButtonAction), for: .touchUpInside)
        tagButton.addTarget(self, action: #selector(tagButtonAction), for: .touchUpInside)
        commentButton.addTarget(self, action: #selector(commentButtonAction), for: .touchUpInside)
    }
    
    override func updateConfiguration(using state: UICellConfigurationState) {
        super.updateConfiguration(using: state)
        setupViewsIfNeeded(using: state)
        
        if let detailItem = state.detailItem, let tag = detailItem.tags.first(where: { $0.id == detailItem.record.tagID }) {
            let title = tag.title
            let tagColor = UIColor(string: tag.color)
            timeButton.configurationUpdateHandler = { button in
                var config = button.configuration
                if let timeText = detailItem.record.getTime() {
                    config?.title = timeText
                    config?.baseForegroundColor = AppColor.text
                } else {
                    config?.title = String(localized: "dayRecord.time")
                    config?.baseForegroundColor = AppColor.text.withAlphaComponent(0.5)
                }
                
                button.configuration = config
            }
            
            tagButton.configurationUpdateHandler = { button in
                var config = button.configuration
                config?.title = title
                config?.baseForegroundColor = tagColor?.isLight == true ? .black.withAlphaComponent(0.8) : .white.withAlphaComponent(0.95)
                
                button.configuration = config
            }
            tagButton.tintColor = tagColor
            
            moreButton.menu = delegate?.getButtonMenu(for: detailItem.record)
            
            commentButton.configurationUpdateHandler = { button in
                var config = button.configuration
                if let commetnText = detailItem.record.comment {
                    config?.title = commetnText
                    config?.baseForegroundColor = AppColor.text.withAlphaComponent(0.8)
                } else {
                    config?.title = String(localized: "dayRecord.comment")
                    config?.baseForegroundColor = AppColor.text.withAlphaComponent(0.4)
                }
                
                button.configuration = config
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        tagButton.removeFromSuperview()
        moreButton.removeFromSuperview()
        commentButton.removeFromSuperview()
        timeButton.removeFromSuperview()
    }
    
    @objc
    func tagButtonAction() {
        let state = configurationState
        if let detailItem = state.detailItem, let tag = detailItem.tags.first(where: { $0.id == detailItem.record.tagID }), detailItem.tags.count > 1 {
            delegate?.handle(tag: tag, in: tagButton, for: detailItem.record)
        }
    }
    
    @objc
    func commentButtonAction() {
        let state = configurationState
        if let detailItem = state.detailItem {
            delegate?.commentButton(for: detailItem.record)
        }
    }
    
    @objc
    func timeButtonAction() {
        let state = configurationState
        if let detailItem = state.detailItem {
            delegate?.timeButton(for: detailItem.record)
        }
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
