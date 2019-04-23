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
    
    var dbRef:DatabaseReference!
    var storage: StorageReference!
    var receiver: String!
    var receiverInfo:[String:String] = [:]
    var dmId = ""
    var dmFlg = false// DMがスタートしているかどうか
    
    var selectedLbl: String!
    var messages: [JSQMessage]?
    var incomingBubble: JSQMessagesBubbleImage!
    var outgoingBubble: JSQMessagesBubbleImage!
    var incomingAvatar: JSQMessagesAvatarImage!
    var outgoingAvatar: JSQMessagesAvatarImage!
    
    override func viewWillAppear(_ animated: Bool) {
        // 初期化
        dbRef = Database.database().reference()
        storage = Storage.storage().reference()
        // ユーザー情報セット
        self.senderId = RootTabBarController.userId
        self.senderDisplayName = RootTabBarController.userInfo["name"]!
        
        //メッセージデータの配列を初期化
        self.messages = []
        // ナビバー表示
        self.navigationController!.navigationBar.isHidden = false
        self.title = receiverInfo["name"]
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
        self.collectionView.backgroundColor = UIColor.black// 画面の背景色
        // テキストフィールドの背景色
        self.inputToolbar.contentView.textView.backgroundColor = UIColor(displayP3Red: 255/255, green: 255/255, blue: 255/255, alpha: 0.0)
        // 入力テキストの文字色
        self.inputToolbar.contentView.textView.tintColor = UIColor.white
        // 送信ボタンのテキスト変更
        self.inputToolbar.contentView.rightBarButtonItem.setTitle("送信", for: .normal)
        // 送信ボタンの文字色
        self.inputToolbar.contentView.rightBarButtonItem.tintColor = UIColor.white
        // 送信ボタンの文字色 アクティブ
        self.inputToolbar.contentView.rightBarButtonItem.setTitleColor(UIColor.white, for: .normal)
        // 入力欄の背景色
        self.inputToolbar.contentView.backgroundColor = UIColor.black
        // 境界線追加
        self.inputToolbar.contentView.layer.addBorder(edge: .top, color: UIColor.white, thickness: 0.5)
        // プレースホルダー
        self.inputToolbar.contentView.textView.placeHolder = "メッセージを入力"
        // テキストビューの文字色
        self.inputToolbar.contentView.textView.textColor = UIColor.white
        // 境界線削除
        self.inputToolbar.contentView.textView.layer.borderWidth = 0
        // 画像アイコンの変更
        self.inputToolbar.contentView.leftBarButtonItem.setImage(UIImage(named: "PostImg"), for: .normal)
        self.inputToolbar.contentView.leftBarButtonItemWidth = inputToolbar.contentView.leftBarButtonContainerView.frame.size.height / 128 * 137
        //吹き出しの設定
        let bubbleFactory = JSQMessagesBubbleImageFactory()
//        self.incomingBubble = bubbleFactory!.incomingMessagesBubbleImage(with: UIColor(red: 229/255, green: 229/255, blue: 229/255, alpha: 1))
        self.incomingBubble = bubbleFactory!.incomingMessagesBubbleImage(with: UIColor.white)
//        self.outgoingBubble = bubbleFactory!.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleBlue())
        self.outgoingBubble = bubbleFactory!.outgoingMessagesBubbleImage(with: UIColor(red: 23/255, green: 232/255, blue: 252/255, alpha: 1))
        

    }
    
    func setupFirebase() {
        dbRef.child("dmMembers").child(RootTabBarController.userId).child(receiver).observeSingleEvent(of: .value, with: { (snapshot) in
            // 過去にDMしたことがある場合
            if snapshot.exists() {
                self.dmFlg = true
                self.dmId = snapshot.value as! String
                // メッセージ取得
                self.dbRef.child("directMessages").child(self.dmId).observe(.childAdded, with: { (snapshot) -> Void in
                    let val = snapshot.value as! [String: String]
                    var name = ""
                    if val["sender"] == self.senderId {
                        name = RootTabBarController.userInfo["name"]!
                    } else  {
                        name = self.receiverInfo["name"]!
                    }
                    let message = JSQMessage(senderId: val["sender"], displayName: name, text: val["message"])
                    self.messages?.append(message!)
                    self.finishReceivingMessage()
                })
            }
        })
    }
    
    // Sendボタンが押された時に呼ばれるメソッド
    override func didPressSend(_ button: UIButton, withMessageText text: String, senderId: String, senderDisplayName: String, date: Date) {

        func postDM(dmKey:String) {
            let messageKey = dbRef.child("directMessages").child(dmKey).childByAutoId().key
            // メッセージをDBに追加
            dbRef.child("directMessages").child(dmKey).child(messageKey!).setValue(["sender":senderId,"message":text]) {
                (error:Error?, ref:DatabaseReference) in
                if error != nil {
                    return
                }
            }
        }
        
        // DMのやりとりが開始している場合
        if dmFlg {
            postDM(dmKey: dmId)
        } else {
            // DMが開始しているか再度確認
            dbRef.child("dmMembers").child(RootTabBarController.userId).child(receiver).observeSingleEvent(of: .value, with: { (snapshot) in
                self.dmFlg = true
                // 相手から送られてDMが開始している場合
                if snapshot.exists() {
                    self.dmId = snapshot.value as! String
                    postDM(dmKey: self.dmId)
                } else {
                // これからDMが開始する場合
                    // ユニークキー自動生成
                    self.dmId = self.dbRef.child("directMessages").childByAutoId().key!
                    // DMのリストに追加
                    self.dbRef.child("dmMembers").child(RootTabBarController.userId).setValue([self.receiver: self.dmId])
                    self.dbRef.child("dmMembers").child(self.receiver).setValue([RootTabBarController.userId: self.dmId])
                    postDM(dmKey: self.dmId)
                }
                // このDMの監視スタート
                self.dbRef.child("directMessages").child(self.dmId).observe(.childAdded, with: { (snapshot) -> Void in
                    let val = snapshot.value as! [String: String]
                    var name = ""
                    if val["sender"] == self.senderId {
                        name = RootTabBarController.userInfo["name"]!
                    } else  {
                        name = self.receiverInfo["name"]!
                    }
                    let message = JSQMessage(senderId: val["sender"], displayName: name, text: val["message"])
                    self.messages?.append(message!)
                    self.finishReceivingMessage()
                })
            })
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
            let userIcon = self.storage.child("users").child(RootTabBarController.userInfo["img"]!)
            cell.avatarImageView.sd_setImage(with: userIcon)
//            cell.textView!.textColor = UIColor.white
            cell.textView!.textColor = UIColor(red: 51/255, green: 51/255, blue: 51/255, alpha: 1)
        }
        else {
        // 相手
            let receiverIcon = self.storage.child("users").child(receiverInfo["img"]!)
            cell.avatarImageView.sd_setImage(with: receiverIcon)
            cell.textView!.textColor = UIColor(red: 51/255, green: 51/255, blue: 51/255, alpha: 1)
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
