//
//  PickerKeyboard.swift
//  Im
//
//  Created by nobumitsu on 2019/05/15.
//  Copyright © 2019 im. All rights reserved.
//

import UIKit

class PickerKeyboard: UITextField, UIPickerViewDelegate, UIPickerViewDataSource {
    
    //SampleViewDelegateのインスタンスを宣言
    weak var del: PickerViewKeyboardDelegate?
    
//    var del: PickerViewKeyboardDelegate?
    var pickerView: UIPickerView = UIPickerView()
    var list:[String] = []

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        inputView = pickerView
        inputAccessoryView = createToolbar()
        pickerView.delegate = self
        pickerView.dataSource = self
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        inputView = pickerView
        inputAccessoryView = createToolbar()
        pickerView.delegate = self
        pickerView.dataSource = self
    }
    
    // キーボードのアクセサリービューを作成する
    private func createToolbar() -> UIToolbar {
        let toolbar = UIToolbar()
        toolbar.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: 44)
        
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
        return list.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return list[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.del?.didDone(sender: self, selectedData: "テスト")
        text = list[row]
    }
    
    func reload() {
        inputView?.reloadInputViews()
    }
    
    @objc func done() {
        endEditing(true)
    }
    
    // コピペ等禁止
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return false
    }
    
    // カーソル非表示
    override func caretRect(for position: UITextPosition) -> CGRect {
        return CGRect(x: 0, y: 0, width: 0, height: 0)
    }
    
    
}

//protocol PickerViewKeyboardDelegate {
////    func titlesOfPickerViewKeyboard(sender: PickerViewKeyboard) -> Array<String>
////    func initSelectedRow(sender: PickerViewKeyboard) -> Int
////    func didCancel(sender: PickerViewKeyboard)
//    func didDone(sender: PickerViewKeyboard, selectedData: String)
//}
