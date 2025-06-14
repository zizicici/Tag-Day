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
