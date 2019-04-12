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

class ChatViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate, UITextFieldDelegate, UITextViewDelegate {

    
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var inputWrap: UIView!
    @IBOutlet weak var textField: UITextField!
    
    var ref: DatabaseReference!
    var communityId: String!
    var messageArr:[[String:Any]] = []
    var padding: CGPoint = CGPoint(x: 6.0, y: 0.0)
    var test:CGRect = CGRect(x: 0, y: 0, width: 0, height: 0)
    var testCounter = 0
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(ChatViewController.handleKeyboardWillShowNotification(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(ChatViewController.handleKeyboardWillHideNotification(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        self.textField.delegate = self
        
        textField.returnKeyType = .done
        
        // 背景色設定
        self.view.backgroundColor = UIColor.clear
        tableView.backgroundColor = UIColor.clear
        inputWrap.backgroundColor = UIColor.clear
        textField.backgroundColor = UIColor.clear
        
        self.tableView.rowHeight = UITableView.automaticDimension
        
        // ボーダー設定
        let border = CALayer()
        border.frame = CGRect(x: 0, y: 0, width:  textField.frame.size.width, height: textField.frame.size.height)
        border.borderColor = UIColor.white.cgColor
        border.borderWidth = CGFloat(1.5)
        border.cornerRadius = 20
        textField.layer.addSublayer(border)
        textField.attributedPlaceholder = NSAttributedString(string: "メッセージを入力", attributes: [NSAttributedString.Key.foregroundColor : UIColor(displayP3Red: 255/255, green: 255/255, blue: 255/255, alpha: 0.5)])
        
        // 初期化
        ref = Database.database().reference()
        
        // 自作セルをテーブルビューに登録する
        let chatXib = UINib(nibName: "ChatTableViewCell", bundle: nil)
        tableView.register(chatXib, forCellReuseIdentifier: "chatCell")
        
        // メッセージ取得
        ref.child("messages").child(communityId).observe(.childAdded, with: { (snapshot) -> Void in
//        self.ref.child("messages").child(communityId).observeSingleEvent(of: .value, with: { (snapshot) in
        
            let val = snapshot.value as! [String:Any]
//            self.messageArr = Array(val.values) as! [[String : Any]]
            self.messageArr.append(val)
            let oldContentSize = self.tableView.contentSize.height
            // データの追加
            self.tableView.reloadData()
            DispatchQueue.main.async {
            
                self.tableView.performBatchUpdates({

                }) { (finished) in
                    print("reload完了しました🙂")
                    if self.testCounter > 0 {
                        
                        let newContentSize = self.tableView.contentSize.height
                        let dif = newContentSize - oldContentSize
                        // 前回の先頭からのオフセット分ずらす
                        self.tableView.contentOffset = CGPoint(x: 0, y: self.tableView.contentOffset.y + dif)

                    } else {
                        let test = self.tableView.contentSize.height - self.tableView.frame.size.height
//                        self.tableView.setContentOffset(CGPoint(x:0, y:test), animated: false)
                        self.tableView.contentOffset = CGPoint(x: 0, y: test)
                    }
                }
            
            }
            
        })
    }
    
    func tableView(_ table: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // セル生成
        let cell = table.dequeueReusableCell(withIdentifier: "chatCell", for: indexPath) as! ChatTableViewCell
        let imgView = cell.userImg as! UIImageView
        let name = cell.userName as! UILabel
        let textView = cell.userMessage as! UILabel
        
//        text.isEditable = false
//        text.delegate = self
        // 画像設定
        let img = UIImage(named: "User")
        imgView.image = img
        // 配色
        cell.backgroundColor = UIColor.clear
        name.backgroundColor = UIColor.clear
        textView.backgroundColor = UIColor.clear
        // paddingを消す
//        text.textContainerInset = UIEdgeInsets.zero
//        text.textContainer.lineFragmentPadding = 0
        textView.text = (messageArr[indexPath.row]["message"] as! String)
        textView.sizeToFit()
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messageArr.count
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    @IBAction func tapScreen(_ sender: Any) {
        // キーボードを閉じる
        self.view.endEditing(true)
    }
    
    @objc func handleKeyboardWillShowNotification(_ notification: Notification) {
        
        
        let userInfo = notification.userInfo!
        let keyboardScreenEndFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let myBoundSize: CGSize = UIScreen.main.bounds.size
        // テキストフィールドの下辺
        let txtLimit = inputWrap.frame.origin.y + inputWrap.frame.height + 8.0
        // キーボードの上辺
        let kbdLimit = myBoundSize.height - keyboardScreenEndFrame.size.height
        
        
        print("テキストフィールドの下辺：(\(txtLimit))")
        print("キーボードの上辺：(\(kbdLimit))")
        
        // キーボードの位置の方が上の場合
        if txtLimit >= kbdLimit {
            // 上にスライド
            print(txtLimit - kbdLimit)
            scrollView.contentOffset.y = txtLimit - kbdLimit
        }
    }
    
    @objc func handleKeyboardWillHideNotification(_ notification: Notification) {
        scrollView.contentOffset.y = 0
    }
    
    //Enterを押したらキーボードが閉じるようにするためのコードです。
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // TextFieldから文字を取得
        let message = textField.text
        if message == "" {
            return false
        }
        let key = ref.child("messages").childByAutoId().key
        self.ref.child("messages").child(communityId).child(key!).setValue(["user":RootTabBarController.userId,"message":message])
        // TextFieldの中身をクリア
        textField.text = ""
        testCounter = 1
        textField.resignFirstResponder()
        return true
    }
}
