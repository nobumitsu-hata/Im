//
//  ChatViewController.swift
//  Im
//
//  Created by nobumitsu on 2019/03/18.
//  Copyright © 2019 im. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase

class ChatViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var inputWrap: UIView!
    @IBOutlet weak var textField: UITextField!
    
    var ref: DatabaseReference!
    var communityId: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        
        self.view.backgroundColor = UIColor.clear
        tableView.backgroundColor = UIColor.clear
        inputWrap.backgroundColor = UIColor.clear

        ref = Database.database().reference()
        // 自作セルをテーブルビューに登録する
        let chatXib = UINib(nibName: "ChatTableViewCell", bundle: nil)
        tableView.register(chatXib, forCellReuseIdentifier: "chatCell")
    }
    
    func tableView(_ table: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = table.dequeueReusableCell(withIdentifier: "chatCell", for: indexPath) as! ChatTableViewCell
        let name = cell.viewWithTag(2) as! UILabel
        let text = cell.viewWithTag(3) as! UITextView
        cell.backgroundColor = UIColor.clear
        name.backgroundColor = UIColor.clear
        text.backgroundColor = UIColor.clear
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
    
    @IBAction func postMessage(_ sender: UIButton) {
        // TextFieldから文字を取得
        let message = textField.text
        self.ref.child("messages").child(communityId).setValue(["user":RootTabBarController.userId,"message":message])
        // TextFieldの中身をクリア
        textField.text = ""
    }

}
