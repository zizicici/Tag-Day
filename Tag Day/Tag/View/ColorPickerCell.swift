//
//  ColorPickerCell.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/5/7.
//

import UIKit
import SnapKit

struct ColorPickerItem: Hashable {
    var title: String
}

extension UIConfigurationStateCustomKey {
    static let colorPickerItem = UIConfigurationStateCustomKey("com.zizicici.tag.cell.colorPicker.item")
}

extension UICellConfigurationState {
    var colorPickerItem: ColorPickerItem? {
        set { self[.colorPickerItem] = newValue }
        get { return self[.colorPickerItem] as? ColorPickerItem }
    }
}

class ColorPickerBaseCell: UITableViewCell {
    private var colorPickerItem: ColorPickerItem? = nil
    
    func update(with newColorPickerItem: ColorPickerItem) {
        guard colorPickerItem != newColorPickerItem else { return }
        colorPickerItem = newColorPickerItem
        setNeedsUpdateConfiguration()
    }
    
    override var configurationState: UICellConfigurationState {
        var state = super.configurationState
        state.colorPickerItem = self.colorPickerItem
        return state
    }
}

class ColorPickerCell: ColorPickerBaseCell {
    private func defaultListContentConfiguration() -> UIListContentConfiguration { return .valueCell() }
    private lazy var listContentView = UIListContentView(configuration: defaultListContentConfiguration())
    
    var dataSource: UICollectionViewDiffableDataSource<Int, ColorBlockCell.Item>! = nil
    var collectionView: UICollectionView! = nil
    
    var selectedColorDidChange: ((String) -> ())?
    var showPicker: (() -> ())?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        collectionView = UIDraggableCollectionView(frame: CGRect.zero, collectionViewLayout: createLayout())
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.delegate = self
        collectionView.backgroundColor = .clear

        configureDataSource()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViewsIfNeeded() {
        guard listContentView.superview == nil else {
            return
        }
        
        contentView.addSubview(listContentView)
        listContentView.snp.makeConstraints { make in
            make.edges.equalTo(contentView)
        }

        contentView.addSubview(collectionView)
    }
    
    private func configureDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<ColorBlockCell, ColorBlockCell.Item> { [weak self] (cell, indexPath, itemIdentifier) in
            guard let self = self else { return }
            cell.update(with: itemIdentifier)
            cell.tapClosure = { [weak self] in
                self?.tap(at: itemIdentifier)
            }
        }
        
        dataSource = UICollectionViewDiffableDataSource<Int, ColorBlockCell.Item>(collectionView: collectionView, cellProvider: { collectionView, indexPath, itemIdentifier in
            let cell = collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: itemIdentifier)
            
            return cell
        })
    }
    
    override func updateConfiguration(using state: UICellConfigurationState) {
        setupViewsIfNeeded()
        var content = defaultListContentConfiguration().updated(for: state)
        if let colorPickerItem = state.colorPickerItem {
            content.text = colorPickerItem.title
            listContentView.configuration = content
            
            if let textLayoutGuide = listContentView.textLayoutGuide {
                collectionView.snp.remakeConstraints { make in
                    make.leading.equalTo(textLayoutGuide.snp.trailing).offset(20.0)
                    make.trailing.equalTo(contentView)
                    make.centerY.equalTo(contentView)
                    make.height.equalTo(44.0)
                }
            }
        }
    }
    
    public func update(colors: [String], selectedColor: String) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, ColorBlockCell.Item>()
        snapshot.appendSections([0])
        snapshot.appendItems([ColorBlockCell.Item(color: UIColor.white.toHexString()!, type: .pickerItem)])
        snapshot.appendItems(colors.enumerated().map({ (index, color) in
            let displayColor = color
            return ColorBlockCell.Item(color: displayColor, type: color == selectedColor ? .colorSelected : .colorUnselected)
        }))
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    private func tap(at item: ColorBlockCell.Item) {
        switch item.type {
        case .colorSelected, .colorUnselected:
            selectedColorDidChange?(item.color)
        case .pickerItem:
            showPicker?()
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        selectedColorDidChange = nil
        showPicker = nil
    }
}

extension ColorPickerCell {
    func createLayout() -> UICollectionViewLayout {
        let sectionProvider = {(sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            let groupSize = NSCollectionLayoutSize(widthDimension: .absolute(40.0), heightDimension: .absolute(40.0))
            let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
            
            let section = NSCollectionLayoutSection(group: group)
            let inset: CGFloat = 2.0
            section.contentInsets = NSDirectionalEdgeInsets(top: inset, leading: 15, bottom: inset, trailing: 15)
            
            return section
        }

        let configuration = UICollectionViewCompositionalLayoutConfiguration()
        configuration.scrollDirection = .horizontal
        
        let layout = UICollectionViewCompositionalLayout(sectionProvider: sectionProvider, configuration: configuration)
        
        return layout
    }
}

extension ColorPickerCell: UICollectionViewDelegate {
    
}

class ColorBlockCell: UICollectionViewCell {
    struct Item: Hashable {
        enum ItemType {
            case colorSelected
            case colorUnselected
            case pickerItem
        }
        var color: String
        var type: ItemType
    }
    
    var colorButton: UIButton = {
        let button = UIButton(type: .custom)
        button.layer.cornerRadius = 10.0
        button.layer.cornerCurve = .continuous
        button.clipsToBounds = true
        
        return button
    }()
    
    var infoMark: UIImageView = {
        let mark = UIImageView()
        mark.image = UIImage(systemName: "checkmark")
        mark.tintColor = UIColor.white
        mark.isUserInteractionEnabled = false
        
        return mark
    }()
    
    var color: UIColor?
    
    var showInfoMark: Bool = true
    
    var tapClosure: (() -> ())?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.addSubview(colorButton)
        colorButton.snp.makeConstraints { make in
            make.width.height.equalTo(30)
            make.centerX.centerY.equalTo(contentView)
        }
        
        colorButton.addSubview(infoMark)
        infoMark.snp.makeConstraints { make in
            make.width.height.equalTo(20)
            make.centerX.centerY.equalTo(contentView)
        }
        
        colorButton.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { [weak self] (cell: Self, previousTraitCollection: UITraitCollection) in
            if cell.traitCollection.userInterfaceStyle != previousTraitCollection.userInterfaceStyle {
                self?.update()
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(with item: Item) {
        self.color = UIColor(hex: item.color)
        switch item.type {
        case .colorSelected:
            showInfoMark = true
            infoMark.image = UIImage(systemName: "checkmark")
        case .colorUnselected:
            showInfoMark = false
        case .pickerItem:
            showInfoMark = true
            infoMark.image = UIImage(systemName: "plus")
        }
        update()
    }
    
    func update() {
        guard let color = color else { return }
        colorButton.setBackgroundImage(drawSquareWithDiagonal(size: 40, color: color), for: .normal)
        colorButton.layer.borderWidth = 1.0
        colorButton.layer.borderColor = UIColor.systemGray.withAlphaComponent(0.5).cgColor
        infoMark.isHidden = !showInfoMark
        if color.isLight {
            infoMark.tintColor = UIColor.gray
        } else {
            infoMark.tintColor = UIColor.white
        }
    }
    
    func drawSquareWithDiagonal(size: CGFloat, color: UIColor) -> UIImage? {
        // 创建图像上下文并设置缩放比例
        UIGraphicsBeginImageContextWithOptions(CGSize(width: size, height: size), false, 0)
        
        // 获取当前图形上下文
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        // 绘制矩形并填充颜色
        context.addRect(CGRect(origin: .zero, size: CGSize(width: size, height: size)))
        context.setFillColor(color.cgColor)
        context.fillPath()
        
        // 获取图像并结束上下文
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    @objc
    func buttonAction() {
        tapClosure?()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        tapClosure = nil
    }
}
