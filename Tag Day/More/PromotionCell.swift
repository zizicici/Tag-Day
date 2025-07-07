//
//  PromotionCell.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/7/6.
//

import Foundation
import UIKit
import SnapKit

class GradientView: UIView {
    override class var layerClass: AnyClass {
        return CAGradientLayer.self
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupGradient()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGradient()
    }
    
    func setupGradient() {
        let gradientLayer = self.layer as! CAGradientLayer
        gradientLayer.colors = [UIColor(hex: "44B97B")!.cgColor, UIColor(hex: "009E4D")!.cgColor] // 设置渐变色的颜色数组
        gradientLayer.locations = [0.0, 1.0] // 设置颜色的位置，0.0代表起始位置，1.0代表结束位置
        gradientLayer.startPoint = CGPoint(x: 0.2, y: 0.0) // 设置渐变色的起始点
        gradientLayer.endPoint = CGPoint(x: 0.8, y: 1.0) // 设置渐变色的结束点
    }
}

class GratefulCell: UITableViewCell {
    private var topLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .headline)
        label.textAlignment = .center
        label.textColor = .white
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        
        let text = String(localized: "grateful.title")
        let attributedString = NSMutableAttributedString(string: text)
        if let range = text.range(of: "Pro") {
            let nsRange = NSRange(range, in: text)
            attributedString.addAttribute(.foregroundColor, value: UIColor.systemYellow, range: nsRange)
        }
        label.attributedText = attributedString
        
        return label
    }()
    
    private var contentLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .footnote)
        label.textAlignment = .center
        label.textColor = .white.withAlphaComponent(0.8)
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        
        label.text = String(localized: "grateful.content")
        
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        let gradientView = GradientView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        contentView.addSubview(gradientView)
        gradientView.snp.makeConstraints { make in
            make.edges.equalTo(contentView)
        }
        
        contentView.addSubview(topLabel)
        topLabel.snp.makeConstraints { make in
            make.top.equalTo(contentView).inset(20)
            make.leading.equalTo(contentView).inset(20)
            make.trailing.equalTo(contentView).inset(20)
        }
        topLabel.setContentHuggingPriority(.defaultLow, for: .vertical)
        
        contentView.addSubview(contentLabel)
        contentLabel.snp.makeConstraints { make in
            make.top.equalTo(topLabel.snp.bottom).offset(12)
            make.bottom.equalTo(contentView).inset(20)
            make.leading.trailing.equalTo(contentView).inset(20)
        }
        
        let view = UIView()
        selectedBackgroundView = view
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

let proColor: UIColor = .white// UIColor(hex: "38671a")!

class PromotionCell: UITableViewCell {
    var purchaseClosure: (() -> ())?
    var restoreClosure: (() -> ())?
    
    private var topLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .headline)
        label.textAlignment = .natural
        label.textColor = .white
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        
        let text = String(localized: "promotion.title")
        let attributedString = NSMutableAttributedString(string: text)
        if let range = text.range(of: "Pro") {
            let nsRange = NSRange(range, in: text)
            attributedString.addAttribute(.foregroundColor, value: proColor, range: nsRange)
        }
        label.attributedText = attributedString
        
        return label
    }()
    
    private var firstItemLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .footnote)
        label.textAlignment = .natural
        label.textColor = .white.withAlphaComponent(0.8)
        label.numberOfLines = 0
        
        label.text = String(localized: "promotion.first")
        
        return label
    }()
    
    private var secondItemLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .footnote)
        label.textAlignment = .natural
        label.textColor = .white.withAlphaComponent(0.8)
        label.numberOfLines = 0
        
        label.text = String(localized: "promotion.second")
        
        return label
    }()
    
    private var thirdItemLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .footnote)
        label.textAlignment = .natural
        label.textColor = .white.withAlphaComponent(0.8)
        label.numberOfLines = 0
        
        label.text = String(localized: "promotion.future")
        
        return label
    }()
    
    private let purchaseButton: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.image = UIImage(systemName: "arrowshape.up.circle", withConfiguration: UIImage.SymbolConfiguration(pointSize: 13, weight: .medium))?.withTintColor(AppColor.main, renderingMode: .alwaysOriginal)
        configuration.title = String(localized: "membership.purchase")
        configuration.titleAlignment = .center
        configuration.imagePadding = 6.0
        configuration.cornerStyle = .large
        configuration.titlePadding = 10.0
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer({ incoming in
            var outgoing = incoming
            outgoing.font = UIFont.systemFont(ofSize: 16, weight: .bold)
            outgoing.foregroundColor = AppColor.main

            return outgoing
        })
        
        let button = UIButton(configuration: configuration)
        button.tintColor = proColor
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)

        return button
    }()
    
    private var priceLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .footnote)
        label.textAlignment = .center
        label.textColor = proColor.withAlphaComponent(0.9)
        label.numberOfLines = 1
        
        label.text = "?.??"
        
        return label
    }()
    
    private let restoreButton: UIButton = {
        var configuration = UIButton.Configuration.plain()
        configuration.title = String(localized: "membership.restore")
        configuration.titleAlignment = .center
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer({ incoming in
            var outgoing = incoming
            outgoing.font = UIFont.preferredFont(forTextStyle: .caption1)
            outgoing.underlineStyle = [.single]
            outgoing.underlineColor = .white.withAlphaComponent(0.8)

            return outgoing
        })
        configuration.contentInsets = .init(top: 0, leading: 4, bottom: 0, trailing: 4)
        
        let button = UIButton(configuration: configuration)
        button.tintColor = .white.withAlphaComponent(0.8)
        
        return button
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        let gradientView = GradientView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        contentView.addSubview(gradientView)
        gradientView.snp.makeConstraints { make in
            make.edges.equalTo(contentView)
        }
        
        // Button Part
        contentView.addSubview(priceLabel)
        contentView.addSubview(purchaseButton)
        purchaseButton.snp.makeConstraints { make in
            make.bottom.equalTo(priceLabel.snp.top).offset(-6)
            make.trailing.equalTo(contentView).inset(20)
        }
        priceLabel.snp.makeConstraints { make in
            make.top.equalTo(contentView.snp.centerY)
            make.leading.trailing.equalTo(purchaseButton)
        }
        contentView.addSubview(restoreButton)
        restoreButton.snp.makeConstraints { make in
            make.bottom.equalTo(contentView).inset(20)
            make.trailing.lessThanOrEqualTo(contentView).inset(18)
            make.centerX.equalTo(priceLabel).priority(.medium)
            make.top.greaterThanOrEqualTo(priceLabel.snp.bottom).offset(10)
        }
        restoreButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        restoreButton.addTarget(self, action: #selector(restoreAction), for: .touchUpInside)
        purchaseButton.addTarget(self, action: #selector(purchaseAction), for: .touchUpInside)
        
        // Text Part
        contentView.addSubview(topLabel)
        topLabel.snp.makeConstraints { make in
            make.top.equalTo(contentView).inset(20)
            make.leading.equalTo(contentView).inset(20)
            make.trailing.equalTo(purchaseButton.snp.leading).offset(-10)
        }
        topLabel.setContentHuggingPriority(.defaultLow, for: .vertical)
        
        contentView.addSubview(firstItemLabel)
        firstItemLabel.snp.makeConstraints { make in
            make.top.equalTo(topLabel.snp.bottom).offset(12)
            make.leading.equalTo(contentView).inset(22)
            make.trailing.equalTo(purchaseButton.snp.leading).offset(-10)
        }
        firstItemLabel.setContentHuggingPriority(.required, for: .vertical)
        
        contentView.addSubview(secondItemLabel)
        secondItemLabel.snp.makeConstraints { make in
            make.top.equalTo(firstItemLabel.snp.bottom).offset(8)
            make.leading.equalTo(contentView).inset(22)
            make.trailing.equalTo(purchaseButton.snp.leading).offset(-10)
        }
        secondItemLabel.setContentHuggingPriority(.required, for: .vertical)
        
        contentView.addSubview(thirdItemLabel)
        thirdItemLabel.snp.makeConstraints { make in
            make.top.equalTo(secondItemLabel.snp.bottom).offset(8)
            make.leading.equalTo(contentView).inset(22)
            make.bottom.equalTo(contentView).inset(20)
            make.trailing.equalTo(restoreButton.snp.leading).offset(-4)
        }
        thirdItemLabel.setContentHuggingPriority(.required, for: .vertical)
        
        let view = UIView()
        selectedBackgroundView = view
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc
    func restoreAction() {
        restoreClosure?()
    }
    
    @objc
    func purchaseAction() {
        purchaseClosure?()
    }
    
    func update(price: String) {
        priceLabel.text = price
    }
}

