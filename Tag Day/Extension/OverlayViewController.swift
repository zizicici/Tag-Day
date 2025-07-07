//
//  OverlayViewController.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/7/7.
//

import UIKit

class OverlayViewController: UIViewController {
    let activityIndicator = UIActivityIndicatorView(style: .large)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 设置背景颜色和透明度
        view.backgroundColor = UIColor.black.withAlphaComponent(0.25)
        
        // 添加指示器到视图并居中
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        // 开始旋转
        activityIndicator.startAnimating()
    }
}

extension UIViewController {
    func showOverlayViewController() {
        let overlayVC = OverlayViewController()
        
        // 让当前视图控制器的内容可见但不可交互
        overlayVC.modalPresentationStyle = .overCurrentContext
        overlayVC.modalTransitionStyle = .crossDissolve
        
        // 显示覆盖全屏的遮罩层
        navigationController?.present(overlayVC, animated: ConsideringUser.animated, completion: nil)
    }
    
    func hideOverlayViewController() {
        // 隐藏覆盖全屏的遮罩层
        navigationController?.dismiss(animated: ConsideringUser.animated, completion: nil)
    }
}
