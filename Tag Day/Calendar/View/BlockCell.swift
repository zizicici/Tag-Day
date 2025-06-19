//
//  BlockCell.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/4/29.
//

import UIKit
import SnapKit
import ZCCalendar
import Collections

fileprivate extension UIConfigurationStateCustomKey {
    static let blockItem = UIConfigurationStateCustomKey("com.zizicici.tag.cell.block.item")
}

private extension UICellConfigurationState {
    var blockItem: BlockItem? {
        set { self[.blockItem] = newValue }
        get { return self[.blockItem] as? BlockItem }
    }
}

class BlockBaseCell: UICollectionViewCell {
    private var blockItem: BlockItem? = nil
    
    func update(with newBlockItem: BlockItem) {
        guard blockItem != newBlockItem else { return }
        blockItem = newBlockItem
        setNeedsUpdateConfiguration()
    }
    
    override var configurationState: UICellConfigurationState {
        var state = super.configurationState
        state.blockItem = self.blockItem
        return state
    }
}

class BlockCell: BlockBaseCell, HoverableCell {
    var isHover: Bool = false {
        didSet {
            if oldValue != isHover {
                setNeedsUpdateConfiguration()
            }
        }
    }
    
    var label: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        label.alpha = 0.8
        
        return label
    }()
    
    var tagContainerView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        
        return view
    }()
    
    var highlightColor: UIColor = .gray.withAlphaComponent(0.25)
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        isHover = false
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    private func setupViewsIfNeeded() {
        guard label.superview == nil else { return }
        
        contentView.addSubview(label)
        label.snp.makeConstraints { make in
            make.top.equalTo(contentView).inset(8)
            make.leading.trailing.equalTo(contentView).inset(6)
            make.height.equalTo(18)
        }
        
        contentView.addSubview(tagContainerView)
        tagContainerView.snp.makeConstraints { make in
            make.top.equalTo(label.snp.bottom).offset(6)
            make.leading.trailing.equalTo(contentView).inset(3)
            make.bottom.equalTo(contentView).inset(4)
        }
        
        isAccessibilityElement = true
        accessibilityTraits = .button
    }
    
    override func updateConfiguration(using state: UICellConfigurationState) {
        super.updateConfiguration(using: state)
        setupViewsIfNeeded()
        
        if let item = state.blockItem {
            var backgroundColor = item.backgroundColor

            if isHover || isHighlighted {
                backgroundColor = highlightColor.overlay(on: backgroundColor)
            }
            
            label.textColor = item.foregroundColor
            label.text = item.day.dayString()
            
            clearTagSubviews()

            var tagViews: [UIView] = []
            
            switch item.tagDisplayType {
            case .normal:
                for record in item.records {
                    if let tag = item.tags.first(where: { $0.id == record.tagID }) {
                        let recordTagView = generateTagView(tag: tag, count: 1)
                        tagViews.append(recordTagView)
                    }
                }
            case .aggregation:
                var orderedCounts = OrderedDictionary<Int64, Int>()
                for record in item.records {
                    orderedCounts[record.tagID, default: 0] += 1
                }
                
                for orderedCount in orderedCounts {
                    if let tag = item.tags.first(where: { $0.id == orderedCount.key }) {
                        let recordTagView = generateTagView(tag: tag, count: orderedCount.value)
                        tagViews.append(recordTagView)
                    }
                }
            }
            
            var lastTagView: UIView? = nil
            for tagView in tagViews {
                tagContainerView.addSubview(tagView)
                if let lastView = lastTagView {
                    tagView.snp.makeConstraints { make in
                        make.leading.trailing.equalTo(tagContainerView)
                        make.height.equalTo(20)
                        make.top.equalTo(lastView.snp.bottom).offset(3)
                    }
                } else {
                    tagView.snp.makeConstraints { make in
                        make.leading.trailing.equalTo(tagContainerView)
                        make.height.equalTo(20)
                        make.top.equalTo(tagContainerView)
                    }
                }
                lastTagView = tagView
            }
            
            if item.isToday {
                accessibilityLabel = String(localized: "weekCalendar.today") + (item.day.completeFormatString() ?? "")
            } else {
                accessibilityLabel = item.day.completeFormatString()
            }
            
            backgroundConfiguration = BlockCellBackgroundConfiguration.configuration(for: state, backgroundColor: backgroundColor, cornerRadius: 6.0, showStroke: item.isToday, strokeColor: UIColor.systemYellow, strokeWidth: 1.5, strokeOutset: 1.0)
        }
    }
    
    func update(isHover: Bool) {
        self.isHover = isHover
    }
    
    func clearTagSubviews() {
        tagContainerView.subviews.forEach{ $0.removeFromSuperview() }
    }
    
    override var isHighlighted: Bool {
        didSet {
            setNeedsUpdateConfiguration()
        }
    }
    
    func generateTagView(tag: Tag, count: Int) -> TagView {
        let recordView = TagView()
        recordView.update(tag: tag, count: count)
        recordView.isUserInteractionEnabled = false
        return recordView
    }
}

struct BlockCellBackgroundConfiguration {
    static func configuration(for state: UICellConfigurationState, backgroundColor: UIColor = .clear, cornerRadius: CGFloat = 6.0, showStroke: Bool, strokeColor: UIColor, strokeWidth: CGFloat = 1.0, strokeOutset: CGFloat = -1.0) -> UIBackgroundConfiguration {
        var background = UIBackgroundConfiguration.clear()
        background.backgroundColor = backgroundColor
        background.cornerRadius = cornerRadius
        background.strokeWidth = strokeWidth
        background.strokeOutset = strokeOutset
        if showStroke {
            background.strokeColor = strokeColor
        } else {
            background.strokeColor = .clear
        }
        if #available(iOS 18.0, *) {
            background.shadowProperties.color = .systemGray
            background.shadowProperties.opacity = 0.1
            background.shadowProperties.radius = 6.0
            background.shadowProperties.offset = CGSize(width: 0.0, height: 2.0)
        }

        return background
    }
}
