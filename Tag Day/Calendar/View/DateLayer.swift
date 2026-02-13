//
//  DateLayer.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/6/22.
//

import UIKit
import CoreText
import QuartzCore

class DateLayer: CALayer {
    private let horizontalLayer = HorizontalTextLayer()
    private let verticalLayer = VerticalTextLayer()
    private let horizontalFont = UIFont.monospacedSystemFont(ofSize: 15, weight: .regular)
    private let verticalFont = UIFont.systemFont(ofSize: 7.0, weight: .black)
    
    private var layoutText: (horizontalText: String, verticalText: String)? = nil
    private var baseTextColor: UIColor = .label
    
    override init() {
        super.init()
        
        addSublayer(horizontalLayer)
        addSublayer(verticalLayer)
        
        verticalLayer.isHidden = true
        
        horizontalLayer.font = horizontalFont
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
    }
    
    func update(text: String, secondaryText: String, textColor: UIColor, traitCollection: UITraitCollection = UITraitCollection.current) {
        RenderMetrics.increment("date.update.calls")
        let previousHorizontal = layoutText?.horizontalText
        let previousVertical = layoutText?.verticalText
        let previousHasSecondary = !(previousVertical?.isEmpty ?? true)
        let hasSecondaryText = !secondaryText.isEmpty
        let resolvedBaseColor = textColor.resolvedColor(with: traitCollection)
        
        layoutText = (text, secondaryText)
        baseTextColor = textColor
        horizontalLayer.configure(
            text: text,
            font: horizontalFont,
            textColor: resolvedBaseColor.withAlphaComponent(0.85)
        )
        
        verticalLayer.isHidden = !hasSecondaryText
        
        if hasSecondaryText {
            verticalLayer.configure(
                text: secondaryText,
                font: verticalFont,
                textColor: resolvedBaseColor.withAlphaComponent(0.6),
                lineSpacing: 0.0
            )
        }
        
        if previousHorizontal != text || previousVertical != secondaryText || previousHasSecondary != hasSecondaryText {
            RenderMetrics.increment("date.update.layout_needed")
            setNeedsLayout()
        } else {
            RenderMetrics.increment("date.update.layout_skipped")
        }
    }
    
    func updateColor(traitCollection: UITraitCollection = UITraitCollection.current) {
        RenderMetrics.increment("date.updateColor.calls")
        let resolvedBaseColor = baseTextColor.resolvedColor(with: traitCollection)
        horizontalLayer.textColor = resolvedBaseColor.withAlphaComponent(0.85)
        verticalLayer.textColor = resolvedBaseColor.withAlphaComponent(0.6)
        horizontalLayer.refreshForCurrentAppearance()
        verticalLayer.refreshForCurrentAppearance()
    }
    
    override func layoutSublayers() {
        let metricsStart = RenderMetrics.begin()
        defer { RenderMetrics.end("date.layoutSublayers.ms", from: metricsStart) }
        RenderMetrics.increment("date.layoutSublayers.calls")
        super.layoutSublayers()
        
        guard bounds.width > 0.0 else { return }
        
        let labelHeight: CGFloat = 20.0
        let labelTopInset: CGFloat = 3.0
        let spacing = 2.0
        
        if verticalLayer.isHidden {
            let newFrame = CGRect(
                x: 0,
                y: labelTopInset,
                width: bounds.width,
                height: labelHeight
            )
            
            if !horizontalLayer.frame.equalTo(newFrame) {
                horizontalLayer.frame = newFrame
            }
        } else {
            let labelWidth: CGFloat = 24.0
            let verticalSize = verticalLayer.textSize()

            let newFrame = CGRect(
                x: (bounds.width - labelWidth - verticalSize.width - spacing) / 2.0,
                y: labelTopInset,
                width: labelWidth,
                height: labelHeight
            )
            
            if !horizontalLayer.frame.equalTo(newFrame) {
                horizontalLayer.frame = newFrame
            }
            
            let newVerticalFrame = CGRect(
                x: newFrame.maxX + spacing,
                y: newFrame.midY - verticalSize.height / 2,
                width: verticalSize.width,
                height: verticalSize.height
            )
            if !verticalLayer.frame.equalTo(newVerticalFrame) {
                verticalLayer.frame = newVerticalFrame
            }
        }
    }
}

final class HorizontalTextLayer: CALayer {
    private struct LineCacheKey: Hashable {
        let text: String
        let fontName: String
        let fontSize: CGFloat
        let colorToken: UInt64
    }
    
    private struct LineCacheValue {
        let line: CTLine
        let bounds: CGRect
    }
    
    private static let maxSharedLineCacheEntries = 512
    private static var sharedLineCache: [LineCacheKey: LineCacheValue] = [:]
    private static let sharedLineCacheQueue = DispatchQueue(label: "com.zizicici.tag.horizontalTextLayer.sharedLineCache", qos: .userInteractive, attributes: .concurrent)
    private static let sRGBColorSpace: CGColorSpace = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
    
    private var _text: String = ""
    private var _font: UIFont = UIFont.monospacedSystemFont(ofSize: 15, weight: .regular)
    private var _textColor: UIColor = .label
    private var textColorToken: UInt64 = HorizontalTextLayer.colorToken(for: .label)
    
    private var cachedLine: CTLine?
    private var cachedLineBounds: CGRect = .zero
    
    var text: String {
        get { _text }
        set {
            if _text != newValue {
                _text = newValue
                invalidateLineAndDisplay()
            }
        }
    }
    
    var font: UIFont {
        get { _font }
        set {
            if _font != newValue {
                _font = newValue
                invalidateLineAndDisplay()
            }
        }
    }
    
    var textColor: UIColor {
        get { _textColor }
        set {
            if !_textColor.isEqual(newValue) {
                _textColor = newValue
                textColorToken = Self.colorToken(for: newValue)
                invalidateLineAndDisplay()
            }
        }
    }
    
    override init() {
        super.init()
        contentsScale = UIScreen.main.scale
        isOpaque = false
        needsDisplayOnBoundsChange = true
        drawsAsynchronously = true
    }
    
    override init(layer: Any) {
        super.init(layer: layer)
        if let layer = layer as? HorizontalTextLayer {
            _text = layer._text
            _font = layer._font
            _textColor = layer._textColor
            textColorToken = layer.textColorToken
        }
        contentsScale = UIScreen.main.scale
        isOpaque = false
        needsDisplayOnBoundsChange = true
        drawsAsynchronously = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(text: String, font: UIFont, textColor: UIColor) {
        var needsDisplay = false
        var needsInvalidateLine = false
        
        if _text != text {
            _text = text
            needsDisplay = true
            needsInvalidateLine = true
        }
        
        if _font != font {
            _font = font
            needsDisplay = true
            needsInvalidateLine = true
        }
        
        if !_textColor.isEqual(textColor) {
            _textColor = textColor
            textColorToken = Self.colorToken(for: textColor)
            needsDisplay = true
            needsInvalidateLine = true
        }
        
        if needsInvalidateLine {
            cachedLine = nil
            cachedLineBounds = .zero
        }
        
        if needsDisplay {
            setNeedsDisplay()
        }
    }
    
    private func invalidateLineAndDisplay() {
        cachedLine = nil
        cachedLineBounds = .zero
        setNeedsDisplay()
    }
    
    func refreshForCurrentAppearance() {
        textColorToken = Self.colorToken(for: _textColor)
        cachedLine = nil
        cachedLineBounds = .zero
        setNeedsDisplay()
    }
    
    private func lineCacheKeyForCurrentState() -> LineCacheKey {
        LineCacheKey(
            text: _text,
            fontName: _font.fontName,
            fontSize: _font.pointSize,
            colorToken: textColorToken
        )
    }
    
    private static func sharedLine(for key: LineCacheKey) -> LineCacheValue? {
        sharedLineCacheQueue.sync {
            sharedLineCache[key]
        }
    }
    
    private static func storeSharedLine(_ value: LineCacheValue, for key: LineCacheKey) {
        sharedLineCacheQueue.async(flags: .barrier) {
            sharedLineCache[key] = value
            if sharedLineCache.count > maxSharedLineCacheEntries {
                sharedLineCache.removeAll(keepingCapacity: true)
            }
        }
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
    
    private func lineForCurrentState() -> (line: CTLine, bounds: CGRect)? {
        guard !_text.isEmpty else { return nil }
        
        if let cachedLine {
            RenderMetrics.increment("date.horizontal.line_cache.hit")
            return (cachedLine, cachedLineBounds)
        }
        
        let cacheKey = lineCacheKeyForCurrentState()
        if let sharedLine = Self.sharedLine(for: cacheKey) {
            RenderMetrics.increment("date.horizontal.line_cache.hit")
            RenderMetrics.increment("date.horizontal.line_cache.shared.hit")
            cachedLine = sharedLine.line
            cachedLineBounds = sharedLine.bounds
            return (sharedLine.line, sharedLine.bounds)
        }
        
        RenderMetrics.increment("date.horizontal.line_cache.miss")
        RenderMetrics.increment("date.horizontal.line_cache.shared.miss")
        
        let attrString = NSAttributedString(
            string: _text,
            attributes: [
                .font: _font,
                .foregroundColor: _textColor.cgColor
            ]
        )
        
        let line = CTLineCreateWithAttributedString(attrString)
        let lineBounds = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)
        cachedLine = line
        cachedLineBounds = lineBounds
        Self.storeSharedLine(.init(line: line, bounds: lineBounds), for: cacheKey)
        
        return (line, lineBounds)
    }
    
    override func draw(in ctx: CGContext) {
        let metricsStart = RenderMetrics.begin()
        defer { RenderMetrics.end("date.horizontal.draw.ms", from: metricsStart) }
        guard let (line, lineBounds) = lineForCurrentState() else { return }
        ctx.saveGState()
        defer { ctx.restoreGState() }
        
        // 翻转坐标系，CoreText坐标系原点在左下角
        ctx.textMatrix = .identity
        ctx.translateBy(x: 0, y: bounds.height)
        ctx.scaleBy(x: 1.0, y: -1.0)
        
        // 计算绘制起点，水平居中，垂直居中
        let x = (bounds.width - lineBounds.width) / 2 - lineBounds.minX
        let y = (bounds.height - lineBounds.height) / 2 - lineBounds.minY
        
        ctx.textPosition = CGPoint(x: x, y: y)
        CTLineDraw(line, ctx)
    }
}

final class VerticalTextLayer: CALayer {
    private struct GlyphRenderItem {
        let line: CTLine
        let width: CGFloat
    }
    
    private struct SizeCacheKey: Hashable {
        let text: String
        let fontName: String
        let fontSize: CGFloat
        let lineSpacing: CGFloat
    }
    
    private struct RenderCacheKey: Hashable {
        let text: String
        let fontName: String
        let fontSize: CGFloat
        let lineSpacing: CGFloat
        let colorToken: UInt64
        let scale: CGFloat
    }
    
    private struct RenderImage {
        let image: CGImage
    }
    
    private static let maxSharedSizeCacheEntries = 1024
    private static var sharedTextSizeCache: [SizeCacheKey: CGSize] = [:]
    private static let sharedTextSizeCacheQueue = DispatchQueue(label: "com.zizicici.tag.verticalTextLayer.sharedSizeCache", qos: .userInteractive, attributes: .concurrent)
    
    private static let maxSharedRenderCacheEntries = 512
    private static var sharedRenderCache: [RenderCacheKey: RenderImage] = [:]
    private static let sharedRenderCacheQueue = DispatchQueue(label: "com.zizicici.tag.verticalTextLayer.sharedRenderCache", qos: .userInteractive, attributes: .concurrent)
    private static let sRGBColorSpace: CGColorSpace = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
    
    private var _text: String = ""
    private var _font: UIFont = .systemFont(ofSize: 17)
    private var _textColor: UIColor = .black
    private var _lineSpacing: CGFloat = 0
    private var textColorToken: UInt64 = VerticalTextLayer.colorToken(for: .black)
    
    private var needsGlyphRebuild = true
    private var glyphRenderItems: [GlyphRenderItem] = []
    private var maxGlyphWidth: CGFloat = 0
    private var cachedTextSize: CGSize?
    
    var text: String {
        get { _text }
        set {
            if _text != newValue {
                _text = newValue
                invalidateGlyphCache()
                setNeedsDisplay()
            }
        }
    }
    
    var font: UIFont {
        get { _font }
        set {
            if _font != newValue {
                _font = newValue
                invalidateGlyphCache()
                setNeedsDisplay()
            }
        }
    }
    
    var textColor: UIColor {
        get { _textColor }
        set {
            if !_textColor.isEqual(newValue) {
                _textColor = newValue
                textColorToken = Self.colorToken(for: newValue)
                invalidateGlyphCache()
                setNeedsDisplay()
            }
        }
    }
    
    var lineSpacing: CGFloat {
        get { _lineSpacing }
        set {
            if _lineSpacing != newValue {
                _lineSpacing = newValue
                cachedTextSize = nil
                setNeedsDisplay()
            }
        }
    }

    override init() {
        super.init()
        contentsScale = UIScreen.main.scale
        isOpaque = false
        needsDisplayOnBoundsChange = true
        drawsAsynchronously = true
    }

    override init(layer: Any) {
        super.init(layer: layer)
        if let layer = layer as? VerticalTextLayer {
            _text = layer._text
            _font = layer._font
            _textColor = layer._textColor
            _lineSpacing = layer._lineSpacing
            textColorToken = layer.textColorToken
        }
        contentsScale = UIScreen.main.scale
        isOpaque = false
        needsDisplayOnBoundsChange = true
        drawsAsynchronously = true
        needsGlyphRebuild = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        contentsScale = UIScreen.main.scale
        isOpaque = false
        needsDisplayOnBoundsChange = true
        drawsAsynchronously = true
    }
    
    func configure(text: String,
                  font: UIFont,
                  textColor: UIColor,
                  lineSpacing: CGFloat) {
        var needsDisplay = false
        var shouldInvalidateGlyph = false
        var shouldInvalidateSize = false
        
        if text != _text {
            _text = text
            shouldInvalidateGlyph = true
        }
        
        if font != _font {
            _font = font
            shouldInvalidateGlyph = true
        }
        
        if !_textColor.isEqual(textColor) {
            _textColor = textColor
            textColorToken = Self.colorToken(for: textColor)
            shouldInvalidateGlyph = true
        }
        
        if lineSpacing != _lineSpacing {
            _lineSpacing = lineSpacing
            shouldInvalidateSize = true
        }
        
        if shouldInvalidateGlyph {
            invalidateGlyphCache()
            needsDisplay = true
        } else if shouldInvalidateSize {
            cachedTextSize = nil
            needsDisplay = true
        }
        
        if needsDisplay {
            setNeedsDisplay()
        }
    }

    func textSize() -> CGSize {
        guard !_text.isEmpty else { return .zero }
        
        if let cachedTextSize {
            RenderMetrics.increment("date.vertical.textSize_cache.hit")
            RenderMetrics.increment("date.vertical.textSize.effective.hit")
            return cachedTextSize
        }
        RenderMetrics.increment("date.vertical.textSize_cache.miss")
        
        let cacheKey = SizeCacheKey(text: _text, fontName: _font.fontName, fontSize: _font.pointSize, lineSpacing: _lineSpacing)
        if let sharedSize = Self.sharedTextSize(for: cacheKey) {
            RenderMetrics.increment("date.vertical.textSize_shared.hit")
            RenderMetrics.increment("date.vertical.textSize.effective.hit")
            cachedTextSize = sharedSize
            return sharedSize
        }
        RenderMetrics.increment("date.vertical.textSize_shared.miss")
        RenderMetrics.increment("date.vertical.textSize.effective.miss")
        
        rebuildGlyphsIfNeeded()
        let lineHeight = _font.lineHeight
        let totalHeight = lineHeight * CGFloat(glyphRenderItems.count) + _lineSpacing * CGFloat(max(glyphRenderItems.count - 1, 0))
        let calculatedSize = CGSize(width: ceil(maxGlyphWidth), height: ceil(totalHeight))
        cachedTextSize = calculatedSize
        Self.storeSharedTextSize(calculatedSize, for: cacheKey)
        
        return calculatedSize
    }
    
    private func invalidateGlyphCache() {
        needsGlyphRebuild = true
        cachedTextSize = nil
    }
    
    func refreshForCurrentAppearance() {
        invalidateGlyphCache()
        setNeedsDisplay()
    }
    
    private func rebuildGlyphsIfNeeded() {
        guard needsGlyphRebuild else {
            RenderMetrics.increment("date.vertical.glyph_rebuild.skipped")
            return
        }
        RenderMetrics.increment("date.vertical.glyph_rebuild.count")
        
        needsGlyphRebuild = false
        glyphRenderItems.removeAll(keepingCapacity: true)
        maxGlyphWidth = 0
        cachedTextSize = nil
        
        guard !_text.isEmpty else { return }
        RenderMetrics.increment("date.vertical.glyph_count.total", by: _text.count)
        
        let ctFont = CTFontCreateWithFontDescriptor(_font.fontDescriptor, _font.pointSize, nil)
        let descender = _font.descender
        glyphRenderItems.reserveCapacity(_text.count)
        
        for char in _text {
            let charString = String(char)
            let attrs: [NSAttributedString.Key: Any] = [
                .font: ctFont,
                .foregroundColor: _textColor.cgColor,
                .baselineOffset: -descender
            ]
            let attrString = NSAttributedString(string: charString, attributes: attrs)
            let line = CTLineCreateWithAttributedString(attrString)
            let width = ceil(CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil)))
            maxGlyphWidth = max(maxGlyphWidth, width)
            glyphRenderItems.append(.init(line: line, width: width))
        }
    }
    
    private static func sharedTextSize(for key: SizeCacheKey) -> CGSize? {
        sharedTextSizeCacheQueue.sync {
            sharedTextSizeCache[key]
        }
    }
    
    private static func storeSharedTextSize(_ size: CGSize, for key: SizeCacheKey) {
        sharedTextSizeCacheQueue.async(flags: .barrier) {
            sharedTextSizeCache[key] = size
            if sharedTextSizeCache.count > maxSharedSizeCacheEntries {
                sharedTextSizeCache.removeAll(keepingCapacity: true)
            }
        }
    }
    
    private static func sharedRenderImage(for key: RenderCacheKey) -> RenderImage? {
        sharedRenderCacheQueue.sync {
            sharedRenderCache[key]
        }
    }
    
    private static func storeSharedRenderImage(_ image: RenderImage, for key: RenderCacheKey) {
        sharedRenderCacheQueue.async(flags: .barrier) {
            sharedRenderCache[key] = image
            if sharedRenderCache.count > maxSharedRenderCacheEntries {
                sharedRenderCache.removeAll(keepingCapacity: true)
            }
        }
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
    
    private func renderCacheKey(scale: CGFloat) -> RenderCacheKey {
        RenderCacheKey(
            text: _text,
            fontName: _font.fontName,
            fontSize: _font.pointSize,
            lineSpacing: _lineSpacing,
            colorToken: textColorToken,
            scale: scale
        )
    }
    
    private func drawGlyphs(in ctx: CGContext, boundsSize: CGSize) {
        ctx.saveGState()
        defer { ctx.restoreGState() }
        
        // 翻转坐标系，保持 CoreText 正常绘制
        ctx.translateBy(x: 0, y: boundsSize.height)
        ctx.scaleBy(x: 1.0, y: -1.0)
        
        let lineHeight = _font.lineHeight
        
        // 文字从上到下排列，起始 y 从 bounds.height - lineHeight 开始递减
        for (index, item) in glyphRenderItems.enumerated() {
            let x = (boundsSize.width - item.width) / 2
            let y = boundsSize.height - (lineHeight + _lineSpacing) * CGFloat(index + 1) + (_lineSpacing / 2)
            
            ctx.textPosition = CGPoint(x: x, y: y)
            CTLineDraw(item.line, ctx)
        }
    }
    
    private func renderImageForCurrentGlyphs(scale: CGFloat) -> RenderImage? {
        let lineCount = glyphRenderItems.count
        guard lineCount > 0 else { return nil }
        
        let lineHeight = _font.lineHeight
        let width = ceil(maxGlyphWidth)
        let height = ceil(lineHeight * CGFloat(lineCount) + _lineSpacing * CGFloat(max(lineCount - 1, 0)))
        guard width > 0, height > 0 else { return nil }
        
        let pixelWidth = max(1, Int(ceil(width * scale)))
        let pixelHeight = max(1, Int(ceil(height * scale)))
        guard let bitmapContext = CGContext(
            data: nil,
            width: pixelWidth,
            height: pixelHeight,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: Self.sRGBColorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }
        
        bitmapContext.scaleBy(x: scale, y: scale)
        drawGlyphs(in: bitmapContext, boundsSize: CGSize(width: width, height: height))
        
        guard let image = bitmapContext.makeImage() else { return nil }
        return RenderImage(image: image)
    }

    override func draw(in ctx: CGContext) {
        let metricsStart = RenderMetrics.begin()
        defer { RenderMetrics.end("date.vertical.draw.ms", from: metricsStart) }
        guard !_text.isEmpty else { return }
        
        let renderScale = max(contentsScale, 1.0)
        let cacheKey = renderCacheKey(scale: renderScale)
        if let renderImage = Self.sharedRenderImage(for: cacheKey) {
            RenderMetrics.increment("date.vertical.render_cache.hit")
            ctx.draw(renderImage.image, in: bounds)
            return
        }
        RenderMetrics.increment("date.vertical.render_cache.miss")
        
        rebuildGlyphsIfNeeded()
        guard !glyphRenderItems.isEmpty else { return }
        
        let buildStart = RenderMetrics.begin()
        if let renderImage = renderImageForCurrentGlyphs(scale: renderScale) {
            RenderMetrics.increment("date.vertical.render_image_build.count")
            RenderMetrics.end("date.vertical.render_image_build.ms", from: buildStart)
            Self.storeSharedRenderImage(renderImage, for: cacheKey)
            ctx.draw(renderImage.image, in: bounds)
            return
        }
        RenderMetrics.end("date.vertical.render_image_build.ms", from: buildStart)
        
        // 回退到直接逐字绘制
        drawGlyphs(in: ctx, boundsSize: bounds.size)
    }
}
