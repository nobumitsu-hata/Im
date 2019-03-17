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

class RootTabBarController: UITabBarController, FUIAuthDelegate, UITabBarControllerDelegate {
    
    var authUI: FUIAuth { get { return FUIAuth.defaultAuthUI()!}}
    
    let providers: [FUIAuthProvider] = [
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
                self.authCheck = true
            } else {
                //サインインしていない
                self.login()
            }
        }
    }
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if viewController is HomeViewController {
//                return false
        } else {
            return self.authCheck
        }
        return true
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
