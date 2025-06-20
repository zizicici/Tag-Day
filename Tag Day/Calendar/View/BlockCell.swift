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

class DateView: UIView {
    private var label: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.textAlignment = .center
        label.font = UIFont.monospacedSystemFont(ofSize: 17.0, weight: .regular)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        
        return label
    }()
    
    private var secondaryLabel: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.textAlignment = .center
        label.numberOfLines = 0
        
        return label
    }()
    
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
        
        addSubview(secondaryLabel)
        secondaryLabel.snp.makeConstraints { make in
            make.centerY.equalTo(self)
            make.trailing.equalTo(self).inset(7)
        }
        secondaryLabel.setContentHuggingPriority(.required, for: .vertical)
        secondaryLabel.setContentHuggingPriority(.required, for: .horizontal)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(text: String, secondaryText: String, textColor: UIColor) {
        label.text = text
        label.textColor = textColor.withAlphaComponent(0.85)
        if !secondaryText.isEmpty, !secondaryText.isBlank {
            secondaryLabel.isHidden = false
            secondaryLabel.attributedText = createCenteredCharacterByCharacterString(from: secondaryText, textColor: textColor.withAlphaComponent(0.6))
            label.snp.updateConstraints { make in
                make.trailing.equalTo(self).inset(14.0)
            }
        } else {
            secondaryLabel.isHidden = true
            label.snp.updateConstraints { make in
                make.trailing.equalTo(self).inset(6.0)
            }
        }
    }
    
    func createCenteredCharacterByCharacterString(from string: String, textColor: UIColor) -> NSAttributedString {
        let charactersWithNewlines = string.map { String($0) }.joined(separator: "\n")
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.lineSpacing = 2 // 较小的行间距
        paragraphStyle.lineHeightMultiple = 0.8 // 行高倍数，使行间距更紧凑
        
        let attributes: [NSAttributedString.Key: Any] = [
            .paragraphStyle: paragraphStyle,
            .foregroundColor: textColor,
            .font: UIFont.systemFont(ofSize: 6.5, weight: .black)
        ]
        
        // 4. 创建并返回 AttributedString
        return NSAttributedString(string: charactersWithNewlines, attributes: attributes)
    }
}
