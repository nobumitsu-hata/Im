//
//  LoginViewController.swift
//  Im
//
//  Created by nobumitsu on 2019/05/28.
//  Copyright © 2019 im. All rights reserved.
//

import UIKit
import Firebase
import FBSDKCoreKit
import FBSDKLoginKit
import GoogleSignIn
import TwitterKit

class LoginViewController: UIViewController, LoginButtonDelegate, GIDSignInDelegate, GIDSignInUIDelegate  {
    
    private let db = Firestore.firestore()
    private let storageRef = Storage.storage().reference()
    var dstView:LoginTestViewController!
    
    @IBOutlet weak var LoginBtns: UIView!
    
    override func viewWillAppear(_ animated: Bool) {
//        dstView = storyboard?.instantiateViewController(withIdentifier: "LoginTestViewController") as! LoginTestViewController
        // ログインボタン
        let fbLoginBtn = FBLoginButton()
        
        fbLoginBtn.permissions = ["public_profile", "email"]
        fbLoginBtn.setBackgroundImage(UIImage(named: "Facebook"), for: .normal)
        fbLoginBtn.setImage(UIImage(), for: .normal)
        fbLoginBtn.titleLabel?.removeFromSuperview()
        fbLoginBtn.frame = CGRect(x: 0, y: 0, width: 45, height: 45)
        
        fbLoginBtn.delegate = self
        LoginBtns.addSubview(fbLoginBtn)
        
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().delegate = self
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        
        if let error = error {
            print(error.localizedDescription)
            return
        }
        
        if result!.isCancelled {
            print("キャンセル押した")
            return
        }

        guard (result!.grantedPermissions.contains("email")) else {
            return
        }
        
        let token = result!.token
        // FBのアクセストークンをFirebase認証情報に交換
        let credential = FacebookAuthProvider.credential(withAccessToken: token!.tokenString)
        
        // Firebaseの認証
        Auth.auth().signIn(with: credential) { (authResult, error) in
            if error != nil {
                print("エラー文")
                print(error as Any)
                return
            }
            print("ログイン成功")
            
            // ログイン成功時の処理
            let userId = (authResult?.user.uid)!
            
            self.db.collection("users").document(userId).getDocument { (document, error) in
                if let userDoc = document.flatMap({
                    $0.data().flatMap({ (data) in
                        return data
                    })
                }) {
                    print("City: \(userDoc)")
                    RootTabBarController.UserId = userId
                    RootTabBarController.UserInfo = userDoc
                    RootTabBarController.AuthCheck = true
                    
                    let LoginController = self.tabBarController?.viewControllers?[2]
                    print(LoginController)
                    self.tabBarController?.selectedViewController = LoginController
//                    self.dismiss(animated: false, completion: nil)
                } else {
                    print("Document does not exist")
                    self.tempRegister(userId: userId, tokenStr: token!.tokenString)
                }
            }

        }
        
    }
    
    // 仮登録
    func tempRegister(userId: String, tokenStr: String) {
        GraphRequest(graphPath: "/me", parameters: ["fields" : "id, name, email, picture.type(large)"]).start { (connection, userInfo, err) in
            if(err != nil){
                print("Failed to start GraphRequest", err ?? "")
                return
            }
            
            // ユーザー情報
            let user = userInfo as! [String:Any]
            let name = user["name"] as! String
            let picture = user["picture"] as! [String:[String:Any]]
            let img = picture["data"]!["url"] as! String
            let email = user["email"] as! String
            
            // facebookからプロフィール画像取得
            self.downLoadImage(imageUrl: img) { (image) in
                guard image != nil  else {
                    return
                }
                
                if let imgData = image?.jpegData(compressionQuality: 0.8) {
                    
                    let fileName = userId + ".jpg"
                    let meta = StorageMetadata()
                    meta.contentType = "image/jpeg"
                    let ref = self.storageRef.child("users").child(fileName)
                    
                    // プロフィール画像 アップロード
                    ref.putData(imgData, metadata: meta, completion: { metaData, error in
                        
                        if error != nil {
                            print(error!.localizedDescription)
                        }
                        
                        // プロフ画URL取得
                        ref.downloadURL(completion: { (url, err) in
                            
                            let fields = [
                                "name": name,
                                "introduction": "",
                                "sex": "",
                                "birthday": 0,
                                "status": "auth",
                                "contact": email,
                                "img": fileName,
                                "imgUrl": url!.absoluteString,
                                "authType": "facebook",
                                "token": tokenStr
                                ] as [String : Any]
                            
                            // 仮登録
                            self.db.collection("users").document(userId).setData(fields) { err in
                                if let err = err {
                                    print("Error adding document: \(err)")
                                } else {
                                    print("登録")
                                    RootTabBarController.userId = userId
                                    RootTabBarController.UserInfo = fields
                                    RootTabBarController.AuthCheck = true
                                }
                            }
                        })
                        
                    })
                }
            }
            
        }// GraphRequest
    }
    
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        let fbLoginManager = LoginManager()
        fbLoginManager.logOut()
    }
    
    @IBAction func tapTwitterLogin(_ sender: Any) {
        TWTRTwitter.sharedInstance().logIn(completion: { (session, error) in
            print(session)
            guard session != nil else {
                print("twitterエラー")
                print("error: \(error!.localizedDescription)")
                return
            }
            let authToken = session!.authToken
            let authTokenSecret = session!.authTokenSecret
            
            let credential = TwitterAuthProvider.credential(withToken: authToken, secret: authTokenSecret)
            print("signed in as \(session!.userName)")
            
            Auth.auth().signIn(with: credential) { (authResult, error) in
                if let error = error {
                    print("error: \(error.localizedDescription)")
                    return

                }
                //Sign In Completed
                print("ログイン成功")
                
                // ログイン成功時の処理
                let userId = (authResult?.user.uid)!
                
                self.db.collection("users").document(userId).getDocument { (document, error) in
                    if let userDoc = document.flatMap({
                        $0.data().flatMap({ (data) in
                            return data
                        })
                    }) {
                        RootTabBarController.UserId = userId
                        RootTabBarController.UserInfo = userDoc
                        RootTabBarController.AuthCheck = true
                        
                    } else {
                        print("Document does not exist")
                        // facebookからプロフィール画像取得
                        
                        var img = ""
                        let name = session!.userName
                        var userEmail = ""
                        let token = authToken + "," + authTokenSecret
                        let client = TWTRAPIClient.withCurrentUser()
                        client.requestEmail { email, error in
                            if (email != nil) {
                                userEmail = email!
                                print("signed in as \(session!.userName)");
                            } else {
                                print("error: \(error!.localizedDescription)");
                            }
                        }
                        client.loadUser(withID: session!.userID, completion: { (user, error) in
                            img = user?.profileImageLargeURL ?? ""
                            print("画像")
                            print(img)
                            if img == "" {
                                let fields = [
                                    "name": name,
                                    "introduction": "",
                                    "sex": "",
                                    "birthday": 0,
                                    "status": "auth",
                                    "contact": userEmail,
                                    "img": "",
                                    "imgUrl": "",
                                    "authType": "twitter",
                                    "token": token
                                    ] as [String : Any]
                                
                                // 仮登録
                                self.db.collection("users").document(userId).setData(fields) { err in
                                    if let err = err {
                                        print("Error adding document: \(err)")
                                    } else {
                                        print("登録")
                                        RootTabBarController.userId = userId
                                        RootTabBarController.UserInfo = fields
                                        RootTabBarController.AuthCheck = true
                                    }
                                }
                            } else {
                                
                                // プロフィール画像 ダウンロード
                                self.getDataFromUrl(url: URL(string: img)!, completion: { (data, response, error) in
                                    
                                    guard let data = data, error == nil  else {
                                        return
                                    }
                                    
                                    let image = UIImage(data: data)
                                    if let imgData = image?.jpegData(compressionQuality: 0.8) {
                                        
                                        let fileName = userId + ".jpg"
                                        let meta = StorageMetadata()
                                        meta.contentType = "image/jpeg"
                                        let ref = self.storageRef.child("users").child(fileName)
                                        
                                        // プロフィール画像 アップロード
                                        ref.putData(imgData, metadata: meta, completion: { metaData, error in
                                            
                                            if error != nil {
                                                print(error!.localizedDescription)
                                            }
                                            
                                            // プロフ画URL取得
                                            ref.downloadURL(completion: { (url, err) in
                                                
                                                let fields = [
                                                    "name": name,
                                                    "introduction": "",
                                                    "sex": "",
                                                    "birthday": 0,
                                                    "status": "auth",
                                                    "contact": userEmail,
                                                    "img": fileName,
                                                    "imgUrl": url!.absoluteString,
                                                    "authType": "twitter",
                                                    "token": token
                                                    ] as [String : Any]
                                                
                                                // 仮登録
                                                self.db.collection("users").document(userId).setData(fields) { err in
                                                    if let err = err {
                                                        print("Error adding document: \(err)")
                                                    } else {
                                                        print("登録")
                                                        RootTabBarController.userId = userId
                                                        RootTabBarController.UserInfo = fields
                                                        RootTabBarController.AuthCheck = true
                                                    }
                                                }
                                            })
                                            
                                        })
                                    }
                                })
                            }
                        })
                        
                        
                        
                    }
                }
            }
            
            
        })
        
    }
    
    @IBAction func tapGoogleSingIn(_ sender: Any) {
        GIDSignIn.sharedInstance().signIn()
    }
    
    @IBAction func facebookLogin(_ sender: Any) {
        let test = LoginManager()
        test.logIn(permissions: ["public_profile", "email"], from: self, handler: { (result, error) -> Void in
            
            if (error == nil){
                let fbloginresult : LoginManagerLoginResult = result!
                
                if(fbloginresult.isCancelled) {
                    //Show Cancel alert
                    print("キャンセル")
                } else if(fbloginresult.grantedPermissions.contains("email")) {
                    //                    self.returnUserData()
                    //fbLoginManager.logOut()
                }
            }
        })
    }
    
    func getDataFromUrl(url: URL, completion: @escaping (_ data: Data?, _  response: URLResponse?, _ error: Error?) -> Void) {
        URLSession.shared.dataTask(with: url) {
            (data, response, error) in
            completion(data, response, error)
        }.resume()
    }
    
    func downLoadImage(imageUrl: String, completion: @escaping(_ image: UIImage?) -> Void) {
        let imageURL = NSURL(string: "https://pbs.twimg.com/profile_images/1116970647408615424/PS7ON4d3_reasonably_small.jpg")
        let imageFileName = (imageUrl.components(separatedBy: "%").last!).components(separatedBy: "?").first!
        
        if fileExistsAtPath(path: imageFileName) {
            
            if let contentsOfFile = UIImage(contentsOfFile: fileInDocumentsDirectory(fileName: imageFileName)) {
                completion(contentsOfFile)
            } else {
                print("失敗")
                completion(nil)
            }
        } else {
            let downloadQueue = DispatchQueue(label: "imageDownloadQueue")
            downloadQueue.async {
                let data = NSData(contentsOf: imageURL! as URL)
                
                if data != nil {
                    var docURL = self.getDocumentsURL()
                    docURL = docURL.appendingPathComponent(imageFileName, isDirectory: false)
                    data!.write(to: docURL, atomically: true)
                    let imageToReturn = UIImage(data: data! as Data)
                    DispatchQueue.main.async {
                        completion(imageToReturn!)
                    }
                } else {
                    DispatchQueue.main.async {
                        print("no image in database")
                        completion(nil)
                    }
                }
            }
        }
    }
    
    func fileInDocumentsDirectory(fileName: String) -> String {
        let fileURL = getDocumentsURL().appendingPathComponent(fileName)
        return fileURL.path
    }
    
    func getDocumentsURL() -> URL {
        let documentURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last
        return documentURL!
    }
    
    func fileExistsAtPath(path:String) -> Bool {
        var doesExist = false
        let filePath = fileInDocumentsDirectory(fileName: path)
        let fileManager = FileManager.default
        
        if fileManager.fileExists(atPath: filePath) {
            doesExist = true
        } else {
            doesExist = false
        }
        
        return doesExist
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error?) {
        
        if let error = error {
            print("Error: \(error.localizedDescription)")
            return
        }
        
        guard let authentication = user.authentication else { return }
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken,
                                                       accessToken: authentication.accessToken)
        // Firebaseにログインする。
        Auth.auth().signIn(with: credential) { (authResult, error) in
            if error != nil {
                print(error as Any)
                return
            }
            print("ログイン成功")
            
            // ログイン成功時の処理
            let userId = (authResult?.user.uid)!
            
            self.db.collection("users").document(userId).getDocument { (document, error) in
                if let userDoc = document.flatMap({
                    $0.data().flatMap({ (data) in
                        return data
                    })
                }) {
                    RootTabBarController.UserId = userId
                    RootTabBarController.UserInfo = userDoc
                    RootTabBarController.AuthCheck = true
                    
                } else {
                    print("Document does not exist")
                    // facebookからプロフィール画像取得
                    
                    let img = user.profile.imageURL(withDimension: 200)
                    let name = user.profile.name
                    let email = user.profile.email
                    let token = authentication.idToken + "," + authentication.accessToken
                    
                    self.downLoadImage(imageUrl: img!.absoluteString) { (image) in
                        guard image != nil  else {
                            return
                        }
                        
                        if let imgData = image?.jpegData(compressionQuality: 0.8) {
                            
                            let fileName = userId + ".jpg"
                            let meta = StorageMetadata()
                            meta.contentType = "image/jpeg"
                            let ref = self.storageRef.child("users").child(fileName)
                            
                            // プロフィール画像 アップロード
                            ref.putData(imgData, metadata: meta, completion: { metaData, error in
                                
                                if error != nil {
                                    print(error!.localizedDescription)
                                }
                                
                                // プロフ画URL取得
                                ref.downloadURL(completion: { (url, err) in
                                    
                                    let fields = [
                                        "name": name!,
                                        "introduction": "",
                                        "sex": "",
                                        "birthday": 0,
                                        "status": "auth",
                                        "contact": email!,
                                        "img": fileName,
                                        "imgUrl": url!.absoluteString,
                                        "authType": "google",
                                        "token": token
                                        ] as [String : Any]
                                    
                                    // 仮登録
                                    self.db.collection("users").document(userId).setData(fields) { err in
                                        if let err = err {
                                            print("Error adding document: \(err)")
                                        } else {
                                            print("登録")
                                            RootTabBarController.userId = userId
                                            RootTabBarController.UserInfo = fields
                                            RootTabBarController.AuthCheck = true
                                        }
                                    }
                                })
                                
                            })
                        }
                    }
                }
            }

            //画面遷移処理
        }
    }
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        // Perform any operations when the user disconnects from app here.
        // ...
    }

    
}
