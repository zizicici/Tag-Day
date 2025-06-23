//
//  ColorPickerCell.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/5/7.
//

import UIKit
import SnapKit

class ColorPickerCell: UITableViewCell {
    var dataSource: UICollectionViewDiffableDataSource<Int, ColorBlockCell.Item>! = nil
    var collectionView: UICollectionView! = nil
    
    var selectedColorDidChange: ((UIColor) -> ())?
    var showPicker: (() -> ())?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        configureCollectionView()
        configureDataSource()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureCollectionView() {
        collectionView = UIDraggableCollectionView(frame: CGRect.zero, collectionViewLayout: createLayout())
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.delegate = self
        collectionView.backgroundColor = .clear
        contentView.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.leading.trailing.equalTo(contentView)
            make.top.bottom.equalTo(contentView).inset(5)
            make.height.greaterThanOrEqualTo(80.0)
        }
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
    
    public func update(colors: [UIColor], selectedColor: UIColor, isLight: Bool) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, ColorBlockCell.Item>()
        snapshot.appendSections([0])
        snapshot.appendItems([ColorBlockCell.Item(color: .white, type: .pickerItem)])
        snapshot.appendItems(colors.enumerated().map({ (index, color) in
            return ColorBlockCell.Item(color: color, type: color.generateLightDarkString(isLight ? .light : .dark) == selectedColor.generateLightDarkString(isLight ? .light : .dark) ? .colorSelected : .colorUnselected)
        }))
        dataSource.apply(snapshot, animatingDifferences: true)
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
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(0.5))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            let groupSize = NSCollectionLayoutSize(widthDimension: .absolute(40.0), heightDimension: .absolute(80.0))
            let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
            
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10)
            
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
        var color: UIColor
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
        self.color = item.color
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
        let lightColor = color.resolvedColor(with: .init(userInterfaceStyle: .light))
        let darkColor = color.resolvedColor(with: .init(userInterfaceStyle: .dark))
        colorButton.setBackgroundImage(drawSquareWithDiagonal(size: 40, color1: lightColor, color2: darkColor), for: .normal)
        colorButton.layer.borderWidth = 1.0
        colorButton.layer.borderColor = UIColor.systemGray.withAlphaComponent(0.5).cgColor
        infoMark.isHidden = !showInfoMark
        if lightColor.isLight {
            infoMark.tintColor = UIColor.gray
        } else {
            infoMark.tintColor = UIColor.white
        }
    }
    
    func drawSquareWithDiagonal(size: CGFloat, color1: UIColor, color2: UIColor) -> UIImage? {
        // 创建图像上下文并设置缩放比例
        UIGraphicsBeginImageContextWithOptions(CGSize(width: size, height: size), false, 0)
        
        // 获取当前图形上下文
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        // 绘制矩形并填充颜色
        context.addRect(CGRect(origin: .zero, size: CGSize(width: size, height: size)))
        context.setFillColor(color1.cgColor)
        context.fillPath()
        
        // 绘制三角形并填充另一个颜色
        let trianglePath = UIBezierPath()
        trianglePath.move(to: CGPoint(x: size, y: 0))
        trianglePath.addLine(to: CGPoint(x: size, y: size))
        trianglePath.addLine(to: CGPoint(x: 0, y: size))
        trianglePath.close()
        context.addPath(trianglePath.cgPath)
        context.setFillColor(color2.cgColor)
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
