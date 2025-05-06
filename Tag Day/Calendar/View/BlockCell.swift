//
//  BlockCell.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/4/29.
//

import UIKit
import SnapKit
import ZCCalendar

fileprivate extension UIConfigurationStateCustomKey {
    static let blockItem = UIConfigurationStateCustomKey("com.zizicici.offday.cell.block.item")
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

class BlockCell: BlockBaseCell {
    var isHover: Bool = false {
        didSet {
            if oldValue != isHover {
                setNeedsUpdateConfiguration()
            }
        }
    }
    
    var paperView: UIView = {
        let view = UIView()
        view.layer.cornerCurve = .continuous
        view.layer.cornerRadius = 6.0
        
        return view
    }()
    
    var highlightView: UIView = {
        let view = UIView()
        view.layer.cornerCurve = .continuous
        view.layer.cornerRadius = 6.0
        
        return view
    }()
    
    var label: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        label.alpha = 0.8
        
        return label
    }()
    
    var tagContainerView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        
        return view
    }()
    
    var defaultBackgroundColor: UIColor = AppColor.paper
    var highlightColor: UIColor = .gray.withAlphaComponent(0.25)
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        isHover = false
        label.text = nil
        label.backgroundColor = .clear
        paperView.backgroundColor = defaultBackgroundColor
        tagContainerView.subviews.forEach { subview in
            subview.removeFromSuperview()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        paperView.layer.shadowPath = UIBezierPath(roundedRect: CGRect(origin: CGPoint.init(x: 0, y: 0), size: CGSize(width: frame.width, height: frame.height)), cornerRadius: 6.0).cgPath
    }
    
    private func setupViewsIfNeeded() {
        guard paperView.superview == nil else { return }
        
        contentView.addSubview(paperView)
        paperView.snp.makeConstraints { make in
            make.edges.equalTo(contentView)
        }
        
        paperView.layer.shadowColor = UIColor.gray.cgColor
        paperView.layer.shadowOpacity = 0.1
        paperView.layer.shadowOffset = CGSize(width: 0, height: 2)
        paperView.layer.cornerCurve = .continuous
        paperView.backgroundColor = defaultBackgroundColor
        
        paperView.addSubview(highlightView)
        highlightView.snp.makeConstraints { make in
            make.edges.equalTo(paperView)
        }
        
        paperView.addSubview(label)
        label.snp.makeConstraints { make in
            make.top.equalTo(paperView).inset(8)
            make.leading.trailing.equalTo(paperView).inset(6)
            make.height.equalTo(18)
        }
        label.layer.cornerRadius = 6.0
        label.clipsToBounds = true
        
        paperView.addSubview(tagContainerView)
        tagContainerView.snp.makeConstraints { make in
            make.top.equalTo(label.snp.bottom).offset(6)
            make.leading.trailing.equalTo(paperView)//.inset(3)
            make.bottom.equalTo(paperView).inset(4)
        }
        
        isAccessibilityElement = true
        accessibilityTraits = .button
    }
    
    override func updateConfiguration(using state: UICellConfigurationState) {
        super.updateConfiguration(using: state)
        setupViewsIfNeeded()
        
        if let item = state.blockItem {
            paperView.backgroundColor = item.backgroundColor

            if isHover || isHighlighted {
                highlightView.backgroundColor = highlightColor
            } else {
                highlightView.backgroundColor = .clear
            }
            
            label.textColor = item.foregroundColor
            label.text = item.day.dayString()
            
            var lastRecordView: UIView? = nil
            for (_, record) in item.records.enumerated() {
//                let isLast = item.records.count == index + 1
                if let tag = item.tags.filter({ $0.id == record.tagID }).first {
                    let recordView = TagView()
                    recordView.update(tag: tag, record: record)
                    tagContainerView.addSubview(recordView)
                    if let lastView = lastRecordView {
                        recordView.snp.makeConstraints { make in
                            make.leading.trailing.equalTo(tagContainerView).inset(2)
                            make.height.equalTo(20)
                            make.top.equalTo(lastView.snp.bottom).offset(3)
                        }
                    } else {
                        recordView.snp.makeConstraints { make in
                            make.leading.trailing.equalTo(tagContainerView).inset(2)
                            make.height.equalTo(20)
                            make.top.equalTo(tagContainerView)
                        }
                    }

                    lastRecordView = recordView
                }
            }
            
            if item.isToday {
                label.backgroundColor = AppColor.today
                accessibilityLabel = String(localized: "weekCalendar.today") + (item.day.completeFormatString() ?? "")
            } else {
                accessibilityLabel = item.day.completeFormatString()
            }
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

class TagView: UIView {
    var label: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(label)
        label.snp.makeConstraints { make in
            make.leading.trailing.equalTo(self).inset(3)
            make.top.bottom.equalTo(self)
        }
        
        self.layer.cornerRadius = 2.0
        self.layer.masksToBounds = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(tag: Tag, record: DayRecord) {
        label.text = tag.name
        if let tagColor = UIColor(string: tag.color) {
            if tagColor.isSimilar(to: UIColor.white) {
                label.textColor = .label
            } else {
                label.textColor = .white
            }
            backgroundColor = tagColor
        }
    }
}
