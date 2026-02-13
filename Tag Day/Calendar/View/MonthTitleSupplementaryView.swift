//
//  MonthTitleSupplementaryView.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/4/29.
//

import UIKit
import SnapKit
import ZCCalendar

class MonthTitleSupplementaryView: UICollectionReusableView {
    private let monthLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.font = UIFont.preferredFont(forTextStyle: .headline)
        label.textAlignment = .center
        label.textColor = AppColor.text
        label.lineBreakMode = .byTruncatingTail
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        
        return label
    }()

    private let yearLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.textAlignment = .center
        label.textColor = AppColor.text
        label.lineBreakMode = .byTruncatingTail
        label.layer.cornerRadius = 8.0
        label.layer.masksToBounds = true
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5

        return label
    }()
    
    private var weekdayOrderView: WeekdayOrderView!
    private var hasYearText: Bool = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure(frame: frame)
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadIfNeeded), name: .SettingsUpdate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadColorIfNeeded), name: .CurrentBookChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadColorIfNeeded), name: .BooksUpdated, object: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.hasDifferentColorAppearance(comparedTo: traitCollection) == true {
            applyStyle()
        }
    }

    func configure(frame: CGRect) {
        let inset = CGFloat(10)
        
        addSubview(monthLabel)
        monthLabel.snp.makeConstraints { make in
            make.top.equalTo(self).inset(30.0)
            make.leading.equalTo(self)
            make.width.equalTo(self).multipliedBy(1/7.0)
        }

        addSubview(yearLabel)
        yearLabel.snp.makeConstraints { make in
            make.centerY.equalTo(monthLabel)
            make.trailing.equalTo(self)
            make.width.equalTo(self).multipliedBy(1/7.0)
        }
        
        weekdayOrderView = WeekdayOrderView(itemCount: 7, interSpacing: DayGrid.interSpacing)
        addSubview(weekdayOrderView)
        weekdayOrderView.snp.makeConstraints { make in
            make.top.equalTo(monthLabel.snp.bottom)
            make.leading.trailing.equalTo(self)
            make.height.equalTo(35.0)
            make.bottom.equalTo(self).inset(inset)
        }
    }
    
    func update(monthText: String, yearText: String?, startWeekOrder: WeekdayOrder) {
        monthLabel.text = monthText
        yearLabel.text = yearText
        hasYearText = yearText != nil
        yearLabel.isHidden = !hasYearText
        applyStyle()
        weekdayOrderView.startWeekdayOrder = startWeekOrder
        isAccessibilityElement = true
        accessibilityLabel = [monthText, yearText].compactMap({ $0 }).joined(separator: " ")
    }
    
    @objc
    func reloadIfNeeded() {
        weekdayOrderView.startWeekdayOrder = WeekdayOrder(rawValue: WeekStartType.current.rawValue) ?? WeekdayOrder.firstDayOfWeek
        applyStyle()
    }

    @objc
    func reloadColorIfNeeded() {
        applyStyle()
    }

    private func applyStyle() {
        monthLabel.textColor = AppColor.text
        yearLabel.textColor = AppColor.dynamicColor
        yearLabel.backgroundColor = hasYearText ? AppColor.dynamicColor.withAlphaComponent(0.12) : .clear
        yearLabel.layer.borderWidth = 0.0
        yearLabel.layer.borderColor = UIColor.clear.cgColor
    }
}
