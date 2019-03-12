//
//  HomeViewController.swift
//  Im
//
//  Created by nobumitsu on 2019/03/12.
//  Copyright © 2019 im. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import FirebaseUI

class HomeViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    var ref: DatabaseReference!
    var storage: Storage!
    var communityArray:[[String:Any]] = []
    
    func setupFirebase() {
        storage = Storage.storage()
        
        ref = Database.database().reference()
        ref.child("communities").observeSingleEvent(of: .value, with: { (snapshot) in
            // Get user value
            let val = snapshot.value as! [String:[String:Any]]
            let community = val.values
            self.communityArray += community
            self.tableView.reloadData()
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        
        // 自作セルをテーブルビューに登録する
        let communityXib = UINib(nibName: "CommunityTableViewCell", bundle: nil)
        tableView.register(communityXib, forCellReuseIdentifier: "communityCell")
        
        setupFirebase()
    }
    
    //各セルの要素を設定する
    func tableView(_ table: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = table.dequeueReusableCell(withIdentifier: "communityCell", for: indexPath) as! CommunityTableViewCell
        
        // Tag番号 1 で UILabel インスタンスの生成
        let titleLabel = cell.viewWithTag(1) as! UILabel
        let title = self.communityArray[indexPath.row]["title"] as! String
        titleLabel.textColor = UIColor.blue
        titleLabel.text = String(describing: title)
        
        let img  = cell.viewWithTag(2) as! UIImageView
        var storageRef = storage.reference()
        var perfumeRef = storageRef.child("perfume.jpg")
        img.sd_setImage(with: perfumeRef)
        
        return cell
    }
    
    //Table Viewのセルの数を指定
    func tableView(_ table: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return communityArray.count
    }
    
    // Cell の高さをスクリーンサイズにする
    func tableView(_ table: UITableView,
                   heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UIScreen.main.bounds.height
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
