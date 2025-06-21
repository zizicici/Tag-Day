//
//  WeekdayOrderView.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/4/29.
//

import UIKit
import SnapKit
import ZCCalendar

class WeekdayOrderView: UIView {
    let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 5.0
        
        return stackView
    }()
    
    var labelColor: UIColor? {
        didSet {
            for subview in stackView.arrangedSubviews {
                if let label = subview as? UILabel {
                    label.textColor = labelColor
                }
            }
        }
    }
    
    private var interSpacing: CGFloat = 5.0
    
    var startWeekdayOrder: WeekdayOrder = WeekdayOrder.sun {
        didSet {
            if startWeekdayOrder != oldValue {
                updateLabels()
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.leading.trailing.equalTo(self)//.inset(12)
            make.top.greaterThanOrEqualTo(self)
            make.bottom.equalTo(self).inset(6)
        }
        
        updateLabels()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    convenience init(itemCount: Int, interSpacing: CGFloat) {
        self.init(frame: .zero)
        self.interSpacing = interSpacing
        self.stackView.spacing = interSpacing
    }
    
    func updateLabels() {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let weekdayOrders = Array(0..<7).compactMap { index in
            let newIndex = self.startWeekdayOrder.rawValue + index
            if newIndex == 7 {
                return WeekdayOrder.sun
            } else {
                return WeekdayOrder(rawValue: newIndex % 7)
            }
        }
        for weekdayOrder in weekdayOrders {
            let label = UILabel()
            label.backgroundColor = AppColor.background
            label.textAlignment = .center
            label.font = UIFont.systemFont(ofSize: 10, weight: .bold)
            label.textColor = color(for: weekdayOrder)
            label.text = weekdayOrder.getVeryShortSymbol()
            label.accessibilityLabel = weekdayOrder.getSymbol()
            stackView.addArrangedSubview(label)
        }
    }
    
    func color(for weekdayOrder: WeekdayOrder) -> UIColor {
        switch weekdayOrder {
        case .sat, .sun:
            return AppColor.text.withAlphaComponent(0.5)
        default:
            return AppColor.text.withAlphaComponent(0.8)
        }
    }
}
