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
