//
//  DateCell.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/5/13.
//

import UIKit
import SnapKit
import ZCCalendar

struct DateCellItem: Hashable {
    enum Mode {
        case date
        case dateAndTime
    }
    
    var title: String
    var nanoSecondsFrom1970: Int64?
    var day: GregorianDay
    var mode: Mode = .dateAndTime
}

extension UIConfigurationStateCustomKey {
    static let dateItem = UIConfigurationStateCustomKey("com.zizicici.tagday.cell.date.item")
}

extension UICellConfigurationState {
    var dateItem: DateCellItem? {
        set { self[.dateItem] = newValue }
        get { return self[.dateItem] as? DateCellItem }
    }
}

class DateBaseCell: UITableViewCell {
    private var dateItem: DateCellItem? = nil
    
    func update(with newDate: DateCellItem) {
        guard dateItem != newDate else { return }
        dateItem = newDate
        setNeedsUpdateConfiguration()
    }
    
    override var configurationState: UICellConfigurationState {
        var state = super.configurationState
        state.dateItem = self.dateItem
        return state
    }
}

class DateCell: DateBaseCell {
    private func defaultListContentConfiguration() -> UIListContentConfiguration { return .valueCell() }
    private lazy var listContentView = UIListContentView(configuration: defaultListContentConfiguration())
    
    var selectDateAction: ((Int64) -> ())?
    
    var datePicker: UIDatePicker?
    
    func setupViewsIfNeeded() {
        guard listContentView.superview == nil else {
            return
        }
        
        contentView.addSubview(listContentView)
        listContentView.snp.makeConstraints { make in
            make.leading.top.bottom.trailing.equalTo(contentView)
        }
        
        let datePicker = UIDatePicker(frame: CGRect.zero, primaryAction: UIAction(handler: { [weak self] _ in
            if let date = self?.datePicker?.date {
                self?.selectDateAction?(date.nanoSecondSince1970)
            }
        }))
        datePicker.datePickerMode = .dateAndTime
        datePicker.tintColor = AppColor.main
        contentView.addSubview(datePicker)
        datePicker.snp.makeConstraints { make in
            make.trailing.equalTo(contentView).inset(16)
            make.centerY.equalTo(contentView)
        }
        self.datePicker = datePicker
    }
    
    override func updateConfiguration(using state: UICellConfigurationState) {
        setupViewsIfNeeded()
        var content = defaultListContentConfiguration().updated(for: state)
        if let dateItem = state.dateItem {
            content.text = dateItem.title
            listContentView.configuration = content
            
            switch dateItem.mode {
            case .date:
                datePicker?.datePickerMode = .date
                datePicker?.date = dateItem.day.generateDate(secondsFromGMT: Calendar.current.timeZone.secondsFromGMT()) ?? Date()
            case .dateAndTime:
                datePicker?.datePickerMode = .dateAndTime
                if let nanoSecondsFrom1970 = dateItem.nanoSecondsFrom1970 {
                    datePicker?.date = Date(nanoSecondSince1970: nanoSecondsFrom1970)
                } else {
                    datePicker?.date = Date().combine(with: dateItem.day)
                }
            }
            
            let text: String = datePicker?.date.formatted(date: .omitted, time: .standard) ?? ""

            accessibilityLabel = dateItem.title + ":" + text
        }
        isAccessibilityElement = true
        accessibilityTraits = .button
    }
}

extension Date {
    func combine(with day: GregorianDay) -> Self {
        let calendar = Calendar.current
        
        // 获取时间组件
        let hour = calendar.component(.hour, from: self)
        let minute = calendar.component(.minute, from: self)
        let second = calendar.component(.second, from: self)
        
        let targetDay = day.generateDate(secondsFromGMT: calendar.timeZone.secondsFromGMT())!
        // 设置时间到目标日期
        let result = calendar.date(bySettingHour: hour, minute: minute, second: second, of: targetDay) ?? Date()
        
        return result
    }
}
