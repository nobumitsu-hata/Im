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
import Photos
import IDMPhotoBrowser
import ImageViewer
import OneSignal
import FirebaseFirestore

class DMViewController: JSQMessagesViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, IDMPhotoBrowserDelegate {
    
    private let db = Firestore.firestore()
    private let storageRef = Storage.storage().reference()
    var storage: StorageReference!
    var partnerId = ""
    var partnerData:[String:Any] = [:]
    var createFlg = false
    var chatId = ""
    var startTimestamp:TimeInterval!
    var loadTimestamp:TimeInterval!
    var firstFlg = true
    var loadingFlg = true
    var urlArr:[String] = []
    var scrollFlg = true
    var listener: ListenerRegistration!
    
    var messages: [JSQMessage]?
    var incomingBubble: JSQMessagesBubbleImage!
    var outgoingBubble: JSQMessagesBubbleImage!
    var incomingAvatar: JSQMessagesAvatarImage!
    var outgoingAvatar: JSQMessagesAvatarImage!
    
    override func viewWillAppear(_ animated: Bool) {
        tabBarController?.tabBar.isHidden = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // ユーザー情報セット
        self.senderId = RootTabBarController.UserId
        self.senderDisplayName = RootTabBarController.UserInfo["name"] as? String

        // 初期化
        self.messages = []
        self.collectionView.reloadData()
        startTimestamp = Date().timeIntervalSince1970
        loadTimestamp = startTimestamp
        getPrivateChatId()
        storage = Storage.storage().reference()
        
        automaticallyScrollsToMostRecentMessage = true
        
        // fix for iPhoneX
        let constraint = perform(Selector(("toolbarBottomLayoutGuide")))?.takeUnretainedValue() as! NSLayoutConstraint
        constraint.priority = UILayoutPriority(rawValue: 1000)
        inputToolbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        // end of iPhoneX fix
        
        navigationController?.delegate = self
        // ナビバー表示
        self.navigationController!.navigationBar.isHidden = false
        self.title = partnerData["name"] as? String
        // ナビゲーションバーのテキストを変更する
        self.navigationController?.navigationBar.titleTextAttributes = [
            // 文字の色
            .foregroundColor: UIColor.white
        ]
        
        setupStyle()
        setupFirebase()
        loadMoreMessages()
        
    }
    
    // fix for iPhoneX
    override func viewDidLayoutSubviews() {
        perform(Selector(("jsq_updateCollectionViewInsets")))
    }
    // end of iPhoneX fix
    
    func getPrivateChatId() {
        let val = RootTabBarController.UserId.compare(partnerId).rawValue
        if val < 0 {
            chatId = RootTabBarController.UserId + partnerId
        } else {
            chatId = partnerId + RootTabBarController.UserId
        }
    }
    
    func setupStyle() {
        // 境界線追加
        inputToolbar.contentView.isOpaque = false
        inputToolbar.contentView.layer.addBorder(edge: .top, color: UIColor.white, thickness: 0.5)
        // プレースホルダー
        inputToolbar.contentView.textView.placeHolder = "メッセージを入力"
        // テキストビューの文字色
        inputToolbar.contentView.textView.textColor = UIColor(red: 51/255, green: 51/255, blue: 51/255, alpha: 1.0)
        // 境界線削除
        inputToolbar.contentView.textView.layer.borderWidth = 0
        // 画像アイコンの変更
        inputToolbar.contentView.leftBarButtonItem.setImage(UIImage(named: "PostImg"), for: .normal)
        inputToolbar.contentView.leftBarButtonItemWidth = inputToolbar.contentView.leftBarButtonContainerView.frame.size.height / 128 * 137
        //吹き出しの設定
        let bubbleFactory = JSQMessagesBubbleImageFactory()
        incomingBubble = bubbleFactory!.incomingMessagesBubbleImage(with: UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.2))
        outgoingBubble = bubbleFactory!.outgoingMessagesBubbleImage(with: UIColor.white)
        // ユーザーのアバターを消す
        collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
        
        // 入力テキストの文字色
        self.inputToolbar.contentView.textView.tintColor = UIColor.clear
        // 送信ボタンのテキスト変更
        self.inputToolbar.contentView.rightBarButtonItem.setTitle("送信", for: .normal)
        // 送信ボタンの文字色
        self.inputToolbar.contentView.rightBarButtonItem.setTitleColor(UIColor(displayP3Red: 23/255, green: 232/255, blue: 252/255, alpha: 1.0), for: .disabled)
        // 送信ボタンの文字色 アクティブ
        self.inputToolbar.contentView.rightBarButtonItem.setTitleColor(UIColor(displayP3Red: 23/255, green: 232/255, blue: 252/255, alpha: 1.0), for: .normal)
        // 入力欄の背景色
        inputToolbar.setBackgroundImage(UIImage(named: "White"), forToolbarPosition: .any, barMetrics: .default)
        inputToolbar.setShadowImage(UIImage(), forToolbarPosition: .any)
        collectionView.removeConstraints(collectionView!.constraints)
        
        self.view.setGradientLayer()
        self.collectionView.backgroundColor = UIColor.clear
        self.inputToolbar.backgroundColor = UIColor.white
        self.inputToolbar.contentView.backgroundColor = UIColor.white
        self.inputToolbar.contentView.textView.backgroundColor = UIColor(displayP3Red: 255/255, green: 255/255, blue: 255/255, alpha: 0)
        
    }
    
    
    func setupFirebase() {
        listener = db.collection("privateChat").document(chatId).collection("messages").whereField("createTime", isGreaterThan: startTimestamp).addSnapshotListener{ querySnapshot, error in

            guard let documents = querySnapshot?.documents else {
                print("Error fetching documents: \(error!)")
                return
            }

            guard documents.count > 0 else { return }
            guard let snapshot = querySnapshot else {
                print("Error fetching documents: \(error!)")
                return
            }
            
            snapshot.documentChanges.forEach { diff in
                switch diff.type {
                    case .added:
                        
                        let messageData = diff.document.data()
                        
                        // 名前
                        var name = ""
                        if messageData["senderId"] as! String == RootTabBarController.UserId {
                            name = RootTabBarController.UserInfo["name"] as! String
                        } else {
                            name = self.partnerData["name"] as! String
                        }
                        
                        // 日付
                        let date = Date(timeIntervalSince1970: messageData["createTime"] as! TimeInterval)
                        // メッセージ
                        // テキスト
                        if messageData["type"] as! String == "text" {
                            
                            let message = JSQMessage(senderId: messageData["senderId"] as? String, senderDisplayName: name, date: date, text: messageData["message"] as? String)
                            self.urlArr.append("")
                            self.messages?.append(message!)
                            
                            
                        } else {
                        // 画像
                            let mediaItem = PhotoMediaItem(image: nil)
                            self.downLoadImage2(imageUrl: messageData["imgUrl"] as! String) { (image) in
                                if image != nil {
                                    self.urlArr.append(messageData["imgUrl"] as! String)
                                    mediaItem?.image = image
                                    self.collectionView.reloadData()
                                }
                            }
                            
                            let message = JSQMessage(senderId: messageData["senderId"] as? String, senderDisplayName: name, date: date, media: mediaItem)
                            self.messages?.append(message!)
                        }
                        
                        if messageData["senderId"] as! String == RootTabBarController.UserId || self.scrollFlg {
                            //メッセージの送信処理を完了する(画面上にメッセージが表示される)
                            self.finishReceivingMessage(animated: true)
                        } else {
                            self.collectionView.reloadData()
                        }
                        self.db.collection("users").document(RootTabBarController.UserId).collection("privateChatPartners").document(self.partnerId).updateData(["unreadCount": 0, "readTime": messageData["createTime"] as! TimeInterval])

                        if self.createFlg { return }
                        
                        self.db.collection("privateChat").document(self.chatId).getDocument { (document, error) in
                            if let document = document, document.exists {
                                self.createFlg = true
                                print("Room exist")
                            } else {
                                print("Document does not exist")
                            }
                        }
                    default:
                        break
                }
            }

        }

    }
    
    func loadMoreMessages() {
        db.collection("privateChat").document(chatId).collection("messages").whereField("createTime", isLessThan: loadTimestamp).order(by: "createTime", descending: true).limit(to: 10).getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
                return
            }
            
            guard querySnapshot!.documents.count > 0 else {
                print("empty")
                return
            }
            
            if querySnapshot!.documents.count < 10 {
                self.loadingFlg = false
                print("No more")
            }
            
            var unreadCountFlg = true
            for document in querySnapshot!.documents {
                
                print("\(document.documentID) => \(document.data())")
                let messageData = document.data()
                
                // 名前
                var name = ""
                if messageData["senderId"] as! String == RootTabBarController.UserId {
                    name = RootTabBarController.UserInfo["name"] as! String
                } else {
                    name = self.partnerData["name"] as! String
                }
                
                // 日付
                self.loadTimestamp = messageData["createTime"] as? TimeInterval
                let date = Date(timeIntervalSince1970: messageData["createTime"] as! TimeInterval)

                // メッセージ
                // テキスト
                if messageData["type"] as! String == "text" {
                    let message = JSQMessage(senderId: messageData["senderId"] as? String, senderDisplayName: name, date: date, text: messageData["message"] as? String)
                    self.urlArr.insert("", at: 0)
                    self.messages?.insert(message!, at: 0)
                } else {
                // 画像
                    let mediaItem = PhotoMediaItem(image: nil)
                    mediaItem?.appliesMediaViewMaskAsOutgoing = self.returnOutgoingStatusForUser(senderId: messageData["senderId"] as? String ?? "")
                    self.downLoadImage2(imageUrl: messageData["imgUrl"] as! String) { (image) in
                        if image != nil {
                            self.urlArr.append(messageData["imgUrl"] as! String)
                            mediaItem?.image = image
                            self.collectionView.reloadData()
                        }
                    }
                    
                    let message = JSQMessage(senderId: messageData["senderId"] as? String, senderDisplayName: name, date: date, media: mediaItem)
                    self.messages?.insert(message!, at: 0)
                   
                }
                
                if unreadCountFlg {
                    self.db.collection("users").document(RootTabBarController.UserId).collection("privateChatPartners").document(self.partnerId).updateData(
                        ["unreadCount": 0, "readTime": messageData["createTime"] as! TimeInterval]
                    )
                    unreadCountFlg = false
                }

            }
            
            
            
            if self.firstFlg {
                //メッセージの送信処理を完了する(画面上にメッセージが表示される)
                self.finishReceivingMessage(animated: false)
                self.firstFlg = false
                
            } else {
                let oldOffset = self.collectionView.contentOffset.y
                let oldHeight = self.collectionView.contentSize.height
                let reverseOffset = oldHeight - oldOffset
                self.collectionView.reloadData()
                self.collectionView.layoutIfNeeded()
                self.collectionView.contentOffset = CGPoint(x: 0.0, y: self.collectionView.contentSize.height - reverseOffset)
                self.collectionView.setContentOffset(CGPoint(x: 0.0, y: self.collectionView.contentSize.height - reverseOffset), animated: true)

            }
            
            if self.createFlg { return }
            
            self.db.collection("privateChat").document(self.chatId).getDocument { (document, error) in
                if let document = document, document.exists {
                    self.createFlg = true
                    print("Room exist")
                } else {
                    print("Document does not exist")
                }
            }
            
        }
    }
    
    func returnOutgoingStatusForUser(senderId: String) -> Bool {
        return senderId == RootTabBarController.UserId
    }
    
    func downLoadImage(at imageUrl: URL, completion: @escaping(_ image: UIImage?) -> Void) {
        let ref = Storage.storage().reference(forURL: imageUrl.absoluteString)
        let megaByte = Int64(1 * 1024 * 1024)
        
        ref.getData(maxSize: megaByte) { data, error in
            guard let imageData = data else {
                completion(nil)
                return
            }
            
            completion(UIImage(data: imageData))
        }
    }
    
    func downLoadImage2(imageUrl: String, completion: @escaping(_ image: UIImage?) -> Void) {
        let imageURL = NSURL(string: imageUrl)
        let imageFileName = (imageUrl.components(separatedBy: "%").last!).components(separatedBy: "?").first!
        
        if fileExistsAtPath(path: imageFileName) {
            
            if let contentsOfFile = UIImage(contentsOfFile: fileInDocumentsDirectory(fileName: imageFileName)) {
                completion(contentsOfFile)
            } else {
                print("失敗")
                completion(nil)
            }
        } else {
            let downloadQueue = DispatchQueue(label: "imageDownloadQueue")
            downloadQueue.async {
                let data = NSData(contentsOf: imageURL! as URL)
                
                if data != nil {
                    var docURL = self.getDocumentsURL()
                    docURL = docURL.appendingPathComponent(imageFileName, isDirectory: false)
                    data!.write(to: docURL, atomically: true)
                    let imageToReturn = UIImage(data: data! as Data)
                    DispatchQueue.main.async {
                        completion(imageToReturn!)
                    }
                } else {
                    DispatchQueue.main.async {
                        print("no image in database")
                        completion(nil)
                    }
                }
            }
        }
    }
    
    func fileInDocumentsDirectory(fileName: String) -> String {
        let fileURL = getDocumentsURL().appendingPathComponent(fileName)
        return fileURL.path
    }
    
    func getDocumentsURL() -> URL {
        let documentURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last
        return documentURL!
    }
    
    func fileExistsAtPath(path:String) -> Bool {
        var doesExist = false
        let filePath = fileInDocumentsDirectory(fileName: path)
        let fileManager = FileManager.default
        
        if fileManager.fileExists(atPath: filePath) {
            doesExist = true
        } else {
            doesExist = false
        }
        
        return doesExist
    }
    
    // ピクチャーアイコンが押された時
    override func didPressAccessoryButton(_ sender: UIButton!) {
        let camera = Camera(delegate_: self)
        camera.presentPhotoLibrary(target: self, canEdit: false)
    }
    
    // 送信ボタンが押された時に呼ばれるメソッド
    override func didPressSend(_ button: UIButton, withMessageText text: String, senderId: String, senderDisplayName: String, date: Date) {
        
        guard text != "" else { return }
        
        let timestamp = Date().timeIntervalSince1970

        if self.createFlg {
            let partnerChatRef = db.collection("users").document(partnerId).collection("privateChatPartners").document(RootTabBarController.UserId)
            self.db.runTransaction({ (transaction, errorPointer) -> Any? in
                
                let partnerChatDocument: DocumentSnapshot
                do {
                    try partnerChatDocument = transaction.getDocument(partnerChatRef)
                } catch let fetchError as NSError {
                    errorPointer?.pointee = fetchError
                    return nil
                }
                
                guard let oldUnreadCount = partnerChatDocument.data()?["unreadCount"] as? Int else {
                    let error = NSError(
                        domain: "AppErrorDomain",
                        code: -1,
                        userInfo: [
                            NSLocalizedDescriptionKey: "Unable to retrieve population from snapshot \(partnerChatDocument)"
                        ]
                    )
                    errorPointer?.pointee = error
                    return nil
                }

                
                // メッセージ追加
                let newRef = self.db.collection("privateChat").document(self.chatId).collection("messages").document()
                transaction.setData(
                    ["senderId": RootTabBarController.UserId,"type": "text","message": text,"createTime": timestamp],
                    forDocument: newRef
                )
                
                // プライベートチャット 最新更新
                transaction.setData(
                    ["lastMessage": text, "updateTime": timestamp, "type": "text", "senderId": RootTabBarController.UserId],
                    forDocument: self.db.collection("privateChat").document(self.chatId)
                )
                
                // バッジカウント追加
                transaction.updateData(["unreadCount":  oldUnreadCount + 1], forDocument: partnerChatRef)
                
                return nil
            }) { (object, error) in
                if let error = error {
                    print("Transaction failed: \(error)")
                } else {
                    self.createFlg = true
                    print("Transaction successfully committed!")
                    OneSignal.postNotification(["contents": ["en": "\(RootTabBarController.UserInfo["name"] as! String)さんからメッセージが届きました"], "ios_badgeType" : "Increase", "ios_badgeCount" : 1, "include_player_ids" : [self.partnerData["pushId"] as! String], "content_available":  true])
                }
            }
            
        } else {
            
            self.db.runTransaction({ (transaction, errorPointer) -> Any? in
                
                // メッセージ追加
                let newRef = self.db.collection("privateChat").document(self.chatId).collection("messages").document()
                transaction.setData(
                    ["senderId": RootTabBarController.UserId,"type": "text","message": text,"createTime": timestamp],
                    forDocument: newRef
                )
                
                // 個人チャットルーム作成
                transaction.setData(
                    ["lastMessage": text, "updateTime": timestamp, "type": "text", "senderId": RootTabBarController.UserId],
                    forDocument: self.db.collection("privateChat").document(self.chatId)
                )
                
                // ユーザーのプライベートチャットリストに追加
                let partnerRef: DocumentReference = self.db.collection("users").document(self.partnerId)
                let privateChatRef: DocumentReference = self.db.collection("privateChat").document(self.chatId)
                transaction.setData(
                    ["partnerRef" : partnerRef, "privateChatRef": privateChatRef, "unreadCount": 0, "readTime": timestamp],
                    forDocument: self.db.document("users/\(RootTabBarController.UserId)/privateChatPartners/\(String(describing: self.partnerId))")
                )
                
                // パートナーのプライベートチャットリストに追加
                let userRef: DocumentReference = self.db.collection("users").document(RootTabBarController.UserId)
                transaction.setData(
                    ["partnerRef" : userRef, "privateChatRef": privateChatRef, "unreadCount": 1, "readTime": TimeInterval(0)],
                    forDocument: self.db.document("users/\(self.partnerId)/privateChatPartners/\(RootTabBarController.UserId)")
                )
                
                return nil
            }) { (object, error) in
                if let error = error {
                    print("Transaction failed: \(error)")
                } else {
                    self.createFlg = true
                    OneSignal.postNotification(["contents": ["en": "\(RootTabBarController.UserInfo["name"] as! String)さんからメッセージが届きました"], "ios_badgeType" : "Increase", "ios_badgeCount" : 1, "include_player_ids" : [self.partnerData["pushId"] as! String]])
                    print("Transaction successfully committed!")
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "fromPrivateChatToOtherProfile" {
            let profileViewController = segue.destination as! OtherProfileViewController
            profileViewController.userId = partnerId
            profileViewController.fromWhere = "privateChat"
        }
    }
    
    // スクロールして途中で止まった場合のみ
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if decelerate == false {
            scrollFlg = false
        }
    }
    
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {

        if scrollView.contentOffset.y <= 0 {
            if loadingFlg {
                loadMoreMessages()
            }
            scrollFlg = false
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {

        guard collectionView.cellForItem(at: IndexPath(row: collectionView.numberOfItems(inSection: 0)-1, section: 0)) != nil else {
            return
        }
        if collectionView.contentOffset.y > 0 {
            scrollFlg = true
        }
    }
    
    // MARK: UIImagePickerController delegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        var picture = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
        
        if picture?.size.width ?? 0 > CGFloat(1024) {
            let aspect = picture!.size.height / picture!.size.width
            picture = picture?.resize(size: CGSize(width: CGFloat(1024), height: CGFloat(1024) * aspect))
        }

        if let imgData = picture?.jpegData(compressionQuality: 0.7) {
            
            let date = Date().toStringDateImg()
            let fileName = RootTabBarController.UserId + date + ".jpg"
            let meta = StorageMetadata()
            meta.contentType = "image/jpeg"
            let uploadRef = storageRef.child("privateChat").child(chatId).child(fileName)
            uploadRef.putData(imgData, metadata: meta, completion: { metaData, error in
                
                if error != nil {
                    print(error!.localizedDescription)
                    return
                }
                
                var downloadUrl = ""
                uploadRef.downloadURL { (url, error) in
                    guard let downloadURL = url else {
                        // Uh-oh, an error occurred!
                        return
                    }
                    downloadUrl = downloadURL.absoluteString
                    
                    let timestamp = Date().timeIntervalSince1970
                    
                    if self.createFlg {
                        let partnerChatRef = self.db.collection("users").document(self.partnerId).collection("privateChatPartners").document(RootTabBarController.UserId)
                        self.db.runTransaction({ (transaction, errorPointer) -> Any? in
                            
                            let partnerChatDocument: DocumentSnapshot
                            do {
                                try partnerChatDocument = transaction.getDocument(partnerChatRef)
                            } catch let fetchError as NSError {
                                errorPointer?.pointee = fetchError
                                return nil
                            }
                            
                            guard let oldUnreadCount = partnerChatDocument.data()?["unreadCount"] as? Int else {
                                let error = NSError(
                                    domain: "AppErrorDomain",
                                    code: -1,
                                    userInfo: [
                                        NSLocalizedDescriptionKey: "Unable to retrieve population from snapshot \(partnerChatDocument)"
                                    ]
                                )
                                errorPointer?.pointee = error
                                return nil
                            }
                            
                            
                            // メッセージ追加
                            let newRef = self.db.collection("privateChat").document(self.chatId).collection("messages").document()
                            transaction.setData(
                                ["senderId": RootTabBarController.UserId, "type": "img", "imgUrl": downloadUrl, "message": fileName, "createTime": timestamp],
                                forDocument: newRef
                            )
                            
                            // プライベートチャット 最新更新
                            transaction.setData(
                                ["lastMessage": fileName, "updateTime": timestamp, "type": "img", "senderId": RootTabBarController.UserId],
                                forDocument: self.db.collection("privateChat").document(self.chatId)
                            )
                            
                            // バッジカウント追加
                            transaction.updateData(["unreadCount":  oldUnreadCount + 1], forDocument: partnerChatRef)
                            
                            return nil
                        }) { (object, error) in
                            if let error = error {
                                print("Transaction failed: \(error)")
                            } else {
                                self.createFlg = true
                                print("Transaction successfully committed!")
                                OneSignal.postNotification(["contents": ["en": "\(RootTabBarController.UserInfo["name"] as! String)さんから画像が届きました"], "ios_badgeType" : "Increase", "ios_badgeCount" : 1, "include_player_ids" : [self.partnerData["pushId"] as! String]])
                            }
                        }
                        
                    } else {
                        
                        self.db.runTransaction({ (transaction, errorPointer) -> Any? in
                            
                            // メッセージ追加
                            let newRef = self.db.collection("privateChat").document(self.chatId).collection("messages").document()
                            transaction.setData(
                                ["senderId": RootTabBarController.UserId, "type": "img", "message": fileName, "imgUrl": downloadUrl, "createTime": timestamp],
                                forDocument: newRef
                            )
                            
                            // 個人チャットルーム作成
                            transaction.setData(
                                ["lastMessage": fileName, "updateTime": timestamp, "type": "img", "senderId": RootTabBarController.UserId],
                                forDocument: self.db.collection("privateChat").document(self.chatId)
                            )
                            
                            // ユーザーのプライベートチャットリストに追加
                            let partnerRef: DocumentReference = self.db.collection("users").document(self.partnerId)
                            let privateChatRef: DocumentReference = self.db.collection("privateChat").document(self.chatId)
                            transaction.setData(
                                ["partnerRef" : partnerRef, "privateChatRef": privateChatRef, "unreadCount": 0, "readTime": timestamp],
                                forDocument: self.db.document("users/\(RootTabBarController.UserId)/privateChatPartners/\(String(describing: self.partnerId))")
                            )
                            
                            // パートナーのプライベートチャットリストに追加
                            let userRef: DocumentReference = self.db.collection("users").document(RootTabBarController.UserId)
                            transaction.setData(
                                ["partnerRef" : userRef, "privateChatRef": privateChatRef, "unreadCount": 1, "readTime": TimeInterval(0)],
                                forDocument: self.db.document("users/\(self.partnerId)/privateChatPartners/\(RootTabBarController.UserId)")
                            )
                            
                            return nil
                        }) { (object, error) in
                            if let error = error {
                                print("Transaction failed: \(error)")
                            } else {
                                self.createFlg = true
                                OneSignal.postNotification(["contents": ["en": "\(RootTabBarController.UserInfo["name"] as! String)さんから画像が届きました"], "ios_badgeType" : "Increase", "ios_badgeCount" : 1, "include_player_ids" : [self.partnerData["pushId"] as! String]])
                                print("Transaction successfully committed!")
                            }
                        }
                    }
                }

                
            })
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    // MARK: UICollectionView delegate
    
    override func collectionView(_ collectionView: UICollectionView, didTapMessageBubbleAt indexPath: IndexPath!) {
        let message = messages![indexPath.row]
        if message.isMediaMessage {

            let mediaItem = message.media as! JSQPhotoMediaItem
            let photos = IDMPhoto.photos(withImages: [mediaItem.image])
            let browser = IDMPhotoBrowser(photos: photos)
            browser?.delegate = self
            let closeImg = UIImage(named: "Close")
            browser!.doneButtonImage = closeImg
            browser!.doneButtonSize = CGSize(width: 30, height: 30)
            browser?.autoHideInterface = true
            browser?.usePopAnimation = false
            browser?.actionButtonImage = closeImg
            self.present(browser!, animated: true, completion: nil)
        }
        
    }
    
    // アバタータップ時
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didTapAvatarImageView avatarImageView: UIImageView!, at indexPath: IndexPath!) {
        self.performSegue(withIdentifier: "fromPrivateChatToOtherProfile", sender: nil)// ページ遷移
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
            return nil
        }
        return self.incomingAvatar
    }
    
    // アイテムの総数を返す
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages!.count
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForCellTopLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        if indexPath.item % 5 == 0 {
            let message = messages?[indexPath.row]
            return NSAttributedString(string: (message?.date.toStringWithCurrentLocale())!)
        }
        return nil
    }
    
    override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout, heightForCellTopLabelAt indexPath: IndexPath!) -> CGFloat {
        if indexPath.item % 5 == 0 {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        }
        return 0.0
    }
    
    override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout, heightForCellBottomLabelAt indexPath: IndexPath!) -> CGFloat {
        return kJSQMessagesCollectionViewCellLabelHeightDefault
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let message = messages![indexPath.row]
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        // 日付 色
        cell.cellTopLabel.textColor = UIColor.white
        // 角丸にする
        cell.avatarImageView.layer.cornerRadius = cell.avatarImageView.frame.size.width * 0.5
        cell.avatarImageView.clipsToBounds = true
        // ユーザー
        if message.senderId == self.senderId {
            let userIcon = self.storage.child("users").child(RootTabBarController.UserInfo["img"] as! String)
            cell.avatarImageView.sd_setImage(with: userIcon)
            if !message.isMediaMessage {
                cell.textView!.textColor = UIColor(red: 51/255, green: 51/255, blue: 51/255, alpha: 1)
            }
        }
        else {
        // 相手
            let partnerIcon = self.storage.child("users").child(partnerData["img"] as! String)
            cell.avatarImageView.sd_setImage(with: partnerIcon)
            if !message.isMediaMessage {
                cell.textView!.textColor = UIColor.white
            }

        }
        
        return cell
    }
    
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        // ViewControllerが表示された時に実行したい処理
        if viewController is OtherProfileViewController {
            //挿入したい処理
            listener.remove()
        }
        
        if viewController is MessageViewController {
            //挿入したい処理
            listener.remove()
        }
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

extension Date {
    
    func toStringWithCurrentLocale() -> String {
        
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.locale = Locale.current
        formatter.dateFormat = "yyyy年MM月dd日 HH:mm"
        
        return formatter.string(from: self)
    }
    
    func toStringDateImg() -> String {
        
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.locale = Locale.current
        formatter.dateFormat = "yyyyMMddHHmmss"
        
        return formatter.string(from: self)
    }
    
}

extension TimeZone {
    static let gmt = TimeZone(secondsFromGMT: 0)!
    static let jst = TimeZone(identifier: "Asia/Tokyo")!
}

extension Locale {
    static let japan = Locale(identifier: "ja_JP")
}

extension DateFormatter {
    static func current(_ dateFormat: String) -> DateFormatter {
        let df = DateFormatter()
        df.timeZone = TimeZone.gmt
        df.locale = Locale.japan
        df.dateFormat = dateFormat
        return df
    }
}

extension Date {
    static var current: Date = Date(timeIntervalSinceNow: TimeInterval(TimeZone.jst.secondsFromGMT()))
}

extension UIImage {
    func resize(size _size: CGSize) -> UIImage? {
        let widthRatio = _size.width / size.width
        let heightRatio = _size.height / size.height
        let ratio = widthRatio < heightRatio ? widthRatio : heightRatio
        
        let resizedSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        UIGraphicsBeginImageContextWithOptions(resizedSize, false, 0.0) // 変更
        draw(in: CGRect(origin: .zero, size: resizedSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage
    }
}

extension JSQMessagesInputToolbar {
    override open func didMoveToWindow() {
        super.didMoveToWindow()
        if #available(iOS 11.0, *), let window = self.window {
            let anchor = window.safeAreaLayoutGuide.bottomAnchor
            bottomAnchor.constraint(lessThanOrEqualToSystemSpacingBelow: anchor, multiplier: 1.0).isActive = true
        }
    }
}
