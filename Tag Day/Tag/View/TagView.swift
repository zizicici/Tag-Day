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
        label.font = UIFont.systemFont(ofSize: 10, weight: .regular)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        
        return label
    }()
    
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
    
    func update(title: String, color: UIColor) {
        label.text = title
        if color.resolvedColor(with: UITraitCollection(userInterfaceStyle: overrideUserInterfaceStyle)).isLight {
            label.textColor = .black.withAlphaComponent(0.8)
        } else {
            label.textColor = .white.withAlphaComponent(0.95)
        }
        backgroundColor = color
    }
    
    func update(tag: Tag, count: Int = 1) {
        label.text = tag.title
        if count > 1 {
            countLabel.isHidden = false
            countLabel.text = "×\(count)"
            label.snp.updateConstraints { make in
                make.trailing.equalTo(self).inset(14.0)
            }
        } else {
            countLabel.isHidden = true
            label.snp.updateConstraints { make in
                make.trailing.equalTo(self).inset(2.0)
            }
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
