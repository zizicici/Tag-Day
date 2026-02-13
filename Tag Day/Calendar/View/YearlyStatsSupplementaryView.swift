//
//  YearlyStatsSupplementaryView.swift
//  Tag Day
//
//  Created by Ci Zi on 2026/2/13.
//

import UIKit

final class YearlyStatsSupplementaryView: UICollectionReusableView {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.textAlignment = .center
        label.textColor = AppColor.text
        label.lineBreakMode = .byTruncatingTail
        label.layer.cornerRadius = 8.0
        label.layer.masksToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        return label
    }()
    
    private var hasTitle: Bool = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 30.0),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10.0),
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleLabel.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 1.0 / 7.0)
        ])
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadIfNeeded), name: .SettingsUpdate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadColorIfNeeded), name: .CurrentBookChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadColorIfNeeded), name: .BooksUpdated, object: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.hasDifferentColorAppearance(comparedTo: traitCollection) == true {
            applyStyle()
        }
    }
    
    func update(title: String?) {
        titleLabel.text = title
        hasTitle = title != nil
        titleLabel.isHidden = !hasTitle
        applyStyle()
    }
    
    @objc
    private func reloadIfNeeded() {
        applyStyle()
    }
    
    @objc
    private func reloadColorIfNeeded() {
        applyStyle()
    }
    
    private func applyStyle() {
        titleLabel.textColor = AppColor.dynamicColor
        titleLabel.backgroundColor = hasTitle ? AppColor.dynamicColor.withAlphaComponent(0.12) : .clear
        titleLabel.layer.borderWidth = 0.0
        titleLabel.layer.borderColor = UIColor.clear.cgColor
    }
}
