//
//  ChatViewController.swift
//  Im
//
//  Created by nobumitsu on 2019/03/18.
//  Copyright © 2019 im. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import FirebaseUI
import FirebaseFirestore

class ChatViewController: UIViewController, UIScrollViewDelegate, UITextFieldDelegate, UITextViewDelegate, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var coverView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var inputWrap: UIView!
    @IBOutlet weak var textField: UITextField!
    
    var ref: DatabaseReference!
    var storage: StorageReference!
    private let db = Firestore.firestore()
    var timestamp: TimeInterval!
    var communityId: String!
    var messageArr:[[String:Any]] = []
    var padding: CGPoint = CGPoint(x: 6.0, y: 0.0)
    var testCounter = 0
    var getId = ""
    var keyboardOn = false
    var autoScrollFlg = true
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        self.textField.delegate = self
        
        // 背景色設定
        self.view.backgroundColor = UIColor.clear
        tableView.backgroundColor = UIColor.clear
        inputWrap.backgroundColor = UIColor.clear
        textField.backgroundColor = UIColor.clear
        coverView.backgroundColor = UIColor.clear
        
        // ナビゲーションを透明にする
        self.navigationController!.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController!.navigationBar.shadowImage = UIImage()
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        //グラデーションの開始色
        let startColor = UIColor(displayP3Red: 147/255, green: 6/255, blue: 229/255, alpha: 0.3)
        //グラデーションの開始色
        let endColor = UIColor(displayP3Red: 23/255, green: 232/255, blue: 252/255, alpha: 0.3)
        scrollView.setGradient(startColor: startColor, endColor: endColor, radius: 0)
        
        // 下向きスワイプ時のジェスチャー作成
        let downSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(self.closeModalView))
        downSwipeGesture.direction = .down
        view.addGestureRecognizer(downSwipeGesture)// ジェスチャーを登録

        // ボーダー設定
        let border = CALayer()
        border.frame = CGRect(x: 0, y: 0, width:  textField.frame.size.width, height: textField.frame.size.height)
        border.borderColor = UIColor.white.cgColor
        border.borderWidth = CGFloat(1.5)
        border.cornerRadius = 20
        textField.layer.addSublayer(border)

        // プレースホルダー
        textField.attributedPlaceholder = NSAttributedString(string: "メッセージを入力", attributes: [NSAttributedString.Key.foregroundColor : UIColor(displayP3Red: 255/255, green: 255/255, blue: 255/255, alpha: 0.5)])
        
        // 初期化
        ref = Database.database().reference()
        storage = Storage.storage().reference()
        
        // 自作セルをテーブルビューに登録する
        let chatXib = UINib(nibName: "ChatTableViewCell", bundle: nil)
        tableView.register(chatXib, forCellReuseIdentifier: "communityChatCell")
        tableView.rowHeight = UITableView.automaticDimension
        
        timestamp = Date().timeIntervalSince1970
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(ChatViewController.handleKeyboardWillShowNotification(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(ChatViewController.handleKeyboardWillHideNotification(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        loadMessages()
        addNewMessage()
        
    }
    
    func loadMessages() {
        
        db.collection("communities").document(communityId!).collection("messages").whereField("createTime", isLessThan: timestamp).order(by: "createTime", descending: true).limit(to: 15).getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
                return
            }
            
            guard querySnapshot!.documents.count > 0 else {
                print("読み込むメッセージはない")
                return
            }
            
            var subScrollFlg = false
            for document in querySnapshot!.documents {
                let messageData = document.data()
                self.messageArr.insert(messageData, at: 0)
                if RootTabBarController.UserId == messageData["senderId"] as! String {
                    self.autoScrollFlg = true
                    subScrollFlg = true
                }
            }
            
            self.tableView.reloadData()
            // グラデーション設定
            let gradientLayer = CAGradientLayer()
            gradientLayer.frame = self.tableView.superview!.bounds
            let clearColor = UIColor.clear.cgColor
            let whiteColor = UIColor.white.cgColor
            gradientLayer.colors = [clearColor, whiteColor, whiteColor]
            gradientLayer.locations = [0.45, 0.55, 1.0]
            self.tableView.superview!.layer.mask = gradientLayer
            self.tableView.backgroundColor = UIColor.clear
            DispatchQueue.main.async {
                self.tableView.performBatchUpdates({
                    
                }) { (finished) in
                    let dif = self.tableView.contentSize.height - self.tableView.frame.size.height
                    if dif < 0 {
                        // 下詰め
                        self.tableView.contentInset = UIEdgeInsets(top: dif * -1, left: 0, bottom: 0, right: 0)
                        return
                    } else {
                        // マージン0
                        self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
                        print(self.autoScrollFlg)
                        guard self.autoScrollFlg || subScrollFlg else {
                            return
                        }
                        self.tableView.setContentOffset(CGPoint(x: self.tableView.contentOffset.x, y: dif), animated: true)
                    }
                }
                
            }
            
        }

    }
    
    func addNewMessage() {
        db.collection("communities").document(communityId!).collection("messages").whereField("createTime", isGreaterThan: timestamp).addSnapshotListener{ querySnapshot, error in
            guard let documents = querySnapshot?.documents else {
                print("Error fetching documents: \(error!)")
                return
            }

            guard documents.count > 0 else { return }

            guard let snapshot = querySnapshot else {
                print("Error fetching documents: \(error!)")
                return
            }

            var subScrollFlg = false
            snapshot.documentChanges.forEach { diff in
                switch diff.type {
                case .added:
                    let messageData = diff.document.data()
                    self.messageArr.append(messageData)
                    if RootTabBarController.UserId == messageData["senderId"] as! String {
                        self.autoScrollFlg = true
                        subScrollFlg = true
                    }
                default:
                    break
                }
            }
            self.tableView.reloadData()
            // グラデーション設定
            let gradientLayer = CAGradientLayer()
            gradientLayer.frame = self.tableView.superview!.bounds
            let clearColor = UIColor.clear.cgColor
            let whiteColor = UIColor.white.cgColor
            gradientLayer.colors = [clearColor, whiteColor, whiteColor]
            gradientLayer.locations = [0.45, 0.55, 1.0]
            self.tableView.superview!.layer.mask = gradientLayer
            self.tableView.backgroundColor = UIColor.clear
            DispatchQueue.main.async {
                self.tableView.performBatchUpdates({

                }) { (finished) in
                    let dif = self.tableView.contentSize.height - self.tableView.frame.size.height
                    if dif < 0 {
                        // 下詰め
                        self.tableView.contentInset = UIEdgeInsets(top: dif * -1, left: 0, bottom: 0, right: 0)
                        return
                    } else {
                        // マージン0
                        self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
                        print(self.autoScrollFlg)
                        guard self.autoScrollFlg || subScrollFlg else {
                            return
                        }
                        self.tableView.setContentOffset(CGPoint(x: self.tableView.contentOffset.x, y: dif), animated: true)
                    }
                }

            }
        }
        
    }
    
    // MARK: UITableView delegate
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "communityChatCell", for: indexPath) as! ChatTableViewCell

        let imgView = cell.img
        let name = cell.name
        let message = cell.message
        
        db.collection("users").document(messageArr[indexPath.row]["senderId"] as! String).getDocument { (document, error) in
            if let user = document.flatMap({
                $0.data().flatMap({ (data) in
                    return data
                })
            }) {
                name!.text = user["name"] as? String
//                DispatchQueue.main.async {
                if user["img"] as! String != "" {
                    let imgRef = self.storage.child("users").child(user["img"] as! String)
                    imgView!.sd_setImage(with: imgRef)
//                    imgView!.setNeedsLayout()
                } else {
                    imgView?.image = UIImage(named: "UserImg")
                }
//                }

            }
        }
        
        let tapImgGesture = UserTapGestureRecognizer(
            target: self,
            action: #selector(ChatViewController.tapSegue(_:)))
        
        let tapNameGesture = UserTapGestureRecognizer(
            target: self,
            action: #selector(ChatViewController.tapSegue(_:)))
        
        tapImgGesture.user = (self.messageArr[indexPath.row]["senderId"] as! String)
        tapImgGesture.userDoc = messageArr[indexPath.row]
        
        tapNameGesture.user = (self.messageArr[indexPath.row]["senderId"] as! String)
        tapNameGesture.userDoc = messageArr[indexPath.row]
        
        imgView?.isUserInteractionEnabled = true
        imgView!.addGestureRecognizer(tapImgGesture)
        
        name?.isUserInteractionEnabled = true
        name?.addGestureRecognizer(tapNameGesture)
        
        message!.text = (messageArr[indexPath.row]["message"] as! String)
        message!.sizeToFit()
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messageArr.count
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 52
    }
    
    // スクロールして途中指で止めた場合のみ
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if decelerate == false {
            print("スクロール止めた")
            autoScrollFlg = false
        }
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        guard tableView.cellForRow(at: IndexPath(row: tableView.numberOfRows(inSection: 0)-1, section: 0)) != nil else {
            autoScrollFlg = false
            print("じゃないほう")
            return
        }
        // 1番下
        if tableView.contentOffset.y > 0 {
            print("1番した")
            autoScrollFlg = true
        }
        
    }

    @IBAction func tapScreen(_ sender: Any) {
        // キーボードを閉じる
        self.view.endEditing(true)
    }

    // キーボード分スライド
    @objc func handleKeyboardWillShowNotification(_ notification: Notification) {
        
        keyboardOn = true
        let userInfo = notification.userInfo!
        let keyboardScreenEndFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let myBoundSize: CGSize = UIScreen.main.bounds.size
        
        let txtLimit = myBoundSize.height// テキストフィールドの下辺
        let kbdLimit = myBoundSize.height - keyboardScreenEndFrame.size.height// キーボードの上辺

        // キーボードの位置の方が上の場合
        if txtLimit >= kbdLimit {
            scrollView.contentOffset.y = txtLimit - kbdLimit
        }
    }

    @objc func handleKeyboardWillHideNotification(_ notification: Notification) {
        scrollView.contentOffset.y = 0
        keyboardOn = false
    }

    // DM画面にページ遷移
    @objc func tapSegue(_ sender: UserTapGestureRecognizer) {
        // IDチェック
        getId = sender.user!
        if getId == RootTabBarController.UserId {
            return
        }
        self.performSegue(withIdentifier: "toOtherProfileViewController", sender: sender.userDoc)// ページ遷移

    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toOtherProfileViewController" {
            let profileViewController = segue.destination as! OtherProfileViewController
            profileViewController.userId = getId
            profileViewController.fromWhere = "communityChat"
        }
    }
    
    // Enterを押したらキーボードが閉じる
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        let message = textField.text// 入力文字を取得
        if message == "" {
            return false
        }
        
        db.collection("communities").document(communityId).collection("messages").addDocument(
            data: ["senderId": RootTabBarController.UserId, "message": message!, "createTime": Date().timeIntervalSince1970]
        ) { err in
            if let err = err {
                print("Error adding document: \(err)")
            } else {
                self.autoScrollFlg = true
                print("Document added with ID:")
            }
        }
        
        testCounter = 1
        textField.text = ""
        textField.resignFirstResponder()// キーボード閉じる
        
        return true
    }
    
    // ボタンで画面を閉じる
    @IBAction func closeModal(_ sender: Any) {
        if keyboardOn { return }
        //呼び出し元のView Controllerを取得しパラメータを渡す
        let InfoVc = self.presentingViewController as! RootTabBarController
        InfoVc.tabBar.isHidden = false
        self.dismiss(animated: true, completion: nil)
    }

    // スワイプで画面を閉じる
    @objc func closeModalView() {
        if keyboardOn { return }
        //呼び出し元のView Controllerを取得しパラメータを渡す
        let InfoVc = self.presentingViewController as! RootTabBarController
        InfoVc.tabBar.isHidden = false
        self.dismiss(animated: true, completion: nil)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // キーボードを閉じる
        textField.resignFirstResponder()
    }
}

class UserTapGestureRecognizer: UITapGestureRecognizer {
    var user: String?
    var userDoc: [String:Any]!
}
