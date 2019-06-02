//
//  CommunityChatCollectionViewCell.swift
//  Im
//
//  Created by nobumitsu on 2019/05/31.
//  Copyright © 2019 im. All rights reserved.
//

import UIKit

class CommunityChatCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var img: UIImageView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var message: UILabel!
    
    @IBOutlet weak var cellWidthConstraint: NSLayoutConstraint! {
        didSet {
//            cellWidthConstraint.isActive = true
        }
    }
    
    var cellWidth: CGFloat? = nil {
        didSet {
            guard let cellWidth = cellWidth else {
                return
            }
//            cellWidthConstraint.constant = cellWidth
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        cellWidthConstraint = contentView.widthAnchor.constraint(equalToConstant: 0)
        // 角丸にする
        img.layer.cornerRadius = img.frame.size.width * 0.5
        img.clipsToBounds = true
//        contentView.translatesAutoresizingMaskIntoConstraints = false
        
//        NSLayoutConstraint.activate([
//            contentView.leftAnchor.constraint(equalTo: leftAnchor),
//            contentView.rightAnchor.constraint(equalTo: rightAnchor),
//            contentView.topAnchor.constraint(equalTo: topAnchor),
//            contentView.bottomAnchor.constraint(equalTo: bottomAnchor)
//            ])

    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        setNeedsLayout()
        layoutIfNeeded()
        let size = contentView.systemLayoutSizeFitting(layoutAttributes.size)
        var frame = layoutAttributes.frame
        frame.size.height = ceil(size.height)
        layoutAttributes.frame = frame
        return layoutAttributes
    }
}
