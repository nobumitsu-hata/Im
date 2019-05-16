//
//  EditProfileViewController.swift
//  Im
//
//  Created by nobumitsu on 2019/04/08.
//  Copyright © 2019 im. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import RSKImageCropper

class EditProfileViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate,UITextViewDelegate, UITableViewDelegate, UITableViewDataSource {
    
    var ref: DatabaseReference!
    var picker: UIImagePickerController! = UIImagePickerController()
    var nowName: String!
    var changeFlg = false
    var selectedImageType: String!
    let storage = Storage.storage()
    
    let belongsArr = ["好きなチーム", "観戦仲間", "ファンレベル"]
    var communityArr:[String] = ["選択してください"]
    var friendsArr:[String] = ["選択してください", "いる", "いない"]
    var levelsArr:[String] = ["選択してください"]
    var belongsData:[String:Any] = [:]
    var communityKey:[String] = []
    
    @IBOutlet weak var wrapperView: UIView!
    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var saveBtn: UIBarButtonItem!
    @IBOutlet weak var imgBtn: UIButton!
    @IBOutlet weak var introduction: UITextView!
    @IBOutlet weak var birthdayField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.tintColor = UIColor.white
        tableView.delegate = self
        tableView.dataSource = self

        // グラデーションセット
        self.view.setGradientLayer()
        nameField.borderGradient(
            startColor: UIColor(displayP3Red: 147/255, green: 6/255, blue: 229/255, alpha: 1.0),
            endColor: UIColor(displayP3Red: 23/255, green: 232/255, blue: 252/255, alpha: 1.0),
            radius: 0
        )
        introduction.delegate = self
        introduction.superview!.borderGradient(
            startColor: UIColor(displayP3Red: 147/255, green: 6/255, blue: 229/255, alpha: 1.0),
            endColor: UIColor(displayP3Red: 23/255, green: 232/255, blue: 252/255, alpha: 1.0),
            radius: 0
        )
        birthdayField.borderGradient(
            startColor: UIColor(displayP3Red: 147/255, green: 6/255, blue: 229/255, alpha: 1.0),
            endColor: UIColor(displayP3Red: 23/255, green: 232/255, blue: 252/255, alpha: 1.0),
            radius: 0
        )
        // 角丸にする
        self.imgView.layer.cornerRadius = self.imgView.frame.size.width * 0.5
        self.imgView.clipsToBounds = true
        
        imgBtn.imageEdgeInsets = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)// ボタンの画像縮小
        wrapperView.backgroundColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.2)
        wrapperView.layer.cornerRadius = 20
        mainView.layer.cornerRadius = 20
        tableView.backgroundColor = UIColor.clear
        
        nameField.text = RootTabBarController.userInfo["name"] as? String
        introduction.text = RootTabBarController.userInfo["introduction"] as? String

        setupFirebase()
    }
    
    func setupFirebase() {
        ref = Database.database().reference()
        if RootTabBarController.userInfo["img"] as? String != "" {
            let storageRef = self.storage.reference()
            let imgRef = storageRef.child("users").child(RootTabBarController.userInfo["img"] as! String)
            self.imgView.sd_setImage(with: imgRef)
        } else {
            
        }
        
        // コミュニティー選択項目設定
        ref.child("communities").observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.exists() {
                let val = snapshot.value as! [String:Any]
                self.communityKey = Array(val.keys)
                let arr = Array(val.values) as! [[String:String]]
                self.communityArr += arr.map({($0["name"])!})
                // ファンレベル選択項目設定
                self.ref.child("levels").observeSingleEvent(of: .value, with: { (snapshot) in
                    if snapshot.exists() {
                        let val = snapshot.value as! [String:Any]
                        var valArr = Array(val.values) as! [[String:Any]]
                        valArr.sort{($0["index"] as! Int) < ($1["index"] as! Int)}// ソート
                        self.levelsArr += valArr.map({(($0["name"]) as? String)!})
                        self.tableView.reloadData()
                    }
                })
                
            }
        })
    }
    
    @IBAction func selectImg(_ sender: Any) {
        //PhotoLibraryから画像を選択
        picker.sourceType = UIImagePickerController.SourceType.photoLibrary
        //デリゲートを設定する
        picker.delegate = self
        //現れるピッカーNavigationBarの文字色を設定する
        picker.navigationBar.tintColor = UIColor.white
        //現れるピッカーNavigationBarの背景色を設定する
        picker.navigationBar.barTintColor = UIColor.gray
        //ピッカーを表示する
        present(picker, animated: true, completion: nil)
    }
    
    //画像が選択された時に呼ばれる.
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let image = info[.originalImage] as? UIImage {
            let imageType = (info[.imageURL] as! NSURL).absoluteString! as NSString
            let imageCropVC = RSKImageCropViewController(image: image, cropMode: .circle)
            imageCropVC.moveAndScaleLabel.text = "切り取り範囲を選択"
            imageCropVC.cancelButton.setTitle("キャンセル", for: .normal)
            imageCropVC.chooseButton.setTitle("完了", for: .normal)
            imageCropVC.delegate = self
            changeFlg = true
            selectedImageType = imageType.pathExtension
            self.dismiss(animated: false)
            present(imageCropVC, animated: true)
        } else {
            print("error")
        }

    }
    
    @IBAction func saveProfile(_ sender: Any) {
        let getName = nameField.text
        let userID = RootTabBarController.userId
        // 名前の変更がある場合
        if getName != nowName {
//            let post = ["name": getName]
            let childUpdates = ["/users/\(userID)/name/": getName]
            ref.updateChildValues(childUpdates as [AnyHashable : Any])
        }
        if changeFlg {
            let childUpdates = ["/users/\(userID)/img/": userID+"."+selectedImageType]
            ref.updateChildValues(childUpdates as [AnyHashable : Any])
            let storageRef = storage.reference().child("users")
            // UIImagePNGRepresentationでUIImageをNSDataに変換
            if let data = self.imgView.image!.pngData() {
                let reference = storageRef.child(userID+"."+self.selectedImageType)
                reference.putData(data, metadata: nil, completion: { metaData, error in
                    
                })
            }
            // 一つ前のViewControllerに戻る
            navigationController?.popViewController(animated: true)
        }
        
    }
    
    func tableView(_ table: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // セル生成
        let cell = table.dequeueReusableCell(withIdentifier: "EditProfileCell", for: indexPath) as! EditProfileTableViewCell
        cell.backgroundColor = UIColor.clear

        cell.keyLbl.text = belongsArr[indexPath.row]
        cell.valField.text = belongsData[belongsArr[indexPath.row]] as? String
        switch indexPath.row {
        case 0:
            cell.valField.list = communityArr
        case 1:
            cell.valField.list = friendsArr
        case 2:
            cell.valField.list = levelsArr
        default:
            print("")
        }
        cell.valField.pickerView.reloadAllComponents()
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return belongsData.count
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 43
    }
    
    // textfile以外の部分をタッチ
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // キーボードを閉じる
        self.view.endEditing(true)
    }
}

extension EditProfileViewController: RSKImageCropViewControllerDelegate {
    //キャンセルを押した時の処理
    func imageCropViewControllerDidCancelCrop(_ controller: RSKImageCropViewController) {
        dismiss(animated: true, completion: nil)
    }
    //完了を押した後の処理
    func imageCropViewController(_ controller: RSKImageCropViewController, didCropImage croppedImage: UIImage, usingCropRect cropRect: CGRect, rotationAngle: CGFloat) {
        dismiss(animated: true)
        imgView.image = croppedImage
    }
}
