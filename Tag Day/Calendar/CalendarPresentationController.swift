//
//  CalendarPresentationController.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/6/23.
//

import UIKit

var CalendarPresentationCornerRadius: CGFloat {
    get {
        if #available(iOS 26.0, *) {
            return 36.0
        } else {
            return 12.0
        }
    }
}

class CalendarPresentationController: UIPresentationController {
    private let detailSize: CGSize
    private var dimmingView: UIView!
    private var shadowView: UIView!
    
    init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?, detailSize: CGSize) {
        self.detailSize = detailSize
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        setupDimmingView()
    }
    
    private func setupDimmingView() {
        dimmingView = UIView()
        dimmingView.backgroundColor = .clear
        dimmingView.alpha = 0
        dimmingView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismiss)))
        dimmingView.isAccessibilityElement = true
        shadowView = UIView()
        shadowView.alpha = 0
        shadowView.backgroundColor = UIColor.white
        shadowView.layer.cornerRadius = CalendarPresentationCornerRadius
        shadowView.layer.shadowColor = UIColor.black.cgColor
        shadowView.layer.shadowOpacity = 0.25
        shadowView.layer.shadowOffset = .zero
        shadowView.layer.shadowRadius = 40.0
    }
    
    @objc private func dismiss() {
        presentedViewController.dismiss(animated: true)
    }
    
    override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerView = containerView else { return .zero }
        
        return CGRect(
            x: (containerView.bounds.width - detailSize.width) / 2,
            y: (containerView.bounds.height - detailSize.height) / 2,
            width: detailSize.width,
            height: detailSize.height
        )
    }
    
    override func presentationTransitionWillBegin() {
        guard let containerView = containerView else { return }
        
        dimmingView.frame = containerView.bounds
        containerView.insertSubview(dimmingView, at: 0)
        containerView.insertSubview(shadowView, aboveSubview: dimmingView)
        
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            self.dimmingView.alpha = 1
        }) { _ in
            self.shadowView.alpha = 1
        }
    }
    
    override func dismissalTransitionWillBegin() {
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            self.shadowView.alpha = 0
            self.dimmingView.alpha = 0
        })
    }
    
    override func containerViewWillLayoutSubviews() {
        presentedView?.frame = frameOfPresentedViewInContainerView
        dimmingView.frame = containerView?.bounds ?? .zero
        shadowView.frame = frameOfPresentedViewInContainerView
    }
}

class CalendarTransitionDelegate: NSObject, UIViewControllerTransitioningDelegate {
    private let originFrame: CGRect
    private let cellBackgroundColor: UIColor
    private let detailSize: CGSize
    
    init(originFrame: CGRect, cellBackgroundColor: UIColor, detailSize: CGSize = CGSize(width: 280, height: 400)) {
        self.originFrame = originFrame
        self.cellBackgroundColor = cellBackgroundColor
        self.detailSize = detailSize
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return CalendarTransitionAnimator(
            isPresenting: true,
            originFrame: originFrame,
            cellBackgroundColor: cellBackgroundColor,
            detailSize: detailSize
        )
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> (any UIViewControllerAnimatedTransitioning)? {
        return CalendarTransitionAnimator(
            isPresenting: false,
            originFrame: originFrame,
            cellBackgroundColor: cellBackgroundColor,
            detailSize: detailSize
        )
    }
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return CalendarPresentationController(
            presentedViewController: presented,
            presenting: presenting,
            detailSize: detailSize
        )
    }
}

class CalendarTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    private let isPresenting: Bool
    private let duration: TimeInterval = 0.5
    private let originFrame: CGRect
    private let cellBackgroundColor: UIColor
    private let detailSize: CGSize
    
    init(isPresenting: Bool, originFrame: CGRect, cellBackgroundColor: UIColor, detailSize: CGSize = CGSize(width: 280, height: 400)) {
        self.isPresenting = isPresenting
        self.originFrame = originFrame
        self.cellBackgroundColor = cellBackgroundColor
        self.detailSize = detailSize
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard
            let containerView = transitionContext.containerView as UIView?,
            let fromVC = transitionContext.viewController(forKey: .from),
            let toVC = transitionContext.viewController(forKey: .to)
        else {
            transitionContext.completeTransition(false)
            return
        }
        
        if isPresenting {
            let toView = toVC.view!
            toView.frame = originFrame
            
            // 计算详情视图的最终frame（居中显示）
            let finalFrame = CGRect(
                x: (containerView.bounds.width - detailSize.width) / 2,
                y: (containerView.bounds.height - detailSize.height) / 2,
                width: detailSize.width,
                height: detailSize.height
            )
            
            // 配置toView的初始状态
            toView.center = CGPoint(
                x: originFrame.midX,
                y: originFrame.midY
            )
            toView.clipsToBounds = true
            toView.layer.cornerRadius = CalendarPresentationCornerRadius
            toView.alpha = 0
            
            // 添加一个临时视图作为动画背景
            let backgroundView = UIView(frame: originFrame)
            backgroundView.backgroundColor = cellBackgroundColor
            backgroundView.layer.cornerRadius = CalendarPresentationCornerRadius
            backgroundView.layer.shadowColor = UIColor.black.cgColor
            backgroundView.layer.shadowOpacity = 0.25
            backgroundView.layer.shadowOffset = .zero
            backgroundView.layer.shadowRadius = 40.0
            containerView.addSubview(backgroundView)
            
            // 添加toView到容器
            containerView.addSubview(toView)
            
            // 执行动画
            UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: [], animations: {
                // 放大到目标尺寸
                toView.transform = .identity
                toView.frame = finalFrame
                toView.alpha = 1
                toView.layer.cornerRadius = CalendarPresentationCornerRadius
                
                // 背景视图同步动画
                backgroundView.frame = finalFrame
                backgroundView.layer.cornerRadius = CalendarPresentationCornerRadius
            }) { _ in
                // 移除临时视图
                backgroundView.removeFromSuperview()
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        } else {
            let fromView = fromVC.view!
            
            let backgroundView = UIView(frame: fromView.frame)
            backgroundView.backgroundColor = cellBackgroundColor
            backgroundView.layer.cornerRadius = CalendarPresentationCornerRadius
            containerView.insertSubview(backgroundView, belowSubview: fromView)
            
            UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: [], animations: {
                backgroundView.frame = self.originFrame
                backgroundView.layer.cornerRadius = CalendarPresentationCornerRadius
                backgroundView.alpha = 0.0
                fromView.alpha = 0.0
            }) { _ in
                backgroundView.removeFromSuperview()
                fromView.removeFromSuperview()
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        }
    }
}
