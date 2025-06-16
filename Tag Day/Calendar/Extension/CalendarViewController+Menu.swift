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
}
