//
//  SpotViewController.swift
//  Im
//
//  Created by nobumitsu on 2019/06/25.
//  Copyright © 2019 im. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import FirebaseFirestore

class SpotViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var bar: UINavigationBar!
    
    private let db = Firestore.firestore()
    var communityArr:[QueryDocumentSnapshot] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        view.setGradientLayer()
        tableView.backgroundColor = .clear
        bar.setBackgroundImage(UIImage(), for: .default)
        bar.shadowImage = UIImage()
        setupFirebase()
    }
    
    func setupFirebase() {
        db.collection("communities").getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
                return
            }
            guard querySnapshot!.documents.count > 0 else {
                return
            }
            
            self.communityArr = querySnapshot!.documents
            self.tableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return communityArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // セル生成
        let cell = tableView.dequeueReusableCell(withIdentifier: "SpotCell", for: indexPath)
        let name = cell.viewWithTag(1) as! UILabel
        name.text = communityArr[indexPath.row]["spot"] as? String
        cell.backgroundColor = .clear
        return cell
    }
}
