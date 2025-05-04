//
//  CalendarYearPickerViewController.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/5/4.
//

import Foundation
import SnapKit
import UIKit

class CalendarYearPickerViewController: UIViewController {
    static let maxYear: Int = 2200
    static let minYear: Int = 1800
    
    private var didSelectClosure: ((Int) -> ())?
    private var currentYear: Int = 2000
    
    private var picker: UIPickerView = {
        let picker = UIPickerView()
        
        return picker
    }()
    
    convenience init(currentYear: Int, didSelectClosure: ((Int) -> ())?) {
        self.init()
        self.currentYear = currentYear
        self.didSelectClosure = didSelectClosure
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(picker)
        picker.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        picker.delegate = self
        picker.dataSource = self
        picker.selectRow(currentYear - Self.minYear, inComponent: 0, animated: false)
    }
}

extension CalendarYearPickerViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        didSelectClosure?(row + Self.minYear)
    }
}

extension CalendarYearPickerViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return Self.maxYear - Self.minYear + 1
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let text = String(format: String(localized: "calendar.title.year%i"), Self.minYear + row)
        return text
    }
}
