//
//  SnapInfoCell.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/7/4.
//

import UIKit
import SnapKit

struct SnapInfoItem: Hashable {
    var dayRecord: DayRecord
    var tag: Tag
    var index: Int
}

fileprivate extension UIConfigurationStateCustomKey {
    static let snapInfoItem = UIConfigurationStateCustomKey("com.zizicici.tag.cell.snapInfo.item")
}

private extension UICellConfigurationState {
    var snapInfoItem: SnapInfoItem? {
        set { self[.snapInfoItem] = newValue }
        get { return self[.snapInfoItem] as? SnapInfoItem }
    }
}

class SnapInfoBaseCell: UICollectionViewCell {
    private var snapInfoItem: SnapInfoItem? = nil
    
    func update(with newSnapInfoItem: SnapInfoItem) {
        guard snapInfoItem != newSnapInfoItem else { return }
        snapInfoItem = newSnapInfoItem
        setNeedsUpdateConfiguration()
    }
    
    override var configurationState: UICellConfigurationState {
        var state = super.configurationState
        state.snapInfoItem = self.snapInfoItem
        return state
    }
}

class SnapInfoCell: SnapInfoBaseCell {
    private let timeInfoLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.font = UIFont.preferredFont(forTextStyle: .footnote)
        label.textAlignment = .left
        label.textColor = AppColor.text.withAlphaComponent(0.6)
        
        return label
    }()
    
    private let commentLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.textAlignment = .left
        label.textColor = AppColor.text
        
        return label
    }()
    
    private func setupViewsIfNeeded() {
        guard timeInfoLabel.superview == nil else { return }
        
        contentView.addSubview(timeInfoLabel)
        timeInfoLabel.snp.makeConstraints { make in
            make.leading.equalTo(contentView).inset(6)
            make.centerY.equalTo(contentView)
        }
        
        contentView.addSubview(commentLabel)
        commentLabel.snp.makeConstraints { make in
            make.leading.greaterThanOrEqualTo(timeInfoLabel.snp.trailing).offset(6)
            make.centerY.equalTo(contentView)
            make.trailing.equalTo(contentView).inset(6)
            make.top.equalTo(contentView).inset(3)
        }
        commentLabel.setContentHuggingPriority(.required, for: .vertical)
    }
    
    override func updateConfiguration(using state: UICellConfigurationState) {
        super.updateConfiguration(using: state)
        setupViewsIfNeeded()
        
        if let item = state.snapInfoItem {
            timeInfoLabel.text = item.dayRecord.getTime() ?? ""
            if let comment = item.dayRecord.comment {
                commentLabel.text = comment
                commentLabel.textColor = AppColor.text
            } else {
                commentLabel.text = String(localized: "record.no.comment")
                commentLabel.textColor = AppColor.text.withAlphaComponent(0.6)
            }
        }
    }
}
