//
//  DatePickerKeyboard.swift
//  Im
//
//  Created by nobumitsu on 2019/05/15.
//  Copyright © 2019 im. All rights reserved.
//

import UIKit

class DatePickerKeyboard: UITextField {

    var datePicker: UIDatePicker!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commoninit()
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        commoninit()
    }
    private func commoninit() {
        // datePickerの設定
        datePicker = UIDatePicker()
        datePicker.date = Date()
        datePicker.datePickerMode = .date
        datePicker.locale = Locale(identifier: "ja")
        datePicker.maximumDate = NSDate() as Date
        inputView = datePicker
        inputAccessoryView = createToolbar()
    }
    
    // キーボードのアクセサリービューを作成する
    private func createToolbar() -> UIToolbar {
        let toolbar = UIToolbar()
        toolbar.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: 44)
        
        let space = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: self, action: nil)
        space.width = 12
        let flexSpaceItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        let doneButtonItem = UIBarButtonItem(title: "完了",style: .done, target: self, action: #selector(donePicker))
        let cancelItem = UIBarButtonItem(title: "削除", style: .done, target: self, action: #selector(cancel))
        let toolbarItems = [cancelItem, flexSpaceItem, doneButtonItem, space]
        
        toolbar.setItems(toolbarItems, animated: true)
        
        return toolbar
    }
    
    // datePickerの日付けをtextFieldのtextに反映させる
    @objc private func setText() {
        let f = DateFormatter()
        f.dateStyle = .long
        f.locale = Locale(identifier: "ja")
        text = f.string(from: datePicker.date)
    }
    
    // キーボードの完了ボタンタップ時に呼ばれる
    @objc private func donePicker() {
        setText()
        resignFirstResponder()
    }
    
    // 削除
    @objc private func cancel() {
        text = ""
        resignFirstResponder()
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
