//
//  EditProfileViewController.swift
//  Im
//
//  Created by nobumitsu on 2019/04/08.
//  Copyright © 2019 im. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase

class EditProfileViewController: UIViewController {
    
    var ref: DatabaseReference!
    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var textField: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.tintColor = UIColor.white
        
        let border = CALayer()
        let width = CGFloat(2.0)
        
        border.borderColor = UIColor.white.cgColor
        border.frame = CGRect(x: 0, y: textField.frame.size.height*1.5, width:  textField.frame.size.width, height: 1)
        border.borderWidth = width
        textField.layer.addSublayer(border)
        
        setupFirebase()
    }
    
    func setupFirebase() {
        ref = Database.database().reference()
        ref.child("users").observeSingleEvent(of: .value, with: { (snapshot) in
            print(snapshot.exists())
            if snapshot.exists() {
                
            } else {
                // 画像設定
                let img = UIImage(named: "UserImg")
                self.imgView.image = img
                
                self.textField.text =  "未設定"
            }
        }) { (error) in
            print(error.localizedDescription)
        }
    }

}
