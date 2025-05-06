//
//  MainViewController.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/5/3.
//

import Foundation
import UIKit
import SnapKit

class MainViewController: NavigationController {
    var calendarVC: CalendarViewController?
    
    var buttonContainer: UIView = {
        var container = UIView()
        container.backgroundColor = AppColor.toolbar
        container.layer.cornerCurve = .continuous
        container.layer.cornerRadius = 25.0
        container.clipsToBounds = true
        
        return container
    }()
    
    var tagButton: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.image = UIImage.tag
        let button = UIButton(configuration: configuration)
        button.showsMenuAsPrimaryAction = true
        button.tintColor = UIColor(hex: "#75c594", alpha: 1.0)
        button.layer.cornerCurve = .continuous
        button.layer.cornerRadius = 20.0
        button.clipsToBounds = true
        
        return button
    }()
    
    var separator: UIView = {
        var view = UIView()
        view.backgroundColor = .white
        
        return view
    }()
    
    var bookPickerButton: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.titleAlignment = .center
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer({ incoming in
            var outgoing = incoming
            outgoing.font = UIFont.preferredFont(forTextStyle: .headline)
            
            return outgoing
        })
        configuration.cornerStyle = .capsule
        let button = UIButton(configuration: configuration)
        button.tintColor = UIColor(hex: "#75c594", alpha: 1.0)
        button.showsMenuAsPrimaryAction = true
        return button
    }()
    
    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
        if let calendarVC = rootViewController as? CalendarViewController {
            self.calendarVC = calendarVC
        }
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(buttonContainer)
        buttonContainer.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(20)
            make.width.greaterThanOrEqualTo(160)
            make.width.lessThanOrEqualTo(280)
            make.height.equalTo(56)
            make.centerX.equalTo(view)
        }
        
        view.addSubview(tagButton)
        tagButton.snp.makeConstraints { make in
            make.trailing.equalTo(buttonContainer).inset(6)
            make.centerY.equalTo(buttonContainer)
            make.height.width.equalTo(44)
        }
        
        view.addSubview(separator)
        separator.snp.makeConstraints { make in
            make.trailing.equalTo(tagButton.snp.leading).offset(-7)
            make.width.equalTo(1.5)
            make.height.equalTo(20.0)
            make.centerY.equalTo(tagButton)
        }
        
        view.addSubview(bookPickerButton)
        bookPickerButton.snp.makeConstraints { make in
            make.leading.equalTo(buttonContainer).inset(6)
            make.trailing.equalTo(separator.snp.leading).offset(-7)
            make.height.equalTo(44)
            make.centerY.equalTo(tagButton)
        }
        
        bookPickerButton.configurationUpdateHandler = { [weak self] button in
            guard let self = self else { return }
            
            var config = button.configuration
            
            config?.title = DataManager.shared.currentBook?.name
            
            button.configuration = config
            button.menu = self.getBooksMenu()
        }
        
        bookPickerButton.setNeedsUpdateConfiguration()
    }
    
    func getBooksMenu() -> UIMenu {
        var elements: [UIMenuElement] = []
        if let books = try? DataManager.shared.fetchAllBooks(for: .active) {
            let bookElements: [UIMenuElement] = books.map({ book in
                return UIAction(title: book.name, subtitle: book.comment, state: DataManager.shared.currentBook?.id == book.id ? .on : .off) { _ in
                    DataManager.shared.select(book: book)
                }
            })
            elements.append(contentsOf: bookElements)
        }
        
        let manageAction = UIAction(title: String(localized: "books.management"), image: UIImage(systemName: "books.vertical")) { [weak self] action in
            self
        }
        let newAction = UIAction(title: String(localized: "books.new"), image: UIImage(systemName: "plus")) { [weak self] action in
            self
        }
        
        let currentPageDivider = UIMenu(title: "", options: .displayInline, children: [newAction, manageAction])
        elements.append(currentPageDivider)
        
        return UIMenu(children: elements)
    }
}
