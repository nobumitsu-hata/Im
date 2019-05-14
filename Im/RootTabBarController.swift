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

class RootTabBarController: UITabBarController, FUIAuthDelegate, UITabBarControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    static var userId = ""
    static var userInfo:[String:Any] = [:]
    var authCheck = false
    var ref: DatabaseReference!
    var authUI: FUIAuth { get { return FUIAuth.defaultAuthUI()!}}
    var picker: UIImagePickerController! = UIImagePickerController()
    
    // 位置情報
    var locationManager: CLLocationManager!
    static var latitude: Double!
    static var longitude: Double!
    
    let providers: [FUIAuthProvider] = [
        FUIEmailAuth(),
        FUIGoogleAuth(),
        FUIPhoneAuth(authUI:FUIAuth.defaultAuthUI()!),
        ]
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        ref = Database.database().reference()
        
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
        UITabBar.appearance().shadowImage = UIImage()
        UITabBar.appearance().backgroundImage = UIImage()
        
        self.delegate = self
        
        UITabBar.appearance().unselectedItemTintColor = UIColor.white
        
        // authUIのデリゲート
        self.authUI.delegate = self
        self.authUI.providers = providers
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
                RootTabBarController.userId = user!.uid
                self.authCheck = true
                self.ref.child("users").child(user!.uid).observeSingleEvent(of: .value, with: { (snapshot) in
                    let val = snapshot.value as! [String:Any]// エラー箇所
                    RootTabBarController.userInfo = val
                })
            } else {
                //サインインしていない
                self.login()
            }
        }
    }
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if viewController is ScrollViewController {

        } else {
            if self.authCheck {
                if viewController is ViewController { //もしShareTweetViewController.swiftをclass指定してあるページ行きのボタンをタップしたら
//                    if let newVC = tabBarController.storyboard?.instantiateViewController(withIdentifier: "CreateViewController"){ //withIdentifier: にはStory Board IDを設定
                        print("モーダル")
//                        tabBarController.present(newVC, animated: true, completion: nil)//newVCで設定したページに遷移
                        //PhotoLibraryから画像を選択
                        picker.sourceType = UIImagePickerController.SourceType.photoLibrary

                        //デリゲートを設定する
                        picker.delegate = self

                        //現れるピッカーNavigationBarの文字色を設定する
                        picker.navigationBar.tintColor = UIColor.white

                        //現れるピッカーNavigationBarの背景色を設定する
                        picker.navigationBar.barTintColor = UIColor.gray

                        //ピッカーを表示する
                        present(picker, animated: true, completion: nil)
                        return false
//                    }
                }
            }
            return self.authCheck
        }
        return true
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
    public func authUI(_ authUI: FUIAuth, didSignInWith user: User?, error: Error?){
        // 認証に成功した場合
        if error == nil {
            self.ref.child("users").child(user!.uid).setValue(["img":"user.png","name":"未設定"])
//            self.performSegue(withIdentifier: "toTopView", sender: self)
        }
        // エラー時の処理をここに書く
    }
    
    func login() {
        // FirebaseUIのViewの取得
        let authViewController = self.authUI.authViewController()
        // FirebaseUIのViewの表示
        self.present(authViewController, animated: true, completion: nil)
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
