//
//  BookCell.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/5/3.
//

import Foundation
import UIKit
import SnapKit

fileprivate extension UIConfigurationStateCustomKey {
    static let bookItem = UIConfigurationStateCustomKey("com.zizicici.tag.cell.book.item")
}

struct BookCellItem: Hashable {
    var book: Book
}

private extension UICellConfigurationState {
    var bookItem: BookCellItem? {
        set { self[.bookItem] = newValue }
        get { return self[.bookItem] as? BookCellItem }
    }
}

class BookBaseCell: UICollectionViewCell {
    private var bookItem: BookCellItem? = nil
    
    func update(with newBook: BookCellItem) {
        guard bookItem != newBook else { return }
        bookItem = newBook
        setNeedsUpdateConfiguration()
    }
    
    override var configurationState: UICellConfigurationState {
        var state = super.configurationState
        state.bookItem = self.bookItem
        return state
    }
}

class BookListCell: BookBaseCell {
    private func defaultListContentConfiguration() -> UIListContentConfiguration { return .valueCell() }
    private lazy var listContentView = UIListContentView(configuration: defaultListContentConfiguration())

    var iconView: UIImageView = UIImageView()
    
    func setupViewsIfNeeded() {
        guard iconView.superview == nil else {
            return
        }
        
        contentView.addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.leading.equalTo(contentView).inset(20.0)
            make.centerY.equalTo(contentView)
            make.height.equalTo(30.0)
            make.width.equalTo(30.0)
        }
        
        contentView.addSubview(listContentView)
        listContentView.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing)
            make.top.bottom.trailing.equalTo(contentView)
        }
    }
    
    override func updateConfiguration(using state: UICellConfigurationState) {
        setupViewsIfNeeded()
        var content = defaultListContentConfiguration().updated(for: state)
        content.imageProperties.preferredSymbolConfiguration = .init(font: content.textProperties.font, scale: .large)
        content.text = state.bookItem?.book.name
        content.axesPreservingSuperviewLayoutMargins = []
        listContentView.configuration = content
        
//        if let icon = state.bookItem?.book.icon {
//            iconView.update(icon)
//        }
        
        backgroundConfiguration = BookCellBackgroundConfiguration.configuration(for: state)
    }
}

struct BookCellBackgroundConfiguration {
    static func configuration(for state: UICellConfigurationState) -> UIBackgroundConfiguration {
        var background = UIBackgroundConfiguration.listGroupedCell()
        if state.isSelected {
            background.backgroundColor = .clear
        }
        return background
    }
}
