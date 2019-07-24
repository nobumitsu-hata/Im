//
//  PrivacySettingViewController.swift
//  Im
//
//  Created by nobumitsu on 2019/07/22.
//  Copyright © 2019 im. All rights reserved.
//

import UIKit

class PrivacySettingViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        navigationController?.navigationBar.tintColor = .white
        
        self.navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]

        view.setGradientLayer()
        tableView.backgroundColor  = .clear
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "privacySettingCell", for: indexPath)
        cell.backgroundColor = .clear
        
        if let label = cell.viewWithTag(1) as? UILabel {
            label.text = "ブロックリスト"
        }
        
        cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator // ここで「>」ボタンを設定
        
        // 選択された背景色を透明に設定
        let cellSelectedBgView = UIView()
        cellSelectedBgView.backgroundColor = UIColor.clear
        cell.selectedBackgroundView = cellSelectedBgView
        
        return cell
    }

    // Cell が選択された場合
    func tableView(_ table: UITableView,didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "toBlockUsersViewController", sender: nil)
    }

}
