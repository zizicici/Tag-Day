//
//  MonthTitleCell.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/4/29.
//

import UIKit
import SnapKit
import ZCCalendar

struct MonthItem: Hashable {
    var text: String
    var color: UIColor
}

fileprivate extension UIConfigurationStateCustomKey {
    static let monthItem = UIConfigurationStateCustomKey("com.zizicici.offday.cell.month.item")
}

private extension UICellConfigurationState {
    var monthItem: MonthItem? {
        set { self[.monthItem] = newValue }
        get { return self[.monthItem] as? MonthItem }
    }
}

class MonthTitleBaseCell: UICollectionViewCell {
    private var monthItem: MonthItem? = nil
    
    func update(with newMonthItem: MonthItem) {
        guard monthItem != newMonthItem else { return }
        monthItem = newMonthItem
        setNeedsUpdateConfiguration()
    }
    
    override var configurationState: UICellConfigurationState {
        var state = super.configurationState
        state.monthItem = self.monthItem
        return state
    }
}

class MonthTitleCell: MonthTitleBaseCell {
    let monthLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.preferredFont(forTextStyle: .headline)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        
        return label
    }()
    
    private func setupViewsIfNeeded() {
        guard monthLabel.superview == nil else { return }
        
        self.addSubview(monthLabel)
        monthLabel.snp.makeConstraints { make in
            make.leading.trailing.equalTo(self)
            make.top.equalTo(self).inset(4)
            make.bottom.equalTo(self).inset(4)
        }
    }
    
    override func updateConfiguration(using state: UICellConfigurationState) {
        super.updateConfiguration(using: state)
        setupViewsIfNeeded()
        
        if let monthItem = state.monthItem {
            monthLabel.text = monthItem.text
            monthLabel.textColor = monthItem.color
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        monthLabel.text = nil
    }
}

class MonthTitleSupplementaryView: UICollectionReusableView {
    private let label: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.font = UIFont.preferredFont(forTextStyle: .headline)
        label.textAlignment = .center
        label.textColor = AppColor.text
        
        return label
    }()
    
    private var weekdayOrderView: WeekdayOrderView!

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    func configure(frame: CGRect) {
        let inset = CGFloat(10)
        
        addSubview(label)
        label.snp.makeConstraints { make in
            make.top.equalTo(self).inset(inset)
            make.leading.equalTo(self)
            make.width.equalTo(self).multipliedBy(1/7.0)
        }
        
        weekdayOrderView = WeekdayOrderView(itemCount: 7, interSpacing: DayGrid.interSpacing)
        addSubview(weekdayOrderView)
        weekdayOrderView.snp.makeConstraints { make in
            make.top.equalTo(label.snp.bottom)
            make.leading.trailing.equalTo(self)
            make.height.equalTo(35.0)
            make.bottom.equalTo(self).inset(inset)
        }
    }
    
    func update(text: String, startWeekOrder: WeekdayOrder) {
        label.text = text
        weekdayOrderView.startWeekdayOrder = startWeekOrder
    }
}
