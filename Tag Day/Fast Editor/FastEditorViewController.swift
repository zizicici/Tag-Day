//
//  FastEditorViewController.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/5/10.
//

import UIKit
import SnapKit
import ZCCalendar

protocol FastEditorNavigator: NSObjectProtocol {
    func reset(day: GregorianDay, tag: Tag?)
}

class FastEditorViewController: UIViewController {
    var day: GregorianDay!
    var book: Book!
    var tags: [Tag] = []
    var records: [DayRecord] = []
    
    enum Section: Hashable {
        case tag
        case delete
        case cancel
    }
    
    enum Item: Hashable {
        case tag(Tag)
        case delete
        case cancel
    }
    
    var dataSource: UICollectionViewDiffableDataSource<Section, Item>! = nil
    var collectionView: UICollectionView! = nil
    
    weak var delegate: FastEditorNavigator?
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    convenience init(day: GregorianDay, book: Book) {
        self.init(nibName: nil, bundle: nil)
        
        self.day = day
        self.book = book
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = AppColor.background
        
        self.title = day.formatString()
        
        configureCollectionView()
        configureDataSource()
        reloadData()
    }
    
    private func configureCollectionView() {
        collectionView = UIDraggableCollectionView(frame: CGRect.zero, collectionViewLayout: createLayout())
        collectionView.backgroundColor = AppColor.background
        collectionView.delegate = self
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalTo(view)
        }
    }
    
    private func configureDataSource() {
        let tagCellRegistration = UICollectionView.CellRegistration<FastEditorTagCell, Item> { [weak self] (cell, indexPath, item) in
            guard let self = self else { return }
            switch item {
            case .tag(let tag):
                cell.didSelectClosure = {
                    self.delegate?.reset(day: self.day, tag: tag)
                }
                cell.update(with: tag)
            default:
                return
            }
        }
        
        let actionCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Item> { (cell, indexPath, item) in
            switch item {
            case .tag:
                return
            case .cancel:
                var content = UIListContentConfiguration.valueCell()
                content.text = String(localized: "button.cancel")
                content.textProperties.alignment = .center
                content.textProperties.color = AppColor.main
                cell.contentConfiguration = content
                cell.backgroundConfiguration?.cornerRadius = 10.0
            case .delete:
                var content = UIListContentConfiguration.valueCell()
                content.text = String(localized: "fastEditor.reset")
                content.textProperties.alignment = .center
                content.textProperties.color = UIColor.systemRed
                cell.contentConfiguration = content
                cell.backgroundConfiguration?.cornerRadius = 10.0
            }
        }
        
        dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView, cellProvider: { collectionView, indexPath, itemIdentifier in
            switch itemIdentifier {
            case .tag:
                return collectionView.dequeueConfiguredReusableCell(using: tagCellRegistration, for: indexPath, item: itemIdentifier)
            case .cancel, .delete:
                return collectionView.dequeueConfiguredReusableCell(using: actionCellRegistration, for: indexPath, item: itemIdentifier)
            }
        })
    }
    
    @objc
    private func reloadData() {
        guard let bookID = book.id else { return }
        self.tags = (try? DataManager.shared.fetchAllTags(bookID: bookID)) ?? []
        self.records = (try? DataManager.shared.fetchAllDayRecords(bookID: bookID, day: Int64(self.day.julianDay))) ?? []
        
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.tag])
        snapshot.appendItems(tags.map{ .tag($0) }, toSection: .tag)
        snapshot.appendSections([.delete])
        snapshot.appendItems([.delete], toSection: .delete)
        snapshot.appendSections([.cancel])
        snapshot.appendItems([.cancel], toSection: .cancel)

        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    func dismissAction() {
        self.dismiss(animated: true)
    }
    
    func resetAction() {
        delegate?.reset(day: day, tag: nil)
    }
}

extension FastEditorViewController {
    func createLayout() -> UICollectionViewLayout {
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.scrollDirection = .vertical
        let layout = UICollectionViewCompositionalLayout(sectionProvider: { [weak self] index, environment in
            guard let self = self else { return nil }
            let sectionType = self.dataSource.sectionIdentifier(for: index)
            switch sectionType {
            case .tag:
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                     heightDimension: .estimated(40))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)

                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                      heightDimension: .estimated(40))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize,
                                                                 subitems: [item])

                let section = NSCollectionLayoutSection(group: group)
                section.interGroupSpacing = 10.0
                section.contentInsets = NSDirectionalEdgeInsets(top: 8.0, leading: 10.0, bottom: 8.0, trailing: 10.0)
                
                return section
            case .delete, .cancel:
                var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
                configuration.separatorConfiguration = UIListSeparatorConfiguration(listAppearance: .insetGrouped)
                configuration.backgroundColor = AppColor.background
                configuration.headerTopPadding = 0.0
                let section = NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: environment)
                section.contentInsets = NSDirectionalEdgeInsets(top: 8.0, leading: 10.0, bottom: 8.0, trailing: 10.0)
                return section
            case nil:
                return nil
            }

        }, configuration: config)
        
        return layout
    }
}

extension FastEditorViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        let item = dataSource.itemIdentifier(for: indexPath)
        switch item {
        case .tag:
            break
        case .delete:
            resetAction()
        case .cancel:
            dismissAction()
        case nil:
            break
        }
    }
}

fileprivate extension UIConfigurationStateCustomKey {
    static let fastEditorItem = UIConfigurationStateCustomKey("com.zizicici.tagday.fastEditor.cell.item")
}

private extension UICellConfigurationState {
    var fastEditorItem: Tag? {
        set { self[.fastEditorItem] = newValue }
        get { return self[.fastEditorItem] as? Tag }
    }
}

class FastEditorBaseCell: UICollectionViewCell {
    private var fastEditorItem: Tag? = nil
    
    func update(with newTag: Tag) {
        guard fastEditorItem != newTag else { return }
        fastEditorItem = newTag
        setNeedsUpdateConfiguration()
    }
    
    override var configurationState: UICellConfigurationState {
        var state = super.configurationState
        state.fastEditorItem = self.fastEditorItem
        return state
    }
}

class FastEditorTagCell: FastEditorBaseCell {
    public var didSelectClosure: (() -> ())?

    private var tagButton: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.titleAlignment = .leading
        configuration.cornerStyle = .fixed
        configuration.background.cornerRadius = 10.0
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer({ incoming in
            var outgoing = incoming
            outgoing.font = UIFont.preferredMonospacedFont(for: .body, weight: .medium)
            
            return outgoing
        })
        configuration.titleLineBreakMode = .byTruncatingTail
        configuration.subtitleLineBreakMode = .byTruncatingTail

        let button = UIButton(configuration: configuration)
        return button
    }()
    
    private func setupViewsIfNeeded() {
        guard tagButton.superview == nil else { return }
        
        contentView.addSubview(tagButton)
        tagButton.snp.makeConstraints { make in
            make.top.leading.equalTo(contentView)
            make.trailing.equalTo(contentView)
            make.bottom.equalTo(contentView)
            make.height.greaterThanOrEqualTo(44.0)
        }
        
        tagButton.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
    }
    
    override func updateConfiguration(using state: UICellConfigurationState) {
        super.updateConfiguration(using: state)
        setupViewsIfNeeded()
        
        if let tag = state.fastEditorItem {
            let title = tag.title
            let tagColor = UIColor(string: tag.color)
            tagButton.configurationUpdateHandler = { button in
                var config = button.configuration
                
                config?.title = title
                config?.baseForegroundColor = tagColor?.isLight == true ? .black.withAlphaComponent(0.8) : .white.withAlphaComponent(0.95)
                button.configuration = config
            }
            tagButton.tintColor = tagColor
        }
    }
    
    @objc
    func buttonAction() {
        didSelectClosure?()
    }
}
