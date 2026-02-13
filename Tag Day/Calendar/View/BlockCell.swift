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
    private struct TagRenderData: Equatable {
        let title: String
        let count: Int
        let tagColor: String
        let textColor: String
    }
    
    private struct ContentSignature: Equatable {
        let index: Int
        let secondaryText: String
        let a11ySecondaryText: String
        let textColorToken: UInt64
        let isToday: Bool
        let isSymbol: Bool
        let isDark: Bool
        let tags: [TagRenderData]
    }
    
    private static let sRGBColorSpace: CGColorSpace = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
    
    var isHover: Bool = false {
        didSet {
            if oldValue != isHover {
                applyBackgroundIfPossible(using: configurationState)
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
    private var visibleTagLayerCount: Int = 0
    private var renderedItemIdentifier: AnyHashable?
    private var renderedIsDarkMode: Bool?
    private var renderedContentSignature: ContentSignature?
    private var currentBaseBackgroundColor: UIColor?
    private var currentShowStroke: Bool = false
    
    var highlightColor: UIColor = .gray.withAlphaComponent(0.25)
    private let tagHeight: CGFloat = 20.0
    private let tagSpacing: CGFloat = 3.0
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        isHover = false
        renderedItemIdentifier = nil
        renderedIsDarkMode = nil
        renderedContentSignature = nil
        currentBaseBackgroundColor = nil
        currentShowStroke = false
        let displayCount = min(visibleTagLayerCount, cachedTagLayers.count)
        if displayCount > 0 {
            for index in 0..<displayCount {
                cachedTagLayers[index].isHidden = true
            }
        }
        visibleTagLayerCount = 0
    }
    
    private func setupViewsIfNeeded() {
        guard tagContainerView.superview == nil else { return }
        
        contentView.layer.addSublayer(dateLayer)
        
        contentView.addSubview(tagContainerView)
        
        isAccessibilityElement = true
        accessibilityTraits = .button
    }
    
    private func updateColor() {
        RenderMetrics.increment("blockCell.updateColor.calls")
        renderedItemIdentifier = nil
        renderedIsDarkMode = nil
        renderedContentSignature = nil
        dateLayer.updateColor(traitCollection: traitCollection)
        setNeedsUpdateConfiguration()
    }
    
    private func updateTagLayers(tagData: [TagRenderData], isDark: Bool, isSymbol: Bool) {
        RenderMetrics.increment("blockCell.updateTagLayers.calls")
        RenderMetrics.increment("blockCell.updateTagLayers.tagCount.total", by: tagData.count)
        let displayCount = tagData.count
        
        // 仅增不减，减少 add/remove sublayer 抖动；超出显示数量的 layer 采用 hidden
        visibleTagLayerCount = displayCount
        
        var createdCount = 0
        while cachedTagLayers.count < displayCount {
            let tagLayer = TagLayer()
            tagContainerView.layer.addSublayer(tagLayer)
            cachedTagLayers.append(tagLayer)
            createdCount += 1
        }
        if createdCount > 0 {
            RenderMetrics.increment("blockCell.tagLayer.created", by: createdCount)
        }
        
        for index in 0..<displayCount {
            let data = tagData[index]
            let tagLayer = cachedTagLayers[index]
            if tagLayer.isHidden {
                tagLayer.isHidden = false
            }
            tagLayer.update(
                title: data.title,
                count: data.count,
                tagColor: data.tagColor,
                textColor: data.textColor,
                isDark: isDark,
                isSymbol: isSymbol
            )
        }
        
        if cachedTagLayers.count > displayCount {
            let start = displayCount
            for index in start..<cachedTagLayers.count where !cachedTagLayers[index].isHidden {
                cachedTagLayers[index].isHidden = true
            }
        }
    }
    
    private func buildTagRenderData(from tagData: [(tag: Tag, count: Int)], isDark: Bool) -> [TagRenderData] {
        var renderData: [TagRenderData] = []
        renderData.reserveCapacity(tagData.count)
        
        for (tag, count) in tagData {
            renderData.append(.init(
                title: tag.title,
                count: count,
                tagColor: tag.getColorString(isDark: isDark),
                textColor: tag.getTitleColorString(isDark: isDark)
            ))
        }
        
        return renderData
    }
    
    private func makeContentSignature(item: any BlockCellProtocol,
                                      isDark: Bool,
                                      tagRenderData: [TagRenderData]) -> ContentSignature {
        let resolvedColor = item.foregroundColor.resolvedColor(with: traitCollection)
        return ContentSignature(
            index: item.index,
            secondaryText: item.secondaryCalendar ?? "",
            a11ySecondaryText: item.a11ySecondaryCalendar ?? "",
            textColorToken: Self.colorToken(for: resolvedColor),
            isToday: item.isToday,
            isSymbol: item.isSymbol,
            isDark: isDark,
            tags: tagRenderData
        )
    }
    
    private func applyBackgroundIfPossible(using state: UICellConfigurationState) {
        guard let currentBaseBackgroundColor else { return }
        
        var backgroundColor = currentBaseBackgroundColor
        if isHover || isHighlighted {
            backgroundColor = highlightColor.overlay(on: backgroundColor)
        }
        
        backgroundConfiguration = BlockCellBackgroundConfiguration.configuration(
            for: state,
            backgroundColor: backgroundColor,
            cornerRadius: 6.0,
            showStroke: currentShowStroke,
            strokeColor: UIColor.systemYellow,
            strokeWidth: 1.5,
            strokeOutset: 1.0
        )
    }
    
    private static func colorToken(for color: UIColor) -> UInt64 {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        if color.getRed(&r, green: &g, blue: &b, alpha: &a) {
            return packedColorToken(r: r, g: g, b: b, a: a)
        }
        
        let candidateColor = color.cgColor.converted(to: sRGBColorSpace, intent: .defaultIntent, options: nil) ?? color.cgColor
        guard let components = candidateColor.components else {
            return UInt64(bitPattern: Int64(color.hashValue))
        }
        
        switch components.count {
        case 2:
            let white = components[0]
            return packedColorToken(r: white, g: white, b: white, a: components[1])
        case 3:
            return packedColorToken(r: components[0], g: components[1], b: components[2], a: 1.0)
        default:
            return packedColorToken(r: components[0], g: components[1], b: components[2], a: components[3])
        }
    }
    
    private static func packedColorToken(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) -> UInt64 {
        let rr = UInt64((max(0.0, min(1.0, r)) * 255.0).rounded())
        let gg = UInt64((max(0.0, min(1.0, g)) * 255.0).rounded())
        let bb = UInt64((max(0.0, min(1.0, b)) * 255.0).rounded())
        let aa = UInt64((max(0.0, min(1.0, a)) * 255.0).rounded())
        return (rr << 24) | (gg << 16) | (bb << 8) | aa
    }
    
    private func shouldUpdateDate(from oldSignature: ContentSignature?, to newSignature: ContentSignature) -> Bool {
        guard let oldSignature else { return true }
        return oldSignature.index != newSignature.index
            || oldSignature.secondaryText != newSignature.secondaryText
            || oldSignature.textColorToken != newSignature.textColorToken
            || oldSignature.isDark != newSignature.isDark
    }
    
    private func shouldUpdateTags(from oldSignature: ContentSignature?, to newSignature: ContentSignature) -> Bool {
        guard let oldSignature else { return true }
        return oldSignature.isSymbol != newSignature.isSymbol
            || oldSignature.isDark != newSignature.isDark
            || oldSignature.tags != newSignature.tags
    }
    
    private func shouldUpdateAccessibility(from oldSignature: ContentSignature?,
                                           to newSignature: ContentSignature,
                                           didUpdateTags: Bool) -> Bool {
        guard let oldSignature else { return true }
        return oldSignature.index != newSignature.index
            || oldSignature.a11ySecondaryText != newSignature.a11ySecondaryText
            || oldSignature.isToday != newSignature.isToday
            || didUpdateTags
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
        let metricsStart = RenderMetrics.begin()
        defer { RenderMetrics.end("blockCell.updateConfiguration.ms", from: metricsStart) }
        RenderMetrics.increment("blockCell.updateConfiguration.calls")
        
        super.updateConfiguration(using: state)
        setupViewsIfNeeded()
        
        if let item = state.blockItem {
            currentBaseBackgroundColor = item.backgroundColor
            currentShowStroke = item.isToday
            applyBackgroundIfPossible(using: state)
            
            let isDark = traitCollection.userInterfaceStyle == .dark
            let itemIdentifier = AnyHashable(item)
            if renderedItemIdentifier != itemIdentifier || renderedIsDarkMode != isDark {
                let rawTagData = item.getTagData()
                let tagRenderData = buildTagRenderData(from: rawTagData, isDark: isDark)
                let nextContentSignature = makeContentSignature(item: item, isDark: isDark, tagRenderData: tagRenderData)
                
                if renderedContentSignature != nextContentSignature {
                    RenderMetrics.increment("blockCell.content.apply")
                    let previousContentSignature = renderedContentSignature
                    let shouldUpdateDate = shouldUpdateDate(from: previousContentSignature, to: nextContentSignature)
                    let shouldUpdateTags = shouldUpdateTags(from: previousContentSignature, to: nextContentSignature)
                    
                    renderedContentSignature = nextContentSignature
                    renderedItemIdentifier = itemIdentifier
                    renderedIsDarkMode = isDark
                    
                    if shouldUpdateDate {
                        RenderMetrics.increment("blockCell.date.update.applied")
                        dateLayer.update(
                            text: item.getDay(),
                            secondaryText: item.secondaryCalendar ?? "",
                            textColor: item.foregroundColor,
                            traitCollection: traitCollection
                        )
                    } else {
                        RenderMetrics.increment("blockCell.date.update.skipped")
                    }
                    
                    if shouldUpdateTags {
                        RenderMetrics.increment("blockCell.tag.update.applied")
                        updateTagLayers(tagData: tagRenderData, isDark: isDark, isSymbol: item.isSymbol)
                        updateTagFramesIfNeeded()
                    } else {
                        RenderMetrics.increment("blockCell.tag.update.skipped")
                    }
                    
                    if shouldUpdateAccessibility(from: previousContentSignature, to: nextContentSignature, didUpdateTags: shouldUpdateTags) {
                        accessibilityLabel = item.getA11yLabel()
                        accessibilityValue = item.getA11yValue()
                        accessibilityHint = item.getA11yHint()
                    }
                } else {
                    RenderMetrics.increment("blockCell.content.skip")
                    RenderMetrics.increment("blockCell.content.skip.signature")
                    renderedItemIdentifier = itemIdentifier
                    renderedIsDarkMode = isDark
                }
            } else {
                RenderMetrics.increment("blockCell.content.skip")
                RenderMetrics.increment("blockCell.content.skip.identity")
            }
        }
    }
                
    func update(isHover: Bool) {
        self.isHover = isHover
    }
    
    override var isHighlighted: Bool {
        didSet {
            applyBackgroundIfPossible(using: configurationState)
        }
    }
    
    override var isSelected: Bool {
        didSet {
            applyBackgroundIfPossible(using: configurationState)
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard let previousTraitCollection else { return }
        guard previousTraitCollection.hasDifferentColorAppearance(comparedTo: traitCollection) else { return }
        RenderMetrics.increment("blockCell.traitChange.calls")
        updateColor()
    }
    
    func updateTagFramesIfNeeded() {
        let displayCount = min(visibleTagLayerCount, cachedTagLayers.count)
        for index in 0..<displayCount {
            let tagLayer = cachedTagLayers[index]
            let tagFrame = CGRect(
                x: 0,
                y: CGFloat(index) * (tagHeight + tagSpacing),
                width: tagContainerView.frame.width,
                height: tagHeight
            )
            if !tagLayer.frame.equalTo(tagFrame) {
                tagLayer.frame = tagFrame
            }
        }
    }
    
    public func getTagOrder(in position: CGPoint) -> Int? {
        let displayCount = min(visibleTagLayerCount, cachedTagLayers.count)
        for index in 0..<displayCount {
            let layer = cachedTagLayers[index]
            if layer.isHidden {
                continue
            }
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
