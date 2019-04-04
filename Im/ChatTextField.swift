//
//  ChatTextField.swift
//  Im
//
//  Created by nobumitsu on 2019/04/03.
//  Copyright © 2019 im. All rights reserved.
//

import UIKit

class ChatTextField: UITextField {

    var padding: CGPoint = CGPoint(x: 10.0, y: 0.0)
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        // テキストの内側に余白を設ける
        return bounds.insetBy(dx: self.padding.x, dy: self.padding.y)
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        // 入力中のテキストの内側に余白を設ける
        return bounds.insetBy(dx: self.padding.x, dy: self.padding.y)
    }
    
    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        // プレースホルダーの内側に余白を設ける
        return bounds.insetBy(dx: self.padding.x, dy: self.padding.y)
    }

}
