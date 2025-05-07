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
            updatePreview()
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
    
    private var tagColor: UIColor {
        get {
            return UIColor(string: tag.color) ?? .systemGreen
        }
        set {
            tag.color = newValue.generateLightDarkString()
        }
    }
    
    private var lightColor: UIColor {
        get {
            if let color = UIColor(string: tag.color)?.resolvedColor(with: .init(userInterfaceStyle: .light)) {
                return color
            } else {
                var first: UIColor = .systemGreen
                if !defaultColors().contains(.systemGreen) {
                    first = defaultColors().first ?? .white
                }
                return first
            }
        }
        set {
            updateTagColor(lightColor: newValue, darkColor: darkColor)
        }
    }
    
    private var darkColor: UIColor {
        get {
            if let color = UIColor(string: tag.color)?.resolvedColor(with: .init(userInterfaceStyle: .dark)) {
                return color
            } else {
                var first: UIColor = .systemGreen
                if !defaultColors().contains(.systemGreen) {
                    first = defaultColors().first ?? .white
                }
                return first
            }
        }
        set {
            updateTagColor(lightColor: lightColor, darkColor: newValue)
        }
    }
    
    private var customColors: [UIColor] = []
    private var isEdited: Bool = false
    private weak var titleCell: TextInputCell?
    private weak var previewCell: TagPreviewCell?
    private weak var lightColorCell: ColorPickerCell?
    private weak var darkColorCell: ColorPickerCell?
    
    enum Section: Int, Hashable {
        case preview
        case title
        case subtitle
        case lightColor
        case darkColor
        case delete
        
        var header: String? {
            switch self {
            case .preview:
                return nil
            case .title:
                return nil
            case .subtitle:
                return nil
            case .lightColor:
                return String(localized: "tags.detail.color.light")
            case .darkColor:
                return String(localized: "tags.detail.color.dark")
            case .delete:
                return nil
            }
        }
        
        var footer: String? {
            switch self {
            case .preview:
                return nil
            case .title:
                return String(localized: "tags.detail.title.hint")
            case .subtitle:
                return nil
            case .lightColor:
                return nil
            case .darkColor:
                return nil
            case .delete:
                return nil
            }
        }
    }
    
    enum Item: Hashable {
        case preview(String, UIColor)
        case title(String)
        case subtitle(String?)
        case lightColor(UIColor)
        case darkColor(UIColor)
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
        tableView.register(TagPreviewCell.self, forCellReuseIdentifier: NSStringFromClass(TagPreviewCell.self))
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
            case .preview(let title, let color):
                let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(TagPreviewCell.self), for: indexPath)
                if let cell = cell as? TagPreviewCell {
                    self.previewCell = cell
                    cell.update(title: title, color: color)
                }
                return cell
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
            case .lightColor(let color):
                let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(ColorPickerCell.self), for: indexPath)
                if let cell = cell as? ColorPickerCell {
                    self.lightColorCell = cell
                    let colors: [UIColor] = self.getColors()
                    cell.update(colors: colors, selectedColor: color, isLight: true)
                    cell.selectedColorDidChange = { [weak self] newColor in
                        self?.updateColor(newColor, isLight: true)
                    }
                    cell.showPicker = { [weak self] in
                        self?.showColorPicker(isLight: true)
                    }
                }
                return cell
            case .darkColor(let color):
                let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(ColorPickerCell.self), for: indexPath)
                if let cell = cell as? ColorPickerCell {
                    self.darkColorCell = cell
                    let colors: [UIColor] = self.getColors()
                    cell.update(colors: colors, selectedColor: color, isLight: false)
                    cell.selectedColorDidChange = { [weak self] newColor in
                        self?.updateColor(newColor, isLight: false)
                    }
                    cell.showPicker = { [weak self] in
                        self?.showColorPicker(isLight: false)
                    }
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
        snapshot.appendSections([.preview])
        snapshot.appendItems([.preview(tagTitle, tagColor)], toSection: .preview)
        snapshot.appendSections([.title])
        snapshot.appendItems([.title(tagTitle)], toSection: .title)
        snapshot.appendSections([.subtitle])
        snapshot.appendItems([.subtitle(subtitle)], toSection: .subtitle)
        snapshot.appendSections([.lightColor])
        snapshot.appendItems([.lightColor(lightColor)])
        snapshot.appendSections([.darkColor])
        snapshot.appendItems([.darkColor(darkColor)])
        if isEditMode() {
            snapshot.appendSections([.delete])
            snapshot.appendItems([.delete], toSection: .delete)
        }
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    func updateTagColor(lightColor: UIColor, darkColor: UIColor) {
        tagColor = UIColor(dynamicProvider: { collection in
            switch collection.userInterfaceStyle {
            case .light, .unspecified:
                return lightColor
            case .dark:
                return darkColor
            @unknown default:
                fatalError()
            }
        })
        updatePreview()
        isEdited = true
    }
    
    func updatePreview() {
        previewCell?.update(title: tagTitle, color: tagColor)
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
        let titleFlag = tagTitle.isValidTagTitle()
        return titleFlag
    }
    
    @objc
    func save() {
        if isEditMode() {
            // Modify Old
            let result = DataManager.shared.update(tag: tag)
            if result {
                dismissViewController()
            }
        } else {
            // Create New
            let result = DataManager.shared.add(tag: tag)
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
        let result = DataManager.shared.delete(tag: tag)
        if result {
            dismissViewController()
        }
    }
    
    func showDeleteAlert() {
        guard let tagID = tag.id else { return }
        guard let records = try? DataManager.shared.fetchAllDayRecords(tagID: tagID) else { return }
        
        let message = (records.count > 0) ? String(format: String(localized: "tags.detail.delete.alert.message.%i"), records.count) : String(localized: "tags.detail.delete.alert.message")
        
        let alertController = UIAlertController(title: String(localized: "tags.detail.delete.alert.title"), message: message, preferredStyle: .alert)
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
            case .preview:
                break
            case .title:
                break
            case .subtitle:
                break
            case .lightColor, .darkColor:
                break
            case .delete:
                showDeleteAlert()
            }
        }
    }
}

extension TagDetailViewController {
    func updateColor(_ newColor: UIColor, isLight: Bool) {
        if !defaultColors().map({ $0.generateLightDarkString(isLight ? .light : .dark) }).contains(newColor.generateLightDarkString(isLight ? .light : .dark)) {
            if !customColors.contains(newColor) {
                customColors.append(newColor)
            }
        }
        
        let colors = getColors()
        if isLight {
            lightColorCell?.update(colors: colors, selectedColor: newColor, isLight: true)
            darkColorCell?.update(colors: colors, selectedColor: darkColor, isLight: false)
            updateTagColor(lightColor: newColor, darkColor: darkColor)
        } else {
            lightColorCell?.update(colors: colors, selectedColor: lightColor, isLight: true)
            darkColorCell?.update(colors: colors, selectedColor: newColor, isLight: false)
            updateTagColor(lightColor: lightColor, darkColor: newColor)
        }
    }
    
    func getColors() -> [UIColor] {
        var colors: [UIColor] = []
        
        colors.append(contentsOf: customColors.reversed())
        colors.append(contentsOf: defaultColors())
        
        return colors
    }
    
    func defaultColors() -> [UIColor] {
        return [.systemPink, .systemRed, .systemOrange, .systemYellow, .systemGreen, .systemMint, .systemTeal, .systemCyan, .systemBlue, .systemIndigo, .systemPurple, .systemBrown, .white, UIColor(white: 0.9, alpha: 1.0), UIColor(white: 0.8, alpha: 1.0), UIColor(white: 0.7, alpha: 1.0), UIColor(white: 0.6, alpha: 1.0), .gray, UIColor(white: 0.4, alpha: 1.0), UIColor(white: 0.3, alpha: 1.0), UIColor(white: 0.2, alpha: 1.0), UIColor(white: 0.1, alpha: 1.0), .black]
    }
    
    func showColorPicker(isLight: Bool) {
        let colorPicker = StyleColorPickerViewController()
        colorPicker.style = isLight ? .light : .dark
        
        colorPicker.selectedColor = isLight ? self.lightColor : self.darkColor
        colorPicker.delegate = self
        present(colorPicker, animated: true)
    }
}

extension TagDetailViewController: UIColorPickerViewControllerDelegate {
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        print("Add color \(viewController.selectedColor)")
        if let viewController = viewController as? StyleColorPickerViewController {
            switch viewController.style {
            case .light:
                updateColor(viewController.selectedColor, isLight: true)
            case .dark:
                updateColor(viewController.selectedColor, isLight: false)
            }
        }
        reloadData()
    }
}

extension String {
    func isValidTagTitle() -> Bool{
        return count > 0 && count <= 60
    }
}

class StyleColorPickerViewController: UIColorPickerViewController {
    enum ColorPickerStyle {
        case light
        case dark
    }
    var style: ColorPickerStyle = .light
}
