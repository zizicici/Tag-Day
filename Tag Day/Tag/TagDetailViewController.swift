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
                updateSaveButtonStatus()
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
                updateSaveButtonStatus()
            }
        }
    }
    
    private var tagColor: UIColor {
        get {
            tag.dynamicColor
        }
        set {
            tag.color = newValue.generateLightDarkString()
        }
    }
    
    private var titleColor: UIColor {
        get {
            tag.dynamicTitleColor
        }
        set {
            tag.titleColor = newValue.generateLightDarkString()
        }
    }
    
    private var tagLightColor: UIColor {
        get {
            return tagColor.resolvedColor(with: .init(userInterfaceStyle: .light))
        }
        set {
            updateTagColor(lightColor: newValue, darkColor: tagDarkColor)
        }
    }
    
    private var tagDarkColor: UIColor {
        get {
            return tagColor.resolvedColor(with: .init(userInterfaceStyle: .dark))
        }
        set {
            updateTagColor(lightColor: tagLightColor, darkColor: newValue)
        }
    }
    
    private var titleLightColor: UIColor {
        get {
            return titleColor.resolvedColor(with: .init(userInterfaceStyle: .light))
        }
        set {
            updateTitleColor(lightColor: newValue, darkColor: titleDarkColor)
        }
    }
    
    private var titleDarkColor: UIColor {
        get {
            return titleColor.resolvedColor(with: .init(userInterfaceStyle: .dark))
        }
        set {
            updateTitleColor(lightColor: titleLightColor, darkColor: newValue)
        }
    }
    
    private var customTagColors: [UIColor] = []
    private var customTitleColors: [UIColor] = []
    private var isEdited: Bool = false
    private weak var titleCell: TextInputCell?
    private weak var previewCell: TagPreviewCell?
    private weak var tagLightColorCell: ColorPickerCell?
    private weak var tagDarkColorCell: ColorPickerCell?
    private weak var titleLightColorCell: ColorPickerCell?
    private weak var titleDarkColorCell: ColorPickerCell?
    
    enum Section: Int, Hashable {
        case preview
        case title
        case subtitle
        case tagLightColor
        case tagDarkColor
        case titleLightColor
        case titleDarkColor
        case delete
        
        var header: String? {
            switch self {
            case .preview:
                return nil
            case .title:
                return String(localized: "tags.detail.title")
            case .subtitle:
                return String(localized: "tags.detail.subtitle")
            case .tagLightColor:
                return String(localized: "tags.detail.color.light")
            case .tagDarkColor:
                return String(localized: "tags.detail.color.dark")
            case .titleLightColor:
                return String(localized: "tags.detail.color.text.light")
            case .titleDarkColor:
                return String(localized: "tags.detail.color.text.dark")
            case .delete:
                return nil
            }
        }
        
        var footer: String? {
            switch self {
            case .preview:
                return nil
            case .title:
                return nil
            case .subtitle:
                return nil
            case .tagLightColor:
                return nil
            case .tagDarkColor:
                return nil
            case .titleLightColor:
                return nil
            case .titleDarkColor:
                return nil
            case .delete:
                return nil
            }
        }
    }
    
    enum Item: Hashable {
        case preview(String, UIColor, UIColor)
        case title(String)
        case subtitle(String?)
        case tagLightColor(UIColor)
        case tagDarkColor(UIColor)
        case titleLightColor(UIColor)
        case titleDarkColor(UIColor)
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
            let sectionKind = sectionIdentifier(for: section)
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
        
        if !defaultColors().map({ $0.generateLightDarkString() }).contains(tag.dynamicColor.generateLightDarkString()) {
            customTagColors = [tag.dynamicColor]
        }
        if !defaultColors().map({ $0.generateLightDarkString() }).contains(tag.dynamicTitleColor.generateLightDarkString()) {
            customTitleColors = [tag.dynamicTitleColor]
        }
        
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
            case .preview(let title, let color, let titleColor):
                let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(TagPreviewCell.self), for: indexPath)
                if let cell = cell as? TagPreviewCell {
                    self.previewCell = cell
                    cell.update(title: title, color: color, titleColor: titleColor)
                }
                return cell
            case .title(let title):
                let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(TextInputCell.self), for: indexPath)
                if let cell = cell as? TextInputCell {
                    self.titleCell = cell
                    cell.update(text: title, placeholder: String(localized: "tags.detail.title.hint"))
                    cell.textDidChanged = { [weak self] text in
                        self?.tagTitle = text
                    }
                    cell.tintColor = AppColor.main
                }
                return cell
            case .subtitle(let subtitle):
                let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(TextInputCell.self), for: indexPath)
                if let cell = cell as? TextInputCell {
                    cell.update(text: subtitle, placeholder: String(localized: "tags.detail.title.hint"))
                    cell.textDidChanged = { [weak self] text in
                        self?.subtitle = text
                    }
                    cell.tintColor = AppColor.main
                }
                return cell
            case .tagLightColor(let color):
                let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(ColorPickerCell.self), for: indexPath)
                if let cell = cell as? ColorPickerCell {
                    self.tagLightColorCell = cell
                    let colors: [UIColor] = self.getTagColors()
                    cell.update(colors: colors, selectedColor: color, isLight: true)
                    cell.selectedColorDidChange = { [weak self] newColor in
                        self?.updateTagColor(newColor, isLight: true)
                    }
                    cell.showPicker = { [weak self] in
                        self?.showTagColorPicker(isLight: true)
                    }
                }
                return cell
            case .tagDarkColor(let color):
                let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(ColorPickerCell.self), for: indexPath)
                if let cell = cell as? ColorPickerCell {
                    self.tagDarkColorCell = cell
                    let colors: [UIColor] = self.getTagColors()
                    cell.update(colors: colors, selectedColor: color, isLight: false)
                    cell.selectedColorDidChange = { [weak self] newColor in
                        self?.updateTagColor(newColor, isLight: false)
                    }
                    cell.showPicker = { [weak self] in
                        self?.showTagColorPicker(isLight: false)
                    }
                }
                return cell
            case .titleLightColor(let color):
                let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(ColorPickerCell.self), for: indexPath)
                if let cell = cell as? ColorPickerCell {
                    self.titleLightColorCell = cell
                    let colors: [UIColor] = self.getTitleColors()
                    cell.update(colors: colors, selectedColor: color, isLight: true)
                    cell.selectedColorDidChange = { [weak self] newColor in
                        self?.updateTitleColor(newColor, isLight: true)
                    }
                    cell.showPicker = { [weak self] in
                        self?.showTitleColorPicker(isLight: true)
                    }
                }
                return cell
            case .titleDarkColor(let color):
                let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(ColorPickerCell.self), for: indexPath)
                if let cell = cell as? ColorPickerCell {
                    self.titleDarkColorCell = cell
                    let colors: [UIColor] = self.getTitleColors()
                    cell.update(colors: colors, selectedColor: color, isLight: false)
                    cell.selectedColorDidChange = { [weak self] newColor in
                        self?.updateTitleColor(newColor, isLight: false)
                    }
                    cell.showPicker = { [weak self] in
                        self?.showTitleColorPicker(isLight: false)
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
        updateSaveButtonStatus()
        
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.preview])
        snapshot.appendItems([.preview(tagTitle, tagColor, titleColor)], toSection: .preview)
        snapshot.appendSections([.title])
        snapshot.appendItems([.title(tagTitle)], toSection: .title)
        snapshot.appendSections([.subtitle])
        snapshot.appendItems([.subtitle(subtitle)], toSection: .subtitle)
        snapshot.appendSections([.tagLightColor])
        snapshot.appendItems([.tagLightColor(tagLightColor)])
        snapshot.appendSections([.tagDarkColor])
        snapshot.appendItems([.tagDarkColor(tagDarkColor)])
        snapshot.appendSections([.titleLightColor])
        snapshot.appendItems([.titleLightColor(titleLightColor)])
        snapshot.appendSections([.titleDarkColor])
        snapshot.appendItems([.titleDarkColor(titleDarkColor)])
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
    
    func updateTitleColor(lightColor: UIColor, darkColor: UIColor) {
        titleColor = UIColor(dynamicProvider: { collection in
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
        previewCell?.update(title: tagTitle, color: tagColor, titleColor: titleColor)
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
    
    func updateSaveButtonStatus() {
        navigationItem.rightBarButtonItem?.isEnabled = allowSave()
    }
    
    func allowSave() -> Bool {
        let titleFlag = tagTitle.isValidTagTitle()
        let subtitleFlag = subtitle?.isValidTagSubtitle() ?? true
        return titleFlag && subtitleFlag
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
            case .tagLightColor, .tagDarkColor:
                break
            case .titleLightColor, .titleDarkColor:
                break
            case .delete:
                showDeleteAlert()
            }
        }
    }
}

extension TagDetailViewController {
    func updateTagColor(_ newColor: UIColor, isLight: Bool) {
        if !defaultColors().map({ $0.generateLightDarkString(isLight ? .light : .dark) }).contains(newColor.generateLightDarkString(isLight ? .light : .dark)) {
            if !customTagColors.map({ $0.generateLightDarkString(isLight ? .light : .dark) }).contains(newColor.generateLightDarkString(isLight ? .light : .dark)) {
                customTagColors.append(newColor)
            }
        }
        
        let colors = getTagColors()
        if isLight {
            tagLightColorCell?.update(colors: colors, selectedColor: newColor, isLight: true)
            tagDarkColorCell?.update(colors: colors, selectedColor: tagDarkColor, isLight: false)
            updateTagColor(lightColor: newColor, darkColor: tagDarkColor)
        } else {
            tagLightColorCell?.update(colors: colors, selectedColor: tagLightColor, isLight: true)
            tagDarkColorCell?.update(colors: colors, selectedColor: newColor, isLight: false)
            updateTagColor(lightColor: tagLightColor, darkColor: newColor)
        }
    }
    
    func updateTitleColor(_ newColor: UIColor, isLight: Bool) {
        if !defaultColors().map({ $0.generateLightDarkString(isLight ? .light : .dark) }).contains(newColor.generateLightDarkString(isLight ? .light : .dark)) {
            if !customTitleColors.map({ $0.generateLightDarkString(isLight ? .light : .dark) }).contains(newColor.generateLightDarkString(isLight ? .light : .dark)) {
                customTitleColors.append(newColor)
            }
        }
        
        let colors = getTitleColors()
        if isLight {
            titleLightColorCell?.update(colors: colors, selectedColor: newColor, isLight: true)
            titleDarkColorCell?.update(colors: colors, selectedColor: titleDarkColor, isLight: false)
            updateTitleColor(lightColor: newColor, darkColor: titleDarkColor)
        } else {
            titleLightColorCell?.update(colors: colors, selectedColor: titleLightColor, isLight: true)
            titleDarkColorCell?.update(colors: colors, selectedColor: newColor, isLight: false)
            updateTitleColor(lightColor: titleLightColor, darkColor: newColor)
        }
    }
    
    func getTagColors() -> [UIColor] {
        var colors: [UIColor] = []
        
        colors.append(contentsOf: customTagColors.reversed())
        colors.append(contentsOf: defaultColors())
        
        return colors
    }
    
    func getTitleColors() -> [UIColor] {
        var colors: [UIColor] = []
        
        colors.append(contentsOf: customTitleColors.reversed())
        colors.append(contentsOf: defaultColors())
        
        return colors
    }
    
    func defaultColors() -> [UIColor] {
        return [.systemPink, .systemRed, .systemOrange, .systemYellow, .systemGreen, .systemMint, .systemTeal, .systemCyan, .systemBlue, .systemIndigo, .systemPurple, .systemBrown, .white, UIColor(white: 0.9, alpha: 1.0), UIColor(white: 0.8, alpha: 1.0), UIColor(white: 0.7, alpha: 1.0), UIColor(white: 0.6, alpha: 1.0), .gray, UIColor(white: 0.4, alpha: 1.0), UIColor(white: 0.3, alpha: 1.0), UIColor(white: 0.2, alpha: 1.0), UIColor(white: 0.1, alpha: 1.0), .black]
    }
    
    func showTagColorPicker(isLight: Bool) {
        let colorPicker = StyleColorPickerViewController()
        colorPicker.style = isLight ? .tag(.light) : .tag(.dark)
        
        colorPicker.selectedColor = isLight ? self.tagLightColor : self.tagDarkColor
        colorPicker.delegate = self
        present(colorPicker, animated: true)
    }
    
    func showTitleColorPicker(isLight: Bool) {
        let colorPicker = StyleColorPickerViewController()
        colorPicker.style = isLight ? .title(.light) : .title(.dark)
        
        colorPicker.selectedColor = isLight ? self.titleLightColor : self.titleDarkColor
        colorPicker.delegate = self
        present(colorPicker, animated: true)
    }
}

extension TagDetailViewController: UIColorPickerViewControllerDelegate {
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        print("Add color \(viewController.selectedColor)")
        if let viewController = viewController as? StyleColorPickerViewController {
            switch viewController.style {
            case .tag(let colorType):
                switch colorType {
                case .light:
                    updateTagColor(viewController.selectedColor, isLight: true)
                case .dark:
                    updateTagColor(viewController.selectedColor, isLight: false)
                }
            case .title(let colorType):
                switch colorType {
                case .light:
                    updateTitleColor(viewController.selectedColor, isLight: true)
                case .dark:
                    updateTitleColor(viewController.selectedColor, isLight: true)
                }
            }
        }
        reloadData()
    }
}

extension String {
    func isValidTagTitle() -> Bool{
        return count > 0 && count <= 60
    }
    
    func isValidTagSubtitle() -> Bool{
        return count <= 60
    }
}

class StyleColorPickerViewController: UIColorPickerViewController {
    enum ColorPickerStyle {
        enum ColorType {
            case light
            case dark
        }
        
        case tag(ColorType)
        case title(ColorType)
    }
    var style: ColorPickerStyle = .tag(.light)
}
