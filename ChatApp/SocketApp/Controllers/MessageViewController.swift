//
//  MessageViewController.swift
//  SocketApp
//
//  Created by Phung Duy Thinh on 7/21/18.
//  Copyright © 2018 Phung Duy Thinh. All rights reserved.
//

import UIKit
import UserNotifications
import  SocketIO
import GoogleMobileAds

class MessageViewController: UIViewController, GADBannerViewDelegate {

    var socket: SocketIOClient?
    var userIndex: Int?
    var receiverId: String?
    var friendUserName: String?
    var friendPicName: String?
    var messHeight: CGFloat = 120.0
    var bannerView: GADBannerView?
    let messageTextFeildHeight: CGFloat = 35.0
    var viewHeight: CGFloat = 0
    
    @IBOutlet weak var messageView: UIView!
    @IBOutlet weak var messageViewHeight: NSLayoutConstraint!
    @IBOutlet weak var messageTable: UITableView!
    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var mesTextViewHeight: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        messageTable.delegate = self
        messageTable.dataSource = self
        messageTextView.delegate = self
        
        viewHeight = view.frame.height
        textFieldSetting()
        hideKeyboardWhenTappedAround()
        addKeyboardNotification()
        
        navigationItem.title = friendUserName
    }
    

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        addhanler()
        isMessageVcVisible = true
        
        //Scroll to the bottom when enter message viewcontroller.
        if(messages[userIndex!].count == 0) {
            return
        }
        let indexpath = IndexPath(row: messages[userIndex!].count - 1, section: 0)
        self.messageTable.scrollToRow(at: indexpath, at: .bottom, animated: true)
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        socket?.off("userLoggedIn")
        socket?.off("userDisconnect")
        socket?.off("privateMessage")
        isMessageVcVisible = false
    }
    
    
    
    //MARK: SET NOTIFICATION WHEN SOMEONE SEND PRIVATE MESSAGE.
    func showMessageNotification(senderName: String, message: String) {
        let content = UNMutableNotificationContent()
        content.title = senderName
        content.body = message
        content.sound = UNNotificationSound.default()
        content.badge = 1
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.01, repeats: false)
        let request = UNNotificationRequest(identifier: "NewMessage", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
    
    
    //MARK: SEND A PRIVATE MESSAGE.
    @IBAction func sendButton(_ sender: UIButton) {
        guard let message = messageTextView.text, message != "" else { return }
        guard let receiverId = receiverId, receiverId != "" else { return }
        guard let userIndex = userIndex else { return }
        
        //Emit to server the message's data.
        socket?.emit("sendMessageTo", receiverId, message)
        
        //Store message.
        var mesInfo: [String:String] = [:]
        mesInfo["senderId"] = myId
        mesInfo["message"] = message
        messages[userIndex].append(mesInfo)
        
        //Store this message as last message for review purpose.
        onlineUsers[userIndex]["lastMessage"] = message
        
        //Insert message row.
        let indexpath = IndexPath(row: messages[userIndex].count - 1, section: 0)
        self.messageTable.insertRows(at: [indexpath], with: .middle)
        self.messageTable.scrollToRow(at: indexpath, at: .bottom, animated: true)
        
        //Make textview origin.
        messageTextView.text = ""
        messageViewHeight.constant = 50
        mesTextViewHeight.constant = messageTextFeildHeight
    }
    
    
    //MARK: ADD SOCKET HANDLE
    func addhanler() {
        
        //Store message and add to messages tableview.
        socket?.on("privateMessage", callback: { (data, ack) in
            guard let senderId = data[0] as? String else { return }
            guard let message = data[1] as? String else { return }
            
            for (index, user) in onlineUsers.enumerated() {
                let userId = user["userId"]
                if(userId == senderId){
                    
                    //Check if message was read or not.
                    onlineUsers[index]["lastMessage"] = message
                    if(isMessageVcVisible) {
                        onlineUsers[index]["isRead"] = "true"
                    }else{
                        onlineUsers[index]["isRead"] = "false"
                    }
                    
                    //Store message.
                    var mesInfo: [String:String] = [:]
                    mesInfo["senderId"] = userId
                    mesInfo["message"] = message
                    
                    messages[index].append(mesInfo)
                }
            }
            
            //Send notification when other user send message.
            if(senderId != self.receiverId) {
                let senderName = data[2] as! String
                self.showMessageNotification(senderName: senderName + " is sending you a message.", message: message)
                return
            }
            
            //Insert message row on messages tableview.
            let indexpath = IndexPath(row: messages[self.userIndex!].count - 1, section: 0)
            self.messageTable.insertRows(at: [indexpath], with: .middle)
            self.messageTable.scrollToRow(at: indexpath, at: .bottom, animated: true)
        })
        
        //Add new logged in user's data.
        socket?.on("userLoggedIn", callback: { (data, ack) in
            guard let userInfo = data[0] as? [String:String] else { return }
            guard userInfo["userName"] != nil else { return }
            
            onlineUsers.append(userInfo)
            
            let message: [[String:String]] = []
            messages.append(message)
        })
        
        //Remove user's data.
        socket?.on("userDisconnect", callback: { (data, ack) in
            guard var userDisconnectIndex = data[1] as? Int else { return }
            
            if (userDisconnectIndex > myIndex) {
                userDisconnectIndex -= 1
            }else{
                myIndex -= 1
            }
            
            onlineUsers.remove(at: userDisconnectIndex)
            messages.remove(at: userDisconnectIndex)
        })
    }
    
    //MARK: SETTING MESSAGE TEXTVIEW
    func textFieldSetting() {
        messageTextView.frame = CGRect(x: 0, y: 0, width: 200, height: messageTextFeildHeight)
        messageTextView.layer.cornerRadius = messageTextView.frame.height / 2
        messageTextView.layer.borderWidth = 1
        messageTextView.layer.borderColor = UIColor.lightGray.cgColor
        messageView.backgroundColor = .clear
    }
    
    
    //MARK: HANDLE KEYBOARD SHOWING AND HIDE
    func addKeyboardNotification() {
        //Regester notification for show and hide keyboard purpose.
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.height == viewHeight{
                self.view.frame.size.height -= keyboardSize.height
            }
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.height != viewHeight{
                self.view.frame.size.height += keyboardSize.height
            }
        }
    }
    
}



extension MessageViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("Number of row: ", messages[userIndex!].count)
        return messages[userIndex!].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var mesCell: UITableViewCell?
        
        //Specify who is send the message.
        let sendid = messages[userIndex!][indexPath.row]["senderId"]
        
        //If own message, will render cell as own message.
        //If other message, will render cell as other message.
        if (sendid == myId) {
            let cell = messageTable.dequeueReusableCell(withIdentifier: "senderMesCell") as! CustomSenderMesCell
            cell.message.text = messages[userIndex!][indexPath.row]["message"]
            configCell(message: cell.message, viewCell: cell.viewCell)
            
            cell.avatar.image = UIImage(named: profilePicName!)
            cell.avatar.layer.cornerRadius = cell.avatar.frame.height / 2
            mesCell = cell
        } else if (sendid == receiverId) {
            let cell = messageTable.dequeueReusableCell(withIdentifier: "receiverMesCell") as! CustomReceiverMesCell
            cell.messageText.text = messages[userIndex!][indexPath.row]["message"]
            configCell(message: cell.messageText, viewCell: cell.viewCell)
            
            cell.avatar.image = UIImage(named: friendPicName!)
            cell.avatar.layer.cornerRadius = cell.avatar.frame.height / 2
            mesCell = cell
        }
        return mesCell!
    }
    
    
    //MARK: DESIGN CELL
    func configCell(message: UILabel, viewCell: UIView) {
        message.preferredMaxLayoutWidth = viewCell.frame.width / 1.7
        message.numberOfLines = 0
        message.lineBreakMode = .byWordWrapping
        message.layer.masksToBounds = true
        message.layer.cornerRadius = 10
        messHeight = message.intrinsicContentSize.height
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var cellHeight: CGFloat = 120.0
        if (messHeight > 98) {
            cellHeight = messHeight + 22
        }
        return cellHeight
    }
}


extension MessageViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        let size = CGSize(width: messageTextView.frame.width, height: .infinity)
        let estimatedSize = messageTextView.sizeThatFits(size)
        
        if(estimatedSize.height <= 120 && estimatedSize.height >= messageTextFeildHeight){
            mesTextViewHeight.constant = estimatedSize.height + 10
            messageViewHeight.constant = estimatedSize.height + 10
        }
    }
}






