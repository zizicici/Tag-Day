//
//  RecordDetailViewController.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/5/13.
//

import UIKit
import SnapKit

class RecordDetailViewController: UIViewController {
    private var record: DayRecord!
    
    private var tableView: UITableView!
    private var dataSource: DataSource!
    
    enum Section: Int, Hashable {
        case time
        case wallet
        case comment
        
        var header: String? {
            switch self {
            case .time:
                return nil
            case .wallet:
                return nil
            case .comment:
                return String(localized: "dayRecord.comment")
            }
        }
        
        var footer: String? {
            switch self {
            case .time:
                return nil
            case .wallet:
                return nil
            case .comment:
                return nil
            }
        }
    }
    
    enum Item: Hashable {
//        case startTime(Int64)
//        case endTime(Int64)
//        case duration(Int64)
//        case incomeAndExpenses
//        case currencyCode(String)
//        case currencyValue(Int64)
        case comment(String?)
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
    
    private var isEdited: Bool = false
    
    private var comment: String? {
        get {
            return record.comment
        }
        set {
            if record.comment != newValue {
                record.comment = newValue
                isEdited = true
                updateSaveButtonStatus()
            }
        }
    }
    
    weak var commentCell: TextViewCell?
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    convenience init(dayRecord: DayRecord) {
        self.init()
        self.record = dayRecord
    }
    
    deinit {
        print("DayRecordDetailViewController is deinited")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        tableView.register(TextViewCell.self, forCellReuseIdentifier: NSStringFromClass(TextViewCell.self))
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 50.0
        tableView.delegate = self
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(view)
        }
        tableView.contentInset = UIEdgeInsets(top: -20.0, left: 0, bottom: 0, right: 0)
    }
    
    func configureDataSource() {
        dataSource = DataSource(tableView: tableView) { [weak self] (tableView, indexPath, item) -> UITableViewCell? in
            guard let self = self else { return nil }
            guard let identifier = dataSource.itemIdentifier(for: indexPath) else { return nil }
            switch identifier {
//            case .startTime(_):
//                <#code#>
//            case .endTime(_):
//                <#code#>
//            case .duration(_):
//                <#code#>
//            case .incomeAndExpenses:
//                <#code#>
//            case .currencyCode(_):
//                <#code#>
//            case .currencyValue(_):
//                <#code#>
            case .comment(let comment):
                let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(TextViewCell.self), for: indexPath)
                if let cell = cell as? TextViewCell {
                    cell.tintColor = AppColor.main
                    cell.update(text: comment, placeholder: String(localized: "dayRecord.placeholder.comment"))
                    cell.textDidChanged = { [weak self] text in
                        self?.comment = text
                    }
                    self.commentCell = cell
                }
                return cell
            }
        }
    }
    
    func reloadData() {
        updateSaveButtonStatus()
        
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.comment])
        snapshot.appendItems([.comment(comment)], toSection: .comment)
        
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    @objc
    func save() {
        let result = DataManager.shared.update(dayRecord: record)
        if result {
            dismissViewController()
        }
    }
    
    @objc
    func dismissViewController() {
        if commentCell?.isFirstResponder == true {
            _ = commentCell?.resignFirstResponder()
            navigationItem.rightBarButtonItem?.isEnabled = false
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.7) {
                self.dismiss(animated: true)
            }
        } else {
            dismiss(animated: true)
        }
    }
    
    func updateSaveButtonStatus() {
        navigationItem.rightBarButtonItem?.isEnabled = allowSave()
    }
    
    func allowSave() -> Bool {
        let commentFlag = comment?.isValidRecordComment() ?? true
        return commentFlag
    }
}


extension RecordDetailViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension String {
    func isValidRecordComment() -> Bool{
        return count <= 200
    }
}
