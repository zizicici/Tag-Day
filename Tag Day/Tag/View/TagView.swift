//
//  TagView.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/6/16.
//

import UIKit

class TagView: UIView {
    var label: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    var countLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 10, weight: .semibold)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private var labelTrailingConstraint: NSLayoutConstraint!
    private let defaultLabelInset: CGFloat = 2.0
    private let countLabelWidth: CGFloat = 14.0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        layer.cornerRadius = 3.0
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        addSubview(label)
        addSubview(countLabel)
        
        labelTrailingConstraint = label.trailingAnchor.constraint(
            equalTo: trailingAnchor,
            constant: -defaultLabelInset
        )
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: defaultLabelInset),
            label.topAnchor.constraint(equalTo: topAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor),
            labelTrailingConstraint,
            
            countLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -1),
            countLabel.widthAnchor.constraint(equalToConstant: countLabelWidth),
            countLabel.topAnchor.constraint(equalTo: topAnchor),
            countLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 8)
        ])
    }
    
    func update(tag: Tag, count: Int = 1) {
        if label.text != tag.title {
            label.text = tag.title
        }
        
        if count > 1 {
            countLabel.isHidden = false
            let countText = "×\(count)"
            if countLabel.text != countText {
                countLabel.text = countText
            }
            labelTrailingConstraint.constant = -countLabelWidth
        } else {
            countLabel.isHidden = true
            labelTrailingConstraint.constant = -defaultLabelInset
        }
        
        if let tagColor = UIColor(string: tag.color) {
            if tagColor.isLight {
                label.textColor = .black.withAlphaComponent(0.8)
            } else {
                label.textColor = .white.withAlphaComponent(0.95)
            }
            countLabel.textColor = label.textColor
            backgroundColor = tagColor
        }
    }
}

class TagLayer: CALayer {
    // MARK: - Properties
    private var tagTitle: String = ""
    private var count: Int = 1
    private var tagColor: UIColor = .clear
    private var textColor: UIColor = .clear
    
    private struct SharedCache {
        static var attributedStrings: [String: NSAttributedString] = [:]
        static var countAttributedStrings: [String: NSAttributedString] = [:]
        static let cacheQueue = DispatchQueue(label: "com.zizicic.tag.TagLayer.cache", qos: .userInteractive, attributes: .concurrent)
    }
    
    private let defaultLabelInset: CGFloat = 2.0
    private let countLabelWidth: CGFloat = 14.0
    private let textFontSize: CGFloat = 12.0
    private let countFontSize: CGFloat = 10.0
    private let minimumScaleFactor: CGFloat = 0.5
    
    // MARK: - Initialization
    override init() {
        super.init()
        setup()
    }
    
    override init(layer: Any) {
        super.init(layer: layer)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        masksToBounds = true
        cornerRadius = 3.0
        contentsScale = UIScreen.main.scale
        backgroundColor = UIColor.clear.cgColor
        needsDisplayOnBoundsChange = true
        drawsAsynchronously = true
    }
    
    // MARK: - Update Content
    func update(tag: Tag, count: Int = 1) {
        // 检查是否需要更新
        let colorChanged: Bool
        if let newColor = UIColor(string: tag.color) {
            colorChanged = tagColor != newColor
            tagColor = newColor
            textColor = newColor.isLight ? .black.withAlphaComponent(0.8) : .white.withAlphaComponent(0.95)
        } else {
            colorChanged = false
        }
        
        let titleChanged = tagTitle != tag.title
        let countChanged = self.count != count
        
        if !titleChanged && !countChanged && !colorChanged {
            return
        }
        
        // 更新属性
        tagTitle = tag.title
        self.count = count
        
        setNeedsDisplay()
    }
    
    // MARK: - Drawing
    override func draw(in ctx: CGContext) {
        super.draw(in: ctx)
        
        // 绘制背景
        ctx.setFillColor(tagColor.cgColor)
        ctx.fill(bounds)
        
        // 保存上下文状态
        ctx.saveGState()
        defer { ctx.restoreGState() }
        
        // 翻转坐标系
        ctx.textMatrix = .identity
        ctx.translateBy(x: 0, y: bounds.height)
        ctx.scaleBy(x: 1.0, y: -1.0)
        
        // 绘制主文本
        if let attributedString = getAttributedString() {
            let textRect = count > 1 ?
                CGRect(x: defaultLabelInset, y: 0,
                      width: bounds.width - countLabelWidth - defaultLabelInset,
                      height: bounds.height) :
                CGRect(x: defaultLabelInset, y: 0,
                      width: bounds.width - 2 * defaultLabelInset,
                      height: bounds.height)
            
            drawScaledText(attributedString: attributedString, in: textRect, context: ctx)
        }
        
        // 绘制计数文本
        if count > 1, let countString = getCountAttributedString() {
            let countRect = CGRect(x: bounds.width - countLabelWidth, y: 8,
                                  width: countLabelWidth, height: 12)
            drawScaledText(attributedString: countString, in: countRect, context: ctx)
        }
    }
    
    private func drawScaledText(attributedString: NSAttributedString, in rect: CGRect, context: CGContext) {
        // 获取原始字体
        let originalFont = attributedString.attribute(.font, at: 0, effectiveRange: nil) as? UIFont ?? UIFont.systemFont(ofSize: 12)
        let originalFontSize = originalFont.pointSize
        
        // 计算文本所需宽度
        let line = CTLineCreateWithAttributedString(attributedString)
        let lineWidth = CTLineGetTypographicBounds(line, nil, nil, nil)
        
        // 计算需要的缩放比例
        let availableWidth = rect.width
        let requiredScale = min(1.0, availableWidth / CGFloat(lineWidth))
        let scaleFactor = max(requiredScale, minimumScaleFactor)
        let scaledFontSize = originalFontSize * scaleFactor
        
        // 如果不需要缩放，直接绘制
        guard scaleFactor < 1.0 else {
            drawSingleLineCentered(attributedString: attributedString, in: rect, context: context)
            return
        }
        
        // 创建缩放后的属性字符串
        let scaledFont = originalFont.withSize(scaledFontSize)
        let mutableString = NSMutableAttributedString(attributedString: attributedString)
        mutableString.addAttribute(.font, value: scaledFont, range: NSRange(location: 0, length: mutableString.length))
        
        // 绘制缩放后的文本
        drawSingleLineCentered(attributedString: mutableString, in: rect, context: context)
    }
    
    private func drawSingleLineCentered(attributedString: NSAttributedString, in rect: CGRect, context: CGContext) {
        let line = CTLineCreateWithAttributedString(attributedString)
        
        // 计算文本宽度
        let lineWidth = CTLineGetTypographicBounds(line, nil, nil, nil)
        
        // 获取字体metrics
        let font = attributedString.attribute(.font, at: 0, effectiveRange: nil) as? UIFont ?? UIFont.systemFont(ofSize: 12)
        let lineHeight = font.lineHeight
        let descender = font.descender
        
        // 计算绘制原点
        let textX = rect.minX + max(0, (rect.width - CGFloat(lineWidth)) / 2)
        let textY = rect.minY + (rect.height - lineHeight) / 2 - descender
        
        // 设置绘制位置
        context.textPosition = CGPoint(x: textX, y: textY)
        
        // 绘制文本
        CTLineDraw(line, context)
    }
    
    private func cacheKey(for text: String, color: UIColor, font: UIFont) -> String {
        let colorHash = color.hashValue
        let combinedHash = text.hashValue ^ colorHash ^ font.pointSize.hashValue ^ font.fontName.hashValue ^ font.fontDescriptor.symbolicTraits.rawValue.hashValue
        return "\(combinedHash)"
    }
    
    // MARK: - Text Attributes
    private func getAttributedString() -> NSAttributedString? {
        let font = UIFont.systemFont(ofSize: textFontSize, weight: .medium)
        let text = tagTitle
        
        let cacheKey = cacheKey(for: text, color: textColor, font: font)
        
        if let cached = SharedCache.cacheQueue.sync(execute: {
            SharedCache.attributedStrings[cacheKey]
        }) {
            return cached
        }
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor
        ]
        
        let string = NSAttributedString(string: text, attributes: attributes)
        
        SharedCache.cacheQueue.async(flags: .barrier) {
            SharedCache.attributedStrings[cacheKey] = string
        }
        
        return string
    }
    
    private func getCountAttributedString() -> NSAttributedString? {
        let font = UIFont.systemFont(ofSize: countFontSize, weight: .semibold)
        let countText = "×\(count)"
        
        let cacheKey = cacheKey(for: countText, color: textColor, font: font)
        
        if let cached = SharedCache.cacheQueue.sync(execute: {
            SharedCache.countAttributedStrings[cacheKey]
        }) {
            return cached
        }
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor
        ]
        
        let string = NSAttributedString(string: countText, attributes: attributes)
        
        SharedCache.cacheQueue.async(flags: .barrier) {
            SharedCache.countAttributedStrings[cacheKey] = string
        }
        
        return string
    }
}
