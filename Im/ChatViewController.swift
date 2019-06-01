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

class ChatViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UIScrollViewDelegate, UITextFieldDelegate, UITextViewDelegate {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var coverView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var inputWrap: UIView!
    @IBOutlet weak var textField: UITextField!
    
    var testd: String!
    var ref: DatabaseReference!
    var storage: StorageReference!
    private let db = Firestore.firestore()
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
    var autoScrollFlg = true
    
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
        
//        tableView.delegate = self
//        tableView.dataSource = self
        collectionView.delegate = self
        collectionView.dataSource = self
        self.textField.delegate = self
        
        // 背景色設定
        self.view.backgroundColor = UIColor.clear
//        tableView.backgroundColor = UIColor.clear
        inputWrap.backgroundColor = UIColor.clear
        textField.backgroundColor = UIColor.clear
        coverView.backgroundColor = UIColor.clear
        
        // セルの大きさを設定
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: collectionView.frame.width, height: 52)
        layout.minimumLineSpacing = 0
//        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        collectionView.collectionViewLayout = layout

        //グラデーションの開始色
        let startColor = UIColor(displayP3Red: 147/255, green: 6/255, blue: 229/255, alpha: 0.3)
        //グラデーションの開始色
        let endColor = UIColor(displayP3Red: 23/255, green: 232/255, blue: 252/255, alpha: 0.3)
        scrollView.setGradient(startColor: startColor, endColor: endColor, radius: 0)
        
//        self.tableView.rowHeight = UITableView.automaticDimension
        
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
        let chatXib = UINib(nibName: "CommunityChatCollectionViewCell", bundle: nil)
        collectionView.register(chatXib, forCellWithReuseIdentifier: "communityChatCell")
        
        db.collection("communities").document(communityId!).collection("messages").addSnapshotListener{ querySnapshot, error in
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
            self.collectionView.reloadData()
            // グラデーション設定
            let gradientLayer = CAGradientLayer()
            gradientLayer.frame = self.collectionView.superview!.bounds
            let clearColor = UIColor.clear.cgColor
            let whiteColor = UIColor.white.cgColor
            gradientLayer.colors = [clearColor, whiteColor, whiteColor]
            gradientLayer.locations = [0.45, 0.55, 1.0]
            self.collectionView.superview!.layer.mask = gradientLayer
            self.collectionView.backgroundColor = UIColor.clear
            DispatchQueue.main.async {
                self.collectionView.performBatchUpdates({
                    
                }) { (finished) in
                    let dif = self.collectionView.contentSize.height - self.collectionView.frame.size.height
                    if dif < 0 {
                        // 下詰め
                        self.collectionView.contentInset = UIEdgeInsets(top: dif * -1, left: 0, bottom: 0, right: 0)
                        return
                    } else {
                        // マージン0
                        self.collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
                        print(self.autoScrollFlg)
                        guard self.autoScrollFlg || subScrollFlg else {
                            return
                        }
                        self.collectionView.setContentOffset(CGPoint(x: self.collectionView.contentOffset.x, y: dif), animated: true)
                    }
                }
                
            }
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messageArr.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // セル生成
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "communityChatCell", for: indexPath) as! CommunityChatCollectionViewCell
        let imgView = cell.img
        let name = cell.name
        let message = cell.message
        
        cell.frame.size.width = collectionView.frame.width
        
        db.collection("users").document(messageArr[indexPath.row]["senderId"] as! String).getDocument { (document, error) in
            if let user = document.flatMap({
                $0.data().flatMap({ (data) in
                    return data
                })
            }) {
                name!.text = user["name"] as? String
                let imgRef = self.storage.child("users").child(user["img"] as! String)
                imgView!.sd_setImage(with: imgRef)
            }
        }
        
        let tapGesture = UserTapGestureRecognizer(
            target: self,
            action: #selector(ChatViewController.tapImg(_:)))
        
        tapGesture.user = (self.messageArr[indexPath.row]["senderId"] as! String)
        tapGesture.userDoc = messageArr[indexPath.row]
        
        imgView?.isUserInteractionEnabled = true
        imgView!.addGestureRecognizer(tapGesture)
        
        // 配色
//        cell.backgroundColor = UIColor.clear
        name!.backgroundColor = UIColor.clear
        message!.backgroundColor = UIColor.clear
        message!.text = (messageArr[indexPath.row]["message"] as! String)
        message!.sizeToFit()
        
        return cell
    }
    
    /// 横のスペース
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        
        return 0.0
        
    }
    
    /// 縦のスペース
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        
        return 0.0
        
    }
    
    // スクロールして途中で止まった場合のみ
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if decelerate == false {
            autoScrollFlg = false
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        guard collectionView.cellForItem(at: IndexPath(row: collectionView.numberOfItems(inSection: 0)-1, section: 0)) != nil else {
            autoScrollFlg = false
            return
        }
        if collectionView.contentOffset.y > 0 {
            autoScrollFlg = true
        }
        
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 52
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
    @objc func tapImg(_ sender: UserTapGestureRecognizer) {
        // IDチェック
        getId = sender.user!
        print(getId)
        print(RootTabBarController.UserId)
        if getId == RootTabBarController.UserId {
            return
        }
        self.performSegue(withIdentifier: "toProfileViewController", sender: sender.userDoc)// ページ遷移

    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toProfileViewController" {
            let profileViewController = segue.destination as! AccountViewController
            profileViewController.userId = getId
        }
    }
    
    // Enterを押したらキーボードが閉じる
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        let message = textField.text// 入力文字を取得
        if message == "" {
            return false
        }
        
        db.collection("communities").document(communityId).collection("messages").addDocument(
            data: ["senderId": RootTabBarController.UserId, "message": message!, "timestamp": Timestamp(date: Date())]
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
