//
//  DateView.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/6/22.
//

import UIKit
import CoreText

class DateLayer: CALayer {
    private let horizontalLayer = HorizontalTextLayer()
    private let verticalLayer = VerticalTextLayer()
    
    private var currentLabelInset: CGFloat = 6.0
    private var layoutText: (horizontalText: String, verticalText: String)? = nil
    
    override init() {
        super.init()
        
        addSublayer(horizontalLayer)
        addSublayer(verticalLayer)
        
        verticalLayer.isHidden = true
        
        horizontalLayer.font = UIFont.monospacedSystemFont(ofSize: 15, weight: .regular)
        horizontalLayer.textColor = UIColor.label
        
        // CALayers need to explicitly set contentsScale for proper retina display
        contentsScale = UIScreen.main.scale
        horizontalLayer.contentsScale = UIScreen.main.scale
        verticalLayer.contentsScale = UIScreen.main.scale
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(layer: Any) {
        super.init(layer: layer)
        if let dateLayer = layer as? DateLayer {
            self.currentLabelInset = dateLayer.currentLabelInset
        }
    }
    
    func update(text: String, secondaryText: String, textColor: UIColor) {
        guard layoutText?.horizontalText != text || layoutText?.verticalText != secondaryText else {
            return
        }
        
        layoutText = (text, secondaryText)
        horizontalLayer.text = text
        horizontalLayer.textColor = textColor.withAlphaComponent(0.85)
        
        let hasSecondaryText = !secondaryText.isEmpty
        verticalLayer.isHidden = !hasSecondaryText
        
        currentLabelInset = hasSecondaryText ? 14.0 : 6.0
        
        if hasSecondaryText {
            verticalLayer.configure(
                text: secondaryText,
                font: .systemFont(ofSize: 7.0, weight: .black),
                textColor: textColor.withAlphaComponent(0.6),
                lineSpacing: 0.0
            )
        }
        
        setNeedsLayout()
    }
    
    func updateColor() {
        horizontalLayer.setNeedsDisplay()
        verticalLayer.setNeedsDisplay()
    }
    
    override func layoutSublayers() {
        super.layoutSublayers()
        
        let labelInsetTrailing = currentLabelInset + (verticalLayer.isHidden ? 0 : 7.0)
        
        let labelHeight: CGFloat = 20.0
        let labelTopInset: CGFloat = 3.0
        let labelLeadingInset: CGFloat = 6.0
        
        let labelWidth = bounds.width - labelLeadingInset - labelInsetTrailing
        
        let newFrame = CGRect(
            x: labelLeadingInset,
            y: labelTopInset,
            width: labelWidth,
            height: labelHeight
        )
        if !horizontalLayer.frame.equalTo(newFrame) {
            horizontalLayer.frame = newFrame
        }
        
        let verticalSize = verticalLayer.textSize()
        
        if !verticalLayer.isHidden, !verticalLayer.bounds.size.equalTo(verticalSize) {
            verticalLayer.frame = CGRect(
                x: bounds.width - verticalSize.width - 7.0,
                y: bounds.midY - verticalSize.height / 2,
                width: verticalSize.width,
                height: verticalSize.height
            )
        }
    }
}

class DateView: UIView {
    private let horizontalLayer = HorizontalTextLayer()
    private let verticalLayer = VerticalTextLayer()
    
    private var currentLabelInset: CGFloat = 6.0
    
    private var mainText: String = ""
    private var mainTextColor: UIColor = .label
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        layer.addSublayer(horizontalLayer)
        layer.addSublayer(verticalLayer)
        
        verticalLayer.isHidden = true
        
        horizontalLayer.font = UIFont.monospacedSystemFont(ofSize: 15, weight: .regular)
        horizontalLayer.textColor = UIColor.label
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(text: String, secondaryText: String, textColor: UIColor) {
        if mainText != text {
            mainText = text
            horizontalLayer.text = text
        }
        mainTextColor = textColor
        horizontalLayer.textColor = textColor.withAlphaComponent(0.85)
        
        let hasSecondaryText = !secondaryText.isEmpty
        verticalLayer.isHidden = !hasSecondaryText
        
        currentLabelInset = hasSecondaryText ? 14.0 : 6.0
        
        if hasSecondaryText {
            verticalLayer.configure(
                text: secondaryText,
                font: .systemFont(ofSize: 8.0, weight: .black),
                textColor: textColor.withAlphaComponent(0.6),
                lineSpacing: 0.0
            )
        }
        
        setNeedsLayout()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let labelInsetTrailing = currentLabelInset + (verticalLayer.isHidden ? 0 : 7.0)
        
        let labelHeight: CGFloat = 20.0
        let labelTopInset: CGFloat = 3.0
        let labelLeadingInset: CGFloat = 6.0
        
        let labelWidth = bounds.width - labelLeadingInset - labelInsetTrailing
        
        let newFrame = CGRect(
            x: labelLeadingInset,
            y: labelTopInset,
            width: labelWidth,
            height: labelHeight
        )
        if !horizontalLayer.frame.equalTo(newFrame) {
            horizontalLayer.frame = newFrame
        }
        
        let verticalSize = verticalLayer.textSize()
        
        if !verticalLayer.isHidden, !verticalLayer.bounds.size.equalTo(verticalSize) {
            verticalLayer.frame = CGRect(
                x: bounds.width - verticalSize.width - 7.0,
                y: bounds.midY - verticalSize.height / 2,
                width: verticalSize.width,
                height: verticalSize.height
            )
        }
    }
}

final class HorizontalTextLayer: CALayer {
    var text: String = "" {
        didSet {
            if oldValue != text {
                setNeedsDisplay()
            }
        }
    }
    
    var font: UIFont = UIFont.monospacedSystemFont(ofSize: 15, weight: .regular) {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var textColor: UIColor = .label {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override init() {
        super.init()
        contentsScale = UIScreen.main.scale
        isOpaque = false
        needsDisplayOnBoundsChange = true
    }
    
    override init(layer: Any) {
        super.init(layer: layer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(in ctx: CGContext) {
        super.draw(in: ctx)
        guard !text.isEmpty else { return }
        
        ctx.saveGState()
        
        // 翻转坐标系，CoreText坐标系原点在左下角
        ctx.textMatrix = .identity
        ctx.translateBy(x: 0, y: bounds.height)
        ctx.scaleBy(x: 1.0, y: -1.0)
        
        // 创建属性字符串
        let attrString = NSAttributedString(
            string: text,
            attributes: [
                .font: font,
                .foregroundColor: textColor.cgColor
            ]
        )
        
        // 创建 CTLine
        let line = CTLineCreateWithAttributedString(attrString)
        
        // 计算绘制起点，水平居中，垂直居中
        let lineBounds = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)
        let x = (bounds.width - lineBounds.width) / 2 - lineBounds.minX
        let y = (bounds.height - lineBounds.height) / 2 - lineBounds.minY
        
        ctx.textPosition = CGPoint(x: x, y: y)
        CTLineDraw(line, ctx)
        
        ctx.restoreGState()
    }
}

final class VerticalTextLayer: CALayer {
    private struct CacheKey: Hashable {
        let text: String
        let font: UIFont
        let spacing: CGFloat
    }
    
    private static var sizeCache: [CacheKey: CGSize] = [:]
    private static let cacheQueue = DispatchQueue(label: "com.zizicici.tag.VerticalTextLayer.cache", qos: .userInteractive, attributes: .concurrent)
    
    private static var charCache = NSCache<NSNumber, CTLine>()
    
    private var _text: String = ""
    private var _font: UIFont = .systemFont(ofSize: 17)
    private var _textColor: UIColor = .black
    private var _lineSpacing: CGFloat = 0
    
    var text: String {
        get { _text }
        set {
            if _text != newValue {
                _text = newValue
                setNeedsDisplay()
            }
        }
    }
    
    var font: UIFont {
        get { _font }
        set {
            if _font != newValue {
                _font = newValue
                setNeedsDisplay()
            }
        }
    }
    
    var textColor: UIColor {
        get { _textColor }
        set {
            if _textColor != newValue {
                _textColor = newValue
                setNeedsDisplay()
            }
        }
    }
    
    var lineSpacing: CGFloat {
        get { _lineSpacing }
        set {
            if _lineSpacing != newValue {
                _lineSpacing = newValue
                setNeedsDisplay()
            }
        }
    }

    override init() {
        super.init()
        contentsScale = UIScreen.main.scale
        isOpaque = false
    }

    override init(layer: Any) {
        super.init(layer: layer)
        if let layer = layer as? VerticalTextLayer {
            self.text = layer.text
            self.font = layer.font
            self.textColor = layer.textColor
            self.lineSpacing = layer.lineSpacing
        }
        contentsScale = UIScreen.main.scale
        isOpaque = false
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        contentsScale = UIScreen.main.scale
        isOpaque = false
    }
    
    func configure(text: String,
                  font: UIFont,
                  textColor: UIColor,
                  lineSpacing: CGFloat) {
        var needsDisplay = false
        
        if text != _text {
            _text = text
            needsDisplay = true
        }
        
        if font != _font {
            _font = font
            needsDisplay = true
        }
        
        if textColor != _textColor {
            _textColor = textColor
            needsDisplay = true
        }
        
        if lineSpacing != _lineSpacing {
            _lineSpacing = lineSpacing
            needsDisplay = true
        }
        
        if needsDisplay {
            setNeedsDisplay()
        }
    }

    func textSize() -> CGSize {
        guard !text.isEmpty else { return .zero }
        
        let cacheKey = CacheKey(text: text, font: font, spacing: lineSpacing)
        if let cachedSize = Self.cacheQueue.sync(execute: {
            return Self.sizeCache[cacheKey]
        }) {
            return cachedSize
        }

        let ctFont = CTFontCreateWithFontDescriptor(font.fontDescriptor, font.pointSize, nil)

        var maxCharWidth: CGFloat = 0

        for char in text {
            let charStr = String(char)
            let attrString = NSAttributedString(string: charStr, attributes: [.font: ctFont])
            let line = CTLineCreateWithAttributedString(attrString)
            let charWidth = CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil))
            if charWidth > maxCharWidth {
                maxCharWidth = charWidth
            }
        }

        let lineHeight = font.lineHeight
        let totalHeight = lineHeight * CGFloat(text.count) + lineSpacing * CGFloat(max(text.count - 1, 0))

        let calculatedSize = CGSize(width: ceil(maxCharWidth), height: ceil(totalHeight))
        Self.cacheQueue.async(flags: .barrier) {
            Self.sizeCache[cacheKey] = calculatedSize
        }
        
        return calculatedSize
    }

    override func draw(in ctx: CGContext) {
        guard !text.isEmpty else { return }

        ctx.saveGState()

        let boundsSize = bounds.size

        // 翻转坐标系，保持 CoreText 正常绘制
        ctx.translateBy(x: 0, y: boundsSize.height)
        ctx.scaleBy(x: 1.0, y: -1.0)

        // 用 fontDescriptor 创建 CTFont 保持字体样式（包括 weight）
        let ctFont = CTFontCreateWithFontDescriptor(font.fontDescriptor, font.pointSize, nil)
        
        let lineHeight = font.lineHeight
        let desender = font.descender

        // 文字从上到下排列，起始 y 从 bounds.height - lineHeight 开始递减
        for (index, char) in text.enumerated() {
            let charStr = String(char)
            var hasher = Hasher()
            hasher.combine(char)
            hasher.combine(font.fontName)
            hasher.combine(font.pointSize)
            hasher.combine(font.fontDescriptor.symbolicTraits.rawValue)
            hasher.combine(textColor.hashValue)
            let cacheKey = NSNumber(value: hasher.finalize())
            let line: CTLine
            if let cachedLine = Self.charCache.object(forKey: cacheKey) {
                line = cachedLine
            } else {
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: ctFont,
                    .foregroundColor: textColor,
                    .baselineOffset: -desender
                ]
                let attrString = NSAttributedString(string: charStr, attributes: attrs)
                
                let newLine = CTLineCreateWithAttributedString(attrString)
                
                Self.charCache.setObject(newLine, forKey: cacheKey)
                
                line = newLine
            }
            
            let charWidth = CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil))

            let x = (boundsSize.width - charWidth) / 2

            // 计算 y 坐标：从上往下绘制
            let y = boundsSize.height - (lineHeight + lineSpacing) * CGFloat(index + 1) + (lineSpacing / 2)

            ctx.textPosition = CGPoint(x: x, y: y)
            
            CTLineDraw(line, ctx)
        }

        ctx.restoreGState()
    }
}
