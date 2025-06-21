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
    
    var label: DateView = DateView()
    
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
        guard label.superview == nil else { return }
        
        contentView.addSubview(label)
        label.snp.makeConstraints { make in
            make.top.equalTo(contentView).inset(4)
            make.leading.trailing.equalTo(contentView)
            make.height.equalTo(26)
        }
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        
        contentView.addSubview(tagContainerView)
        tagContainerView.snp.makeConstraints { make in
            make.top.equalTo(label.snp.bottom).offset(2)
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
            
            label.update(text: item.day.dayString(), secondaryText: item.secondaryCalendar ?? "", textColor: item.foregroundColor)
            
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

class DateView: UIView {
    private var label: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.textAlignment = .center
        label.font = UIFont.monospacedSystemFont(ofSize: 15.0, weight: .regular)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        
        return label
    }()
    
    private var verticalLabel: VerticalTextLabel = {
        let label = VerticalTextLabel()
        
        return label
    }()
    
    private var currentLabelInset: CGFloat = 6.0 {
        didSet {
            if oldValue != currentLabelInset {
                label.snp.updateConstraints { make in
                    make.trailing.equalTo(self).inset(currentLabelInset)
                }
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(label)
        label.snp.makeConstraints { make in
            make.top.equalTo(self).inset(3)
            make.leading.equalTo(self).inset(6)
            make.trailing.equalTo(self).inset(6.0)
            make.height.equalTo(20)
            make.bottom.equalTo(self).inset(3)
        }
        addSubview(verticalLabel)
        verticalLabel.snp.makeConstraints { make in
            make.centerY.equalTo(self)
            make.trailing.equalTo(self).inset(7)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(text: String, secondaryText: String, textColor: UIColor) {
        if label.text != text {
            label.text = text
        }
        label.textColor = textColor.withAlphaComponent(0.85)
        let hasSecondaryText = !secondaryText.isEmpty && !secondaryText.isBlank
        verticalLabel.isHidden = !hasSecondaryText
        
        currentLabelInset = hasSecondaryText ? 14.0 : 6.0

        if hasSecondaryText {
            verticalLabel.configure(with: secondaryText, textColor: textColor.withAlphaComponent(0.6), font: .systemFont(ofSize: 6.5, weight: .black), spacing: 0.0)
        }
    }
}

final class VerticalTextLabel: UIView {
    private struct CacheKey: Hashable {
        let text: String
        let font: UIFont
        let spacing: CGFloat
        let maxWidth: CGFloat
    }
    
    private static var sizeCache: [CacheKey: CGSize] = [:]
    private static let cacheQueue = DispatchQueue(label: "com.verticalTextLabel.cache", qos: .userInteractive, attributes: .concurrent)
    
    private var textLayers: [CATextLayer] = []
    private var textColor: UIColor = .black
    private var font: UIFont = .systemFont(ofSize: 14)
    private var characterSpacing: CGFloat = 2
    private var currentText: String = ""
    private var lastLayoutBounds: CGRect = .zero
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        backgroundColor = .clear
        isOpaque = false
    }
    
    func configure(with text: String, textColor: UIColor, font: UIFont, spacing: CGFloat = 2) {
        // 检查是否有实际变化
        let needsUpdate = text != currentText || self.textColor != textColor || self.font != font || self.characterSpacing != spacing
        guard needsUpdate else { return }
        
        // 保存旧尺寸用于比较
        let oldIntrinsicSize = intrinsicContentSize
        
        // 更新属性
        self.currentText = text
        self.textColor = textColor
        self.font = font
        self.characterSpacing = spacing
        
        let targetCount = text.count
        let currentCount = textLayers.count
        
        // 调整图层数量
        if targetCount > currentCount {
            let newLayers = (currentCount..<targetCount).map { _ in createTextLayer() }
            newLayers.forEach { layer.addSublayer($0) }
            textLayers.append(contentsOf: newLayers)
        } else if targetCount < currentCount {
            for index in targetCount..<currentCount {
                textLayers[index].removeFromSuperlayer()
            }
            textLayers.removeLast(currentCount - targetCount)
        }
        
        // 配置所有图层
        for (index, textLayer) in textLayers.enumerated() {
            let character = String(text[text.index(text.startIndex, offsetBy: index)])
            if (textLayer.string as? String) != character {
                textLayer.string = character
                textLayer.foregroundColor = textColor.cgColor
                textLayer.font = font
                textLayer.fontSize = font.pointSize
            }
        }
        
        // 计算新尺寸
        let newIntrinsicSize = calculateIntrinsicContentSize()
        
        // 只在尺寸变化时通知系统
        if newIntrinsicSize != oldIntrinsicSize {
            invalidateIntrinsicContentSize()
            setNeedsLayout()
        }
    }
    
    override var intrinsicContentSize: CGSize {
        return calculateIntrinsicContentSize()
    }
    
    private func calculateIntrinsicContentSize() -> CGSize {
        guard !textLayers.isEmpty else {
            return CGSize(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric)
        }
        
        let maxWidth = bounds.width > 0 ? bounds.width : .greatestFiniteMagnitude
        let cacheKey = CacheKey(text: currentText, font: font, spacing: characterSpacing, maxWidth: maxWidth)
        
        // 尝试从全局缓存读取
        if let cachedSize = Self.cacheQueue.sync(execute: {
            return Self.sizeCache[cacheKey]
        }) {
            return cachedSize
        }
        
        // 计算尺寸
        let charHeight = font.lineHeight
        let totalHeight = CGFloat(textLayers.count) * (charHeight + characterSpacing) - characterSpacing
        
        // 计算最大字符宽度（限制在maxWidth内）
        var maxCharWidth: CGFloat = 0
        for layer in textLayers {
            guard let char = layer.string as? String else { continue }
            let size = char.size(withAttributes: [.font: font])
            maxCharWidth = min(max(size.width, maxCharWidth), maxWidth)
        }
        
        let calculatedSize = CGSize(
            width: maxCharWidth.rounded(.up),
            height: totalHeight.rounded(.up)
        )
        
        // 写入全局缓存
        Self.cacheQueue.async(flags: .barrier) {
            Self.sizeCache[cacheKey] = calculatedSize
        }
        
        return calculatedSize
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        guard !textLayers.isEmpty, bounds != lastLayoutBounds else {
            return
        }
        
        lastLayoutBounds = bounds
        
        let charHeight = font.lineHeight
        
        for (index, textLayer) in textLayers.enumerated() {
            let yPosition = CGFloat(index) * (charHeight + characterSpacing)
            textLayer.frame = CGRect(
                x: 0,
                y: yPosition,
                width: bounds.width,
                height: charHeight
            )
        }
    }
    
    static func clearCache() {
        cacheQueue.async(flags: .barrier) {
            sizeCache.removeAll()
        }
    }
    
    private func createTextLayer() -> CATextLayer {
        let textLayer = CATextLayer()
        textLayer.drawsAsynchronously = true
        textLayer.foregroundColor = textColor.cgColor
        textLayer.font = font
        textLayer.fontSize = font.pointSize
        textLayer.alignmentMode = .center
        textLayer.contentsScale = UIScreen.main.scale
        textLayer.truncationMode = .none
        textLayer.isWrapped = false
        textLayer.allowsFontSubpixelQuantization = true
        textLayer.masksToBounds = false
        return textLayer
    }
    
    deinit {
        textLayers.forEach { $0.removeFromSuperlayer() }
        textLayers.removeAll()
    }
}
