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

class ChatViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate, UITextFieldDelegate, UITextViewDelegate {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var coverView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var inputWrap: UIView!
    @IBOutlet weak var textField: UITextField!
    
    var testd: String!
    var ref: DatabaseReference!
    var storage: StorageReference!
    var communityId: String!
    var messageArr:[[String:Any]] = []
    var padding: CGPoint = CGPoint(x: 6.0, y: 0.0)
    var test:CGRect = CGRect(x: 0, y: 0, width: 0, height: 0)
    var testCounter = 0
    var getId = ""
    var keyboardOn = false
    var offsetY:CGFloat = 0
    var flg = false
    var flg2 = true
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // ナビゲーションを透明にする
        self.navigationController!.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController!.navigationBar.shadowImage = UIImage()
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(ChatViewController.handleKeyboardWillShowNotification(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(ChatViewController.handleKeyboardWillHideNotification(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)

    }
    
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

        //グラデーションの開始色
        let startColor = UIColor(displayP3Red: 147/255, green: 6/255, blue: 229/255, alpha: 0.3)
        //グラデーションの開始色
        let endColor = UIColor(displayP3Red: 23/255, green: 232/255, blue: 252/255, alpha: 0.3)
        scrollView.setGradient(startColor: startColor, endColor: endColor, radius: 0)
        
        self.tableView.rowHeight = UITableView.automaticDimension
        
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
        tableView.register(chatXib, forCellReuseIdentifier: "chatCell")
        
        // メッセージ取得
        ref.child("messages").child(communityId).observe(.childAdded, with: { (snapshot) -> Void in
            
            let val = snapshot.value as! [String:Any]
            self.messageArr.append(val)
            // データの追加
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
            print("reload完了しました🙂")
            
            // スクロール中
            DispatchQueue.main.async {
                self.tableView.performBatchUpdates({
                    
                }) { (finished) in
                    let dif = self.tableView.contentSize.height - self.tableView.frame.size.height
                    if dif < 0 {
                    // 下詰め
                        self.tableView.contentInset = UIEdgeInsets(top: dif, left: 0, bottom: 0, right: 0)
                    } else {
                    // 1番下までスクロール
                        guard self.flg else {
                            // マージン0
                            self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
                            self.tableView.contentOffset.y = dif
                            self.flg = true
                            return
                        }
                        // 1番下でじゃない場合
                        guard self.flg2 else { return }
                        self.tableView.contentOffset.y = dif// 1番下にスクロール
                    }
                }
            }
        })
        
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if tableView.cellForRow(at: IndexPath(row: tableView.numberOfRows(inSection: 0)-2, section: 0)) != nil {
            flg2 = false
        }
        guard tableView.cellForRow(at: IndexPath(row: tableView.numberOfRows(inSection: 0)-1, section: 0)) != nil else {
            return
        }
        print("1番下")
        flg2 = true
        // ここでリフレッシュのメソッドを呼ぶ
    }
    
    func tableView(_ table: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // セル生成
        let cell = table.dequeueReusableCell(withIdentifier: "chatCell", for: indexPath) as! ChatTableViewCell
        let imgView = cell.userImg
        let name = cell.userName
        let textView = cell.userMessage


        ref.child("users").child(messageArr[indexPath.row]["user"] as! String).observeSingleEvent(of: .value, with: { (snapshot) in
            let val = snapshot.value as! [String:Any]
            print(val)
            name!.text = (val["name"] as! String)
            let getImg = self.storage.child("users").child(val["img"] as! String)
            imgView!.sd_setImage(with: getImg)
        })
        
        let tapGesture = UserTapGestureRecognizer(
            target: self,
            action: #selector(ChatViewController.tapImg(_:)))

        tapGesture.user = (self.messageArr[indexPath.row]["user"] as! String)
        //            tapGesture.delegate = self

        imgView?.isUserInteractionEnabled = true
        imgView!.addGestureRecognizer(tapGesture)

//        text.isEditable = false
//        text.delegate = self
        // 配色
        cell.backgroundColor = UIColor.clear
        name!.backgroundColor = UIColor.clear
        textView!.backgroundColor = UIColor.clear
        // paddingを消す
//        text.textContainerInset = UIEdgeInsets.zero
//        text.textContainer.lineFragmentPadding = 0
        textView!.text = (messageArr[indexPath.row]["message"] as! String)
        textView!.sizeToFit()
        
//        cell.transform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: 0)
        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messageArr.count
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 52
    }

    @IBAction func tapScreen(_ sender: Any) {
        print("タップ")
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

        print("テキストフィールドの下辺：(\(txtLimit))")
        print("キーボードの上辺：(\(kbdLimit))")

        // キーボードの位置の方が上の場合
        if txtLimit >= kbdLimit {
            print(txtLimit - kbdLimit)
            scrollView.contentOffset.y = txtLimit - kbdLimit
        }
    }

    @objc func handleKeyboardWillHideNotification(_ notification: Notification) {
        scrollView.contentOffset.y = 0
        keyboardOn = false
    }

    // DM画面にページ遷移
    @objc func tapImg(_ sender: UserTapGestureRecognizer) {
        // IDチェック
        getId = sender.user!
        if getId == RootTabBarController.userId {
            return
        }
        
        ref.child("users").child(getId).observeSingleEvent(of: .value, with: { (snapshot) in
            let val = snapshot.value as! [String:String]
            self.performSegue(withIdentifier: "toDMViewController", sender: val)// ページ遷移
        })

    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toDMViewController" {
            let dmViewController = segue.destination as! DMViewController
            dmViewController.partnerId = getId
            dmViewController.partnerData = sender as! [String : String]
        }
    }
    
    // Enterを押したらキーボードが閉じる
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        let message = textField.text// 入力文字を取得
        if message == "" {
            return false
        }
        
        let key = ref.child("messages").childByAutoId().key
        self.ref.child("messages").child(communityId).child(key!).setValue(
            ["user":RootTabBarController.userId,"message":message])
        
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
}
