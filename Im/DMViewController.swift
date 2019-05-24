//
//  DMViewController.swift
//  Im
//
//  Created by nobumitsu on 2019/04/14.
//  Copyright © 2019 im. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import FirebaseUI
import JSQMessagesViewController

class DMViewController: JSQMessagesViewController {
    
    private let db = Firestore.firestore()
    private let storageRef = Storage.storage().reference()
    var storage: StorageReference!
    var partnerId = ""
    var partnerData:[String:String] = [:]
    var createFlg = false
    var chatId = ""
    
    var messages: [JSQMessage]?
    var incomingBubble: JSQMessagesBubbleImage!
    var outgoingBubble: JSQMessagesBubbleImage!
    var incomingAvatar: JSQMessagesAvatarImage!
    var outgoingAvatar: JSQMessagesAvatarImage!
    
    override func viewWillAppear(_ animated: Bool) {
        // 初期化
        storage = Storage.storage().reference()
        
        // ユーザー情報セット
        self.senderId = RootTabBarController.userId
        self.senderDisplayName = RootTabBarController.userInfo["name"] as? String
        
        getPrivateChatId()
        
        //メッセージデータの配列を初期化
        self.messages = []
        // ナビバー表示
        self.navigationController!.navigationBar.isHidden = false
        self.title = partnerData["name"]
        // ナビゲーションバーのテキストを変更する
        self.navigationController?.navigationBar.titleTextAttributes = [
            // 文字の色
            .foregroundColor: UIColor.white
        ]
        setupFirebase()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        automaticallyScrollsToMostRecentMessage = true
        
        self.view.setGradientLayer()
        self.collectionView.backgroundColor = UIColor.clear// 画面の背景色
        self.inputToolbar.backgroundColor = UIColor.clear
        self.inputToolbar.contentView.backgroundColor = UIColor.clear
        self.inputToolbar.contentView.textView.backgroundColor = UIColor(displayP3Red: 255/255, green: 255/255, blue: 255/255, alpha: 0)
        
        // 入力テキストの文字色
        self.inputToolbar.contentView.textView.tintColor = UIColor.clear
        // 送信ボタンのテキスト変更
        self.inputToolbar.contentView.rightBarButtonItem.setTitle("送信", for: .normal)
        // 送信ボタンの文字色
        self.inputToolbar.contentView.rightBarButtonItem.setTitleColor(UIColor(displayP3Red: 255/255, green: 255/255, blue: 255/255, alpha: 0.7), for: .disabled)
        // 送信ボタンの文字色 アクティブ
        self.inputToolbar.contentView.rightBarButtonItem.setTitleColor(UIColor.white, for: .normal)
        // 入力欄の背景色
        inputToolbar.setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)
        inputToolbar.setShadowImage(UIImage(), forToolbarPosition: .any)
        
        setupStyle()
        
    }
    
    func getPrivateChatId() {
        let val = RootTabBarController.userId.compare(partnerId).rawValue
        if val < 0 {
            chatId = RootTabBarController.userId + partnerId
        } else {
            chatId = partnerId + RootTabBarController.userId
        }
    }
    
    func setupStyle() {
        // 境界線追加
        inputToolbar.contentView.isOpaque = false
        inputToolbar.contentView.layer.addBorder(edge: .top, color: UIColor.white, thickness: 0.5)
        // プレースホルダー
        inputToolbar.contentView.textView.placeHolder = "メッセージを入力"
        // テキストビューの文字色
        inputToolbar.contentView.textView.textColor = UIColor.white
        // 境界線削除
        inputToolbar.contentView.textView.layer.borderWidth = 0
        // 画像アイコンの変更
        inputToolbar.contentView.leftBarButtonItem.setImage(UIImage(named: "PostImg"), for: .normal)
        inputToolbar.contentView.leftBarButtonItemWidth = inputToolbar.contentView.leftBarButtonContainerView.frame.size.height / 128 * 137
        //吹き出しの設定
        let bubbleFactory = JSQMessagesBubbleImageFactory()
        incomingBubble = bubbleFactory!.incomingMessagesBubbleImage(with: UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.2))
        outgoingBubble = bubbleFactory!.outgoingMessagesBubbleImage(with: UIColor.white)
    }
    
    func setupFirebase() {
        db.collection("privateChat").document(chatId).collection("messages").addSnapshotListener{ querySnapshot, error in
            guard let documents = querySnapshot?.documents else {
                print("Error fetching documents: \(error!)")
                return
            }
            
            guard documents.count > 0 else {
                print("カウントぜろ")
                return
            }

            guard let snapshot = querySnapshot else {
                print("Error fetching documents: \(error!)")
                return
            }

            snapshot.documentChanges.forEach { diff in
                switch diff.type {
                    case .added:
                        let messageData = diff.document.data()
                        var name = ""
                        if messageData["senderId"] as! String == RootTabBarController.userId {
                            name = RootTabBarController.userInfo["name"] as! String
                        } else {
                            name = self.partnerData["name"] ?? ""
                        }
                        let message = JSQMessage(senderId: messageData["senderId"] as? String, displayName: name, text: messageData["message"] as? String)
                        self.messages?.append(message!)
                        //メッセージの送信処理を完了する(画面上にメッセージが表示される)
                        self.finishReceivingMessage(animated: true)
                        
                        if self.createFlg { return }
                        
                        self.db.collection("privateChat").document(self.chatId).getDocument { (document, error) in
                            if let document = document, document.exists {
                                self.createFlg = true
                                print("ルーム作成")
                            } else {
                                print("Document does not exist")
                            }
                        }
                    print("追加した \(diff.document.data())")
                    default:
                        break
                }
            }

        }

    }
    
//    override func didPressAccessoryButton(_ sender: UIButton!) {
//        <#code#>
//    }
    
    // 送信ボタンが押された時に呼ばれるメソッド
    override func didPressSend(_ button: UIButton, withMessageText text: String, senderId: String, senderDisplayName: String, date: Date) {
        
        guard text != "" else { return }
        
        var ref: DocumentReference? = nil
        let timestamp = FieldValue.serverTimestamp()
        ref = db.collection("privateChat").document(chatId).collection("messages").addDocument(data: [
            "senderId": RootTabBarController.userId,
            "type": "text",
            "message": text,
            "createTime": timestamp
        ]) { err in
            if let err = err {
                print("Error adding document: \(err)")
            } else {
                print("Document added with ID: \(ref!.documentID)")
                if self.createFlg {
                    
                    self.db.collection("privateChat").document(self.chatId).setData([
                        "lastMessage": text, "updateTime": timestamp, "type": "text", "senderId": RootTabBarController.userId
                    ])
                    
                } else {
                    // トランザクション
                    self.db.runTransaction({ (transaction, errorPointer) -> Any? in
                        
                        // 個人チャットルーム作成
                        transaction.setData(
                            ["lastMessage": text, "updateTime": timestamp, "type": "text", "senderId": RootTabBarController.userId],
                            forDocument: self.db.collection("privateChat").document(self.chatId)
                        )
                        
                        // ユーザーのプライベートチャットリストに追加
                        let partnerRef: DocumentReference = self.db.collection("users").document(self.partnerId)
                        let privateChatRef: DocumentReference = self.db.collection("privateChat").document(self.chatId)
                        transaction.setData(
                            ["partnerRef" : partnerRef, "privateChatRef": privateChatRef],
                            forDocument: self.db.document("users/\(RootTabBarController.userId)/privateChatPartners/\(String(describing: self.partnerId))")
                        )
                        
                        // パートナーのプライベートチャットリストに追加
                        let userRef: DocumentReference = self.db.collection("users").document(RootTabBarController.userId)
                        transaction.setData(
                            ["partnerRef" : userRef, "privateChatRef": privateChatRef],
                            forDocument: self.db.document("users/\(self.partnerId)/privateChatPartners/\(RootTabBarController.userId)")
                        )
                        
                        return nil
                    }) { (object, error) in
                        if let error = error {
                            print("Transaction failed: \(error)")
                        } else {
                            self.createFlg = true
                            print("Transaction successfully committed!")
                        }
                    }
                }

            }
        }
        
        //メッセージの送信処理を完了する(画面上にメッセージが表示される)
        self.finishReceivingMessage(animated: true)
        
        //textFieldをクリアする
        self.inputToolbar.contentView.textView.text = ""
        
        //キーボードを閉じる
        self.view.endEditing(true)
    }
    
    // アイテムごとに参照するメッセージデータを返す
    override func collectionView(_ collectionView: JSQMessagesCollectionView, messageDataForItemAt indexPath: IndexPath) -> JSQMessageData {
        return messages![indexPath.item]
    }
    
    // アイテムごとのMessageBubble(背景)を返す
    override func collectionView(_ collectionView: JSQMessagesCollectionView, messageBubbleImageDataForItemAt indexPath: IndexPath) -> JSQMessageBubbleImageDataSource {
        let message = self.messages?[indexPath.item]
        if message?.senderId == self.senderId {
            return self.outgoingBubble
        }
        return self.incomingBubble
    }
    
    // アイテムごとにアバター画像を返す
    override func collectionView(_ collectionView: JSQMessagesCollectionView, avatarImageDataForItemAt indexPath: IndexPath) -> JSQMessageAvatarImageDataSource? {
        let message = self.messages?[indexPath.item]
        if message?.senderId == self.senderId {
            return self.outgoingAvatar
        }
        return self.incomingAvatar
    }
    
    // アイテムの総数を返す
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages!.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let message = messages![indexPath.row]
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        
        // 角丸にする
        cell.avatarImageView.layer.cornerRadius = cell.avatarImageView.frame.size.width * 0.5
        cell.avatarImageView.clipsToBounds = true
        // ユーザー
        if message.senderId == self.senderId {
            let userIcon = self.storage.child("users").child(RootTabBarController.userInfo["img"] as! String)
            cell.avatarImageView.sd_setImage(with: userIcon)
            cell.textView!.textColor = UIColor(red: 51/255, green: 51/255, blue: 51/255, alpha: 1)
        }
        else {
        // 相手
            let partnerIcon = self.storage.child("users").child(partnerData["img"]!)
            cell.avatarImageView.sd_setImage(with: partnerIcon)
            cell.textView!.textColor = UIColor.white
        }
        
        return cell
    }
    
    
}

extension CALayer {
    
    func addBorder(edge: UIRectEdge, color: UIColor, thickness: CGFloat) {
        
        let border = CALayer()
        
        switch edge {
        case .top:
            border.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: thickness)
        case .bottom:
            border.frame = CGRect(x: 0, y: frame.height - thickness, width: frame.width, height: thickness)
        case .left:
            border.frame = CGRect(x: 0, y: 0, width: thickness, height: frame.height)
        case .right:
            border.frame = CGRect(x: frame.width - thickness, y: 0, width: thickness, height: frame.height)
        default:
            break
        }
        
        border.backgroundColor = color.cgColor;
        
        addSublayer(border)
    }
}


extension UIView {
    func parentViewController() -> UIViewController? {
        var parentResponder: UIResponder? = self
        while true {
            guard let nextResponder = parentResponder?.next else { return nil }
            if let viewController = nextResponder as? UIViewController {
                return viewController
            }
            parentResponder = nextResponder
        }
    }
}
