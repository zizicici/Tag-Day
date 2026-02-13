//
//  DayByDayViewController.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/4/29.
//

import UIKit
import ZCCalendar

class DayDisplayHandler: DisplayHandler {
    weak var delegate: DisplayHandlerDelegate?
    
    required init(delegate: DisplayHandlerDelegate) {
        self.delegate = delegate
        self.anchorYear = ZCCalendar.manager.today.year
        self.selectedYear = ZCCalendar.manager.today.year
    }
    
    func getLeading() -> Int {
        guard let firstMonth = getDisplayMonths().first else {
            return GregorianDay(year: selectedYear, month: .jan, day: 1).julianDay
        }
        return ZCCalendar.manager.firstDay(at: firstMonth.month, year: firstMonth.year).julianDay
    }
    
    func getTrailing() -> Int {
        guard let lastMonth = getDisplayMonths().last else {
            return GregorianDay(year: selectedYear, month: .dec, day: 31).julianDay
        }
        return ZCCalendar.manager.lastDay(at: lastMonth.month, year: lastMonth.year).julianDay
    }
    
    private var selectedYear: Int {
        didSet {
            delegate?.reloadData()
        }
    }
    
    private var anchorYear: Int!
    
    func getCatalogueMenuElements() -> [UIMenuElement] {
        var elements: [UIMenuElement] = []
        for i in -3...3 {
            let year = selectedYear + i
            let subtitle: String? = anchorYear == year ? String(localized: "calendar.title.year.current") : nil
            let action = UIAction(title: String(format: String(localized: "calendar.title.year%i"), year), subtitle: subtitle, state: selectedYear == year ? .on : .off) { [weak self] _ in
                guard let self = self else { return }
                self.updateSelectedYear(to: year)
            }
            elements.append(action)
        }
        return elements
    }
    
    func updateSelectedYear(to year: Int) {
        selectedYear = year
    }
    
    func getSelectedYear() -> Int {
        return selectedYear
    }
    
    func getSnapshot(tags: [Tag], records: [DayRecord]) -> NSDiffableDataSourceSnapshot<Section, Item>? {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        let displayMonths = getDisplayMonths()
        guard let firstMonth = displayMonths.first,
              let lastMonth = displayMonths.last else {
            return snapshot
        }

        let leading = ZCCalendar.manager.firstDay(at: firstMonth.month, year: firstMonth.year).julianDay
        let trailing = ZCCalendar.manager.lastDay(at: lastMonth.month, year: lastMonth.year).julianDay

        let filterRecords = records.filter { ($0.day >= leading) && ($0.day <= trailing) }

        LayoutGenerater.dayLayout(for: &snapshot, months: displayMonths, tags: tags, records: filterRecords, allRecords: records, selectedYear: selectedYear)

        return snapshot
    }
    
    func getTitle() -> String {
        let title = String(format: (String(localized: "calendar.title.year%i")), selectedYear)
        return title
    }
}

private extension DayDisplayHandler {
    func getDisplayMonths() -> [GregorianMonth] {
        var months = Month.allCases.map { GregorianMonth(year: selectedYear, month: $0) }

        if CrossYearMonthDisplay.getValue() == .enable {
            months.insert(GregorianMonth(year: selectedYear - 1, month: .dec), at: 0)
            months.append(GregorianMonth(year: selectedYear + 1, month: .jan))
        }

        return months
    }
}
