//
//  RootTabBarController.swift
//  Im
//
//  Created by nobumitsu on 2019/03/12.
//  Copyright © 2019 im. All rights reserved.
//

import UIKit
import Firebase
import FirebaseUI

class RootTabBarController: UITabBarController, FUIAuthDelegate, UITabBarControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    static var userId = ""
    var authUI: FUIAuth { get { return FUIAuth.defaultAuthUI()!}}
    var picker: UIImagePickerController! = UIImagePickerController()
    
    let providers: [FUIAuthProvider] = [
        FUIEmailAuth(),
        FUIGoogleAuth(),
        FUIPhoneAuth(authUI:FUIAuth.defaultAuthUI()!),
        ]
    
    var authCheck = false
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        checkLoggedIn()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        UITabBar.appearance().shadowImage = UIImage()
        UITabBar.appearance().backgroundImage = UIImage()
        
        self.delegate = self
        
        // authUIのデリゲート
        self.authUI.delegate = self
        self.authUI.providers = providers
        
    }
    
    func checkLoggedIn() {
        Auth.auth().addStateDidChangeListener{auth, user in
            if user != nil{
                //サインインしている
                print("ログイン中")
                print(user!.uid)
                RootTabBarController.userId = user!.uid
                self.authCheck = true
            } else {
                //サインインしていない
                self.login()
            }
        }
    }
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if viewController is HomeViewController {

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
            let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let nextView = storyboard.instantiateViewController(withIdentifier: "CreateViewController") as! CreateViewController
            nextView.selectedImage = image
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
