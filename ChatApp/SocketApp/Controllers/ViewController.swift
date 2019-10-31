//
//  ViewController.swift
//  SocketApp
//
//  Created by Phung Duy Thinh on 7/2/18.
//  Copyright © 2018 Phung Duy Thinh. All rights reserved.
//

import UIKit
import SocketIO

class ViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var ToUserName: UITextField!
    @IBOutlet weak var myUserName: UITextField!
    @IBOutlet weak var messageInput: UITextField!
    @IBOutlet weak var receiveMessage: UILabel!
    
    let manager = SocketManager(socketURL: URL(string: "http://192.168.1.108:5000")!, config: [.log(true), .reconnectWait(2)])
    var socket: SocketIOClient!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hideKeyboardWhenTappedAround()
        
        manager.reconnects = true
        socket = manager.defaultSocket
        
        socket.on("privateMessage") { (data, ack) in
            print("- DATA: ", data)
            self.receiveMessage.text = (data[0] as! String)
        }
    }
    
    @IBAction func sendButton(_ sender: UIButton) {
        guard let message = messageInput.text else {
            print("No message to send")
            return
        }
        
        guard let ToUserName = ToUserName.text else {
            print("No ToUserName was set")
            return
        }
        //Send message to server
        socket.emit("sendMessageToSomeone", ToUserName, message)
        
        //Receive message
//        socket.on("senToAllUsers") { (data, ack) in
//            self.receiveMessage.text = (data[0] as! String)
//        }
        
    }
    
    @IBAction func connectSocketBtn(_ sender: UIButton) {
        socket.on(clientEvent: .connect) { (data, ack) in
            print("- Socket Connected")
            ack.with("I got the message!")
            
            self.socket.emit("connectName", with: [self.myUserName.text!])
        }
        
        socket.connect()
        print("- Socket status: ", manager.status)
    }
    
    @IBAction func disconnectSocketBtn(_ sender: UIButton) {
        socket.on(clientEvent: .disconnect) { (data, ack) in
            print("- Socket Disconnected")
        }
        socket.off(clientEvent: .connect)
        socket.disconnect()
        print("- Socket status: ", socket.status)
    }
}

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

