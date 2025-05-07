//
//  TagDetailViewController.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/5/7.
//

import UIKit
import SnapKit

class TagDetailViewController: UIViewController {
    private var tag: Tag!
    
    private var tableView: UITableView!
    private var dataSource: DataSource!
    
    private var tagTitle: String {
        get {
            return tag.title
        }
        set {
            if tag.title != newValue {
                tag.title = newValue
                isEdited = true
                updateAddButtonStatus()
            }
        }
    }
    
    private var subtitle: String? {
        get {
            return tag.subtitle
        }
        set {
            if tag.subtitle != newValue {
                tag.subtitle = newValue
                isEdited = true
            }
        }
    }
    
    private var color: UIColor {
        get {
            if let color = UIColor(string: tag.color) {
                return color
            } else {
                let first = defaultColors().first!
                tag.color = first.generateLightDarkString()
                return first
            }
        }
        set {
            tag.color = newValue.generateLightDarkString()
            isEdited = true
        }
    }
    
    private var customColor: UIColor?
    private weak var titleCell: TextInputCell?
    private var isEdited: Bool = false
    
    enum Section: Int, Hashable {
        case title
        case subtitle
        case color
        case delete
        
        var header: String? {
            switch self {
            case .title:
                return nil
            case .subtitle:
                return nil
            case .color:
                return String(localized: "tags.detail.color")
            case .delete:
                return nil
            }
        }
        
        var footer: String? {
            return nil
        }
    }
    
    enum Item: Hashable {
        case title(String)
        case subtitle(String?)
        case color(UIColor)
        case delete
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    convenience init(tag: Tag) {
        self.init()
        self.tag = tag
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
        print("TagDetailViewController is deinited")
    }
    
    func isEditMode() -> Bool {
        return tag.id != nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = isEditMode() ? String(localized: "tags.detail.title.edit") : String(localized: "tags.detail.title.add")
        
        view.backgroundColor = AppColor.background
        navigationController?.navigationBar.tintColor = AppColor.main
        
        let saveItem = UIBarButtonItem(title: String(localized: "tags.detail.save"), style: .plain, target: self, action: #selector(save))
        saveItem.isEnabled = false
        navigationItem.rightBarButtonItem = saveItem
        
        let cancelItem = UIBarButtonItem(title: String(localized: "tags.detail.cancel"), style: .plain, target: self, action: #selector(cancel))
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
        tableView.register(ColorPickerCell.self, forCellReuseIdentifier: NSStringFromClass(ColorPickerCell.self))
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
                    cell.update(text: title, placeholder: String(localized: "tags.detail.placeholder.title"))
                    cell.textDidChanged = { [weak self] text in
                        self?.tagTitle = text
                    }
                    cell.tintColor = AppColor.main
                }
                return cell
            case .subtitle(let subtitle):
                let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(TextInputCell.self), for: indexPath)
                if let cell = cell as? TextInputCell {
                    cell.update(text: subtitle, placeholder: String(localized: "tags.detail.placeholder.subtitle"))
                    cell.textDidChanged = { [weak self] text in
                        self?.subtitle = text
                    }
                    cell.tintColor = AppColor.main
                }
                return cell
            case .color(let color):
                let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(ColorPickerCell.self), for: indexPath)
                if let cell = cell as? ColorPickerCell {
                    let colors: [UIColor] = self.getColors()
                    cell.update(colors: colors, selectedColor: color)
                    cell.selectedColorDidChange = { [weak cell, weak self] newColor in
                        guard let colors = self?.getColors() else { return }
                        cell?.update(colors: colors, selectedColor: newColor)
                        self?.updateColor(newColor)
                    }
                    cell.showPicker = { [weak self] in
                        self?.showColorPicker()
                    }
                }
                return cell
            case .delete:
                let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(UITableViewCell.self), for: indexPath)
                cell.accessoryType = .none
                var content = cell.defaultContentConfiguration()
                content.text = String(localized: "tags.detail.delete")
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
        snapshot.appendItems([.title(tagTitle)], toSection: .title)
        snapshot.appendSections([.subtitle])
        snapshot.appendItems([.subtitle(subtitle)], toSection: .subtitle)
        snapshot.appendSections([.color])
        snapshot.appendItems([.color(color)])
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
                return tagTitle.count == 0
            }
        }
    }
    
    func updateAddButtonStatus() {
        navigationItem.rightBarButtonItem?.isEnabled = allowSave()
    }
    
    func allowSave() -> Bool {
        let titleFlag = tagTitle.isValidEventTitle()
        return titleFlag
    }
    
    @objc
    func save() {
        
    }
    
    @objc
    func cancel() {
        dismiss(animated: true)
    }
    
    func delete() {
        
    }
    
    func showDeleteAlert() {
        let alertController = UIAlertController(title: String(localized: "tags.detail.delete.alert.title"), message: String(localized: "tags.detail.delete.alert.message"), preferredStyle: .alert)
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

extension TagDetailViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let identifier = dataSource.itemIdentifier(for: indexPath) {
            switch identifier {
            case .title(_):
                break
            case .subtitle(_):
                break
            case .color(_):
                break
            case .delete:
                showDeleteAlert()
            }
        }
    }
}

extension TagDetailViewController {
    func updateColor(_ color: UIColor) {
        self.color = color
    }
    
    func getColors() -> [UIColor] {
        var colors: [UIColor] = []
        if !defaultColors().map({ $0.generateLightDarkString() }).contains(color.generateLightDarkString()) {
            if customColor?.generateLightDarkString() != color.generateLightDarkString() {
                self.customColor = color
            }
        }
        if let customColor = customColor {
            colors.append(customColor)
        }
        colors.append(contentsOf: defaultColors())
        
        return colors
    }
    
    func defaultColors() -> [UIColor] {
        return [.systemPink, .systemRed, .systemOrange, .systemYellow, .systemGreen, .systemMint, .systemTeal, .systemCyan, .systemBlue, .systemIndigo, .systemPurple, .systemBrown, .white, UIColor(white: 0.9, alpha: 1.0), UIColor(white: 0.8, alpha: 1.0), UIColor(white: 0.7, alpha: 1.0), UIColor(white: 0.6, alpha: 1.0), .gray, UIColor(white: 0.4, alpha: 1.0), UIColor(white: 0.3, alpha: 1.0), UIColor(white: 0.2, alpha: 1.0), UIColor(white: 0.1, alpha: 1.0), .black]
    }
    
    func showColorPicker() {
        let colorPicker = UIColorPickerViewController()
        
        colorPicker.selectedColor = color
        colorPicker.delegate = self
        present(colorPicker, animated: true)
    }
}

extension TagDetailViewController: UIColorPickerViewControllerDelegate {
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        print("Add color \(viewController.selectedColor)")
        color = viewController.selectedColor
        reloadData()
    }
}

extension String {
    func isValidEventTitle() -> Bool{
        return count > 0 && count <= 150
    }
}
