//
//  MessageViewController.swift
//  Im
//
//  Created by nobumitsu on 2019/03/13.
//  Copyright © 2019 im. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import FirebaseUI

class MessageViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var ref: DatabaseReference!
    var storage: StorageReference!
    var dmKeyArr:[String] = []
    var dmValArr:[String] = []
    @IBOutlet weak var tableView: UITableView!
    
    override func viewWillAppear(_ animated: Bool) {
        tableView.delegate = self
        tableView.dataSource = self
        // 自作セルをテーブルビューに登録する
        let chatXib = UINib(nibName: "MessageTableViewCell", bundle: nil)
        tableView.register(chatXib, forCellReuseIdentifier: "messageCell")
        setupFirebase()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // ナビゲーションを透明にする処理
        self.navigationController!.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController!.navigationBar.shadowImage = UIImage()
        // ナビゲーションバーのテキストを変更する
        navigationController?.navigationBar.titleTextAttributes = [
            // 文字の色
            .foregroundColor: UIColor.white
        ]
    }
    
    func setupFirebase() {
        storage = Storage.storage().reference()
        ref = Database.database().reference()
        
        ref.child("dmMembers").child(RootTabBarController.userId).observeSingleEvent(of: .value, with: { (snapshot) in
            let val = snapshot.value as! [String:String]
            self.dmKeyArr = Array(val.keys)
            self.dmValArr = Array(val.values)
            self.tableView.reloadData()
        }) { (error) in
            
        }
    }
    
    func tableView(_ table: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // セル生成
        let cell = table.dequeueReusableCell(withIdentifier: "messageCell", for: indexPath) as! MessageTableViewCell
        ref.child("users").child(dmKeyArr[indexPath.row]).observeSingleEvent(of: .value, with: { (snapshot) in
            let val = snapshot.value as! [String:String]
            cell.name.text = val["name"]
            let getImg = self.storage.child("users").child(val["img"]!)
            cell.imgView.sd_setImage(with: getImg)
            // 角丸にする
            cell.imgView.layer.cornerRadius = cell.imgView.frame.size.width * 0.5
            cell.imgView.clipsToBounds = true
            self.ref.child("directMessages").child(self.dmValArr[indexPath.row]).queryLimited(toLast: 1).observeSingleEvent(of: .value, with: { (snapshot) in
                let snap = snapshot.value as! [String:Any]
                let dt = Array(snap.values)
                let dic = dt[0] as! [String:String]
                cell.lastMsg.text = dic["message"]
            }) { (error) in
                
            }
        }) { (error) in
            
        }
        
        return cell
    }
    

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dmKeyArr.count
    }

}
