//
//  MessageTableViewCell.swift
//  SocketApp
//
//  Created by Phung Duy Thinh on 7/21/18.
//  Copyright © 2018 Phung Duy Thinh. All rights reserved.
//

import UIKit

class CustomReceiverMesCell: UITableViewCell {
    
    @IBOutlet weak var avatar: UIImageView!
    @IBOutlet weak var messageView: UIView!
    @IBOutlet weak var messageText: UILabel!
    @IBOutlet weak var mesViewHeight: NSLayoutConstraint!
    @IBOutlet weak var viewCell: UIView!
}
