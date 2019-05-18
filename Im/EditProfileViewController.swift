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
    var customCell:[EditProfileTableViewCell] = []
    let belongsArr = ["好きなチーム", "観戦仲間", "ファンレベル"]
    var communityArr:[String] = ["選択してください"]
    var friendsArr:[String] = ["選択してください", "いる", "いない"]
    var levelsArr:[String] = ["選択してください"]
    var belongsData:[String:Any] = [:]
    var communityKey:[String] = []
    var levelDic:[String:Any] = [:]
    let friendDic:[String:Any] = ["選択してください":"", "いる":true, "いない": false]
    var saveFlg = true
    
    @IBOutlet weak var wrapperView: UIView!
    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var saveBtn: UIBarButtonItem!
    @IBOutlet weak var imgBtn: UIButton!
    @IBOutlet weak var introduction: UITextView!
    @IBOutlet weak var birthdayField: DatePickerKeyboard!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.tintColor = UIColor.white
        tableView.delegate = self
        tableView.dataSource = self
        
        let imageView = UIImageView()
        let image = UIImage(named: "Picker")
        imageView.image = image
        imageView.frame = CGRect(x: CGFloat(birthdayField.frame.size.width - 50), y: CGFloat(30), width: CGFloat(25), height: CGFloat(25))
        birthdayField.rightView = imageView
        birthdayField.rightViewMode = UITextField.ViewMode.always
        
        birthdayField.datePicker.addTarget(self, action: #selector(setText), for: .valueChanged)
        
        for i in 0 ..< 3 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "EditProfileCell", for: NSIndexPath(row: i, section: 0) as IndexPath) as! EditProfileTableViewCell
            customCell.append(cell)
        }

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
    
    // datePickerの日付けをtextFieldのtextに反映させる
    @objc private func setText() {
        let f = DateFormatter()
        f.dateStyle = .long
        f.locale = Locale(identifier: "ja")
        birthdayField.text = f.string(from: birthdayField.datePicker.date)
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
                        self.levelDic = snapshot.value as! [String:Any]
                        var valArr = Array(self.levelDic.values) as! [[String:Any]]
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
    
    func tableView(_ table: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = customCell[indexPath.row]
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
    
    // 名前 判定
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if nameField.text == "" {
            saveBtn.tintColor = UIColor.gray
            saveFlg = false
        } else {
            saveBtn.tintColor = UIColor.white
            saveFlg = true
        }
        return true
    }
    
    // 紹介文 文字数制限
    func textViewDidChange(_ textView: UITextView) {
        if textView.text.count > 150 {
            saveBtn.tintColor = UIColor.gray
            saveFlg = false
        } else {
            saveBtn.tintColor = UIColor.white
            saveFlg = true
        }
        
    }
    
    @IBAction func saveProfile(_ sender: Any) {
        // 取得
        let name = nameField.text
        let birthday = birthdayField.text
        let intro = introduction.text
        let community = customCell[0].valField.text
        let friend = friendDic[customCell[1].valField.text!]
        let level = findKeyForValue(value: customCell[2].valField.text!, dictionary: levelDic as! [String: [String:Any]])
        // バリデーション
        guard name != "" else { return }
        if friend as? String != "" && community == "" { return }
        if level != "" && community == "" { return }
        // 更新
        let childUpdates = ["/users/\(RootTabBarController.userId)/": ["name": name, "birthday": birthday, "introduction": intro]]
        ref.updateChildValues(childUpdates as [AnyHashable : Any])
        let belongsUpdates = ["/users/\(RootTabBarController.userId)/": [community: ["friend": friend, "level": level]]]
        ref.updateChildValues(belongsUpdates as [AnyHashable : Any])
        // 一つ前のViewControllerに戻る
        navigationController?.popViewController(animated: true)
    }
    
    func findKeyForValue(value: String, dictionary: [String: [String:Any]]) ->String?
    {
        for (key, dic) in dictionary
        {
            if dic["name"] as? String == value
            {
                return key
            }
        }
        return ""
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

protocol PickerViewKeyboardDelegate : class{
//    func titlesOfPickerViewKeyboard(sender: PickerKeyboard) -> Array<String>
//    func initSelectedRow(sender: PickerKeyboard) -> Int
//    func didCancel(sender: PickerKeyboard)
    func didDone(sender: PickerKeyboard, selectedData: String)
}

extension EditProfileViewController: PickerViewKeyboardDelegate {

    
    func didDone(sender: PickerKeyboard, selectedData: String) {
        print(selectedData)
    }
    
}
