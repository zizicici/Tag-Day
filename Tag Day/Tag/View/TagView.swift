//
//  TagView.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/6/16.
//

import UIKit

class TagView: UIView {
    var tagLayer = TagLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        layer.addSublayer(tagLayer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if !tagLayer.frame.equalTo(bounds) {
            tagLayer.frame = bounds
        }
    }
    
    func update(tag: Tag, count: Int = 1) {
        let isDark: Bool
        switch overrideUserInterfaceStyle {
        case .unspecified:
            isDark = traitCollection.userInterfaceStyle == .dark
        case .light:
            isDark = false
        case .dark:
            isDark = true
        @unknown default:
            fatalError()
        }
        tagLayer.update(title: tag.title, count: count, tagColor: tag.getColorString(isDark: isDark), textColor: tag.getTitleColorString(isDark: isDark), isDark: isDark)
    }
}

class TagLayer: CALayer {
    // MARK: - Properties
    struct DisplayInfo: Equatable, Hashable {
        var title: String
        var count: Int
        var tagColor: String
        var textColor: String
        var boundWidth: CGFloat
        var isSymbol: Bool
    }
    
    private(set) var displayInfo: DisplayInfo? {
        didSet {
            if oldValue != displayInfo {
                setNeedsDisplay()
            }
        }
    }
    
    private struct SharedCache {
        struct RenderInfo: Hashable {
            var line: CTLine
            var point: CGPoint
        }
        
        struct TitleCacheKey: Hashable {
            var title: String
            var textColor: String
            var boundWidth: CGFloat
            var hasCountSuffix: Bool
        }
        
        struct CountCacheKey: Hashable {
            var count: Int
            var textColor: String
            var boundWidth: CGFloat
        }
        
        private static let maxRenderCacheEntries = 1500
        private static var titleRenderInfos: [TitleCacheKey: RenderInfo] = [:]
        private static var countRenderInfos: [CountCacheKey: RenderInfo] = [:]
        static let symbolImageCache = NSCache<NSString, UIImage>()
        
        static func titleRenderInfo(for key: TitleCacheKey) -> RenderInfo? {
            cacheQueue.sync {
                titleRenderInfos[key]
            }
        }
        
        static func countRenderInfo(for key: CountCacheKey) -> RenderInfo? {
            cacheQueue.sync {
                countRenderInfos[key]
            }
        }
        
        static func setTitleRenderInfo(_ renderInfo: RenderInfo, for key: TitleCacheKey) {
            cacheQueue.async(flags: .barrier) {
                titleRenderInfos[key] = renderInfo
                trimCachesIfNeeded()
            }
        }
        
        static func setCountRenderInfo(_ renderInfo: RenderInfo, for key: CountCacheKey) {
            cacheQueue.async(flags: .barrier) {
                countRenderInfos[key] = renderInfo
                trimCachesIfNeeded()
            }
        }
        
        private static func trimCachesIfNeeded() {
            let totalEntries = titleRenderInfos.count + countRenderInfos.count
            guard totalEntries > maxRenderCacheEntries else { return }
            titleRenderInfos.removeAll(keepingCapacity: true)
            countRenderInfos.removeAll(keepingCapacity: true)
        }
        
        static let cacheQueue = DispatchQueue(label: "com.zizicic.tag.TagLayer.cache", qos: .userInteractive, attributes: .concurrent)
    }
    
    private let defaultLabelInset: CGFloat = 2.0
    private let countLabelWidth: CGFloat = 14.0
    private let textFontSize: CGFloat = 12.0
    private let countFontSize: CGFloat = 10.0
    private let symbolSize: CGFloat = 12.0
    private let minimumScaleFactor: CGFloat = 0.5
    private var resolvedTextColor: UIColor = AppColor.text
    private var resolvedTextCGColor: CGColor = AppColor.text.cgColor
    
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
        needsDisplayOnBoundsChange = true
        drawsAsynchronously = true
    }
    
    // MARK: - Update Content
    func update(title: String, count: Int = 1, tagColor: String, textColor: String, isDark: Bool, isSymbol: Bool = false) {
        RenderMetrics.increment("tag.update.calls")
        var tagColor = tagColor
        var textColor = textColor
        if tagColor.isEmpty || tagColor.isBlank {
            let tag = Tag.empty()
            tagColor = tag.dynamicColor.generateLightDarkString(isDark ? .dark : .light)
            textColor = tag.dynamicTitleColor.generateLightDarkString(isDark ? .dark : .light)
        }
        let nextDisplayInfo = DisplayInfo(
            title: title,
            count: count,
            tagColor: tagColor,
            textColor: textColor,
            boundWidth: bounds.width,
            isSymbol: isSymbol
        )
        guard nextDisplayInfo != displayInfo else {
            RenderMetrics.increment("tag.update.skipped")
            return
        }
        RenderMetrics.increment("tag.update.applied")
        
        let nextTagColor = UIColor(hex: tagColor) ?? AppColor.paper
        let nextTextColor = UIColor(hex: textColor) ?? AppColor.text
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        if backgroundColor != nextTagColor.cgColor {
            backgroundColor = nextTagColor.cgColor
        }
        CATransaction.commit()
        
        resolvedTextColor = nextTextColor
        resolvedTextCGColor = nextTextColor.cgColor
        
        displayInfo = nextDisplayInfo
    }
    
    private func displayInfoForCurrentBounds() -> DisplayInfo? {
        guard var displayInfo = displayInfo else { return nil }
        displayInfo.boundWidth = bounds.width
        return displayInfo
    }
    
    // MARK: - Drawing
    override func draw(in ctx: CGContext) {
        let metricsStart = RenderMetrics.begin()
        defer { RenderMetrics.end("tag.draw.ms", from: metricsStart) }
        RenderMetrics.increment("tag.draw.calls")
        
        guard let displayInfo = displayInfoForCurrentBounds() else { return }
        
        // 保存上下文状态
        ctx.saveGState()
        defer { ctx.restoreGState() }
        
        if displayInfo.isSymbol {
            RenderMetrics.increment("tag.draw.symbol")
            // 绘制 SF Symbol
            drawSymbol(in: ctx, displayInfo: displayInfo)
        } else {
            RenderMetrics.increment("tag.draw.text")
            // 绘制文本
            drawText(in: ctx, displayInfo: displayInfo)
        }
    }
    
    private func drawSymbol(in ctx: CGContext, displayInfo: DisplayInfo) {
        let count = displayInfo.count
        
        // 计算 Symbol 的绘制区域
        let symbolRect: CGRect
        if count > 0 {
            // 有计数标签时，Symbol 靠左显示
            symbolRect = CGRect(x: defaultLabelInset, y: 2.0,
                              width: bounds.width - countLabelWidth - defaultLabelInset,
                                height: bounds.height - 4.0)
        } else {
            // 没有计数标签时，Symbol 居中显示
            symbolRect = CGRect(x: defaultLabelInset, y: 2.0,
                              width: bounds.width - 2 * defaultLabelInset,
                                height: bounds.height - 4.0)
        }
        
        // 绘制 SF Symbol
        drawSFSymbol(named: displayInfo.title, in: symbolRect, context: ctx, color: resolvedTextColor, colorHex: displayInfo.textColor)
        
        // 绘制计数文本（如果需要）
        if count > 0 {
            ctx.saveGState()
            ctx.textMatrix = .identity
            ctx.translateBy(x: 0, y: bounds.height)
            ctx.scaleBy(x: 1.0, y: -1.0)
            drawCountText(in: ctx, displayInfo: displayInfo)
            ctx.restoreGState()
        }
    }
    
    private func drawText(in ctx: CGContext, displayInfo: DisplayInfo) {
        // 翻转坐标系（仅用于文本绘制）
        ctx.textMatrix = .identity
        ctx.translateBy(x: 0, y: bounds.height)
        ctx.scaleBy(x: 1.0, y: -1.0)
        
        let count = displayInfo.count
        let titleKey = SharedCache.TitleCacheKey(
            title: displayInfo.title,
            textColor: displayInfo.textColor,
            boundWidth: displayInfo.boundWidth,
            hasCountSuffix: count > 1
        )
        
        if let titleRenderInfo = SharedCache.titleRenderInfo(for: titleKey) {
            RenderMetrics.increment("tag.title_cache.hit")
            render(for: titleRenderInfo, context: ctx)
        } else {
            RenderMetrics.increment("tag.title_cache.miss")
            // 绘制主文本
            if let attributedString = getAttributedString() {
                let textRect = count > 1 ?
                    CGRect(x: defaultLabelInset, y: 0,
                          width: bounds.width - countLabelWidth - defaultLabelInset,
                          height: bounds.height) :
                    CGRect(x: defaultLabelInset, y: 0,
                          width: bounds.width - 2 * defaultLabelInset,
                          height: bounds.height)
                
                let (resultLine, resultPoint) = drawScaledText(attributedString: attributedString, in: textRect, context: ctx)
                SharedCache.setTitleRenderInfo(.init(line: resultLine, point: resultPoint), for: titleKey)
            }
        }
        
        if count > 1 {
            drawCountText(in: ctx, displayInfo: displayInfo)
        }
    }
    
    private func drawCountText(in ctx: CGContext, displayInfo: DisplayInfo) {
        // 翻转坐标系（用于计数文本绘制）
        let countKey = SharedCache.CountCacheKey(
            count: displayInfo.count,
            textColor: displayInfo.textColor,
            boundWidth: displayInfo.boundWidth
        )
        
        if let countRenderInfo = SharedCache.countRenderInfo(for: countKey) {
            RenderMetrics.increment("tag.count_cache.hit")
            render(for: countRenderInfo, context: ctx)
        } else {
            RenderMetrics.increment("tag.count_cache.miss")
            // 绘制计数文本
            if let countString = getCountAttributedString() {
                let countRect = CGRect(x: bounds.width - countLabelWidth, y: 8,
                                       width: countLabelWidth, height: 12)
                let (resultLine, resultPoint) = drawScaledText(attributedString: countString, in: countRect, context: ctx)
                SharedCache.setCountRenderInfo(.init(line: resultLine, point: resultPoint), for: countKey)
            }
        }
    }
    
    private func drawSFSymbol(named symbolName: String, in rect: CGRect, context: CGContext, color: UIColor, colorHex: String) {
        let cacheKey = "\(symbolName)|\(colorHex)|\(symbolSize)" as NSString
        let symbolImage: UIImage?
        
        if let cachedImage = SharedCache.symbolImageCache.object(forKey: cacheKey) {
            RenderMetrics.increment("tag.symbol_cache.hit")
            symbolImage = cachedImage
        } else {
            RenderMetrics.increment("tag.symbol_cache.miss")
            // 先将 Symbol 栅格化，避免直接使用符号 cgImage 导致颜色丢失
            let config = UIImage.SymbolConfiguration(pointSize: symbolSize, weight: .medium)
            let tintedImage = UIImage(systemName: symbolName, withConfiguration: config)?
                .withTintColor(color, renderingMode: .alwaysOriginal)
            symbolImage = tintedImage.flatMap { rasterizedSymbolImage(from: $0) } ?? tintedImage
            if let symbolImage {
                SharedCache.symbolImageCache.setObject(symbolImage, forKey: cacheKey)
            }
        }
        
        guard let symbolImage else {
            RenderMetrics.increment("tag.symbol_fallback_text")
            drawFallbackText(symbolName, in: rect, context: context, color: color)
            return
        }
        
        // 计算图像在矩形中的居中位置
        let imageSize = symbolImage.size
        let imageRect = CGRect(
            x: rect.minX + (rect.width - imageSize.width) / 2,
            y: rect.minY + (rect.height - imageSize.height) / 2,
            width: imageSize.width,
            height: imageSize.height
        )
        
        // 在 CALayer 的绘制上下文中绘制 cgImage 需要翻转 Y 轴，避免图标倒置
        if let cgImage = symbolImage.cgImage {
            context.saveGState()
            context.translateBy(x: 0, y: bounds.height)
            context.scaleBy(x: 1.0, y: -1.0)
            let flippedRect = CGRect(
                x: imageRect.minX,
                y: bounds.height - imageRect.maxY,
                width: imageRect.width,
                height: imageRect.height
            )
            context.draw(cgImage, in: flippedRect)
            context.restoreGState()
        }
    }
    
    private func rasterizedSymbolImage(from image: UIImage) -> UIImage? {
        let imageSize = image.size
        guard imageSize.width > 0, imageSize.height > 0 else { return nil }
        
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = max(image.scale, contentsScale, 1.0)
        format.opaque = false
        return UIGraphicsImageRenderer(size: imageSize, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: imageSize))
        }
    }
    
    private func drawFallbackText(_ text: String, in rect: CGRect, context: CGContext, color: UIColor) {
        // 回退方案：如果找不到 SF Symbol，就绘制文本
        context.saveGState()
        context.textMatrix = .identity
        context.translateBy(x: 0, y: bounds.height)
        context.scaleBy(x: 1.0, y: -1.0)
        
        let font = UIFont.systemFont(ofSize: textFontSize, weight: .medium)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color.cgColor
        ]
        
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let line = CTLineCreateWithAttributedString(attributedString)
        
        // 计算文本的居中位置
        let lineWidth = CTLineGetTypographicBounds(line, nil, nil, nil)
        let lineHeight = font.lineHeight
        let descender = font.descender
        
        let textX = rect.minX + max(0, (rect.width - CGFloat(lineWidth)) / 2)
        let textY = rect.minY + (rect.height - lineHeight) / 2 - descender
        
        context.textPosition = CGPoint(x: textX, y: textY)
        CTLineDraw(line, context)
        
        context.restoreGState()
    }
    
    private func render(for renderInfo: SharedCache.RenderInfo, context: CGContext) {
        let line = renderInfo.line
        context.textPosition = renderInfo.point
        CTLineDraw(line, context)
    }
    
    private func drawScaledText(attributedString: NSAttributedString, in rect: CGRect, context: CGContext) -> (CTLine, CGPoint) {
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
            RenderMetrics.increment("tag.text_scale.no_scale")
            return drawSingleLineCentered(attributedString: attributedString, in: rect, context: context)
        }
        RenderMetrics.increment("tag.text_scale.scaled")
        
        // 创建缩放后的属性字符串
        let scaledFont = originalFont.withSize(scaledFontSize)
        let mutableString = NSMutableAttributedString(attributedString: attributedString)
        mutableString.addAttribute(.font, value: scaledFont, range: NSRange(location: 0, length: mutableString.length))
        
        // 绘制缩放后的文本
        return drawSingleLineCentered(attributedString: mutableString, in: rect, context: context)
    }
    
    private func drawSingleLineCentered(attributedString: NSAttributedString, in rect: CGRect, context: CGContext) -> (CTLine, CGPoint) {
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
        
        return (line, CGPoint(x: textX, y: textY))
    }
    
    // MARK: - Text Attributes
    private func getAttributedString() -> NSAttributedString? {
        guard let displayInfo = displayInfo, !displayInfo.isSymbol else { return nil }
        let font = UIFont.systemFont(ofSize: textFontSize, weight: .medium)
        let text = displayInfo.title
        guard text.count > 0 else { return nil }
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: resolvedTextCGColor
        ]
        
        let string = NSAttributedString(string: text, attributes: attributes)
        
        return string
    }
    
    private func getCountAttributedString() -> NSAttributedString? {
        guard let displayInfo = displayInfo else { return nil }
        let font = UIFont.systemFont(ofSize: countFontSize, weight: .semibold)
        let countText = "×\(displayInfo.count)"
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: resolvedTextCGColor
        ]
        
        let string = NSAttributedString(string: countText, attributes: attributes)
        
        return string
    }
}
