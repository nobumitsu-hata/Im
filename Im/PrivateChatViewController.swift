//
//  PrivateChatViewController.swift
//  Im
//
//  Created by nobumitsu on 2019/05/22.
//  Copyright © 2019 im. All rights reserved.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import Photos
import Firebase

class PrivateChatViewController: MessagesViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage().reference()
    private var reference: CollectionReference?
    private var messageListener: ListenerRegistration?

    var messageList: [ChatMessage] = []
    var h:CGFloat = 0
    var userinfo: [AnyHashable:Any] = [:]
    var partnerId = ""
    var partnerInfo:[String:String] = [:]
    
    lazy var formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
//        guard let id = channel.id else {
//            navigationController?.popViewController(animated: true)
//            return
//        }
        
        
        reference = db.collection(["privateChat"].joined(separator: "/"))
        var i = 0
        var s = 0
        messageListener = reference?.addSnapshotListener { querySnapshot, error in
            guard let snapshot = querySnapshot else {
                print("Error listening for channel updates: \(error?.localizedDescription ?? "No error")")
                return
            }
            
            snapshot.documentChanges.forEach { change in
                switch change.type {
                case .added:
                    let content = change.document.data()
                    self.insertMessages([content["message"]!])
                default:
                    break
                }
            }
        }
        // ユーザー側のアイコンを非表示
        if let layout = messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout {
            layout.textMessageSizeCalculator.outgoingAvatarSize = .zero
        }
        
        // アバターの位置をメッセージのbottomに合わせる
        if let layout = messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout {
            layout.setMessageIncomingAvatarPosition(.init(vertical: .messageBottom))
        }
        
        // メッセージ入力時に一番下までスクロール
        scrollsToBottomOnKeyboardBeginsEditing = false // default false
        maintainPositionOnKeyboardFrameChanged = true // default false
        
        DispatchQueue.main.async {
            // messageListにメッセージの配列をいれて
//            self.messageList = self.getMessages()
            // messagesCollectionViewをリロードして
            self.messagesCollectionView.reloadData()
            self.messagesCollectionView.frame = CGRect(x: 0,y: 0,width: UIScreen.main.bounds.width,height: UIScreen.main.bounds.height - self.messageInputBar.frame.size.height)
            // 一番下までスクロールする
            self.messagesCollectionView.scrollToBottom()
            
            print("高さ")
            print(self.messageInputBar.backgroundView.bounds.height)
            self.messagesCollectionView.insetsLayoutMarginsFromSafeArea = true
            self.messagesCollectionView.contentInset.bottom = 0
            self.messagesCollectionView.scrollIndicatorInsets.bottom = 0
        }
        self.setupUI()
    }
    
    func setupUI() {
        self.view.setGradientLayer()
    
        messagesCollectionView.backgroundColor = UIColor.clear
        messagesCollectionView.backgroundView?.backgroundColor = UIColor.clear
        messageInputBar.backgroundColor = UIColor.clear
        messageInputBar.backgroundView.backgroundColor = UIColor.clear
    
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self
    
        messageInputBar.delegate = self
        messageInputBar.sendButton.title = "送信"
        messageInputBar.sendButton.setTitleColor(.white, for: .normal)
        messageInputBar.sendButton.setTitleColor(UIColor(displayP3Red: 255/255, green: 255/255, blue: 255/255, alpha: 0.7), for: .disabled)
        messageInputBar.inputTextView.placeholder = "メッセージを入力"
        messageInputBar.inputTextView.placeholderTextColor = UIColor(displayP3Red: 255/255, green: 255/255, blue: 255/255, alpha: 0.7)
        messageInputBar.inputTextView.tintColor = UIColor.white
        messageInputBar.inputTextView.textColor = UIColor.white
        messageInputBar.inputTextView.layer.borderColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0).cgColor
        messageInputBar.separatorLine.backgroundColor = UIColor.white
        messageInputBar.middleContentViewPadding.left = 10
        messageInputBar.inputTextView.contentInset = UIEdgeInsets(top: 5, left: 0, bottom: 0, right: 0)
    }
    
    private func handleDocumentChange(_ change: DocumentChange) {
        print("答え")
        print(change.document)
//        guard let message = ChatMessage(document: change.document) else {
//            return
//        }
        
//        switch change.type {
//        case .added:
//            insertMessages(messageList)
//
//        default:
//            break
//        }
    }

    
    private func sendPhoto(_ image: UIImage) {
//        isSendingPhoto = true
        
        uploadImage(image) { [weak self] url in
            guard let `self` = self else {
                return
            }
//            self.isSendingPhoto = false
            
            guard let url = url else {
                return
            }
            
//            var message = ChatMessage(image: image, user: ChatUser(senderId: "123", displayName: "自分"), messageId: UUID().uuidString, date: Date())
//            message.downloadURL = url
            
//            self.save(message)
            self.messagesCollectionView.scrollToBottom()
        }
    }
    
    private func save() {
        reference?.addDocument(data: ["content": "あああ"]) { error in
            if let e = error {
                print("Error sending message: \(e.localizedDescription)")
                return
            }

            self.messagesCollectionView.scrollToBottom()
        }
    }


    private func uploadImage(_ image: UIImage, completion: @escaping (URL?) -> Void) {
        
        // jpeg変換
        guard let data = image.jpegData(compressionQuality: 0.4) else {
                completion(nil)
                return
        }
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        let imageName = [UUID().uuidString, String(Date().timeIntervalSince1970)].joined()
        storage.child("privateChat").child(imageName).putData(data, metadata: metadata) { meta, error in
            guard meta != nil else {
                // Uh-oh, an error occurred!
                return
            }
            
            self.storage.downloadURL { (url, error) in
                guard let downloadURL = url else {
                    // Uh-oh, an error occurred!
                    return
                }
                
                completion(downloadURL)
            }
            
        }
    }
}

extension PrivateChatViewController: MessagesDataSource {
    func currentSender() -> SenderType {
        return ChatUser(senderId: RootTabBarController.userId, displayName: RootTabBarController.userInfo["name"] as! String)
    }
    
    func otherSender() -> ChatUser {
        return ChatUser(senderId: partnerId, displayName: partnerInfo["name"]!)
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messageList.count
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messageList[indexPath.section]
    }
    
    // メッセージの上に文字を表示
    func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        if indexPath.section % 3 == 0 {
            return NSAttributedString(
                string: MessageKitDateFormatter.shared.string(from: message.sentDate),
                attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10),
                             NSAttributedString.Key.foregroundColor: UIColor.white]
            )
        }
        return nil
    }
    
    // メッセージの上に文字を表示（名前）
    func messageTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        let name = message.sender.displayName
        return NSAttributedString(string: name, attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption1),NSAttributedString.Key.foregroundColor: UIColor.white])
    }
    
}

// メッセージのdelegate
extension PrivateChatViewController: MessagesDisplayDelegate {
    
    // メッセージの色を変更（デフォルトは自分：黒、相手：白）
    func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? UIColor(red: 51/255, green: 51/255, blue: 51/255, alpha: 1) : .white
    }
    
    // メッセージの背景色を変更している（デフォルトは自分：白、相手：白）
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ?
            UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1) :
            UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.2)
    }
    
    // メッセージの枠にしっぽを付ける
    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        let corner: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight : .bottomLeft
        return .bubbleTail(corner, .curved)
    }
    
    // アイコンをセット
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        // message.sender.displayNameとかで送信者の名前を取得できるので
        // そこからイニシャルを生成するとよい
        let avatar = Avatar(initials: "人")
        avatarView.set(avatar: avatar)
    }
}

// 各ラベルの高さを設定（デフォルト0なので必須）
extension PrivateChatViewController: MessagesLayoutDelegate {
    
    func cellTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        if indexPath.section % 3 == 0 { return 24 }
        return 0
    }
    
    func messageTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 0
    }
    
    func messageBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 16
    }
}

extension PrivateChatViewController: MessageCellDelegate {
    // メッセージをタップした時の挙動
    func didTapMessage(in cell: MessageCollectionViewCell) {
        print("Message tapped")
    }
}

extension PrivateChatViewController: InputBarAccessoryViewDelegate {
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        // Here we can parse for which substrings were autocompleted
//        let attributedText = messageInputBar.inputTextView.attributedText!
//        let range = NSRange(location: 0, length: attributedText.length)
//        attributedText.enumerateAttribute(.autocompleted, in: range, options: []) { (_, range, _) in
//
//            let substring = attributedText.attributedSubstring(from: range)
//            let context = substring.attribute(.autocompletedContext, at: 0, effectiveRange: nil)
//            print("Autocompleted: `", substring, "` with context: ", context ?? [])
//        }
        
        let components = inputBar.inputTextView.components
        messageInputBar.inputTextView.text = String()
        messageInputBar.invalidatePlugins()
        
        // Send button activity animation
        messageInputBar.sendButton.startAnimating()
        messageInputBar.inputTextView.placeholder = "Sending..."
        
//        save()
        
//        db.document("users/\(RootTabBarController.userId)/.privateChatList/\(partnerId)").getDocument { (document, error) in
//            if let document = document, document.exists {
//                let dataDescription = document.data().map(String.init(describing:)) ?? "nil"
//                print("Document data: \(dataDescription)")
//            } else {
                var ref: DocumentReference? = nil
                ref = self.db.collection("privateChat").addDocument(data: ["message": text]) { err in
                    if let err = err {
                        print("Error adding document: \(err)")
                    } else {
                        print("Document added with ID: \(ref!.documentID)")
                        self.messagesCollectionView.scrollToBottom(animated: true)
                    }
                }
//                print("Document does not exist")

//            }
//        }

        DispatchQueue.global(qos: .default).async {
            // fake send request task
            sleep(1)
            DispatchQueue.main.async { [weak self] in
                self?.messageInputBar.sendButton.stopAnimating()
                self?.messageInputBar.inputTextView.placeholder = "メッセージを入力"
//                self?.insertMessages(components)
                self?.messagesCollectionView.scrollToBottom(animated: true)
            }
        }
    }
    
    private func insertMessages(_ data: [Any]) {
        for component in data {
            let user = ChatUser(senderId: RootTabBarController.userId, displayName: RootTabBarController.userInfo["name"] as! String)
            if let str = component as? String {
                let message = ChatMessage(text: str, user: user, messageId: UUID().uuidString, date: Date())
                messageList.append(message)
                messagesCollectionView.insertSections([messageList.count - 1])
            } else if let img = component as? UIImage {
                let message = ChatMessage(image: img, user: user, messageId: UUID().uuidString, date: Date())
                messageList.append(message)
                messagesCollectionView.insertSections([messageList.count - 1])
//                let isLatestMessage = messageList.index(of: message) == (messageList.count - 1)
//                let shouldScrollToBottom = messagesCollectionView.isAtBottom && isLatestMessage
//                if shouldScrollToBottom {
//                    DispatchQueue.main.async {
//                        self.messagesCollectionView.scrollToBottom(animated: true)
//                    }
//                }
            }
        }
    }
}
