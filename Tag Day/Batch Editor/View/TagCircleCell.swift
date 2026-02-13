//
//  TagCircleCell.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/8/6.
//

import UIKit
import ZCCalendar
import SnapKit

fileprivate extension UIConfigurationStateCustomKey {
    static let tagCircleItem = UIConfigurationStateCustomKey("com.zizicici.tag.cell.tagCircle.item")
}

private extension UICellConfigurationState {
    var tagCircleItem: TagCircle.Item? {
        set { self[.tagCircleItem] = newValue }
        get { return self[.tagCircleItem] as? TagCircle.Item }
    }
}

class TagCircleBaseCell: UICollectionViewCell {
    private var tagCircleItem: TagCircle.Item? = nil
    
    func update(with newTagCircleItem: TagCircle.Item) {
        guard tagCircleItem != newTagCircleItem else { return }
        tagCircleItem = newTagCircleItem
        setNeedsUpdateConfiguration()
    }
    
    override var configurationState: UICellConfigurationState {
        var state = super.configurationState
        state.tagCircleItem = self.tagCircleItem
        return state
    }
}

class TagCircleCell: TagCircleBaseCell {
    var label: UILabel = {
        let label = UILabel()
        label.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        label.numberOfLines = 1
        label.textAlignment = .center
        label.minimumScaleFactor = 0.8
        label.adjustsFontSizeToFitWidth = true
        
        return label
    }()
    
    var tagContainerView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        
        return view
    }()
    
    private var cachedTagLayers: [TagLayer] = []
    private var renderedItem: TagCircle.Item?
    private var renderedIsDarkMode: Bool?
    
    private var highlightColor: UIColor = .gray.withAlphaComponent(0.25)
    
    private func setupViewsIfNeeded() {
        guard tagContainerView.superview == nil else { return }
        
        contentView.addSubview(label)
        label.snp.makeConstraints { make in
            make.leading.trailing.equalTo(contentView).inset(4.0)
            make.top.equalTo(contentView).inset(4.0)
            make.height.equalTo(26.0)
        }
        
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
        renderedItem = nil
        renderedIsDarkMode = nil
        setNeedsUpdateConfiguration()
    }
    
    private func updateTagLayers(tagData: [(tag: Tag, count: Int)], isDark: Bool) {
        while cachedTagLayers.count > tagData.count {
            let layer = cachedTagLayers.removeLast()
            layer.removeFromSuperlayer()
        }
        
        while cachedTagLayers.count < tagData.count {
            let tagLayer = TagLayer()
            tagContainerView.layer.addSublayer(tagLayer)
            cachedTagLayers.append(tagLayer)
        }
        
        for (index, (tag, count)) in tagData.enumerated() {
            let tagLayer = cachedTagLayers[index]
            tagLayer.update(
                title: tag.title,
                count: count,
                tagColor: tag.getColorString(isDark: isDark),
                textColor: tag.getTitleColorString(isDark: isDark),
                isDark: isDark
            )
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let tagContainerFrame = CGRect(x: 3.0, y: 32.0, width: bounds.width - 6.0, height: bounds.height - 36.0)
        if !tagContainerView.frame.equalTo(tagContainerFrame) {
            tagContainerView.frame = tagContainerFrame
        }
        
        updateTagFramesIfNeeded()
    }
    
    override func updateConfiguration(using state: UICellConfigurationState) {
        super.updateConfiguration(using: state)
        setupViewsIfNeeded()
        
        if let item = state.tagCircleItem {
            var backgroundColor = item.backgroundColor

            if isHighlighted {
                backgroundColor = highlightColor.overlay(on: backgroundColor)
            }
            
            let isDark = traitCollection.userInterfaceStyle == .dark
            if renderedItem != item || renderedIsDarkMode != isDark {
                renderedItem = item
                renderedIsDarkMode = isDark
                
                label.text = item.title
                label.textColor = item.foregroundColor
                
                let tagData: [(tag: Tag, count: Int)] = item.tags.map { (tag: $0, count: 1) }
                updateTagLayers(tagData: tagData, isDark: isDark)
                
                accessibilityLabel = item.title
                accessibilityValue = item.recordString
            }
            
            updateTagFramesIfNeeded()
            
            backgroundConfiguration = BlockCellBackgroundConfiguration.configuration(for: state, backgroundColor: backgroundColor, cornerRadius: 6.0, showStroke: false, strokeColor: UIColor.systemYellow, strokeWidth: 1.5, strokeOutset: 1.0)
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
}

class TagCircleAddCell: UICollectionViewCell {
    private var highlightColor: UIColor = .gray.withAlphaComponent(0.25)

    var imageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "plus"))
        imageView.tintColor = AppColor.dynamicColor
        imageView.contentMode = .center
        imageView.isUserInteractionEnabled = false
        
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.addSubview(imageView)
        
        imageView.snp.makeConstraints { make in
            make.center.equalTo(contentView)
            make.width.height.equalTo(40.0)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateConfiguration(using state: UICellConfigurationState) {
        super.updateConfiguration(using: state)
        
        var backgroundColor = AppColor.background
        
        if isHighlighted {
            backgroundColor = highlightColor.overlay(on: backgroundColor)
        }
        
        backgroundConfiguration = BlockCellBackgroundConfiguration.configuration(for: state, backgroundColor: backgroundColor, cornerRadius: 6.0, showStroke: false, strokeColor: UIColor.systemYellow, strokeWidth: 1.5, strokeOutset: 1.0)
    }
}
