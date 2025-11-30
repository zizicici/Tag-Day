//
//  BlockCell.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/4/29.
//

import UIKit
import ZCCalendar
import Collections

fileprivate extension UIConfigurationStateCustomKey {
    static let blockItem = UIConfigurationStateCustomKey("com.zizicici.tag.cell.block.item")
}

private extension UICellConfigurationState {
    var blockItem: (any BlockCellProtocol)? {
        set { self[.blockItem] = newValue as? AnyHashable }
        get { return self[.blockItem] as? (any BlockCellProtocol) }
    }
}

class BlockBaseCell: UICollectionViewCell {
    private var blockItem: (any BlockCellProtocol)? = nil
    
    func update(with newBlockItem: (any BlockCellProtocol)?) {
        switch (blockItem, newBlockItem) {
        case (nil, nil):
            return
        case (let lhs?, let rhs?) where areEqual(lhs, rhs):
            return
        default:
            break
        }
        
        blockItem = newBlockItem
        setNeedsUpdateConfiguration()
    }
    
    override var configurationState: UICellConfigurationState {
        var state = super.configurationState
        state.blockItem = self.blockItem
        return state
    }
    
    private func areEqual(_ lhs: any BlockCellProtocol, _ rhs: any BlockCellProtocol) -> Bool {
        return type(of: lhs) == type(of: rhs) && lhs.hashValue == rhs.hashValue
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
    
    private var cachedTagLayers: [TagLayer] = []
    
    var highlightColor: UIColor = .gray.withAlphaComponent(0.25)
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        isHover = false
    }
    
    private func setupViewsIfNeeded() {
        guard tagContainerView.superview == nil else { return }
        
        contentView.layer.addSublayer(dateLayer)
        
        contentView.addSubview(tagContainerView)
        
        isAccessibilityElement = true
        accessibilityTraits = .button
        
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { [weak self] (cell: Self, previousTraitCollection: UITraitCollection) in
            if cell.traitCollection.userInterfaceStyle != previousTraitCollection.userInterfaceStyle {
                self?.updateColor()
            }
        }
    }
    
    private func updateColor() {
        dateLayer.updateColor()
        
        for layer in tagContainerView.layer.sublayers ?? [] {
            layer.setNeedsDisplay()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let dateFrame = CGRect(x: 0, y: 4, width: bounds.width, height: 26)
        if !dateLayer.frame.equalTo(dateFrame) {
            dateLayer.frame = dateFrame
        }
        
        let tagContainerFrame = CGRect(x: 3.0, y: 32.0, width: bounds.width - 6.0, height: bounds.height - 36.0)
        if !tagContainerView.frame.equalTo(tagContainerFrame) {
            tagContainerView.frame = tagContainerFrame
        }
        
        updateTagFramesIfNeeded()
    }
    
    override func updateConfiguration(using state: UICellConfigurationState) {
        super.updateConfiguration(using: state)
        setupViewsIfNeeded()
        
        if let item = state.blockItem {
            var backgroundColor = item.backgroundColor

            if isHover || isHighlighted {
                backgroundColor = highlightColor.overlay(on: backgroundColor)
            }
            
            dateLayer.update(text: item.getDay(), secondaryText: item.secondaryCalendar ?? "", textColor: item.foregroundColor)
            
            // 获取需要显示的tag数据
            let tagData: [(tag: Tag, count: Int)] = item.getTagData()
            
            // 复用或创建tagViews
            while cachedTagLayers.count > tagData.count {
                let view = cachedTagLayers.removeLast()
                view.removeFromSuperlayer()
            }
            
            while cachedTagLayers.count < tagData.count {
                let tagLayer = TagLayer()
                tagContainerView.layer.addSublayer(tagLayer)
                cachedTagLayers.append(tagLayer)
            }
            
            for (index, (tag, count)) in tagData.enumerated() {
                let tagLayer = cachedTagLayers[index]
                let isDark = traitCollection.userInterfaceStyle == .dark
                tagLayer.update(title: tag.title, count: count, tagColor: tag.getColorString(isDark: isDark), textColor: tag.getTitleColorString(isDark: isDark), isDark: isDark, isSymbol: item.isSymbol)
            }
            
            updateTagFramesIfNeeded()
            
            accessibilityLabel = item.getA11yLabel()
            accessibilityValue = item.getA11yValue()
            accessibilityHint = item.getA11yHint()
            
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
    
    func updateTagFramesIfNeeded() {
        let tagHeight = 20.0
        let tagSpacing = 3.0
        for (index, tagLayer) in cachedTagLayers.enumerated() {
            let tagFrame = CGRect(x: 0, y: Double(index) * (tagHeight + tagSpacing), width: tagContainerView.frame.width, height: 20)
            if !tagLayer.frame.equalTo(tagFrame) {
                tagLayer.frame = tagFrame
            }
        }
    }
    
    public func getTagOrder(in position: CGPoint) -> Int? {
        for (index, layer) in cachedTagLayers.enumerated() {
            if layer.frame.contains(CGPoint(x: position.x - tagContainerView.frame.origin.x, y: position.y - tagContainerView.frame.origin.y)) {
                return index
            }
        }
        return nil
    }
}

struct BlockCellBackgroundConfiguration {
    static func configuration(for state: UICellConfigurationState, backgroundColor: UIColor = .clear, cornerRadius: CGFloat = 6.0, showStroke: Bool, strokeColor: UIColor, strokeWidth: CGFloat = 1.0, strokeOutset: CGFloat = -1.0) -> UIBackgroundConfiguration {
        var background = UIBackgroundConfiguration.clear()
        background.backgroundColor = backgroundColor
        background.cornerRadius = cornerRadius
        background.strokeWidth = strokeWidth
        background.strokeOutset = strokeOutset
        background.backgroundColorTransformer = UIConfigurationColorTransformer({ color in
            if state.isSelected {
                return UIColor.gray.withAlphaComponent(0.5).overlay(on: color)
            } else {
                return color
            }
        })
        
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
