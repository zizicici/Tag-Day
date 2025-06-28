//
//  MainViewController.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/5/3.
//

import Foundation
import UIKit
import SnapKit

class MainViewController: CalendarViewController {
    var tagButton: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.cornerStyle = .large
        configuration.image = UIImage(systemName: "tag")?.withConfiguration(UIImage.SymbolConfiguration(textStyle: .body, scale: .default))
        configuration.baseForegroundColor = .white
        configuration.background.backgroundColor = AppColor.main.withAlphaComponent(0.85)
        let button = UIButton(configuration: configuration)
        button.showsMenuAsPrimaryAction = true
        return button
    }()
    
    var bookPickerButton: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.titleAlignment = .center
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer({ incoming in
            var outgoing = incoming
            outgoing.font = UIFont.preferredSystemFont(for: .body, weight: .semibold)
            
            return outgoing
        })
        configuration.titleLineBreakMode = .byTruncatingTail
        configuration.cornerStyle = .large
        configuration.image = UIImage(systemName: "book.closed")?.withConfiguration( UIImage.SymbolConfiguration(textStyle: .body, scale: .default))
        configuration.imagePadding = 10.0
        configuration.baseForegroundColor = .white
        configuration.background.backgroundColor = AppColor.main.withAlphaComponent(0.85)
        let button = UIButton(configuration: configuration)
        button.showsMenuAsPrimaryAction = true
        return button
    }()
    
    var tagBarButtonItem: UIBarButtonItem?
    
    var bookBarButtonItem: UIBarButtonItem?
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 26.0, *) {
            setupBottomBarItems()
        } else {
            setupBottomButtons()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadButtomButtons), name: .CurrentBookChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadButtomButtons), name: .ActiveTagsUpdated, object: nil)

        reloadButtomButtons()
    }
    
    func setupBottomButtons() {
        view.addSubview(tagButton)
        tagButton.snp.makeConstraints { make in
            make.trailing.equalTo(view).inset(20)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(20)
            make.height.width.equalTo(44)
        }
        
        tagButton.configurationUpdateHandler = { [weak self] button in
            guard let self = self else { return }
            
            button.menu = self.getTagsMenu()
            if DataManager.shared.currentBook == nil {
                button.isEnabled = false
            } else {
                button.isEnabled = true
            }
        }
        
        view.addSubview(bookPickerButton)
        bookPickerButton.snp.makeConstraints { make in
            make.leading.equalTo(view).inset(20)
            make.trailing.lessThanOrEqualTo(tagButton.snp.leading).offset(-20)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(20)
            make.height.equalTo(44)
        }
        
        bookPickerButton.configurationUpdateHandler = { [weak self] button in
            guard let self = self else { return }
            
            var config = button.configuration
            if let title = DataManager.shared.currentBook?.title {
                config?.title = title
            } else {
                config?.title = String(localized: "books.empty")
            }
            
            button.configuration = config
            button.menu = self.getBooksMenu()
        }
    }
    
    func setupBottomBarItems() {
        let bookItem = UIBarButtonItem(title: String(localized: "tags.new"), style: .done, target: nil, action: nil)
        bookItem.tintColor = AppColor.main
        
        let tagItem = UIBarButtonItem(image: UIImage(systemName: "tag"), style: .done, target: nil, action: nil)
        tagItem.tintColor = AppColor.main
        
        self.bookBarButtonItem = bookItem
        self.tagBarButtonItem = tagItem
        
        bookBarButtonItem?.menu = getBooksMenu()
        bookBarButtonItem?.title = DataManager.shared.currentBook?.title
        tagBarButtonItem?.menu = getTagsMenu()
        
        toolbarItems = [bookBarButtonItem!, .flexibleSpace(), tagBarButtonItem!]
        navigationController?.setToolbarHidden(false, animated: false)
    }
    
    @objc
    func reloadButtomButtons() {
        bookPickerButton.setNeedsUpdateConfiguration()
        tagButton.setNeedsUpdateConfiguration()
        bookBarButtonItem?.menu = getBooksMenu()
        tagBarButtonItem?.menu = getTagsMenu()
    }
    
    func getBooksMenu() -> UIMenu {
        var elements: [UIMenuElement] = []
        if let books = try? DataManager.shared.fetchAllBookInfos(for: .active) {
            let bookElements: [UIMenuElement] = books.reversed().map({ info in
                return UIAction(title: info.book.title, subtitle: info.subtitle(), image: info.book.image, state: DataManager.shared.currentBook?.id == info.book.id ? .on : .off) { _ in
                    DataManager.shared.select(book: info.book)
                }
            })
            elements.append(contentsOf: bookElements)
        }
        
        let manageAction = UIAction(title: String(localized: "books.management"), image: UIImage(systemName: "books.vertical")) { [weak self] action in
            self?.showBookManagement()
        }
        let newAction = UIAction(title: String(localized: "books.new"), image: UIImage(systemName: "plus")) { [weak self] action in
            self?.showBookEditorForAdd()
        }
        
        let currentPageDivider = UIMenu(title: "", options: .displayInline, children: [newAction, manageAction])
        elements.append(currentPageDivider)
        
        return UIMenu(children: elements)
    }
    
    func showBookManagement() {
        let bookListVC = BookListViewController()
        let nav = NavigationController(rootViewController: bookListVC)
        navigationController?.present(nav, animated: true)
    }
    
    func showBookEditorForAdd() {
        let activeBooks = DataManager.shared.books.filter({ $0.bookType == .active }).sorted(by: { $0.order < $1.order })

        var bookOrder = 0
        if let lastestBook = activeBooks.last {
            bookOrder = lastestBook.order + 1
        }
        let newBook = Book(title: "", color: AppColor.main.generateLightDarkString(), order: bookOrder)
        let nav = NavigationController(rootViewController: BookDetailViewController(book: newBook))
        
        navigationController?.present(nav, animated: true)
    }
    
    func getTagsMenu() -> UIMenu {
        var elements: [UIMenuElement] = []
        let tags = DataManager.shared.tags
        let activeTags = DataManager.shared.activeTags

        if tags.count > 0 {
            let deselectAllAction = UIAction(title: String(localized: "tags.deselect.all"), image: UIImage(systemName: "xmark.square"), state: activeTags.count == 0 ? .on : .off) { _ in
                DataManager.shared.resetActiveToggle(blank: true)
            }
            
            let tagElements: [UIMenuElement] = tags.reversed().map({ tag in
                return UIAction(title: tag.title, subtitle: tag.subtitle, image: UIImage(systemName: "rectangle.fill")?.withTintColor(tag.dynamicColor, renderingMode: .alwaysOriginal)) { _ in
                    DataManager.shared.toggleActive(only: tag)
                }
            })
            let singleSelectionMenu = UIMenu(title: String(localized: "tags.singleSelection"), options: .singleSelection, children: tagElements)
            
            let selectAllAction = UIAction(title: String(localized: "tags.select.all"), image: UIImage(systemName: "checkmark.square"), state: tags.count == activeTags.count ? .on : .off) { _ in
                DataManager.shared.resetActiveToggle(blank: false)
            }
            
            let currentPageDivider = UIMenu(title: "", options: .displayInline, children: [deselectAllAction, singleSelectionMenu, selectAllAction])
            elements.append(currentPageDivider)
        }
        
        let tagElements: [UIMenuElement] = tags.reversed().map({ tag in
            return UIAction(title: tag.title, subtitle: tag.subtitle, image: UIImage(systemName: "rectangle.fill")?.withTintColor(tag.dynamicColor, renderingMode: .alwaysOriginal), attributes: [.keepsMenuPresented], state: activeTags.contains(tag) ? .on : .off) { _ in
                DataManager.shared.toggleActiveState(to: tag)
            }
        })
        let tagsDivider = UIMenu(title: "", options: .displayInline, children: tagElements)
        elements.append(tagsDivider)
        
        let manageAction = UIAction(title: String(localized: "tags.management"), image: UIImage(systemName: "list.bullet")) { [weak self] action in
            self?.showTagManagement()
        }
        let newAction = UIAction(title: String(localized: "tags.new"), image: UIImage(systemName: "plus")) { [weak self] action in
            self?.showTagEditorForAdd()
        }
        
        let currentPageDivider = UIMenu(title: "", options: .displayInline, children: [newAction, manageAction])
        elements.append(currentPageDivider)
        
        return UIMenu(children: elements)
    }
    
    func showTagManagement() {
        let tagListVC = TagListViewController(bookID: DataManager.shared.currentBook?.id)
        let nav = NavigationController(rootViewController: tagListVC)
        navigationController?.present(nav, animated: true)
    }
    
    func showTagEditorForAdd() {
        guard let bookID = DataManager.shared.currentBook?.id else {
            return
        }
        var tagIndex = 0
        if let lastestTag = DataManager.shared.tags.last {
            tagIndex = lastestTag.order + 1
        }
        let newTag = Tag(bookID: bookID, title: "", color: "", order: tagIndex)
        let nav = NavigationController(rootViewController: TagDetailViewController(tag: newTag))
        
        navigationController?.present(nav, animated: true)
    }
}
