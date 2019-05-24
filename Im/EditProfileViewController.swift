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

class EditProfileViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextViewDelegate, UITextFieldDelegate {
    
    var ref: DatabaseReference!
    var picker: UIImagePickerController! = UIImagePickerController()
    var changeFlg = false
    var selectedImageType: String!
    let storage = Storage.storage()
    var belongsData:[String] = []
    var communityKey:[String] = []
    var communityDic:[String:Any] = [:]
    var levelDic:[String:Any] = [:]
    var belongsVal:[String] = []
    let friendDic:[String:Any] = ["選択してください":"", "いる":true, "いない": false]
    var saveFlg = true
    var pickerViewArr:[UIPickerView] = [UIPickerView(), UIPickerView(), UIPickerView()]
    var textFieldArr:[UITextField] = []
    var list:[[String]] = [["選択してください"], ["選択してください", "いる", "いない"], ["選択してください"]]
    
    @IBOutlet weak var wrapperView: UIView!
    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var saveBtn: UIBarButtonItem!
    @IBOutlet weak var imgBtn: UIButton!
    @IBOutlet weak var introduction: UITextView!
    @IBOutlet weak var birthdayField: DatePickerKeyboard!
    @IBOutlet weak var communityField: UITextField!
    @IBOutlet weak var friendField: UITextField!
    @IBOutlet weak var levelField: UITextField!
    @IBOutlet weak var counter: UILabel!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        setupFirebase()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.tintColor = UIColor.white
        
        nameField.delegate = self
        introduction.delegate = self
        
        initField(textField: communityField, num: 0)
        initField(textField: friendField, num: 1)
        initField(textField: levelField, num: 2)
        
        let imageView = UIImageView()
        let image = UIImage(named: "Picker")
        imageView.image = image
        imageView.frame = CGRect(x: CGFloat(birthdayField.frame.size.width - 50), y: CGFloat(30), width: CGFloat(25), height: CGFloat(25))
        birthdayField.rightView = imageView
        birthdayField.rightViewMode = UITextField.ViewMode.always
        
        birthdayField.datePicker.addTarget(self, action: #selector(setText), for: .valueChanged)
        
        // グラデーションセット
        self.view.setGradientLayer()
        nameField.borderGradient(
            startColor: UIColor(displayP3Red: 147/255, green: 6/255, blue: 229/255, alpha: 1.0),
            endColor: UIColor(displayP3Red: 23/255, green: 232/255, blue: 252/255, alpha: 1.0),
            radius: 0
        )
        
        introduction.superview!.introductionGradient(
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
        
        introduction.textContainerInset = UIEdgeInsets.zero
        introduction.textContainer.lineFragmentPadding = 0
        
        imgBtn.imageEdgeInsets = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)// ボタンの画像縮小
        wrapperView.backgroundColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.2)
        wrapperView.layer.cornerRadius = 20
        mainView.layer.cornerRadius = 20
        
        nameField.text = RootTabBarController.userInfo["name"] as? String
        introduction.text = RootTabBarController.userInfo["introduction"] as? String

    }
    
    func initField (textField: UITextField, num: Int) {
        
        pickerViewArr[num].delegate = self
        pickerViewArr[num].dataSource = self
        pickerViewArr[num].tag = num
        
        let i = list[num].index(of: belongsVal[num])
        if  i !=  nil {
            pickerViewArr[num].selectRow(i!, inComponent: 0, animated: false)
        }
        
        textField.inputView = pickerViewArr[num]
        textField.inputAccessoryView = createToolbar()
 
        let imageView = UIImageView()
        let image = UIImage(named: "Picker")
        imageView.image = image
        imageView.frame = CGRect(x: CGFloat(textField.frame.size.width - 50), y: CGFloat(30), width: CGFloat(25), height: CGFloat(25))
        textField.rightView = imageView
        textField.rightViewMode = UITextField.ViewMode.always
        
        textField.text = belongsVal[num]
        textFieldArr.append(textField)
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
                self.communityDic = snapshot.value as! [String:Any]
                self.communityKey = Array(self.communityDic.keys)
                let arr = Array(self.communityDic.values) as! [[String:String]]
                self.list[0] += arr.map({($0["name"])!})
                
                let i = self.list[0].index(of: self.belongsVal[0])
                if  i !=  nil {
                    self.pickerViewArr[0].selectRow(i!, inComponent: 0, animated: false)
                }
                self.communityField.inputView = self.pickerViewArr[0]
                // ファンレベル選択項目設定
                self.ref.child("levels").observeSingleEvent(of: .value, with: { (snapshot) in
                    if snapshot.exists() {
                        self.levelDic = snapshot.value as! [String:Any]
                        var valArr = Array(self.levelDic.values) as! [[String:Any]]
                        valArr.sort{($0["index"] as! Int) < ($1["index"] as! Int)}// ソート
                        self.list[2] += valArr.map({(($0["name"]) as? String)!})
                        
                        let i = self.list[2].index(of: self.belongsVal[2])
                        if  i !=  nil {
                            self.pickerViewArr[2].selectRow(i!, inComponent: 0, animated: false)
                        }
                        self.levelField.inputView = self.pickerViewArr[2]
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
    
    // textfile以外の部分をタッチ
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // キーボードを閉じる
        self.view.endEditing(true)
    }
    
    // 名前 判定
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        if nameField.text! == "" {
            saveBtn.tintColor = UIColor.lightGray
            saveFlg = false
        } else {
            saveBtn.tintColor = UIColor.white
            saveFlg = true
        }
        return true
        
    }
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if (textField.text! as NSString).replacingCharacters(in: range, with: string) == "" {
            saveBtn.tintColor = UIColor.lightGray
            saveFlg = false
        } else {
            saveBtn.tintColor = UIColor.white
            saveFlg = true
        }
        return true
    }
    
    // 紹介文 文字数制限
    func textViewDidChange(_ textView: UITextView) {
        let dif = 120 - textView.text.count
        textView.text = textView.text.replacingOccurrences(of: "\n", with: " ")
        counter.text = String(dif)
        if textView.text.count > 120 {
            counter.textColor = UIColor.red
            saveBtn.tintColor = UIColor.gray
            saveFlg = false
        } else {
            counter.textColor = UIColor(displayP3Red: 51/255, green: 51/255, blue: 51/255, alpha: 1.0)
            saveBtn.tintColor = UIColor.white
            saveFlg = true
        }
    }
    
//    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange,
//                  replacementText text: String) -> Bool {
//        if text == "\n" {
//            textView.resignFirstResponder() //キーボードを閉じる
//            return false
//        }
//        return true
//    }
    
    @IBAction func saveProfile(_ sender: Any) {
        guard saveFlg else { return }
        print("保存")
        // 取得
        let name = nameField.text
        let birthday = birthdayField.text
        let intro = introduction.text
        let community = findKeyForValue(value: communityField.text!, dictionary: communityDic as! [String : [String : Any]])
        let friend = friendDic[friendField.text!]
        let level = findKeyForValue(value: levelField.text!, dictionary: levelDic as! [String: [String:Any]])

        // 更新
        let childUpdates = ["/users/\(RootTabBarController.userId)/": ["name": name, "birthday": birthday, "introduction": intro, "img": RootTabBarController.userInfo["img"]]]
        ref.updateChildValues(childUpdates as [AnyHashable : Any])
        if community != "" {
            let belongsUpdates = ["/belongs/\(RootTabBarController.userId)/": [community: ["friend": friend, "level": level]]]
            ref.updateChildValues(belongsUpdates as [AnyHashable : Any])
        } else {
            let belongsUpdates = ["/users/\(RootTabBarController.userId)/": nil] as [String : Any?]
            ref.updateChildValues(belongsUpdates as [AnyHashable : Any])
        }
        // 一つ前のViewControllerに戻る
        navigationController?.popViewController(animated: true)
    }
    
    func findKeyForValue(value: String, dictionary: [String: [String:Any]]) ->String
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

extension EditProfileViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    
    // キーボードのアクセサリービューを作成する
    func createToolbar() -> UIToolbar {
        let toolbar = UIToolbar()
        toolbar.frame = CGRect(x: 0, y: 0, width: pickerViewArr[0].frame.width, height: 44)
        
        let space = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: self, action: nil)
        space.width = 12
        let flexSpaceItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        let doneButtonItem = UIBarButtonItem(title: "完了",style: .done, target: self, action: #selector(done))
        let toolbarItems = [flexSpaceItem, doneButtonItem, space]
        
        toolbar.setItems(toolbarItems, animated: true)
        
        return toolbar
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return list[pickerView.tag].count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return list[pickerView.tag][row]
    }
    // 選択時
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // 観戦仲間もしくはファンレベルが選択中にコミュニティーが未選択の場合
        if pickerView.tag > 0 && row > 0 && communityField.text == list[0][0] {
            saveBtn.tintColor = UIColor.lightGray
            saveFlg = false
        } else if pickerView.tag == 0 && row == 0 && (friendField.text != list[1][0] || levelField.text != list[2][0]) {
            saveBtn.tintColor = UIColor.lightGray
            saveFlg = false
        } else {
            saveBtn.tintColor = UIColor.white
            saveFlg = true
        }
        textFieldArr[pickerView.tag].text = list[pickerView.tag][row]
    }
    
    @objc func done() {
        // キーボードを閉じる
        self.view.endEditing(true)
    }
}
