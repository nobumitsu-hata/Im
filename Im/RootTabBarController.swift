//
//  RootTabBarController.swift
//  Im
//
//  Created by nobumitsu on 2019/03/12.
//  Copyright © 2019 im. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import FirebaseFirestore
import FirebaseUI
import FBSDKCoreKit
import FBSDKLoginKit
import OneSignal
import KRProgressHUD
import TwitterKit

class RootTabBarController: UITabBarController, UITabBarControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    static var UserId = ""
    static var UserInfo:[String:Any] = [:]
    static var AuthCheck = false
    static var currentUser:User!
    static var unreadCountDic:[String:Int] = [:]
    static var locationFlg = false
    private let db = Firestore.firestore()
    var picker: UIImagePickerController! = UIImagePickerController()
    
    // 位置情報
    static var latitude: Double!
    static var longitude: Double!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        checkLoggedIn()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        UITabBar.appearance().shadowImage = UIImage()
        UITabBar.appearance().backgroundImage = UIImage()
        
        self.delegate = self
        
        UITabBar.appearance().unselectedItemTintColor = UIColor.white
        
    }
    
    func badgeCount() {
        
        db.collection("users").document(RootTabBarController.UserId).collection("privateChatPartners").addSnapshotListener{ querySnapshot, error in
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
                let documentId = diff.document.documentID
                let data = diff.document.data()
                switch diff.type {
                case .added:
                    RootTabBarController.unreadCountDic[documentId] = data["unreadCount"] as? Int
                    let val = RootTabBarController.unreadCountDic.values
                    let sum = val.reduce(0, { $0 + $1 })
                    if sum > 0 {
                        if let tabItem = self.tabBar.items?[1] {
                            tabItem.badgeValue = String(sum)
                            UIApplication.shared.applicationIconBadgeNumber = sum
                        }
                    } else {
                        if let tabItem = self.tabBar.items?[1] {
                            tabItem.badgeValue = nil
                            UIApplication.shared.applicationIconBadgeNumber = 0
                        }
                    }
                    
                case .modified:
                    RootTabBarController.unreadCountDic[documentId] = data["unreadCount"] as? Int
                    let val = RootTabBarController.unreadCountDic.values
                    let sum = val.reduce(0, { $0 + $1 })
                    if sum > 0 {
                        if let tabItem = self.tabBar.items?[1] {
                            tabItem.badgeValue = String(sum)
                            UIApplication.shared.applicationIconBadgeNumber = sum
                        }
                    } else {
                        if let tabItem = self.tabBar.items?[1] {
                            tabItem.badgeValue = nil
                            UIApplication.shared.applicationIconBadgeNumber = 0
                        }
                    }
                default:
                    break
                }
            }
            
        }
    }
    
    func checkLoggedIn() {
        
        Auth.auth().addStateDidChangeListener{auth, user in
            if user != nil {
            // ログインしている
                RootTabBarController.UserId = user!.uid
                RootTabBarController.AuthCheck = true
                RootTabBarController.currentUser = auth.currentUser
                self.badgeCount()
                self.startOneSignal()
                
                self.db.collection("users").document(user!.uid).getDocument { (document, error) in
                    if let userDoc = document.flatMap({
                        $0.data().flatMap({ (data) in
                            return RootTabBarController.UserInfo = data
                        })
                    }) {
                        print("User: \(userDoc)")
                    } else {
                        print("Document does not exist")
                    }
                }
            } else {
                RootTabBarController.AuthCheck = false
                if let tabItem = self.tabBar.items?[2] {
                    tabItem.badgeValue = nil
                    UIApplication.shared.applicationIconBadgeNumber = 0
                }
            }
        }
    }
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        
        if viewController is ScrollViewController || viewController is SpotViewController {
            return true
        }
        
        //  ログイン済み
        if RootTabBarController.AuthCheck {
            // タブを切り替える
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "didNotification"), object: nil, userInfo: ["userID" : RootTabBarController.UserId])
            // 仮登録状態の場合
            if RootTabBarController.UserInfo["status"] as? Int  == 0 {
                let modalViewController = storyboard?.instantiateViewController(withIdentifier: "RegisterViewController") as! RegisterViewController
                present(modalViewController, animated: true, completion: {
                    modalViewController.fromWhere = "RootTabBarController"
                })
                return false
            }
            
            return true
        } else {
            
            let modalViewController = storyboard?.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
            modalViewController.modalPresentationStyle = .custom
            modalViewController.transitioningDelegate = self
            present(modalViewController, animated: true, completion: nil)
            return false
        }
        
    }
    
    // iPhoneで表示させる場合に必要
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
    
    func startOneSignal() {
        let status: OSPermissionSubscriptionState = OneSignal.getPermissionSubscriptionState()
        let userID = status.subscriptionStatus.userId
        
        if let pushID = userID {
            db.collection("users").document(RootTabBarController.UserId).updateData(["pushId": pushID])
        }
    }
    
    func updateOneSignalId(pushId: String) {
        db.collection("users").document(RootTabBarController.UserId).updateData(["pushId": pushId]) { err in
            if let err = err {
                print("Error updating document: \(err)")
                return
            }
        }
    }
}

extension RootTabBarController: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return LoginPresentationController(presentedViewController: presented, presenting: presenting)
    }
}
