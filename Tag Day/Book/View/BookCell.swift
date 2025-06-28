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
    var bookInfo: BookInfo
}

private extension UICellConfigurationState {
    var bookItem: BookCellItem? {
        set { self[.bookItem] = newValue }
        get { return self[.bookItem] as? BookCellItem }
    }
}

class BookBaseCell: UICollectionViewListCell {
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
    var detail: UICellAccessory?

    private func defaultListContentConfiguration() -> UIListContentConfiguration { return .subtitleCell() }
    private lazy var listContentView = UIListContentView(configuration: defaultListContentConfiguration())

    override func prepareForReuse() {
        super.prepareForReuse()
        
        detail = nil
    }
    
    func setupViewsIfNeeded() {
        guard listContentView.superview == nil else {
            return
        }
        
        contentView.addSubview(listContentView)
        listContentView.snp.makeConstraints { make in
            make.edges.equalTo(contentView)
        }
    }
    
    override func updateConfiguration(using state: UICellConfigurationState) {
        setupViewsIfNeeded()
        
        accessories = [detail, .reorder(displayed: .always)].compactMap{ $0 }
        
        var content = defaultListContentConfiguration().updated(for: state)
        content.imageProperties.preferredSymbolConfiguration = .init(font: content.textProperties.font, scale: .large)
        content.textToSecondaryTextVerticalPadding = 6.0
        var layoutMargins = content.directionalLayoutMargins
        layoutMargins.leading = 10.0
        layoutMargins.top = 10.0
        layoutMargins.bottom = 10.0
        content.directionalLayoutMargins = layoutMargins
        
        if let bookInfo = state.bookItem?.bookInfo {
            content.image = bookInfo.book.image
            content.text = bookInfo.book.title
            content.textProperties.color = AppColor.text
            content.secondaryText = bookInfo.subtitle()
            content.secondaryTextProperties.color = AppColor.text.withAlphaComponent(0.75)
        }

        listContentView.configuration = content
        
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
