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

class AccountViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var ref: DatabaseReference!
    var storage: Storage!
    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var nameLbl: UILabel!
    @IBOutlet weak var editBtn: UIButton!
    @IBOutlet weak var wrapperView: UIView!
    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var introduction: UITextView!
    @IBOutlet weak var tableView: UITableView!
    
    let belongsArr = ["好きなチーム", "観戦仲間", "ファンレベル"]
    var belongsDic = ["好きなチーム": "未設定", "観戦仲間": "未設定", "ファンレベル":"未設定"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // 編集ボタンカスタマイズ
        editBtn.setGradientBackground(
            colorOne: UIColor(displayP3Red: 147/255, green: 6/255, blue: 229/255, alpha: 1.0),
            colorTwo: UIColor(displayP3Red: 23/255, green: 232/255, blue: 252/255, alpha: 1.0)
        )
        
        // 初期化
        storage = Storage.storage()
        tableView.delegate = self
        tableView.dataSource = self
        
        introduction.textContainerInset = UIEdgeInsets.zero
        introduction.textContainer.lineFragmentPadding = 0
        
        self.view.setGradientLayer()
        wrapperView.backgroundColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.2)
        wrapperView.layer.cornerRadius = 20
        mainView.layer.cornerRadius = 20
        tableView.backgroundColor = UIColor.clear
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
                self.nameLbl.text = (val["name"] as! String)
                if (val["introduction"] as? String != "") {
                    print("紹介文あり")
                    self.introduction.text = val["introduction"] as? String
                } else {
                    print("紹介文なし")
                    self.introduction.isHidden = true
                }
            } else {
                // 画像設定
                let img = UIImage(named: "UserImg")
                self.imgView.image = img
                self.nameLbl.text =  "未設定"
            }
            
            self.ref.child("belongs").child(RootTabBarController.userId).observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists() {
                    let belongsVal = snapshot.value as! [String:Any]
                    let keyArr = Array(belongsVal.keys)
                    self.ref.child("communities").child(keyArr[0]).observeSingleEvent(of: .value, with: { (snapshot) in
                        let communityVal = snapshot.value as! [String:Any]
                        self.belongsDic["好きなチーム"] = (communityVal["name"] as! String)
                        let test = belongsVal[keyArr[0]] as! [String: Any]
                        self.belongsDic["ファンレベル"] = test["level"] as? String
                        if (test["friend"] != nil && test["friend"] as? String != "未設定") {
                            self.belongsDic["観戦仲間"] = "いる"
                        }
                        if test["friend"] as? Bool == false {
                            self.belongsDic["観戦仲間"] = "いない"
                        }
                        self.tableView.reloadData()
                    })
                } else {
                    
                }
                
                
            })
        }) { (error) in
            print(error.localizedDescription)
        }
    }
        
    func tableView(_ table: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // セル生成
        let cell = table.dequeueReusableCell(withIdentifier: "ProfileCell", for: indexPath) as! ProfileTableViewCell
        cell.backgroundColor = UIColor.clear
        
        cell.keyLbl.text = belongsArr[indexPath.row]
        cell.valLbl.text = belongsDic[belongsArr[indexPath.row]]
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return belongsDic.count
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 43
    }
    
    @IBAction func toEdit(_ sender: Any) {
        self.performSegue(withIdentifier: "toEditProfileViewController", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toEditProfileViewController" {
            let dmViewController = segue.destination as! EditProfileViewController
            dmViewController.belongsData = belongsDic
        }
    }
}

extension UIView {
    
    func setGradientBackground(colorOne: UIColor, colorTwo: UIColor) {
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = bounds
        gradientLayer.colors = [colorOne.cgColor, colorTwo.cgColor]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.cornerRadius = 15.0
        
        layer.insertSublayer(gradientLayer, at: 0)
    }
    
    func setGradientLayer() {
        //グラデーションの開始色
        let topColor = UIColor(displayP3Red: 147/255, green: 6/255, blue: 229/255, alpha: 1.0)
        //グラデーションの開始色
        let bottomColor = UIColor(displayP3Red: 23/255, green: 232/255, blue: 252/255, alpha: 1.0)
        
        //グラデーションの色を配列で管理
        let gradientColors: [CGColor] = [topColor.cgColor, bottomColor.cgColor]
        
        //グラデーションレイヤーを作成
        let gradientLayer: CAGradientLayer = CAGradientLayer()
        
        //グラデーションの色をレイヤーに割り当てる
        gradientLayer.colors = gradientColors
        //グラデーションレイヤーをスクリーンサイズにする
        gradientLayer.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        // 上から下へグラデーション向きの設定
        gradientLayer.startPoint = CGPoint.init(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint.init(x: 1, y: 1)
        //グラデーションレイヤーをビューの一番下に配置
        layer.insertSublayer(gradientLayer, at:0)
    }
    
    func setGradient(startColor: UIColor, endColor: UIColor, radius:CGFloat) {
        
        //グラデーションの色を配列で管理
        let gradientColors: [CGColor] = [startColor.cgColor, endColor.cgColor]
        //グラデーションレイヤーを作成
        let gradientLayer: CAGradientLayer = CAGradientLayer()
        //グラデーションの色をレイヤーに割り当てる
        gradientLayer.colors = gradientColors
        //グラデーションレイヤーをスクリーンサイズにする
        gradientLayer.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        // 上から下へグラデーション向きの設定
        gradientLayer.startPoint = CGPoint.init(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint.init(x: 1, y: 1)
        // 角丸
        gradientLayer.cornerRadius = radius
        //グラデーションレイヤーをビューの一番下に配置
        layer.insertSublayer(gradientLayer, at:0)
    }
    
    func borderGradient(startColor: UIColor, endColor: UIColor, radius:CGFloat) {
        
        //グラデーションの色を配列で管理
        let gradientColors: [CGColor] = [startColor.cgColor, endColor.cgColor]
        //グラデーションレイヤーを作成
        let gradientLayer: CAGradientLayer = CAGradientLayer()
        //グラデーションの色をレイヤーに割り当てる
        gradientLayer.colors = gradientColors
        //グラデーションレイヤーをスクリーンサイズにする
        gradientLayer.frame = CGRect(x: 0, y: frame.size.height - 1, width: frame.size.width, height: 1)
        // 上から下へグラデーション向きの設定
        gradientLayer.startPoint = CGPoint.init(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint.init(x: 1, y: 1)
        // 角丸
        gradientLayer.cornerRadius = radius
        //グラデーションレイヤーをビューの一番下に配置
        layer.insertSublayer(gradientLayer, at:0)
    }
    
    func setGradientMask(colorStart: UIColor, colorEnd: UIColor) {
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = superview!.bounds
        gradientLayer.colors = [colorStart.cgColor, colorEnd.cgColor]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.1)
        gradientLayer.endPoint = CGPoint(x: 0, y: 0)
        
        superview!.layer.mask = gradientLayer
    }
}
