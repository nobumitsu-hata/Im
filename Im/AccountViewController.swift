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
import FirebaseFirestore
import TwitterKit

class AccountViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UINavigationControllerDelegate {
    
    var storage: Storage!
    private let db = Firestore.firestore()
    let contentViewController = UINavigationController(rootViewController: UIViewController())
    let sidemenuViewController = SidemenuViewController()
    private var isShownSidemenu: Bool {
        return sidemenuViewController.parent == self
    }
    
    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var nameLbl: UILabel!
    @IBOutlet weak var editBtn: UIButton!
    @IBOutlet weak var wrapperView: UIView!
    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var introduction: UITextView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var menuBtn: UIBarButtonItem!
    
    var userData:[String:Any]!
    let belongsArr = ["好きなチーム", "観戦仲間", "ファンレベル"]
    var belongsVal = ["未設定", "未設定", "未設定"]
    var communityId = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sidemenuViewController.delegate = self
        sidemenuViewController.startPanGestureRecognizing()

        // 編集ボタンカスタマイズ
        editBtn.setGradientBackground(
            colorOne: UIColor(displayP3Red: 147/255, green: 6/255, blue: 229/255, alpha: 1.0),
            colorTwo: UIColor(displayP3Red: 23/255, green: 232/255, blue: 252/255, alpha: 1.0)
        )
        
        menuBtn.tintColor = .white
        
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
        print("フラッシュ")
        print(RootTabBarController.profileListener)
        setupFirebase()
        print(RootTabBarController.profileListener)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("どうなん")
        print(RootTabBarController.profileListener)
        if (RootTabBarController.profileListener != nil) {
            print("リッスン済み")
            return
        }
        
        print("再度リッスン")
        setupFirebase()
    }
    
    func setupFirebase() {
        RootTabBarController.profileListener = db.collection("users").document(RootTabBarController.UserId).addSnapshotListener { documentSnapshot, error in
            guard let document = documentSnapshot else {
                print("Error fetching document: \(error!)")
                return
            }
            self.userData = document.data()
            let storageRef = self.storage.reference()
            if self.userData?["img"] as! String != "" {
                let imgRef = storageRef.child("users").child(self.userData?["img"] as! String)
                DispatchQueue.main.async {
                    self.imgView.sd_setImage(with: imgRef)
                    self.imgView.setNeedsLayout()
                }
            } else {
                self.imgView.image = UIImage(named: "UserImg")
            }

            self.nameLbl.text = (self.userData!["name"] as! String)

            if (self.userData?["introduction"] as? String != "") {
                print("紹介文あり")
                self.introduction.text = self.userData?["introduction"] as? String
            } else {
                print("紹介文なし")
                self.introduction.isHidden = true
            }

            self.db.collection("users").document(RootTabBarController.UserId).collection("belongs").getDocuments() { (querySnapshot, err) in
                guard let documents = querySnapshot?.documents else {
                    print("Error fetching documents: \(error!)")
                    return
                }
                guard documents.count > 0 else {
                    return
                }

                for document in documents {

                    self.communityId = document.documentID
                    let data = document.data()
                    self.db.collection("communities").document(self.communityId).getDocument { (communityDoc, error) in

                        let communityData = communityDoc?.data()

                        self.belongsVal[0] = communityData?["name"] as! String
                        if (data["friend"] as? Bool)! { self.belongsVal[1] = "いる" }
                        else if data["friend"] as? Bool == false { self.belongsVal[1] = "いない" }
                        // ファンレベル
                        guard data["level"] as? String != "" else {
                            return
                        }
                        self.db.collection("levels").document(data["level"] as! String).getDocument { (levelDoc, error) in
                            if let levelDoc = levelDoc, levelDoc.exists {
                                let levelData = levelDoc.data()
                                self.belongsVal[2] = levelData?["name"] as! String
                                self.tableView.reloadData()
                            } else {
                                print("Document does not exist")
                            }
                        }

                        self.tableView.reloadData()
                    }
                }
            }
        }

    }
    
    // MARK: UITableView delegate
    
    func tableView(_ table: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // セル生成
        let cell = table.dequeueReusableCell(withIdentifier: "ProfileCell", for: indexPath) as! ProfileTableViewCell
        cell.backgroundColor = UIColor.clear
        
        cell.keyLbl.text = belongsArr[indexPath.row]
        cell.valLbl.text = belongsVal[indexPath.row]
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return belongsVal.count
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 43
    }
    
    @IBAction func toEdit(_ sender: Any) {
        self.performSegue(withIdentifier: "toEditProfileViewController", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "toEditProfileViewController" {
            let editProfileViewController = segue.destination as! EditProfileViewController
            for i in 0..<3 {
                if belongsVal[i] == "未設定" {
                    belongsVal[i] = "選択してください"
                }
            }
            editProfileViewController.belongsCommunityId = communityId
            editProfileViewController.belongsVal = belongsVal
        }
    }
    
    
    // MARK: サイドメニュー
    
    @IBAction func sidemenuButtonTapped(_ sender: Any) {
        if isShownSidemenu {
            hideSidemenu(animated: true)
            return
        }
        showSidemenu(animated: true)
    }
    
    private func showSidemenu(contentAvailability: Bool = true, animated: Bool) {
        if isShownSidemenu { return }
        
        addChild(sidemenuViewController)
        sidemenuViewController.view.autoresizingMask = .flexibleHeight
        sidemenuViewController.view.frame = view.bounds
        view.insertSubview(sidemenuViewController.view, aboveSubview: view)
        sidemenuViewController.didMove(toParent: self)
        if contentAvailability {
            sidemenuViewController.showContentView(animated: animated)
        }
    }
    
    private func hideSidemenu(animated: Bool) {
        if !isShownSidemenu { return }
        
        sidemenuViewController.hideContentView(animated: animated, completion: { (_) in
            self.sidemenuViewController.willMove(toParent: nil)
            self.sidemenuViewController.removeFromParent()
            self.sidemenuViewController.view.removeFromSuperview()
        })
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
    
    func introductionGradient(startColor: UIColor, endColor: UIColor, radius:CGFloat) {
        
        //グラデーションの色を配列で管理
        let gradientColors: [CGColor] = [startColor.cgColor, endColor.cgColor]
        //グラデーションレイヤーを作成
        let gradientLayer: CAGradientLayer = CAGradientLayer()
        //グラデーションの色をレイヤーに割り当てる
        gradientLayer.colors = gradientColors
        //グラデーションレイヤーをスクリーンサイズにする
        gradientLayer.frame = CGRect(x: 0, y: frame.size.height - 1, width: bounds.size.width - 30, height: 1)
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
        gradientLayer.frame = CGRect(x: 0, y: frame.size.height - 1, width: bounds.size.width, height: 1)
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

extension AccountViewController: SidemenuViewControllerDelegate {
    func parentViewControllerForSidemenuViewController(_ sidemenuViewController: SidemenuViewController) -> UIViewController {
        return self
    }
    
    func logout() {
        tabBarController?.selectedIndex = 0
        RootTabBarController.AuthCheck = false
        print("リムーブ")
        RootTabBarController.profileListener.remove()
        RootTabBarController.profileListener = nil
        print(RootTabBarController.profileListener)
//        let sessionStore = TWTRTwitter.sharedInstance().sessionStore
//        // アクティブなアカウントのsessionを取得
//        if let session = sessionStore.session() {
//            // userIDでログアウト
//            print("twitterログアウト")
//            sessionStore.logOutUserID(session.userID)
//        }

    }
    
    func shouldPresentForSidemenuViewController(_ sidemenuViewController: SidemenuViewController) -> Bool {
        /* You can specify sidemenu availability */
        return true
    }
    
    func toDeleteViewController() {
        self.performSegue(withIdentifier: "toDeleteViewController", sender: nil)
    }
    
    func sidemenuViewControllerDidRequestShowing(_ sidemenuViewController: SidemenuViewController, contentAvailability: Bool, animated: Bool) {
        showSidemenu(contentAvailability: contentAvailability, animated: animated)
    }
    
    func sidemenuViewControllerDidRequestHiding(_ sidemenuViewController: SidemenuViewController, animated: Bool) {
        hideSidemenu(animated: animated)
    }
    
    func sidemenuViewController(_ sidemenuViewController: SidemenuViewController, didSelectItemAt indexPath: IndexPath) {
        hideSidemenu(animated: true)
    }
}
