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
    func add(day: GregorianDay, tag: Tag)
    func replace(day: GregorianDay, tag: Tag, for record: DayRecord)
}

class FastEditorViewController: UIViewController {
    private var day: GregorianDay!
    private var book: Book!
    private var tags: [Tag] = []
    
    enum EditMode {
        case add
        case replace(Tag, DayRecord)
        case overwrite
        
        var tag: Tag? {
            switch self {
            case .add:
                return nil
            case .replace(let tag, _):
                return tag
            case .overwrite:
                return nil
            }
        }
        
        var dayRecord: DayRecord? {
            switch self {
            case .add:
                return nil
            case .replace(_, let record):
                return record
            case .overwrite:
                return nil
            }
        }
    }
    
    private var editMode: EditMode!
    
    enum Section: Hashable {
        case tag
    }
    
    enum Item: Hashable {
        case tag(Tag)
    }
    
    private var dataSource: UICollectionViewDiffableDataSource<Section, Item>! = nil
    private var collectionView: UICollectionView! = nil
    
    weak var delegate: FastEditorNavigator?
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    convenience init(day: GregorianDay, book: Book, editMode: EditMode) {
        self.init(nibName: nil, bundle: nil)
        
        self.day = day
        self.book = book
        self.editMode = editMode
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = AppColor.background
        
        switch editMode {
        case .add:
            self.title = String(localized: "dayDetail.new")
        case .replace:
            self.title = String(localized: "dayDetail.replace")
        case .overwrite:
            self.title = day.formatString()
        case .none:
            break
        }
        
        configureCollectionView()
        configureDataSource()
        reloadData()
        
        var items: [UIBarButtonItem] = []

        switch editMode {
        case .add:
            let newTagItem = UIBarButtonItem(title: String(localized: "tags.new"), style: .plain, target: self, action: #selector(newTagAction))
            newTagItem.tintColor = AppColor.dynamicColor
            items.append(newTagItem)
        case .replace:
            break
        case .overwrite:
            let resetItem = UIBarButtonItem(title: String(localized: "fastEditor.reset"), style: .plain, target: self, action: #selector(resetAction))
            resetItem.tintColor = .systemRed
            items.append(resetItem)
        case .none:
            break
        }
        
        items.append(.flexibleSpace())
        
        let cancelItem = UIBarButtonItem(title: String(localized: "button.cancel"), style: .done, target: self, action: #selector(dismissAction))
        cancelItem.tintColor = AppColor.dynamicColor
        items.append(cancelItem)

        toolbarItems = items
        navigationController?.setToolbarHidden(false, animated: false)
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: .TagsUpdated, object: nil)
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
                    self.tap(tag: tag)
                }
                cell.update(with: tag)
            }
        }
        
        dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView, cellProvider: { collectionView, indexPath, itemIdentifier in
            return collectionView.dequeueConfiguredReusableCell(using: tagCellRegistration, for: indexPath, item: itemIdentifier)
        })
    }
    
    @objc
    private func reloadData() {
        guard let bookID = book.id else { return }
        self.tags = ((try? DataManager.shared.fetchAllTags(bookID: bookID)) ?? []).filter({ tag in
            return tag != self.editMode.tag
        })
        
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.tag])
        snapshot.appendItems(tags.map{ .tag($0) }, toSection: .tag)

        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    @objc
    func dismissAction() {
        self.dismiss(animated: true)
    }
    
    @objc
    func resetAction() {
        delegate?.reset(day: day, tag: nil)
    }
    
    @objc
    func newTagAction() {
        guard let bookID = DataManager.shared.currentBook?.id else {
            return
        }
        var tagIndex = 0
        if let lastestTag = DataManager.shared.tags.last {
            tagIndex = lastestTag.order + 1
        }
        let newTag = Tag(bookID: bookID, title: "", subtitle: "", color: "", order: tagIndex)
        let nav = NavigationController(rootViewController: TagDetailViewController(tag: newTag))
        
        present(nav, animated: true)
    }
    
    func tap(tag: Tag) {
        switch editMode {
        case .add:
            delegate?.add(day: day, tag: tag)
        case .overwrite:
            delegate?.reset(day: day, tag: tag)
        case .replace:
            guard let record = editMode.dayRecord else { return }
            delegate?.replace(day: day, tag: tag, for: record)
        case .none:
            break
        }
    }
}

extension FastEditorViewController {
    func createLayout() -> UICollectionViewLayout {
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.scrollDirection = .vertical
        let layout = UICollectionViewCompositionalLayout(sectionProvider: { index, environment in
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                 heightDimension: .estimated(44))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                  heightDimension: .estimated(44))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize,
                                                             subitems: [item])

            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = 10.0
            section.contentInsets = NSDirectionalEdgeInsets(top: 8.0, leading: 20.0, bottom: 8.0, trailing: 20.0)
            
            return section

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
        case nil:
            break
        }
    }
}

fileprivate extension UIConfigurationStateCustomKey {
    static let fastEditorItem = UIConfigurationStateCustomKey("com.zizicici.tag.fastEditor.cell.item")
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
            outgoing.font = UIFont.preferredSystemFont(for: .body, weight: .medium)
            
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
            make.height.equalTo(44.0)
        }
        
        tagButton.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
    }
    
    override func updateConfiguration(using state: UICellConfigurationState) {
        super.updateConfiguration(using: state)
        setupViewsIfNeeded()
        
        if let tag = state.fastEditorItem {
            let title = tag.title
            let tagColor = tag.dynamicColor
            let tagTitleColor = tag.dynamicTitleColor
            tagButton.configurationUpdateHandler = { button in
                var config = button.configuration
                
                config?.title = title
                config?.baseForegroundColor = tagTitleColor
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
