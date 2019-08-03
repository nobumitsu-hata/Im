//
//  AccountDetailViewController.swift
//  Im
//
//  Created by nobumitsu on 2019/07/20.
//  Copyright © 2019 im. All rights reserved.
//

import UIKit
import Firebase

class AccountDetailViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    private let db = Firestore.firestore()
    private let storageRef = Storage.storage().reference()
    var partnerData:[String:Any] = [:]
    var partnerId = ""
    var chatId =  ""
    var blockFlg = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        getPrivateChatId()
        
        view.setGradientLayer()
        tableView.backgroundColor  = .clear
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        db.collection("users").document(RootTabBarController.UserId).collection("blockUsers").document(partnerId).getDocument { (document
            , error) in
            if let document = document, document.exists {
                let dataDescription = document.data().map(String.init(describing:)) ?? "nil"
                self.blockFlg = true
                self.tableView.reloadData()
                print("Document data: \(dataDescription)")
            } else {
                self.blockFlg = false
                self.tableView.reloadData()
                print("Document does not exist")
            }
        }
    }
    
    func getPrivateChatId() {
        let val = RootTabBarController.UserId.compare(partnerId).rawValue
        if val < 0 {
            chatId = RootTabBarController.UserId + partnerId
        } else {
            chatId = partnerId + RootTabBarController.UserId
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell:UITableViewCell!
        
        if indexPath.row == 0 {
            cell = tableView.dequeueReusableCell(withIdentifier: "toAccountDetailCell1", for: indexPath)
            cell.backgroundColor = .clear
            
            if let imgView = cell.viewWithTag(1) as? UIImageView {
                imgView.layer.cornerRadius = imgView.frame.size.width * 0.5
                imgView.clipsToBounds = true
                if self.partnerData["img"] as! String != "" {
                    let imgRef = storageRef.child("users").child(self.partnerData["img"] as! String)
                    imgView.sd_setImage(with: imgRef)
                } else {
                    imgView.image = UIImage(named: "UserImg")
                }
                
            }
            if let name = cell.viewWithTag(2) as? UILabel {
                name.text = partnerData["name"] as? String
            }
            
        } else {
            
            cell = tableView.dequeueReusableCell(withIdentifier: "toAccountDetailCell2", for: indexPath)
            
            if indexPath.row == 1{
                if let label = cell.viewWithTag(1) as? UILabel {
                    if self.blockFlg {
                        label.text = "ブロックを解除"
                    } else {
                        label.text = "ブロック"
                    }
                    
                }
            } else {
                let label = cell.viewWithTag(1) as? UILabel
                label?.text = "報告する"
            }
            
            
            cell.backgroundColor = .clear
        }
        
        // 選択された背景色を透明に設定
        let cellSelectedBgView = UIView()
        cellSelectedBgView.backgroundColor = UIColor.clear
        cell.selectedBackgroundView = cellSelectedBgView
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return .leastNormalMagnitude
    }
    
    // Cell が選択された場合
    func tableView(_ table: UITableView,didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: false)
        
        if indexPath.row == 0 {
            performSegue(withIdentifier: "fromAccountDetailToOtherProfile", sender: nil)
        }
        
        if indexPath.row == 1 {
            
            // ① UIAlertControllerクラスのインスタンスを生成
            var alertTitle = "\(partnerData["name"] as? String ?? "")さんをブロックしますか？"
            if self.blockFlg {
                alertTitle = "\(partnerData["name"] as? String ?? "")さんのブロックを解除しますか？"
            }
            let alert: UIAlertController = UIAlertController(title: alertTitle, message: "\(partnerData["name"] as? String ?? "")さんはあなたにメッセージを送れなくなります。", preferredStyle:  UIAlertController.Style.alert)
            
            // ② Actionの設定
            var okTitle = "ブロック"
            if self.blockFlg {
                okTitle = "ブロックを解除"
            }
            // OKボタン
            let defaultAction: UIAlertAction = UIAlertAction(title: okTitle, style: .destructive, handler: {
                (action:UIAlertAction!) -> Void in
                
                // ブロックを解除
                if self.blockFlg {
                    
                    self.db.collection("users").document(RootTabBarController.UserId).collection("blockUsers").document(self.partnerId).delete() { err in
                        if let err = err {
                            print("Error removing document: \(err)")
                        } else {
                            print("Document successfully removed!")
                            
                            let cell = self.tableView.cellForRow(at: [0, 1])
                            let label = cell!.viewWithTag(1) as? UILabel
                            label?.text = "ブロック"
                            self.blockFlg = false
                            
                        }
                    }
                    
                // ブロック
                } else {
                    
                    self.db.collection("users").document(RootTabBarController.UserId).collection("blockUsers").document(self.partnerId).setData(["status": true]) { err in
                        if let err = err {
                            print("Error writing document: \(err)")
                        } else {
                            print("Document successfully written!")
                            
                            let cell = self.tableView.cellForRow(at: [0, 1])
                            let label = cell!.viewWithTag(1) as? UILabel
                            label?.text = "ブロックを解除"
                            self.blockFlg = true
                            
                        }
                    }
                    
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
        
        if indexPath.row == 2 {
            performSegue(withIdentifier: "fromAccountDetailToReportUser", sender: nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "fromAccountDetailToOtherProfile" {
            let profileViewController = segue.destination as! OtherProfileViewController
            profileViewController.userId = partnerId
            profileViewController.backChatCount = 2
        }
        
        if segue.identifier == "fromAccountDetailToReportUser" {
            let nav = segue.destination as! UINavigationController
            let reportUserViewController = nav.topViewController as! ReportUserViewController
            reportUserViewController.targetId = partnerId
        }
    }
}
