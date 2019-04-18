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
        dbRef = Database.database().reference()
        self.senderId = RootTabBarController.userId
        self.senderDisplayName = RootTabBarController.userInfo["name"]!
        //メッセージデータの配列を初期化
        self.messages = []
        self.navigationController!.navigationBar.isHidden = false
        setupFirebase()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        automaticallyScrollsToMostRecentMessage = true
        
        //吹き出しの設定
        let bubbleFactory = JSQMessagesBubbleImageFactory()
        self.incomingBubble = bubbleFactory!.incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
        self.outgoingBubble = bubbleFactory!.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleBlue())

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

}
