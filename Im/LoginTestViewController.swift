//
//  LoginTestViewController.swift
//  Im
//
//  Created by nobumitsu on 2019/05/29.
//  Copyright © 2019 im. All rights reserved.
//

import UIKit
import Firebase
import FBSDKCoreKit
import FBSDKLoginKit
import GoogleSignIn

class LoginTestViewController: UIViewController, LoginButtonDelegate, GIDSignInDelegate, GIDSignInUIDelegate {
    @IBOutlet weak var collectionViewLayout: UICollectionViewFlowLayout!{
        didSet {
//            collectionViewLayout.itemSize = CGSize(width: collectionView.frame.width, height: 52)
//            collectionViewLayout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        }
    }
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        collectionView.delegate = self
//        collectionView.dataSource = self
//        self.tabBarController?.selectedViewController = ScrollViewController() as! ViewController
        print("どうも")
        self.tabBarController?.selectedIndex = 3
        print("あああ")
        // 自作セルをテーブルビューに登録する
//        let chatXib = UINib(nibName: "CommunityChatCollectionViewCell", bundle: nil)
//        collectionView.register(chatXib, forCellWithReuseIdentifier: "communityChatCell")
//
//        let layout = UICollectionViewFlowLayout()
////        layout.itemSize = CGSize(width: collectionView.frame.width, height: 52)
//        layout.minimumLineSpacing = 0
//        layout.estimatedItemSize = CGSize(width: collectionView.frame.width, height: 52)
//        collectionView.collectionViewLayout = layout
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
     func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
//     func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        // セル生成
//        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "communityChatCell", for: indexPath) as! CommunityChatCollectionViewCell
//
//        cell.message.text = "This is label one.\nThis is label one.\nThis is label one.\nThis is label one.\nThis is label one."
//        cell.name.text = "This is label two.\nThis is label two.\nThis is label two.\nThis is label two.\nThis is label two."
//        cell.cellWidth = collectionView.frame.size.width
//        return cell
//    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        print("呼ばれた")
//        // ログインボタン設置
//        self.tabBarController?.selectedIndex = 0
//        let fbLoginBtn = FBLoginButton()
//        fbLoginBtn.permissions = ["public_profile", "email"]
//        fbLoginBtn.center = self.view.center
//        fbLoginBtn.delegate = self
//        self.view.addSubview(fbLoginBtn)
//        GIDSignIn.sharedInstance().uiDelegate = self
//        GIDSignIn.sharedInstance().delegate = self
        
    }
    
    @IBAction func tapGoogleSingIn(_ sender: Any) {
        GIDSignIn.sharedInstance().signIn()
    }
    
    func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        if let error = error {
            print(error.localizedDescription)
            return
        }
    }
    
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error?) {

        if let error = error {
            print("Error: \(error.localizedDescription)")
            return
        }
        
        guard let authentication = user.authentication else { return }
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken,
                                                       accessToken: authentication.accessToken)
        // ...
    }
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        // Perform any operations when the user disconnects from app here.
        // ...
    }

}
