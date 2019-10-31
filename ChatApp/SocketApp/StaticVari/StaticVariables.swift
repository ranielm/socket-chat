//
//  File.swift
//  SocketApp
//
//  Created by Phung Duy Thinh on 7/21/18.
//  Copyright © 2018 Phung Duy Thinh. All rights reserved.
//

import Foundation
import UIKit

var isLoggedIn: Bool = false
var myId: String?
var myIndex: Int = 0
var profilePicName: String?
var onlineUsers: [[String:String]] = []
var messages: [[[String:String]]] = []
var isMessageVcVisible = false

