//
//  BlockUsersViewController.swift
//  Im
//
//  Created by nobumitsu on 2019/07/22.
//  Copyright © 2019 im. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import FirebaseUI
import FirebaseFirestore

class BlockUsersViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    private let db = Firestore.firestore()
    private let storageRef = Storage.storage().reference()
    var blockUserArr:[DocumentSnapshot] = []
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        view.setGradientLayer()
        tableView.backgroundColor  = .clear
        
        navigationController?.navigationBar.tintColor = .white
        
        db.collection("users").document(RootTabBarController.UserId).collection("blockUsers").getDocuments { (querySnapshot, error) in
            
            if let error = error {
                print("Error getting documents: \(error)")
                return
            }
            
            guard querySnapshot!.documents.count > 0 else {
                print("empty")
                return
            }
            
            for document in querySnapshot!.documents {
                self.db.collection("users").document(document.documentID).getDocument(completion: { (documentSnapshot, err) in
                    
                    if let err = err {
                        print("Error getting documents: \(err)")
                        return
                    }
                    
                    self.blockUserArr.append(documentSnapshot!)
                    self.tableView.reloadData()
                })
            }
            
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.tabBarController?.tabBar.isHidden = false
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return blockUserArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "blockUserCell", for: indexPath)
        cell.backgroundColor = .clear
        
        let userData =  blockUserArr[indexPath.row].data()
        
        if let imgView = cell.viewWithTag(1) as? UIImageView {
            
            imgView.layer.cornerRadius = imgView.frame.size.width * 0.5
            imgView.clipsToBounds = true
            
            if userData?["img"] as! String != "" {
                let imgRef = storageRef.child("users").child(userData?["img"] as! String)
                imgView.sd_setImage(with: imgRef)
            } else {
                imgView.image = UIImage(named: "UserImg")
            }
            
        }
        
        if let name = cell.viewWithTag(2) as? UILabel {
            name.text = userData?["name"] as? String
        }
        
        // 選択された背景色を透明に設定
        let cellSelectedBgView = UIView()
        cellSelectedBgView.backgroundColor = UIColor.clear
        cell.selectedBackgroundView = cellSelectedBgView
        
        return cell
    }
    
    // Cell が選択された場合
    func tableView(_ table: UITableView,didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "fromBlockUsersToOtherProfile", sender: blockUserArr[indexPath.row])
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "fromBlockUsersToOtherProfile" {
            let profileViewController = segue.destination as! OtherProfileViewController
            profileViewController.userId = (sender as? DocumentSnapshot)!.documentID
            profileViewController.backChatCount = 0
        }
    }

}
