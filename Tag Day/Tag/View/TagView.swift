//
//  TagView.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/6/16.
//

import UIKit
import SnapKit

class TagView: UIView {
    var label: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        
        return label
    }()
    
    var countLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 10, weight: .semibold)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        
        return label
    }()
    
    private var currentLabelInset: CGFloat = 2.0 {
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
            make.leading.equalTo(self).inset(2.0)
            make.trailing.equalTo(self).inset(2.0)
            make.top.bottom.equalTo(self)
        }
        
        addSubview(countLabel)
        countLabel.snp.makeConstraints { make in
            make.trailing.equalTo(self).inset(1.0)
            make.width.equalTo(14.0)
            make.top.equalTo(self).inset(0.0)
            make.height.greaterThanOrEqualTo(8.0)
        }
        
        layer.cornerRadius = 3.0
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
            currentLabelInset = 14.0
        } else {
            countLabel.isHidden = true
            currentLabelInset = 2.0
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
