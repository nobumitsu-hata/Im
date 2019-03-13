//
//  ViewController.swift
//  Im
//
//  Created by nobumitsu on 2019/03/11.
//  Copyright © 2019 im. All rights reserved.
//

import UIKit
import Firebase
import FirebaseUI

class ViewController: UIViewController, FUIAuthDelegate {

    var authUI: FUIAuth { get { return FUIAuth.defaultAuthUI()!}}
    
    let providers: [FUIAuthProvider] = [
        FUIGoogleAuth(),
        ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // authUIのデリゲート
        self.authUI.delegate = self
        self.authUI.providers = providers
    }
    
    @objc func AuthButtonTapped(sender : AnyObject) {
        // FirebaseUIのViewの取得
        let authViewController = self.authUI.authViewController()
        // FirebaseUIのViewの表示
        self.present(authViewController, animated: true, completion: nil)
    }
    
    //　認証画面から離れたときに呼ばれる（キャンセルボタン押下含む）
    public func authUI(_ authUI: FUIAuth, didSignInWith user: User?, error: Error?){
        // 認証に成功した場合
        if error == nil {
            self.performSegue(withIdentifier: "toTopView", sender: self)
        }
        // エラー時の処理をここに書く
    }


}

