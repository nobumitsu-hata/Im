//
//  DeleteViewController.swift
//  Im
//
//  Created by nobumitsu on 2019/06/04.
//  Copyright © 2019 im. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore

class DeleteViewController: UIViewController {
    
    private let db = Firestore.firestore()
    private let storageRef = Storage.storage().reference()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.tintColor = .white
        view.setGradientLayer()
    }
    
    @IBAction func deleteAccount(_ sender: Any) {
        let alert: UIAlertController = UIAlertController(title: "アカウントを削除しますか？", message: "", preferredStyle:  UIAlertController.Style.alert)
        // OKボタン
        let defaultAction: UIAlertAction = UIAlertAction(title: "削除する",style: .default, handler: {
            (action:UIAlertAction!) -> Void in
            
            // 退会
            let user = Auth.auth().currentUser
            user?.delete(completion: { (err) in
                if err != nil {
                    let firebaseAuth = Auth.auth()
                    do {
                        try firebaseAuth.signOut()
                        AccountViewController.profileListener.remove()
                        AccountViewController.belongsListener.remove()
                        AccountViewController.listenerFlg = false
                        self.showMessagePrompt(message: "アカウントを削除するには再認証が必要です")
                    } catch let signOutError as NSError {
                        print ("Error signing out: %@", signOutError)
                    }
                    self.tabBarController?.selectedIndex = 0
                    return
                }
                print("削除")
                
                let ref = self.db.collection("users").document(RootTabBarController.UserId)
                ref.updateData(["name":"退会済みユーザー", "img": "", "deleteFlg": true, "pushId": ""]) { err in
                    if let err = err {
                        print("Error updating document: \(err)")
                    } else {
                        print("Document successfully updated")
                        if RootTabBarController.UserInfo["img"] as? String == "" {
                            return
                        }
                        
                        // プロフィール画像削除
                        self.storageRef.child("users").child(RootTabBarController.UserInfo["img"] as! String).delete { error in
                            if let error = error {
                                // Uh-oh, an error occurred!
                                print(error.localizedDescription)
                            } else {
                                // File deleted successfully
                                print("File deleted")
                            }
                        }
                    }
                }
                AccountViewController.profileListener.remove()
                AccountViewController.belongsListener.remove()
                AccountViewController.listenerFlg = false
                self.tabBarController?.selectedIndex = 0
            })
            
            guard RootTabBarController.AuthCheck else {
                return
            }

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
        
        // ④ Alertを表示
        present(alert, animated: true, completion: nil)
    }
    
}
