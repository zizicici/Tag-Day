//
//  CalendarViewController+Menu.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/4/29.
//

import UIKit

extension CalendarViewController {
    func getWeekStartType() -> WeekStartType {
        return WeekStartType.getValue()
    }
    
    func getWeekStartTypeMenu() -> UIMenu {
        let weekStartDays: [WeekStartType] = WeekStartType.allCases
        let weekStartActions = weekStartDays.map { type in
            let action = UIAction(title: type.getName(), state: type == getWeekStartType() ? .on : .off) { _ in
                WeekStartType.setValue(type)
            }
            return action
        }
        let weekStartTypeMenu = UIMenu(title: WeekStartType.getTitle(), subtitle: getWeekStartType().getName(), image: UIImage(systemName: "calendar"), children: weekStartActions)
    
        return weekStartTypeMenu
    }
    
    func getTagDisplayType() -> TagDisplayType {
        return TagDisplayType.getValue()
    }
    
    func getTagDisplayTypeMenu() -> UIMenu {
        let tagDisplayTypes: [TagDisplayType] = TagDisplayType.allCases
        let tagDisplayActions = tagDisplayTypes.map { type in
            let action = UIAction(title: type.getName(), state: type == getTagDisplayType() ? .on : .off) { _ in
                TagDisplayType.setValue(type)
            }
            return action
        }
        let tagDisplayTypeMenu = UIMenu(title: TagDisplayType.getTitle(), subtitle: getTagDisplayType().getName(), image: UIImage(systemName: "tag"), children: tagDisplayActions)
    
        return tagDisplayTypeMenu
    }
    
    func getMonthlyStatsType() -> MonthlyStatsType {
        return MonthlyStatsType.getValue()
    }
    
    func getMonthlyStatsTypeMenu() -> UIMenu {
        let monthlyStatsTypes: [MonthlyStatsType] = MonthlyStatsType.allCases
        let monthlyStatsTypeActions = monthlyStatsTypes.map { type in
            let action = UIAction(title: type.getName(), state: type == getMonthlyStatsType() ? .on : .off) { _ in
                MonthlyStatsType.setValue(type)
            }
            return action
        }
        let monthlyStatsTypeMenu = UIMenu(title: MonthlyStatsType.getTitle(), subtitle: getMonthlyStatsType().getName(), image: UIImage(systemName: "chart.xyaxis.line"), children: monthlyStatsTypeActions)
    
        return monthlyStatsTypeMenu
    }
    
    func getTodayIndicator() -> TodayIndicator {
        return TodayIndicator.getValue()
    }
    
    func getTodayIndicatorMenu() -> UIMenu {
        let todayIndicatorCases: [TodayIndicator] = TodayIndicator.allCases
        let todayIndicatorActions = todayIndicatorCases.map { type in
            let action = UIAction(title: type.getName(), state: type == getTodayIndicator() ? .on : .off) { _ in
                TodayIndicator.setValue(type)
            }
            return action
        }
        let todayIndicatorMenu = UIMenu(title: TodayIndicator.getTitle(), subtitle: getTodayIndicator().getName(), image: UIImage(systemName: "calendar"), children: todayIndicatorActions)
    
        return todayIndicatorMenu
    }
}
