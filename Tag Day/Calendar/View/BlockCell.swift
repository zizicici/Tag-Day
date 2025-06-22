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
    
    var dateLayer = DateLayer()
    
    var tagContainerView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        
        return view
    }()
    
    private var cachedTagViews: [TagView] = []
    
    private var lastLayoutInfo: (count: Int, firstItemTop: CGFloat, spacing: CGFloat)?
    
    var highlightColor: UIColor = .gray.withAlphaComponent(0.25)
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        isHover = false
    }
    
    private func setupViewsIfNeeded() {
        guard dateLayer.superlayer == nil else { return }
        
        contentView.layer.addSublayer(dateLayer)
        
        contentView.addSubview(tagContainerView)
        tagContainerView.snp.makeConstraints { make in
            make.top.equalTo(contentView).offset(32)
            make.leading.trailing.equalTo(contentView).inset(3)
            make.bottom.equalTo(contentView).inset(4)
        }
        
        isAccessibilityElement = true
        accessibilityTraits = .button
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let dateFrame = CGRect(x: 0, y: 4, width: bounds.width, height: 26)
        if !dateLayer.frame.equalTo(dateFrame) {
            dateLayer.frame = dateFrame
        }
    }
    
    override func updateConfiguration(using state: UICellConfigurationState) {
        super.updateConfiguration(using: state)
        setupViewsIfNeeded()
        
        if let item = state.blockItem {
            var backgroundColor = item.backgroundColor

            if isHover || isHighlighted {
                backgroundColor = highlightColor.overlay(on: backgroundColor)
            }
            
            dateLayer.update(text: item.day.dayString(), secondaryText: item.secondaryCalendar ?? "", textColor: item.foregroundColor)
            
            // 获取需要显示的tag数据
            let tagData: [(tag: Tag, count: Int)]
            switch item.tagDisplayType {
            case .normal:
                tagData = item.records.compactMap { record in
                    item.tags.first(where: { $0.id == record.tagID }).map { (tag: $0, count: 1) }
                }
            case .aggregation:
                var orderedCounts = OrderedDictionary<Int64, Int>()
                for record in item.records {
                    orderedCounts[record.tagID, default: 0] += 1
                }
                tagData = orderedCounts.compactMap { key, value in
                    item.tags.first(where: { $0.id == key }).map { (tag: $0, count: value) }
                }
            }
            
            // 复用或创建tagViews
            while cachedTagViews.count > tagData.count {
                let view = cachedTagViews.removeLast()
                view.removeFromSuperview()
            }
            
            while cachedTagViews.count < tagData.count {
                let recordView = TagView()
                recordView.isUserInteractionEnabled = false
                tagContainerView.addSubview(recordView)
                cachedTagViews.append(recordView)
            }
            
            // 计算当前需要的布局信息
            let currentFirstItemTop: CGFloat = 0
            let currentSpacing: CGFloat = 3
            let currentLayoutInfo = (tagData.count, currentFirstItemTop, currentSpacing)
            
            // 检查是否需要更新约束
            let needsUpdateConstraints = lastLayoutInfo == nil || lastLayoutInfo! != currentLayoutInfo
            
            // 更新内容和约束
            for (index, (tag, count)) in tagData.enumerated() {
                let tagView = cachedTagViews[index]
                tagView.update(tag: tag, count: count)
            }
            
            if needsUpdateConstraints {
                for (index, tagView) in cachedTagViews.enumerated() {
                    tagView.snp.remakeConstraints { make in
                        make.leading.trailing.equalTo(tagContainerView)
                        make.height.equalTo(20)
                        if index == 0 {
                            make.top.equalTo(tagContainerView)
                        } else {
                            make.top.equalTo(cachedTagViews[index-1].snp.bottom).offset(3)
                        }
                    }
                }
                lastLayoutInfo = currentLayoutInfo
            }
            
            if item.isToday {
                accessibilityLabel = String(localized: "weekCalendar.today") + item.calendarString
            } else {
                accessibilityLabel = item.calendarString
            }
            
            backgroundConfiguration = BlockCellBackgroundConfiguration.configuration(for: state, backgroundColor: backgroundColor, cornerRadius: 6.0, showStroke: item.isToday, strokeColor: UIColor.systemYellow, strokeWidth: 1.5, strokeOutset: 1.0)
        }
    }
    
    func update(isHover: Bool) {
        self.isHover = isHover
    }
    
    override var isHighlighted: Bool {
        didSet {
            setNeedsUpdateConfiguration()
        }
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
