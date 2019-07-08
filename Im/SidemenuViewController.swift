//
//  SideMenuViewController.swift
//  Im
//
//  Created by nobumitsu on 2019/06/03.
//  Copyright © 2019 im. All rights reserved.
//

import UIKit
import Firebase

class SidemenuViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    let tableItem = ["アカウント管理", "ログアウト"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.setGradientLayer()
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Default")
        tableView.backgroundColor = .clear
        tableView.reloadData()
        
        // ナビゲーションを透明にする処理
        self.navigationController!.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController!.navigationBar.shadowImage = UIImage()
    }
    
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
            self.performSegue(withIdentifier: "toDeleteViewController", sender: nil)
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
                    let referenceForTabBarController = self.presentingViewController as! RootTabBarController
                    self.dismiss(animated: true, completion: {
                        referenceForTabBarController.selectedIndex = 0
                    })
                    RootTabBarController.AuthCheck = false
                    AccountViewController.profileListener.remove()
                    AccountViewController.belongsListener.remove()
                    AccountViewController.listenerFlg = false
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
    }
    
}

