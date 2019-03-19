//
//  ChatViewController.swift
//  Im
//
//  Created by nobumitsu on 2019/03/18.
//  Copyright © 2019 im. All rights reserved.
//

import UIKit

class ChatViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var inputWrap: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        self.view.backgroundColor = UIColor.clear
        tableView.backgroundColor = UIColor.clear
        inputWrap.backgroundColor = UIColor.clear
        
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
