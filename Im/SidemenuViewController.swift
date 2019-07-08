//
//  SideMenuViewController.swift
//  Im
//
//  Created by nobumitsu on 2019/06/03.
//  Copyright © 2019 im. All rights reserved.
//

import UIKit
import Firebase

protocol SidemenuViewControllerDelegate: class {
    func parentViewControllerForSidemenuViewController(_ sidemenuViewController: SidemenuViewController) -> UIViewController
    func shouldPresentForSidemenuViewController(_ sidemenuViewController: SidemenuViewController) -> Bool
    func sidemenuViewControllerDidRequestShowing(_ sidemenuViewController: SidemenuViewController, contentAvailability: Bool, animated: Bool)
    func sidemenuViewControllerDidRequestHiding(_ sidemenuViewController: SidemenuViewController, animated: Bool)
    func sidemenuViewController(_ sidemenuViewController: SidemenuViewController, didSelectItemAt indexPath: IndexPath)
    func logout()
    func toDeleteViewController()
}

class SidemenuViewController: UIViewController {
    private let contentView = UIView(frame: .zero)
    private let tableView = UITableView(frame: .zero, style: .plain)
    private var screenEdgePanGestureRecognizer: UIScreenEdgePanGestureRecognizer!
    weak var delegate: SidemenuViewControllerDelegate?
    private var beganLocation: CGPoint = .zero
    private var beganState: Bool = false
    private var startDragX:CGFloat = 0.0
    private var endDragX:CGFloat = 0.0
    
    let tableItem = ["アカウント管理", "ログアウト"]
    var isShown: Bool {
        return self.parent != nil
    }
    private var contentMaxWidth: CGFloat {
        return view.bounds.width * 0.65
    }
    private var contentRatio: CGFloat {
        get {
            return (view.bounds.width - contentView.frame.minX) / contentMaxWidth
        }
        set {
            let ratio = min(max(newValue, 0), 1)
            contentView.frame.origin.x = view.frame.width - contentMaxWidth * ratio
            contentView.layer.shadowColor = UIColor.black.cgColor
            contentView.layer.shadowRadius = 3.0
            contentView.layer.shadowOpacity = 0.7
            
            view.backgroundColor = UIColor(white: 0, alpha: 0.3 * ratio)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var contentRect = view.bounds
        contentRect.size.width = contentMaxWidth
        contentRect.origin.x = contentRect.width
        contentView.frame = contentRect
        contentView.setGradientLayer()
        contentView.autoresizingMask = .flexibleHeight
        view.addSubview(contentView)
        
        tableView.frame = contentView.bounds
        tableView.separatorInset = .zero
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Default")
        contentView.addSubview(tableView)
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.reloadData()
        
        let dragGesture = UIPanGestureRecognizer(
            target: self,
            action: #selector(panGestureRecognizerHandled2(panGestureRecognizer:)))
        tableView.addGestureRecognizer(dragGesture)
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped(sender:)))
        tapGestureRecognizer.delegate = self
        view.addGestureRecognizer(tapGestureRecognizer)
    }
    
    // 画面にタッチで呼ばれる
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("touchesBegan")
        if contentRatio == 0.0 {
            return
        }
        // タッチイベントを取得
        let touchEvent = touches.first!
        
        // ドラッグ前の座標, Swift 1.2 から
        let preDx = touchEvent.previousLocation(in: self.view).x
        startDragX = preDx
        endDragX = 0
        beganState = isShown

        self.delegate?.sidemenuViewControllerDidRequestShowing(self, contentAvailability: false, animated: false)

    }
    
    //　ドラッグ時に呼ばれる
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        // タッチイベントを取得
        let touchEvent = touches.first!
        
        // ドラッグ後の座標
        let newDx = touchEvent.location(in: self.view).x
        endDragX = newDx
        let distance = beganState ? newDx - startDragX : startDragX - newDx
        if distance >= 0 {
            let ratio = distance / (beganState ? (view.bounds.width - startDragX) : startDragX)
            let contentRatio = beganState ? 1 - ratio : ratio
            self.contentRatio = contentRatio
        }
    }
    
    // ドラッグ終了
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if contentRatio <= 1.0, contentRatio >= 0 {
            let screenWidth = UIScreen.main.bounds.width
            let dif = endDragX - startDragX
            if dif >= screenWidth * 0.25 {
                self.delegate?.sidemenuViewControllerDidRequestHiding(self, animated: true)
            } else {
                showContentView(animated: true)
            }
        }
        beganLocation = .zero
        beganState = false
    }
    
    @objc private func backgroundTapped(sender: UITapGestureRecognizer) {
        hideContentView(animated: true) { (_) in
            self.willMove(toParent: nil)
            self.removeFromParent()
            self.view.removeFromSuperview()
        }
    }
    
    func showContentView(animated: Bool) {
        if animated {
            UIView.animate(withDuration: 0.3) {
                self.contentRatio = 1.0
            }
        } else {
            contentRatio = 1.0
        }
    }
    
    func hideContentView(animated: Bool, completion: ((Bool) -> Swift.Void)?) {
        if animated {
            UIView.animate(withDuration: 0.2, animations: {
                self.contentRatio = 0
            }, completion: { (finished) in
                completion?(finished)
            })
        } else {
            contentRatio = 0
            completion?(true)
        }
    }
    
    func startPanGestureRecognizing() {
        if let parentViewController = self.delegate?.parentViewControllerForSidemenuViewController(self) {
            screenEdgePanGestureRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(panGestureRecognizerHandled(panGestureRecognizer:)))
            screenEdgePanGestureRecognizer.edges = [.right]
            screenEdgePanGestureRecognizer.delegate = self
            parentViewController.view.addGestureRecognizer(screenEdgePanGestureRecognizer)
        }
    }
    
    @objc private func panGestureRecognizerHandled(panGestureRecognizer: UIPanGestureRecognizer) {
//        print("通過1")
        guard let shouldPresent = self.delegate?.shouldPresentForSidemenuViewController(self), shouldPresent else {
            return
        }
        
        let translation = panGestureRecognizer.translation(in: view)
        if translation.x > 0 && contentRatio == 1.0 {
            return
        }
//        print("通過2")
        let location = panGestureRecognizer.location(in: view)
        switch panGestureRecognizer.state {
        case .began:
            beganState = isShown
            beganLocation = location
            if translation.x <= 0 {
                self.delegate?.sidemenuViewControllerDidRequestShowing(self, contentAvailability: false, animated: false)
            }
        case .changed:
            let distance = beganState ? location.x - beganLocation.x : beganLocation.x - location.x
            if distance >= 0 {
                let ratio = distance / (beganState ? (view.bounds.width - beganLocation.x) : beganLocation.x)
                let contentRatio = beganState ? 1 - ratio : ratio
                self.contentRatio = contentRatio
            }
        case .ended, .cancelled, .failed:
            if contentRatio <= 1.0, contentRatio >= 0 {
                if location.x * 2 < beganLocation.x {
                    showContentView(animated: true)
                } else {
                    self.delegate?.sidemenuViewControllerDidRequestHiding(self, animated: true)
                }
            }
            beganLocation = .zero
            beganState = false
        default: break
        }
    }
    
    @objc private func panGestureRecognizerHandled2(panGestureRecognizer: UIPanGestureRecognizer) {
        print("通過1")
        guard let shouldPresent = self.delegate?.shouldPresentForSidemenuViewController(self), shouldPresent else {
            return
        }
        
        let translation = panGestureRecognizer.translation(in: view)
        if translation.x > 0 && contentRatio == 0.0 {
            return
        }
        print("通過2")
        let location = panGestureRecognizer.location(in: view)
        switch panGestureRecognizer.state {
        case .began:
            beganState = isShown
            beganLocation = location
            if translation.x <= 0 {
                self.delegate?.sidemenuViewControllerDidRequestShowing(self, contentAvailability: false, animated: false)
            }
        case .changed:
            let distance = beganState ? location.x - beganLocation.x : beganLocation.x - location.x
            if distance >= 0 {
                let ratio = distance / (beganState ? (view.bounds.width - beganLocation.x) : beganLocation.x)
                let contentRatio = beganState ? 1 - ratio : ratio
                self.contentRatio = contentRatio
            }
        case .ended, .cancelled, .failed:
            if contentRatio <= 1.0, contentRatio >= 0 {
                print(location.x)
                print(beganLocation.x)
                if location.x > beganLocation.x + 50 {
                    self.delegate?.sidemenuViewControllerDidRequestHiding(self, animated: true)
                } else {
                    showContentView(animated: true)
                }
            }
            beganLocation = .zero
            beganState = false
        default: break
        }
    }
}

extension SidemenuViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableItem.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Default", for: indexPath)
        cell.textLabel?.text = tableItem[indexPath.row]
        cell.backgroundColor = .clear
        cell.textLabel?.textColor = .white
        cell.selectionStyle = .none
        if indexPath.row == 0 {
            cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator // ここで「>」ボタンを設定
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            self.delegate?.toDeleteViewController()
        }
        if indexPath.row == 1 {

            let alert: UIAlertController = UIAlertController(title: "ログアウトしますか？", message: "", preferredStyle:  UIAlertController.Style.alert)
            // OKボタン
            let defaultAction: UIAlertAction = UIAlertAction(title: "ログアウト",style: .default, handler: {
                    (action:UIAlertAction!) -> Void in
                // ボタンが押された時の処理を書く（クロージャ実装）
                let firebaseAuth = Auth.auth()
                do {
                    try firebaseAuth.signOut()
                    self.delegate?.logout()
                } catch let error {
                    print(error.localizedDescription)
                }
            })
            // キャンセルボタン
            let cancelAction: UIAlertAction = UIAlertAction(title: "キャンセル", style: UIAlertAction.Style.cancel, handler:{
                // ボタンが押された時の処理を書く（クロージャ実装）
                (action: UIAlertAction!) -> Void in
                print("Cancel")
            })
                
            // ③ UIAlertControllerにActionを追加
            alert.addAction(cancelAction)
            alert.addAction(defaultAction)
            
            // ④ Alertを表示
            present(alert, animated: true, completion: nil)
            
        }
        delegate?.sidemenuViewController(self, didSelectItemAt: indexPath)
    }
}

extension SidemenuViewController: UIGestureRecognizerDelegate {
    internal func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let location = gestureRecognizer.location(in: tableView)
        if tableView.indexPathForRow(at: location) != nil {
            return false
        }
        if contentRatio == 1, location.x > 0 {
            return false
        }
        return true
    }
}
