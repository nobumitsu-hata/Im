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
    var receiverArr:[[String:String]] = []
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
            self.receiverArr.append(val)
            // 名前セット
            cell.name.text = val["name"]
            // 画像取得
            let getImg = self.storage.child("users").child(val["img"]!)
            cell.imgView.sd_setImage(with: getImg)
            // 角丸にする
            cell.imgView.layer.cornerRadius = cell.imgView.frame.size.width * 0.5
            cell.imgView.clipsToBounds = true
            // ラストメッセージ取得
            self.ref.child("directMessages").child(self.dmValArr[indexPath.row]).queryLimited(toLast: 1).observeSingleEvent(of: .value, with: { (snapshot) in
                let snap = snapshot.value as! [String:Any]
                let dt = Array(snap.values)
                let dic = dt[0] as! [String:String]
                cell.lastMsg.text = dic["message"]
            }) { (error) in
                
            }
        }) { (error) in
            
        }
        
        // 選択された背景色を白に設定
        let cellSelectedBgView = UIView()
        cellSelectedBgView.backgroundColor = UIColor.black
        cell.selectedBackgroundView = cellSelectedBgView
        
        return cell
    }
    

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dmKeyArr.count
    }
    
    // Cell が選択された場合
    func tableView(_ table: UITableView,didSelectRowAt indexPath: IndexPath) {
        // DMViewController へ遷移するために Segue を呼び出す
        performSegue(withIdentifier: "fromListToDMViewController",sender: indexPath.row)
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "fromListToDMViewController" {
            let dmViewController = segue.destination as! DMViewController
            print("レシ")
            print(dmKeyArr[sender as! Int])
            dmViewController.receiver = "uYGxXJ9tDsYz2P7BLCZSf25otPY2"
            dmViewController.receiverInfo = receiverArr[sender as! Int]
        }
    }

}
