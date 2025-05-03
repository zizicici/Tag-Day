//
//  HeaderReuseView.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/5/3.
//

import UIKit
import SnapKit

class HeaderReuseView: UICollectionReusableView {
    var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .footnote)
        label.textAlignment = .natural
        label.numberOfLines = 1
        label.textColor = .secondaryLabel
        
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(self).inset(6)
            make.bottom.equalTo(self).inset(6)
            make.leading.trailing.equalTo(self).inset(20)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
