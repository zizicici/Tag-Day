//
//  DurationCell.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/5/16.
//

import UIKit
import SnapKit
import DurationPicker

struct DurationConfiguration: Hashable {
    var duration: TimeInterval = 0
}

fileprivate extension UIConfigurationStateCustomKey {
    static let durationItem = UIConfigurationStateCustomKey("com.zizicici.tag.cell.duration.item")
}

extension UICellConfigurationState {
    var durationItem: DurationConfiguration? {
        set { self[.durationItem] = newValue }
        get { return self[.durationItem] as? DurationConfiguration }
    }
}

class DurationBaseCell: UITableViewCell {
    private var durationItem: DurationConfiguration? = nil
    
    func update(with newDuration: DurationConfiguration) {
        guard durationItem != newDuration else { return }
        durationItem = newDuration
        setNeedsUpdateConfiguration()
    }
    
    override var configurationState: UICellConfigurationState {
        var state = super.configurationState
        state.durationItem = self.durationItem
        return state
    }
}

class DurationCell: DurationBaseCell {
    private func defaultListContentConfiguration() -> UIListContentConfiguration { return .cell() }
    private lazy var listContentView = UIListContentView(configuration: defaultListContentConfiguration())
    
    var valueChangedAction: ((TimeInterval) -> ())?
    
    private let durationPicker: DurationPicker = {
        let picker = DurationPicker()
        picker.pickerMode = .hourMinute
        
        return picker
    }()

    func setupViewsIfNeeded() {
        guard listContentView.superview == nil else {
            return
        }
        
        contentView.addSubview(listContentView)
        listContentView.snp.makeConstraints { make in
            make.leading.top.bottom.trailing.equalTo(contentView)
        }
        
        listContentView.addSubview(durationPicker)
        durationPicker.snp.makeConstraints { make in
            make.edges.equalTo(listContentView)
        }
        
        let action = UIAction { [weak self] action in
            guard let self = self else { return }
            self.valueChangedAction?(self.durationPicker.duration)
        }
        durationPicker.addAction(action, for: .valueChanged)
    }
    
    override func updateConfiguration(using state: UICellConfigurationState) {
        setupViewsIfNeeded()
        if let durationItem = state.durationItem {
            durationPicker.duration = durationItem.duration
        }
    }
}
