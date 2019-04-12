//
//  AccountViewController.swift
//  Im
//
//  Created by nobumitsu on 2019/04/08.
//  Copyright © 2019 im. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase

class AccountViewController: UIViewController {
    
    var ref: DatabaseReference!
    var storage: Storage!
    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var editBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // 編集ボタンカスタマイズ
        editBtn.layer.cornerRadius = 20.0
        editBtn.setGradientBackground(
            colorOne: UIColor(displayP3Red: 23/255, green: 234/255, blue: 217/255, alpha: 1.0),
            colorTwo: UIColor(displayP3Red: 96/255, green: 120/255, blue: 234/255, alpha: 1.0)
        )
        
        // 初期化
        storage = Storage.storage()
        
        // 角丸にする
        self.imgView.layer.cornerRadius = self.imgView.frame.size.width * 0.5
        self.imgView.clipsToBounds = true
        // ナビゲーションを透明にする処理
        self.navigationController!.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController!.navigationBar.shadowImage = UIImage()
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        setupFirebase()
    }
    
    func setupFirebase() {
        ref = Database.database().reference()
        // ユーザー情報取得
        ref.child("users").child(RootTabBarController.userId).observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.exists() {
                let val = snapshot.value as! [String:Any]
                let storageRef = self.storage.reference()
                let imgRef = storageRef.child("users").child(val["img"] as! String)
                // セット
                self.imgView.sd_setImage(with: imgRef)
                self.nameLabel.text = (val["name"] as! String)
            } else {
                // 画像設定
                let img = UIImage(named: "UserImg")
                self.imgView.image = img
                self.nameLabel.text =  "未設定"
            }
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    @IBAction func toEdit(_ sender: Any) {
        self.performSegue(withIdentifier: "toEditProfileViewController", sender: nil)
    }
    

}

extension UIView {
    
    func setGradientBackground(colorOne: UIColor, colorTwo: UIColor) {
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = bounds
        gradientLayer.colors = [colorOne.cgColor, colorTwo.cgColor]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 1.0)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        gradientLayer.cornerRadius = 20.0
        
        layer.insertSublayer(gradientLayer, at: 0)
    }
}
