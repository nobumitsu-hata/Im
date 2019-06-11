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
import FirebaseUI
import CoreLocation
import FBSDKCoreKit
import FBSDKLoginKit
import OneSignal

class RootTabBarController: UITabBarController, UITabBarControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    static var userId = ""
    static var UserId = ""
    static var userInfo:[String:Any] = [:]
    static var UserInfo:[String:Any] = [:]
    static var AuthCheck = false
    static var currentUser:User!
    private let db = Firestore.firestore()
    var authCheck = false
    var ref: DatabaseReference!
//    var authUI: FUIAuth { get { return FUIAuth.defaultAuthUI()!}}
    var picker: UIImagePickerController! = UIImagePickerController()
    
    // 位置情報
    var locationManager: CLLocationManager!
    static var latitude: Double!
    static var longitude: Double!
    
//    let providers: [FUIAuthProvider] = [
//        FUIEmailAuth(),
//        FUIGoogleAuth(),
//        FUIPhoneAuth(authUI:FUIAuth.defaultAuthUI()!),
//        ]
//
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        ref = Database.database().reference()
        
        // ログアウト
//        let firebaseAuth = Auth.auth()
//        do {
//            try firebaseAuth.signOut()
//        } catch let signOutError as NSError {
//            print ("Error signing out: %@", signOutError)
//        }
        checkLoggedIn()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        print("要素")
        print(selectedIndex)
//        print(viewControllers)
//        selectedIndex = 1
        UITabBar.appearance().shadowImage = UIImage()
        UITabBar.appearance().backgroundImage = UIImage()
        
        self.delegate = self
        
        UITabBar.appearance().unselectedItemTintColor = UIColor.white
        
        // authUIのデリゲート
//        self.authUI.delegate = self
//        self.authUI.providers = providers
        
        
//        setupLocationManager()
    }
    
//    func setupLocationManager() {
//        // 初期化
//        locationManager = CLLocationManager()
//        // 初期化に成功しているかどうか
//        guard let locationManager = locationManager else { return }
//        // 位置情報を許可するリクエスト
//        locationManager.requestWhenInUseAuthorization()
//
//        let status = CLLocationManager.authorizationStatus()
//        // ユーザから「アプリ使用中の位置情報取得」の許可が得られた場合
//        if status == .authorizedWhenInUse {
//            locationManager.delegate = self
//            // 管理マネージャが位置情報を更新するペース
//            locationManager.distanceFilter = 20// メートル単位
//            // 位置情報の取得を開始
//            locationManager.startUpdatingLocation()
//        }
//    }
    
    func checkLoggedIn() {
        
        Auth.auth().addStateDidChangeListener{auth, user in
            if user != nil{
                
                // ログインしている
                RootTabBarController.UserId = user!.uid
                RootTabBarController.AuthCheck = true
                RootTabBarController.currentUser = auth.currentUser
                
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
//                self.ref.child("users").child(user!.uid).observeSingleEvent(of: .value, with: { (snapshot) in
//                    let val = snapshot.value as! [String:Any]// エラー箇所
//                    RootTabBarController.userInfo = val
//                })
            } else {
//                //サインインしていない
//                self.login()
                print("ログアウト")
                RootTabBarController.AuthCheck = false
            }
        }
    }
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if viewController is ScrollViewController {
            return true
        }
        
            //  ログイン済み
            if RootTabBarController.AuthCheck {
                print("ページ遷移2")
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
                
//                self.tabBarController?.selectedIndex = 0
//                if viewController is ViewController { //もしShareTweetViewController.swiftをclass指定してあるページ行きのボタンをタップしたら
////                    if let newVC = tabBarController.storyboard?.instantiateViewController(withIdentifier: "CreateViewController"){ //withIdentifier: にはStory Board IDを設定
//                        print("モーダル")
////                        tabBarController.present(newVC, animated: true, completion: nil)//newVCで設定したページに遷移
//                        //PhotoLibraryから画像を選択
//                        picker.sourceType = UIImagePickerController.SourceType.photoLibrary
//
//                        //デリゲートを設定する
//                        picker.delegate = self
//
//                        //現れるピッカーNavigationBarの文字色を設定する
//                        picker.navigationBar.tintColor = UIColor.white
//
//                        //現れるピッカーNavigationBarの背景色を設定する
//                        picker.navigationBar.barTintColor = UIColor.gray
//
//                        //ピッカーを表示する
//                        present(picker, animated: true, completion: nil)
//                        return false
////                    }
//                }
                return true
            } else {
                
                let modalViewController = storyboard?.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
                modalViewController.modalPresentationStyle = .custom
                modalViewController.transitioningDelegate = self
                present(modalViewController, animated: true, completion: nil)
                return false
            }
        
//        }
//        return true
    }
    
    // iPhoneで表示させる場合に必要
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
    
    //画像が選択された時に呼ばれる.
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let image = info[.originalImage] as? UIImage {
            let imageType = (info[.imageURL] as! NSURL).absoluteString! as NSString
            let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let nextView = storyboard.instantiateViewController(withIdentifier: "CreateViewController") as! CreateViewController
            nextView.selectedImage = image
            nextView.selectedImageType = imageType.pathExtension
            self.dismiss(animated: false)
            self.present(nextView, animated: true, completion: nil)
        } else{
            print("Error")
        }
    }
        
    //　認証画面から離れたときに呼ばれる（キャンセルボタン押下含む）
//    public func authUI(_ authUI: FUIAuth, didSignInWith user: User?, error: Error?){
//        // 認証に成功した場合
//        if error == nil {
//            self.ref.child("users").child(user!.uid).setValue(["img":"user.png","name":"未設定"])
////            self.performSegue(withIdentifier: "toTopView", sender: self)
//        }
//        // エラー時の処理をここに書く
//    }
    
//    func login() {
//        // FirebaseUIのViewの取得
//        let authViewController = self.authUI.authViewController()
//        // FirebaseUIのViewの表示
//        self.present(authViewController, animated: true, completion: nil)
//    }
    func startOneSignal() {
        let status: OSPermissionSubscriptionState = OneSignal.getPermissionSubscriptionState()
        let userID = status.subscriptionStatus.userId
        let pushToken = status.subscriptionStatus.pushToken
        
        if pushToken != nil {
            if let playerID = userID {
                UserDefaults.standard.set(playerID, forKey: "pushID")
                OneSignal.postNotification(["contents": ["ja": "プッシュが来たぞー"], "ios_badgeType" : "Increase", "ios_badgeCount" : 1, "include_player_ids" : [playerID]])
            } else {
                UserDefaults.standard.removeObject(forKey: "pushID")
            }
            UserDefaults.standard.synchronize()
        }
        
        // updateOneSignalId
        if let pushId = UserDefaults.standard.string(forKey: "pushID") {
            print("俺のプッシュID\(pushId)")
//            setOneSignalId(pushId: pushId)
            updateOneSignalId(pushId: pushId)
        } else {
            updateOneSignalId(pushId: "")
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

extension RootTabBarController: CLLocationManagerDelegate {
    
//    // 位置情報を取得・更新するたびに呼ばれる
//    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        let location = locations.first
//        RootTabBarController.latitude = location!.coordinate.latitude
//        RootTabBarController.longitude = location!.coordinate.longitude
//
//        print("latitude: \(RootTabBarController.latitude!)\nlongitude: \(RootTabBarController.longitude!)")
//    }

}

extension RootTabBarController: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return LoginPresentationController(presentedViewController: presented, presenting: presenting)
    }
}
