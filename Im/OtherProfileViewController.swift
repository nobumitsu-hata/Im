//
//  OtherProfileViewController.swift
//  Im
//
//  Created by nobumitsu on 2019/06/03.
//  Copyright © 2019 im. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import FirebaseFirestore

class OtherProfileViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var storage: Storage!
    private let db = Firestore.firestore()
    
    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var nameLbl: UILabel!
    @IBOutlet weak var genderLbl: UILabel!
    @IBOutlet weak var talkBtn: UIButton!
    @IBOutlet weak var wrapperView: UIView!
    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var introduction: UITextView!
    @IBOutlet weak var tableView: UITableView!

    var userId = ""
    var userData:[String:Any]!
    let belongsArr = ["好きなチーム", "観戦仲間", "ファンレベル"]
    var belongsVal = ["未設定", "未設定", "未設定"]
    var communityId = ""
    var backChatCount = 0
    var myBlockFlg = false
    var partnerBlockFlg = false
    var chatId = ""
    static var blockListener: ListenerRegistration!
    static var profileListener: ListenerRegistration!

    override func viewDidLoad() {
        super.viewDidLoad()

        // 編集ボタンカスタマイズ
        talkBtn.setGradientBackground(
            colorOne: UIColor(displayP3Red: 147/255, green: 6/255, blue: 229/255, alpha: 1.0),
            colorTwo: UIColor(displayP3Red: 23/255, green: 232/255, blue: 252/255, alpha: 1.0)
        )
        
        getPrivateChatId()
        
        // 初期化
        storage = Storage.storage()
        tableView.delegate = self
        tableView.dataSource = self
        
        introduction.textContainerInset = UIEdgeInsets.zero
        introduction.textContainer.lineFragmentPadding = 0
        
        self.view.setGradientLayer()
        wrapperView.backgroundColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.2)
        wrapperView.layer.cornerRadius = 20
        mainView.layer.cornerRadius = 20
        tableView.backgroundColor = UIColor.clear
        // 角丸にする
        self.imgView.layer.cornerRadius = self.imgView.frame.size.width * 0.5
        self.imgView.clipsToBounds = true
        // ナビゲーションを透明にする処理
        self.navigationController!.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController!.navigationBar.shadowImage = UIImage()
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        blockCheck()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
        setupFirebase()
    }
    
    func getPrivateChatId() {
        let val = RootTabBarController.UserId.compare(userId).rawValue
        if val < 0 {
            chatId = RootTabBarController.UserId + userId
        } else {
            chatId = userId + RootTabBarController.UserId
        }
    }
    
    
    // 相手がブロックしているかどうか
    func blockCheck() {
        
        if OtherProfileViewController.blockListener != nil {
            OtherProfileViewController.blockListener.remove()
        }
        OtherProfileViewController.blockListener = db.collection("users").document(userId).collection("blockUsers").addSnapshotListener{ querySnapshot, error in
            
            guard let documents = querySnapshot?.documents else {
                print("Error fetching documents: \(error!)")
                return
            }
            
            print(documents.count)
            
            guard let snapshot = querySnapshot else {
                print("Error fetching documents: \(error!)")
                return
            }
            
            snapshot.documentChanges.forEach { diff in
                switch diff.type {
                case .added:
                    print("ブロック追加")
                    if diff.document.documentID == RootTabBarController.UserId {
                        self.partnerBlockFlg = true
                        self.talkBtn.setTitle("トークできません", for: .normal)
                    }
                case .removed:
                    if diff.document.documentID == RootTabBarController.UserId {
                        print("相手のブロック解除")
                        self.partnerBlockFlg = false
                        if !self.myBlockFlg {
                            self.talkBtn.setTitle("トークする", for: .normal)
                        }
                    }
                default:
                    print("blockUser")
                }
            }
            
        }
        
    }
    
    func setupFirebase() {
        
        // 自分がブロックしているかどうか
        db.collection("users").document(RootTabBarController.UserId).collection("blockUsers").document(userId).getDocument { (document
            , error) in
            if let document = document, document.exists {
                let dataDescription = document.data().map(String.init(describing:)) ?? "nil"
                self.myBlockFlg = true
                self.talkBtn.setTitle("トークできません", for: .normal)
                print("Document data: \(dataDescription)")
            } else {
                print("Document does not exist")
            }
        }
        
        db.collection("users").document(userId).addSnapshotListener { documentSnapshot, error in
            guard let document = documentSnapshot else {
                print("Error fetching document: \(error!)")
                return
            }
            print("プロフィール変更")
            self.userData = document.data()
            let storageRef = self.storage.reference()
            if self.userData?["img"] as! String != "" {
                let imgRef = storageRef.child("users").child(self.userData?["img"] as! String)
                DispatchQueue.main.async {
                    self.imgView.sd_setImage(with: imgRef)
                    self.imgView.setNeedsLayout()
                }
            } else {
                self.imgView.image = UIImage(named: "UserImg")
            }
            
            self.nameLbl.text = (self.userData!["name"] as! String)
            
            if "男性" == self.userData!["sex"] as? String {
                self.genderLbl.text = "男性"
            } else if "女性" == self.userData!["sex"] as? String {
                self.genderLbl.text = "女性"
            }
            
            if (self.userData?["introduction"] as? String != "") {
                self.introduction.isHidden = false
                self.introduction.text = self.userData?["introduction"] as? String
            } else {
                self.introduction.isHidden = true
            }
            
            self.db.collection("users").document(self.userId).collection("belongs").getDocuments() { (querySnapshot, err) in
                guard let documents = querySnapshot?.documents else {
                    print("Error fetching documents: \(error!)")
                    return
                }
                guard documents.count > 0 else {
                    return
                }
                
                for document in documents {
                    
                    self.communityId = document.documentID
                    let data = document.data()
                    self.db.collection("communities").document(self.communityId).getDocument { (communityDoc, error) in
                        
                        let communityData = communityDoc?.data()
                        
                        self.belongsVal[0] = communityData?["name"] as! String
                        if data["friend"] as? String == "" {
                            self.belongsVal[1] = "未設定"
                        
                        } else {
                            if (data["friend"] as? Bool)! { self.belongsVal[1] = "いる" }
                            else if data["friend"] as? Bool == false { self.belongsVal[1] = "いない" }
                        }
                        // ファンレベル
                        guard data["level"] as? String != "" else {
                            return
                        }
                        self.db.collection("levels").document(data["level"] as! String).getDocument { (levelDoc, error) in
                            if let levelDoc = levelDoc, levelDoc.exists {
                                let levelData = levelDoc.data()
                                self.belongsVal[2] = levelData?["name"] as! String
                                self.tableView.reloadData()
                            } else {
                                print("Document does not exist")
                            }
                        }
                        
                        self.tableView.reloadData()
                    }
                }
            }
        }
        
    }
    
    // MARK: UITableView delegate
    
    func tableView(_ table: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // セル生成
        let cell = table.dequeueReusableCell(withIdentifier: "OtherProfileCell", for: indexPath) as! ProfileTableViewCell
        cell.backgroundColor = UIColor.clear
        
        cell.keyLbl.text = belongsArr[indexPath.row]
        cell.valLbl.text = belongsVal[indexPath.row]
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return belongsVal.count
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 43
    }
    
    
    @IBAction func toPrivateChat(_ sender: Any) {
        if backChatCount > 0 {
        // 個人チャットに戻る
            print(backChatCount)
            let count = (self.navigationController?.viewControllers.count)! - (1+backChatCount)
            let vc = self.navigationController?.viewControllers[count] as! DMViewController
            vc.partnerId = userId
            vc.partnerData = userData
            // 画面を消す
            self.navigationController?.popToViewController(self.navigationController!.viewControllers[count], animated: true)
        } else {
        // 個人チャットに進む
            if myBlockFlg || partnerBlockFlg {
                return
            }
            self.performSegue(withIdentifier: "toPrivateChatViewController", sender: nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "toPrivateChatViewController" {
            let privateChatViewController = segue.destination as! DMViewController
            privateChatViewController.partnerId = userId
            privateChatViewController.partnerData = userData
        }
        
        if segue.identifier == "fromOtherProfileToReportUser" {
            let nav = segue.destination as! UINavigationController
            let reportUserViewController = nav.topViewController as! ReportUserViewController
            reportUserViewController.targetId = userId
        }
    }
    
    @IBAction func tapActionSheet(_ sender: Any) {
        
        // ① UIAlertControllerクラスのインスタンスを生成
        let alert: UIAlertController = UIAlertController(title: nil, message: nil, preferredStyle:  UIAlertController.Style.actionSheet)
        
        // ② Actionの設定
        // OKボタン
        var okTitle = "ブロック"
        var alertStyle = UIAlertAction.Style.destructive
        if self.myBlockFlg {
            okTitle = "ブロックを解除"
            alertStyle = UIAlertAction.Style.default
        }
        let defaultAction: UIAlertAction = UIAlertAction(title: okTitle, style: alertStyle, handler: {
            (action:UIAlertAction!) -> Void in
            
            // ① UIAlertControllerクラスのインスタンスを生成
            var alertTitle = "\(self.userData["name"] as? String ?? "")さんをブロックしますか？"
            var message = "\(self.userData["name"] as? String ?? "")さんはあなたにメッセージを送れなくなります。"
            if self.myBlockFlg {
                alertTitle = "\(self.userData["name"] as? String ?? "")さんのブロックを解除しますか？"
                message = "\(self.userData["name"] as? String ?? "")さんはあなたにメッセージを送れるようになります。"
            }
            let alertComplete: UIAlertController = UIAlertController(
                title: alertTitle,
                message: message,
                preferredStyle: UIAlertController.Style.alert
            )
            
            // ② Actionの設定
            // OKボタン
            var okTitle = "ブロック"
            var alertStyle = UIAlertAction.Style.destructive
            if self.myBlockFlg {
                okTitle = "ブロックを解除"
                alertStyle = UIAlertAction.Style.default
            }
            let defaultAction: UIAlertAction = UIAlertAction(title: okTitle, style: alertStyle, handler: {
                (action:UIAlertAction!) -> Void in
                
                // ブロックを解除
                if self.myBlockFlg {
                    
                    self.db.collection("users").document(RootTabBarController.UserId).collection("blockUsers").document(self.userId).delete() { err in
                        if let err = err {
                            print("Error removing document: \(err)")
                        } else {
                            print("Document successfully removed!")
                            self.myBlockFlg = false
                            if !self.partnerBlockFlg {
                                self.talkBtn.setTitle("トークする", for: .normal)
                            }
                        }
                    }
                    
                // ブロック
                } else {
                    
                    self.db.collection("users").document(RootTabBarController.UserId).collection("blockUsers").document(self.userId).setData(["status": true]) { err in
                        if let err = err {
                            print("Error writing document: \(err)")
                        } else {
                            print("Document successfully written!")
                            self.myBlockFlg = true
                            self.talkBtn.setTitle("トークできません", for: .normal)
                            
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
            alertComplete.addAction(cancelAction)
            alertComplete.addAction(defaultAction)
            
            // ④ Alertを表示
            self.present(alertComplete, animated: true, completion: nil)
            
        })
        
        let reportAction: UIAlertAction = UIAlertAction(title: "報告する", style: UIAlertAction.Style.destructive, handler: {
            (action:UIAlertAction!) -> Void in
            self.performSegue(withIdentifier: "fromOtherProfileToReportUser", sender: nil)
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
        alert.addAction(reportAction)
        // iPadでは必須！
        alert.popoverPresentationController?.sourceView = self.view
        let screenSize = UIScreen.main.bounds
        // ここで表示位置を調整
        // xは画面中央、yは画面下部になる様に指定
        alert.popoverPresentationController?.sourceRect = CGRect(x: screenSize.size.width/2, y: screenSize.size.height, width: 0, height: 0)
        
        
        // ④ Alertを表示
        present(alert, animated: true, completion: nil)
        
    }
    
}
