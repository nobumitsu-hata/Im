//
//  TestViewController.swift
//  Im
//
//  Created by nobumitsu on 2019/04/11.
//  Copyright © 2019 im. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import FirebaseUI

class TestViewController: UIViewController {

    var ref: DatabaseReference!
    var storage: Storage!
    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var nameLbl: UILabel!
    @IBOutlet weak var editBtn: UIButton!
    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var wrapperView: UIView!
    @IBOutlet weak var introduction: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 編集ボタンカスタマイズ
        //        editBtn.layer.cornerRadius = 10.0
//        editBtn.setGradientBackground(
//            colorOne: UIColor(displayP3Red: 147/255, green: 6/255, blue: 229/255, alpha: 1.0),
//            colorTwo: UIColor(displayP3Red: 23/255, green: 232/255, blue: 252/255, alpha: 1.0)
//        )
        
        // 初期化
        storage = Storage.storage()
        
        self.view.setGradientLayer()
//        wrapperView.backgroundColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.2)
//        wrapperView.layer.cornerRadius = 20
//        mainView.layer.cornerRadius = 20
        // 角丸にする
//        self.imgView.layer.cornerRadius = self.imgView.frame.size.width * 0.5
//        self.imgView.clipsToBounds = true
        
//        UIView.animate(withDuration: 0.3){
//            self.introduction.isHidden = true //またはfalse
//        }
        self.introduction.isHidden = true //またはfalse
        setupFirebase()

    }
    
    func setupFirebase() {
        ref = Database.database().reference()
        // ユーザー情報取得
        ref.child("users").child("uYGxXJ9tDsYz2P7BLCZSf25otPY2").observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.exists() {
                let val = snapshot.value as! [String:Any]
                let storageRef = self.storage.reference()
//                let imgRef = storageRef.child("users").child(val["img"] as! String)
                // セット
//                self.imgView.sd_setImage(with: imgRef)
//                self.nameLbl.text = "はたぼー"
            } else {
                // 画像設定
                let img = UIImage(named: "UserImg")
                self.imgView.image = img
//                self.nameLbl.text =  "未設定"
            }
        }) { (error) in
            print(error.localizedDescription)
        }
    }

}
