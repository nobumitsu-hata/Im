//
//  ScrollViewController.swift
//  Im
//
//  Created by nobumitsu on 2019/03/30.
//  Copyright © 2019 im. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import FirebaseUI
import FirebaseFirestore
import CoreLocation

class MyTapGestureRecognizer: UITapGestureRecognizer {
    var targetString: String?
}

class ScrollViewController: UIViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    var storage: Storage!
    private let db = Firestore.firestore()
    var appGuideView:UIView!
    
    var communityKey:[String] = []
    var communityVal:[[String:Any]] = []
    
    var scrollScreenHeight:CGFloat!// ScrollScreenの高さ
    var scrollScreenWidth:CGFloat!// ScrollScreenの幅
    var screenSize:CGRect!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // ページスクロールとするためにページ幅を合わせる
        screenSize = UIScreen.main.bounds
        scrollScreenWidth = screenSize.width
        scrollScreenHeight = screenSize.height
        self.view.setGradientLayer()
        setAppGuide()
        setupFirebase()
        
    }
    
    func setAppGuide() {
        let communityXib = UINib(nibName: "CommunityTableViewCell", bundle: Bundle(for: type(of: self)))
        appGuideView = communityXib.instantiate(withOwner: self, options: nil).first as? UIView
        appGuideView.isUserInteractionEnabled = true
        // 描画開始の x,y 位置
        let px:CGFloat = 0.0
        let py:CGFloat = 0.0
        
        // コミュニティー画像設定
        let imgView  = appGuideView.viewWithTag(2) as! UIImageView
        imgView.image = UIImage(named: "AppGuide")
        imgView.isUserInteractionEnabled = true
        
        // 描画開始設定
        var viewFrame:CGRect = appGuideView.frame
        viewFrame.size.width = self.scrollScreenWidth
        viewFrame.size.height = self.scrollScreenHeight
        viewFrame.origin = CGPoint(x: px, y: py)
        appGuideView.frame = viewFrame
        
        self.scrollView.addSubview(appGuideView)
        
        // スクロール範囲の設定
        let nHeight:CGFloat = self.scrollScreenHeight * CGFloat(1)
        self.scrollView.contentSize = CGSize(width: self.scrollScreenWidth, height: nHeight)
    }
    
    func setupFirebase() {
        storage = Storage.storage()
        
        let communityXib = UINib(nibName: "CommunityTableViewCell", bundle: Bundle(for: type(of: self)))
        
        // 描画開始の x,y 位置
        let px:CGFloat = 0.0
        var py:CGFloat = 0.0
        
        var counter = 1
        
        db.collection("locations").getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
                return
            }
            guard querySnapshot!.documents.count > 0 else {
                return
            }
            
            for document in querySnapshot!.documents {
                print("\(document.documentID) => \(document.data())")
                let communityView = communityXib.instantiate(withOwner: self, options: nil).first as! UIView
                communityView.isUserInteractionEnabled = true
                
                let data = document.data()
                let documentId = document.documentID
                let latitude = data["latitude"] as! String
                let longitude = data["longitude"] as! String
                
                let baseLocation: CLLocation = CLLocation(latitude: Double(latitude)!, longitude: Double(longitude)!)
                let targetLocation: CLLocation = CLLocation(latitude: Double(latitude)!, longitude: Double(longitude)!)
                let distanceLocation = baseLocation.distance(from: targetLocation)
                print("距離は \(distanceLocation)")
                
                let radius = data["radius"] as! Double
                
                guard radius >= distanceLocation else {
                    return
                }
                
                self.db.collection("communities").document(documentId).getDocument { (document, error) in
                    if let community = document.flatMap({
                        $0.data().flatMap({ (data) in
                            return data
                        })
                    }) {
                        print("community: \(community)")
                        
                        // コミュニティー名設定
                        let titleLabel = communityView.viewWithTag(1) as! UILabel
                        let title = community["name"] as! String
                        titleLabel.textColor = UIColor.white
                        titleLabel.text = String(describing: title)
                        // コミュニティー画像設定
                        let img  = communityView.viewWithTag(2) as! UIImageView
                        let storageRef = self.storage.reference()
                        let imgData = storageRef.child("communities").child(community["img"] as! String)
                        img.sd_setImage(with: imgData)
                        img.isUserInteractionEnabled = true
                        
                        let gesture = MyTapGestureRecognizer(target: self, action: #selector(ScrollViewController.btnClick(_:)))
                        gesture.targetString = documentId
                        communityView.addGestureRecognizer(gesture)
                        self.scrollView.addSubview(communityView)
                        
                        // 描画開始設定
                        var viewFrame:CGRect = communityView.frame
                        viewFrame.size.width = self.scrollScreenWidth
                        viewFrame.size.height = self.scrollScreenHeight
                        viewFrame.origin = CGPoint(x: px, y: py)
                        communityView.frame = viewFrame
                        
                        // 次の描画位置設定
                        py += (self.screenSize.height)
                        counter += 1
                        
                        var appGuideViewFrame:CGRect = self.appGuideView.frame
                        appGuideViewFrame.size.width = self.scrollScreenWidth
                        appGuideViewFrame.size.height = self.scrollScreenHeight
                        appGuideViewFrame.origin = CGPoint(x: px, y: py)
                        self.appGuideView.frame = appGuideViewFrame
                        
                        // スクロール範囲の設定
                        let nHeight:CGFloat = self.scrollScreenHeight * CGFloat(counter)
                        self.scrollView.contentSize = CGSize(width: self.scrollScreenWidth, height: nHeight)
                    } else {
                        print("Document does not exist")
                    }
                }
                
            }
            
        }
        
    }
    
    override var prefersStatusBarHidden:Bool {
        // trueの場合はステータスバー非表示
        return true;
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toChatViewController" {
            let nav = segue.destination as! UINavigationController
            let chatViewController = nav.topViewController as! ChatViewController
            chatViewController.communityId = (sender as! String)
        }
    }
    
    @objc func btnClick(_ sender:MyTapGestureRecognizer) {
        
        //  ログイン済み
        if RootTabBarController.AuthCheck {
            // 仮登録状態の場合
            if RootTabBarController.UserInfo["status"] as? Int  == 0 {
                let modalViewController = storyboard?.instantiateViewController(withIdentifier: "RegisterViewController") as! RegisterViewController
                present(modalViewController, animated: true, completion: {
                    modalViewController.fromWhere = "RootTabBarController"
                })
                
            } else {
                tabBarController?.tabBar.isHidden = true
                performSegue(withIdentifier: "toChatViewController", sender: sender.targetString)
            }
        } else {
            
            let modalViewController = storyboard?.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
            modalViewController.modalPresentationStyle = .custom
            modalViewController.transitioningDelegate = self
            present(modalViewController, animated: true, completion: nil)
        }
    }
    
}

extension ScrollViewController: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return LoginPresentationController(presentedViewController: presented, presenting: presenting)
    }
}
