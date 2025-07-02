//
//  TagPreviewCell.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/5/7.
//

import UIKit
import SnapKit

class TagPreviewView: UIView {
    var paperView: UIView = {
        let view = UIView()
        view.layer.cornerCurve = .continuous
        view.layer.cornerRadius = 6.0
        view.backgroundColor = AppColor.paper
        
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
    
    var tagView: TagView = {
        let tagView = TagView()
        
        return tagView
    }()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        paperView.layer.shadowPath = UIBezierPath(roundedRect: CGRect(origin: CGPoint.init(x: 0, y: 0), size: CGSize(width: frame.width, height: frame.height)), cornerRadius: 6.0).cgPath
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(paperView)
        paperView.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }
        
        paperView.layer.shadowColor = UIColor.gray.cgColor
        paperView.layer.shadowOpacity = 0.1
        paperView.layer.shadowOffset = CGSize(width: 0, height: 2)
        paperView.layer.cornerCurve = .continuous
        
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
            make.leading.trailing.equalTo(paperView)
            make.bottom.equalTo(paperView).inset(4)
        }
        
        paperView.addSubview(tagView)
        tagView.snp.makeConstraints { make in
            make.leading.trailing.equalTo(tagContainerView).inset(2)
            make.height.equalTo(20)
            make.top.equalTo(tagContainerView)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(title: String, color: UIColor, titleColor: UIColor) {
        label.text = "14"
        tagView.overrideUserInterfaceStyle = overrideUserInterfaceStyle
        tagView.update(tag: Tag(bookID: -1, title: title, subtitle: "", color: color.generateLightDarkString(), titleColor: titleColor.generateLightDarkString(), order: -1))
    }
}

class TagPreviewCell: UITableViewCell {
    private let lightTagView: TagPreviewView = {
        let tagView = TagPreviewView()
        tagView.overrideUserInterfaceStyle = .light
        
        return tagView
    }()
    
    private let darkTagView: TagPreviewView = {
        let tagView = TagPreviewView()
        tagView.overrideUserInterfaceStyle = .dark
        
        return tagView
    }()
    
    private let lightLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredSystemFont(for: .footnote, weight: .regular)
        label.textAlignment = .center
        label.text = String(localized: "tag.detail.preview.light")
        label.textColor = AppColor.text.withAlphaComponent(0.75)
        
        return label
    }()
    
    private let darkLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredSystemFont(for: .footnote, weight: .regular)
        label.textAlignment = .center
        label.text = String(localized: "tag.detail.preview.dark")
        label.textColor = AppColor.text.withAlphaComponent(0.75)

        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.backgroundColor = AppColor.background
        
        contentView.addSubview(lightTagView)
        lightTagView.snp.makeConstraints { make in
            make.top.equalTo(contentView).inset(5)
            make.trailing.equalTo(contentView.snp.centerX).offset(-20)
            make.height.equalTo(80)
            make.width.equalTo(50)
        }
        contentView.addSubview(lightLabel)
        lightLabel.snp.makeConstraints { make in
            make.centerX.equalTo(lightTagView)
            make.top.equalTo(lightTagView.snp.bottom).offset(10)
            make.bottom.equalTo(contentView)
        }
        contentView.addSubview(darkTagView)
        darkTagView.snp.makeConstraints { make in
            make.top.equalTo(contentView).inset(5)
            make.leading.equalTo(contentView.snp.centerX).offset(20)
            make.height.equalTo(80)
            make.width.equalTo(50)
        }
        contentView.addSubview(darkLabel)
        darkLabel.snp.makeConstraints { make in
            make.centerX.equalTo(darkTagView)
            make.top.equalTo(darkTagView.snp.bottom).offset(10)
            make.bottom.equalTo(contentView)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(title: String, color: UIColor, titleColor: UIColor) {
        lightTagView.update(title: title, color: color, titleColor: titleColor)
        darkTagView.update(title: title, color: color, titleColor: titleColor)
    }
}

