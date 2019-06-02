//
//  OtherProfileViewController.swift
//  Im
//
//  Created by nobumitsu on 2019/06/03.
//  Copyright © 2019 im. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase

class OtherProfileViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var storage: Storage!
    private let db = Firestore.firestore()
    
    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var nameLbl: UILabel!
    @IBOutlet weak var editBtn: UIButton!
    @IBOutlet weak var wrapperView: UIView!
    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var introduction: UITextView!
    @IBOutlet weak var tableView: UITableView!

    var userId = ""
    var userData:[String:Any]!
    let belongsArr = ["好きなチーム", "観戦仲間", "ファンレベル"]
    var belongsVal = ["未設定", "未設定", "未設定"]
    var communityId = ""

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
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupFirebase()
    }
    
    func setupFirebase() {
        db.collection("users").document(userId).addSnapshotListener { documentSnapshot, error in
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
            }
            
            self.nameLbl.text = (self.userData!["name"] as! String)
            
            if (self.userData?["introduction"] as? String != "") {
                print("紹介文あり")
                self.introduction.text = self.userData?["introduction"] as? String
            } else {
                print("紹介文なし")
                self.introduction.isHidden = true
            }
            
            self.db.collection("users").document(self.userId).collection("belongs").getDocuments() { (querySnapshot, err) in
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
        let cell = table.dequeueReusableCell(withIdentifier: "OtherProfileCell", for: indexPath) as! ProfileTableViewCell
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
    
    
    @IBAction func toPrivateChat(_ sender: Any) {
        self.performSegue(withIdentifier: "toPrivateChatViewController", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "toPrivateChatViewController" {
            let privateChatViewController = segue.destination as! DMViewController
            privateChatViewController.partnerId = userId
            privateChatViewController.partnerData = userData
        }
    }
}
