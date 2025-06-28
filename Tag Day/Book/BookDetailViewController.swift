//
//  BookDetailViewController.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/5/8.
//

import UIKit
import SnapKit

class BookDetailViewController: UIViewController {
    private var book: Book!
    
    private var tableView: UITableView!
    private var dataSource: DataSource!
    
    private var bookTitle: String {
        get {
            return book.title
        }
        set {
            if book.title != newValue {
                book.title = newValue
                isEdited = true
                updateSaveButtonStatus()
            }
        }
    }
    
    private var symbol: String? {
        get {
            return book.symbol
        }
        set {
            if book.symbol != newValue {
                book.symbol = newValue
                isEdited = true
                updateSaveButtonStatus()
            }
        }
    }
    
    private var bookColor: UIColor {
        get {
            book.dynamicColor
        }
        set {
            book.color = newValue.generateLightDarkString()
        }
    }
    
    private var bookLightColor: UIColor {
        get {
            return bookColor.resolvedColor(with: .init(userInterfaceStyle: .light))
        }
        set {
            updateBookColor(lightColor: newValue, darkColor: bookDarkColor)
        }
    }
    
    private var bookDarkColor: UIColor {
        get {
            return bookColor.resolvedColor(with: .init(userInterfaceStyle: .dark))
        }
        set {
            updateBookColor(lightColor: bookLightColor, darkColor: newValue)
        }
    }
    
    private var customBookColors: [UIColor] = []
    
    private var isEdited: Bool = false
    private weak var titleCell: TextInputCell?
    private weak var symbolCell: SymbolCell?
    private weak var lightColorCell: ColorPickerCell?
    private weak var darkColorCell: ColorPickerCell?
    
    enum Section: Int, Hashable {
        case title
        case symbol
        case color
        case tag
        case delete
        
        var header: String? {
            switch self {
            case .title:
                return String(localized: "books.detail.title")
            case .symbol:
                return String(localized: "books.detail.symbol")
            case .color:
                return String(localized: "books.detail.color")
            case .tag:
                return nil
            case .delete:
                return nil
            }
        }
        
        var footer: String? {
            switch self {
            case .title:
                return nil
            case .symbol:
                return nil
            case .color:
                return String(localized: "books.detail.color.hint")
            case .tag:
                return nil
            case .delete:
                return nil
            }
        }
    }
    
    enum Item: Hashable {
        case title(String)
        case symbol
        case lightColor(ColorPickerItem)
        case darkColor(ColorPickerItem)
        case tagEntry
        case tag(Tag)
        case delete
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    convenience init(book: Book) {
        self.init()
        self.book = book
    }
    
    class DataSource: UITableViewDiffableDataSource<Section, Item> {
        override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
            let sectionKind = sectionIdentifier(for: section)
            return sectionKind?.header
        }
        
        override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
            let sectionKind = sectionIdentifier(for: section)
            return sectionKind?.footer
        }
    }
    
    deinit {
        print("BookDetailViewController is deinited")
    }
    
    func isEditMode() -> Bool {
        return book.id != nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = isEditMode() ? String(localized: "books.detail.title.edit") : String(localized: "books.detail.title.add")
        
        view.backgroundColor = AppColor.background
        
        let saveItem = UIBarButtonItem(title: String(localized: "button.save"), style: .done, target: self, action: #selector(save))
        saveItem.tintColor = AppColor.main
        saveItem.isEnabled = false
        navigationItem.rightBarButtonItem = saveItem
        
        let cancelItem = UIBarButtonItem(title: String(localized: "button.cancel"), style: .plain, target: self, action: #selector(dismissViewController))
        cancelItem.tintColor = AppColor.main
        navigationItem.leftBarButtonItem = cancelItem
        
        if !defaultColors().map({ $0.generateLightDarkString() }).contains(book.dynamicColor.generateLightDarkString()) {
            customBookColors = [book.dynamicColor]
        }
        
        configureHierarchy()
        configureDataSource()
        reloadData()
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: .DatabaseUpdated, object: nil)
    }
    
    func configureHierarchy() {
        tableView = UIDraggableTableView(frame: .zero, style: .insetGrouped)
        tableView.backgroundColor = AppColor.background
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: NSStringFromClass(UITableViewCell.self))
        tableView.register(TextInputCell.self, forCellReuseIdentifier: NSStringFromClass(TextInputCell.self))
        tableView.register(TextViewCell.self, forCellReuseIdentifier: NSStringFromClass(TextViewCell.self))
        tableView.register(BookTagCell.self, forCellReuseIdentifier: NSStringFromClass(BookTagCell.self))
        tableView.register(ColorPickerCell.self, forCellReuseIdentifier: NSStringFromClass(ColorPickerCell.self))
        tableView.register(SymbolCell.self, forCellReuseIdentifier: NSStringFromClass(SymbolCell.self))
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 50.0
        tableView.delegate = self
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(view)
        }
        tableView.contentInset = UIEdgeInsets(top: 0.0, left: 0, bottom: 0, right: 0)
    }
    
    func configureDataSource() {
        dataSource = DataSource(tableView: tableView) { [weak self] (tableView, indexPath, item) -> UITableViewCell? in
            guard let self = self else { return nil }
            guard let identifier = dataSource.itemIdentifier(for: indexPath) else { return nil }
            switch identifier {
            case .title(let title):
                let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(TextInputCell.self), for: indexPath)
                if let cell = cell as? TextInputCell {
                    self.titleCell = cell
                    cell.update(text: title, placeholder: String(localized: "books.detail.title.hint"))
                    cell.textDidChanged = { [weak self] text in
                        self?.bookTitle = text
                    }
                    cell.tintColor = AppColor.main
                }
                return cell
            case .symbol:
                let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(SymbolCell.self), for: indexPath)
                self.symbolCell = cell as? SymbolCell
                self.updateSymbolCell()
                return cell
            case .lightColor(let colorPickerItem):
                let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(ColorPickerCell.self), for: indexPath)
                if let cell = cell as? ColorPickerCell {
                    self.lightColorCell = cell
                    cell.update(with: colorPickerItem)
                    cell.update(colors: self.getBookColors(isLight: true), selectedColor: bookLightColor.generateLightDarkString(.light))
                    cell.selectedColorDidChange = { [weak self] newColor in
                        if let color = UIColor(hex: newColor) {
                            self?.updateBookColor(color, isLight: true)
                        }
                    }
                    cell.showPicker = { [weak self] in
                        self?.showBookColorPicker(isLight: true)
                    }
                }
                return cell
            case .darkColor(let colorPickerItem):
                let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(ColorPickerCell.self), for: indexPath)
                if let cell = cell as? ColorPickerCell {
                    self.darkColorCell = cell
                    cell.update(with: colorPickerItem)
                    cell.update(colors: self.getBookColors(isLight: false), selectedColor: bookDarkColor.generateLightDarkString(.dark))
                    cell.selectedColorDidChange = { [weak self] newColor in
                        if let color = UIColor(hex: newColor) {
                            self?.updateBookColor(color, isLight: false)
                        }
                    }
                    cell.showPicker = { [weak self] in
                        self?.showBookColorPicker(isLight: false)
                    }
                }
                return cell
            case .tag(let tag):
                let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(BookTagCell.self), for: indexPath)
                cell.accessoryType = .none
                var content = UIListContentConfiguration.subtitleCell()
                content.imageProperties.preferredSymbolConfiguration = .init(font: content.textProperties.font, scale: .large)
                content.textToSecondaryTextVerticalPadding = 6.0
                var layoutMargins = content.directionalLayoutMargins
                layoutMargins.top = 10.0
                layoutMargins.bottom = 10.0
                content.directionalLayoutMargins = layoutMargins
                content.image = UIImage(systemName: "square.fill")?.withTintColor(UIColor(string: tag.color) ?? .white, renderingMode: .alwaysOriginal)
                content.text = tag.title
                content.textProperties.color = AppColor.text
                content.textProperties.alignment = .natural
                content.secondaryText = tag.subtitle
                content.secondaryTextProperties.color = AppColor.text.withAlphaComponent(0.75)
                cell.contentConfiguration = content
                return cell
            case .tagEntry:
                let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(UITableViewCell.self), for: indexPath)
                cell.accessoryType = .none
                var content = cell.defaultContentConfiguration()
                content.text = String(localized: "tags.management")
                content.textProperties.color = AppColor.main
                content.textProperties.alignment = .center
                cell.contentConfiguration = content
                cell.separatorInset = .zero
                return cell
            case .delete:
                let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(UITableViewCell.self), for: indexPath)
                cell.accessoryType = .none
                var content = cell.defaultContentConfiguration()
                content.text = String(localized: "button.delete")
                content.textProperties.color = .systemRed
                content.textProperties.alignment = .center
                cell.contentConfiguration = content
                return cell
            }
        }
    }
    
    @objc
    func reloadData() {
        updateSaveButtonStatus()
        
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.title])
        snapshot.appendItems([.title(bookTitle)], toSection: .title)
        snapshot.appendSections([.symbol])
        snapshot.appendItems([.symbol], toSection: .symbol)
        snapshot.appendSections([.color])
        snapshot.appendItems([
            .lightColor(ColorPickerItem(title: String(localized: "tag.detail.preview.light"))),
            .darkColor(ColorPickerItem(title: String(localized: "tag.detail.preview.dark")))
        ], toSection: .color)
        if isEditMode() {
            snapshot.appendSections([.tag])
            if let bookID = book.id, let tags = try? DataManager.shared.fetchAllTags(bookID: bookID) {
                snapshot.appendItems(tags.map{ Item.tag($0) }, toSection: .tag)
            }
            snapshot.appendItems([.tagEntry], toSection: .tag)
            snapshot.appendSections([.delete])
            snapshot.appendItems([.delete], toSection: .delete)
        }
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    public func allowDismiss() -> Bool {
        if isEditMode() {
            if titleCell?.keyboardIsShowing == true {
                return false
            } else {
                return !isEdited
            }
        } else {
            if titleCell?.keyboardIsShowing == true {
                return false
            } else {
                return bookTitle.count == 0
            }
        }
    }
    
    func updateSaveButtonStatus() {
        navigationItem.rightBarButtonItem?.isEnabled = allowSave()
    }
    
    func allowSave() -> Bool {
        let titleFlag = bookTitle.isValidBookTitle()
        let commentFlag = symbol?.isValidBookComment() ?? true
        
        return titleFlag && commentFlag
    }
    
    @objc
    func save() {
        if isEditMode() {
            // Modify Old
            let result = DataManager.shared.update(book: book)
            if result {
                dismissViewController()
            }
        } else {
            // Create New
            let result = DataManager.shared.add(book: book)
            if result {
                dismissViewController()
            }
        }
    }
    
    @objc
    func dismissViewController() {
        dismiss(animated: true)
    }
    
    func delete() {
        let result = DataManager.shared.delete(book: book)
        if result {
            dismissViewController()
        }
    }
    
    func showDeleteAlert() {
        guard let bookID = book.id else { return }
        guard let tags = try? DataManager.shared.fetchAllTags(bookID: bookID) else { return }
        guard let records = try? DataManager.shared.fetchAllDayRecords(bookID: bookID) else { return }
        
        let message = (tags.count > 0) ? String(format: String(localized: "books.detail.delete.alert.message.%i.%i"), tags.count, records.count) : String(localized: "books.detail.delete.alert.message")
        
        let alertController = UIAlertController(title: String(localized: "books.detail.delete.alert.title"), message: message, preferredStyle: .alert)
        let deleteAction = UIAlertAction(title: String(localized: "button.delete"), style: .destructive) { [weak self] _ in
            alertController.dismiss(animated: true)
            self?.delete()
        }
        let cancelAction = UIAlertAction(title: String(localized: "button.cancel"), style: .cancel)
        alertController.addAction(deleteAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true)
    }
    
    func showTagManagement() {
        let tagListVC = TagListViewController(bookID: book.id)
        let nav = NavigationController(rootViewController: tagListVC)
        present(nav, animated: true)
    }
    
    func updateBookColor(lightColor: UIColor, darkColor: UIColor) {
        bookColor = UIColor(dynamicProvider: { collection in
            switch collection.userInterfaceStyle {
            case .light, .unspecified:
                return lightColor
            case .dark:
                return darkColor
            @unknown default:
                fatalError()
            }
        })
        isEdited = true
    }
    
    func getBookColors(isLight: Bool) -> [String] {
        var colors: [String] = []
        
        let defaultColors = defaultColors().map({ $0.generateLightDarkString(isLight ? .light : .dark)}).unique()
        
        customBookColors.reversed().forEach { customTagColor in
            let customTagColorString = customTagColor.generateLightDarkString(isLight ? .light : .dark)
            if !defaultColors.contains(customTagColorString) {
                colors.append(customTagColorString)
            }
        }
        colors.append(contentsOf: defaultColors)
        
        return colors
    }
    
    func defaultColors() -> [UIColor] {
        return [.systemPink, .systemRed, .systemOrange, .systemYellow, .systemGreen, .systemMint, .systemTeal, .systemCyan, .systemBlue, .systemIndigo, .systemPurple, .systemBrown, .white, UIColor(white: 0.9, alpha: 1.0), UIColor(white: 0.8, alpha: 1.0), UIColor(white: 0.7, alpha: 1.0), UIColor(white: 0.6, alpha: 1.0), .gray, UIColor(white: 0.4, alpha: 1.0), UIColor(white: 0.3, alpha: 1.0), UIColor(white: 0.2, alpha: 1.0), UIColor(white: 0.1, alpha: 1.0), .black]
    }
    
    func updateBookColor(_ newColor: UIColor, isLight: Bool) {
        if !defaultColors().map({ $0.generateLightDarkString(isLight ? .light : .dark) }).unique().contains(newColor.generateLightDarkString(isLight ? .light : .dark)) {
            if !customBookColors.map({ $0.generateLightDarkString(isLight ? .light : .dark) }).contains(newColor.generateLightDarkString(isLight ? .light : .dark)) {
                customBookColors.append(newColor)
            }
        }
        
        let lightColors = getBookColors(isLight: true)
        let darkColors = getBookColors(isLight: false)
        if isLight {
            updateBookColor(lightColor: newColor, darkColor: bookDarkColor)
            lightColorCell?.update(colors: lightColors, selectedColor: newColor.generateLightDarkString(.light))
            darkColorCell?.update(colors: darkColors, selectedColor: bookDarkColor.generateLightDarkString(.dark))
        } else {
            updateBookColor(lightColor: bookLightColor, darkColor: newColor)
            lightColorCell?.update(colors: lightColors, selectedColor: bookLightColor.generateLightDarkString(.light))
            darkColorCell?.update(colors: darkColors, selectedColor: newColor.generateLightDarkString(.dark))
        }
        updateSymbolCell()
    }
    
    func updateSymbolCell() {
        guard let cell = symbolCell else { return }
        var content = UIListContentConfiguration.valueCell()
        content.image = UIImage(systemName: symbol ?? "book.closed")?.withTintColor(bookColor, renderingMode: .alwaysOriginal)
        content.text = ""
        content.secondaryText = String(localized: "book.detail.updateSymbol")
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
    }
    
    func showBookColorPicker(isLight: Bool) {
        let colorPicker = StyleColorPickerViewController()
        colorPicker.style = isLight ? .book(.light) : .book(.dark)
        
        colorPicker.selectedColor = isLight ? self.bookLightColor : self.bookDarkColor
        colorPicker.delegate = self
        present(colorPicker, animated: true)
    }
    
    @objc private func showSymbolPicker() {
        if let symbol = book.symbol {
            presentSymbolPicker(currentSymbol: symbol) { [weak self] symbol in
                self?.symbol = symbol
                self?.updateSymbolCell()
            }
        }
    }
}

extension BookDetailViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let identifier = dataSource.itemIdentifier(for: indexPath) {
            switch identifier {
            case .title:
                break
            case .symbol:
                showSymbolPicker()
            case .lightColor:
                break
            case .darkColor:
                break
            case .tag:
                break
            case .tagEntry:
                showTagManagement()
            case .delete:
                showDeleteAlert()
            }
        }
    }
}

extension BookDetailViewController: UIColorPickerViewControllerDelegate {
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        print("Add color \(viewController.selectedColor)")
        if let viewController = viewController as? StyleColorPickerViewController {
            switch viewController.style {
            case .tag, .title:
                break
            case .book(let colorType):
                switch colorType {
                case .light:
                    updateBookColor(viewController.selectedColor, isLight: true)
                case .dark:
                    updateBookColor(viewController.selectedColor, isLight: true)
                }
            }
        }
        reloadData()
    }
}

extension String {
    func isValidBookTitle() -> Bool{
        return count > 0 && count <= 60
    }
    
    func isValidBookComment() -> Bool{
        return count <= 200
    }
}

class BookTagCell: UITableViewCell {
    
}

class SymbolCell: UITableViewCell {
    
}
