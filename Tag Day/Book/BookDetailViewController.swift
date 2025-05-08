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
                updateAddButtonStatus()
            }
        }
    }
    
    private var comment: String? {
        get {
            return book.comment
        }
        set {
            if book.comment != newValue {
                book.comment = newValue
                isEdited = true
            }
        }
    }
    
    private var isEdited: Bool = false
    private weak var titleCell: TextInputCell?
    
    enum Section: Int, Hashable {
        case title
        case comment
        case delete
        
        var header: String? {
            switch self {
            case .title:
                return nil
            case .comment:
                return nil
            case .delete:
                return nil
            }
        }
        
        var footer: String? {
            switch self {
            case .title:
                return String(localized: "books.detail.title.hint")
            case .comment:
                return nil
            case .delete:
                return nil
            }
        }
    }
    
    enum Item: Hashable {
        case title(String)
        case comment(String?)
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
            let sectionKind = Section(rawValue: section)
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
        navigationController?.navigationBar.tintColor = AppColor.main
        
        let saveItem = UIBarButtonItem(title: String(localized: "button.save"), style: .plain, target: self, action: #selector(save))
        saveItem.isEnabled = false
        navigationItem.rightBarButtonItem = saveItem
        
        let cancelItem = UIBarButtonItem(title: String(localized: "button.cancel"), style: .plain, target: self, action: #selector(dismissViewController))
        navigationItem.leftBarButtonItem = cancelItem
        
        configureHierarchy()
        configureDataSource()
        reloadData()
    }
    
    func configureHierarchy() {
        tableView = UIDraggableTableView(frame: .zero, style: .insetGrouped)
        tableView.backgroundColor = AppColor.background
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: NSStringFromClass(UITableViewCell.self))
        tableView.register(TextInputCell.self, forCellReuseIdentifier: NSStringFromClass(TextInputCell.self))
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
                    cell.update(text: title, placeholder: String(localized: "books.detail.placeholder.title"))
                    cell.textDidChanged = { [weak self] text in
                        self?.bookTitle = text
                    }
                    cell.tintColor = AppColor.main
                }
                return cell
            case .comment(let comment):
                let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(TextInputCell.self), for: indexPath)
                if let cell = cell as? TextInputCell {
                    cell.update(text: comment, placeholder: String(localized: "books.detail.placeholder.comment"))
                    cell.textDidChanged = { [weak self] text in
                        self?.comment = text
                    }
                    cell.tintColor = AppColor.main
                }
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
    
    func reloadData() {
        updateAddButtonStatus()
        
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.title])
        snapshot.appendItems([.title(bookTitle)], toSection: .title)
        snapshot.appendSections([.comment])
        snapshot.appendItems([.comment(comment)], toSection: .comment)
        if isEditMode() {
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
    
    func updateAddButtonStatus() {
        navigationItem.rightBarButtonItem?.isEnabled = allowSave()
    }
    
    func allowSave() -> Bool {
        let titleFlag = bookTitle.isValidTagTitle()
        return titleFlag
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
}

extension BookDetailViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let identifier = dataSource.itemIdentifier(for: indexPath) {
            switch identifier {
            case .title:
                break
            case .comment:
                break
            case .delete:
                showDeleteAlert()
            }
        }
    }
}

extension String {
    func isValidBookTitle() -> Bool{
        return count > 0 && count <= 60
    }
}
