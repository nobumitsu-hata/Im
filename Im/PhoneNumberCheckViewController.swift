//
//  PhoneNumberCheckViewController.swift
//  Im
//
//  Created by nobumitsu on 2019/06/06.
//  Copyright © 2019 im. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import KRProgressHUD

class PhoneNumberCheckViewController: UIViewController {
    
    @IBOutlet weak var wrapperView: UIView!
    @IBOutlet weak var codeTextField: UITextField!
    @IBOutlet weak var sendBtn: UIButton!
    
    private let db = Firestore.firestore()
    private let storageRef = Storage.storage().reference()
    var verificationId = ""
    var phoneNumber = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.tintColor = .white
        
        view.setGradientLayer()
        wrapperView.layer.cornerRadius = 20
        codeTextField.borderGradient(
            startColor: UIColor(displayP3Red: 147/255, green: 6/255, blue: 229/255, alpha: 1.0),
            endColor: UIColor(displayP3Red: 23/255, green: 232/255, blue: 252/255, alpha: 1.0),
            radius: 0
        )
        sendBtn.setGradientBackground(
            colorOne: UIColor(displayP3Red: 147/255, green: 6/255, blue: 229/255, alpha: 1.0),
            colorTwo: UIColor(displayP3Red: 23/255, green: 232/255, blue: 252/255, alpha: 1.0)
        )

    }
    
    @IBAction func checkCode(_ sender: Any) {
        guard codeTextField.text! != "" else {
            self.showMessagePrompt(message: "認証コードを入力してください")
            return
        }
        
        // ローディング開始
        let appearance = KRProgressHUD.appearance()
        appearance.activityIndicatorColors = [UIColor]([
            UIColor(displayP3Red: 147/255, green: 6/255, blue: 229/255, alpha: 1.0),
            UIColor(displayP3Red: 23/255, green: 232/255, blue: 252/255, alpha: 1.0)
            ])
        KRProgressHUD.show()
        
        let code = codeTextField.text
        
        let credential = PhoneAuthProvider.provider().credential(withVerificationID: verificationId, verificationCode: code!)
        Auth.auth().signIn(with: credential) { authData, error in
            if error != nil {
                KRProgressHUD.dismiss()// ローディング終了
                self.showMessagePrompt(message: "認証に失敗しました")
                return
            }
            
            // 認証成功時の処理
            let userId = authData!.user.uid
            
            self.db.collection("users").document(userId).getDocument { (document, error) in
                if let userDoc = document.flatMap({
                    $0.data().flatMap({ (data) in
                        return data
                    })
                }) {
                    RootTabBarController.UserId = userId
                    RootTabBarController.UserInfo = userDoc
                    RootTabBarController.AuthCheck = true
                    
                    if userDoc["status"] as? Int == 0 {
                        // 仮登録済みの場合
                        KRProgressHUD.dismiss()// ローディング終了
                        let presentController = self.storyboard?.instantiateViewController(withIdentifier: "RegisterViewController") as! RegisterViewController
                        self.present(presentController, animated: true, completion: {
                            presentController.fromWhere = "afterAuth"
                        })
                    }  else {
                        // 本登録済みの場合
                        KRProgressHUD.dismiss()// ローディング終了
                        self.presentingViewController!.presentingViewController!.dismiss(animated: true, completion: nil)
                    }
                    
                } else {
                    // 仮登録する
                    
                    let fields = [
                        "name": "",
                        "introduction": "",
                        "sex": "",
                        "birthday": 0,
                        "status": 0,
                        "deleteFlg": false,
                        "contact": self.phoneNumber,
                        "img": "",
                        "imgUrl": "",
                        "authType": "phoneNumber",
                        "token": ""
                        ] as [String : Any]
                    
                    // 仮登録
                    self.db.collection("users").document(userId).setData(fields) { err in
                        if let err = err {
                            print("Error adding document: \(err)")
                            KRProgressHUD.dismiss()// ローディング終了
                        } else {
                            print("登録")
                            RootTabBarController.UserId = userId
                            RootTabBarController.UserInfo = fields
                            RootTabBarController.AuthCheck = true
                            KRProgressHUD.dismiss()// ローディング終了
                            // 本登録へ
                            let presentController = self.storyboard?.instantiateViewController(withIdentifier: "RegisterViewController") as! RegisterViewController
                            self.present(presentController, animated: true, completion: {
                                presentController.fromWhere = "PhoneNumberCheckViewController"
                            })

                        }
                    }
                    
                }
            }
        }
        
    }
    
}
