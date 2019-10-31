//
//  FriendsListViewController.swift
//  SocketApp
//
//  Created by Phung Duy Thinh on 7/21/18.
//  Copyright © 2018 Phung Duy Thinh. All rights reserved.
//

import UIKit
import UserNotifications
import SocketIO
import GoogleMobileAds

class FriendsListViewController: UIViewController, GADBannerViewDelegate {

    @IBOutlet weak var friendsTableView: UITableView!
    
    var socket: SocketIOClient?
    var userName: String?
    var bannerView: GADBannerView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        friendsTableView.delegate = self
        friendsTableView.dataSource = self
        
        requestAdBanner()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        addhanle()
        addOnlineUsers()
        navigationSetting()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        socket?.off("userLoggedIn")
        socket?.off("userDisconnect")
        socket?.off("privateMessage")
    }
    
    
    //MARK: ADD USER PROFILE PICTURE ON RIGHT BAR ITEM
    func navigationSetting() {
        let avatar = UIButton(frame: CGRect(x: 0, y: 0, width: 35, height: 35))
        avatar.layer.cornerRadius = 17
        avatar.clipsToBounds = true
        avatar.setBackgroundImage(UIImage(named: profilePicName!), for: .normal)
        let rightBarItem = UIBarButtonItem(customView: avatar)
        rightBarItem.customView?.widthAnchor.constraint(equalToConstant: 35).isActive = true
        rightBarItem.customView?.heightAnchor.constraint(equalToConstant: 35).isActive = true
        
        navigationItem.rightBarButtonItems = [rightBarItem]
    }
    
    
    //MARK: ADD SOCKET HANDLE
    func addhanle() {
        //Occur when a user logged in - We need to store data and insert a user row on friends list.
        socket?.on("userLoggedIn", callback: { (data, ack) in
            guard let userInfo = data[0] as? [String:String] else { return }
            guard userInfo["userName"] != nil else { return }
            
            //Add user's data in users list
            onlineUsers.append(userInfo)
            
            //This will create an empty message box for this user.
            let message: [[String:String]] = []
            messages.append(message)
            
            //Insert user in friends list.
            let indexpath = IndexPath(row: onlineUsers.count - 1, section: 0)
            self.friendsTableView.insertRows(at: [indexpath], with: .right)
        })
        
        //Occur when a user disconneted
        //When a user disconnected, server will send the user's index in list of all users on server.
        //And we need to remove data of that user.
        socket?.on("userDisconnect", callback: { (data, ack) in
            guard var userDisconnectIndex = data[1] as? Int else { return }
            
            //On server, all users will be store include this own.
            //But on client side we only store others user. So we need to specify which user was disconneced on client side.
            if (userDisconnectIndex > myIndex) {
                userDisconnectIndex -= 1
            }else{
                myIndex -= 1
            }
            
            //And remove that data
            onlineUsers.remove(at: userDisconnectIndex)
            
            //Make it disappear on friends list table view
            let indexpath = IndexPath(row: userDisconnectIndex, section: 0)
            self.friendsTableView.deleteRows(at: [indexpath], with: .left)
            
            //We also delete all messages.
            //In serious project you need to store messages on database - So remove this line of code.
            messages.remove(at: userDisconnectIndex)
        })
        
        //Occur when some one send a message.
        socket?.on("privateMessage", callback: { (data, ack) in
            guard let senderId = data[0] as? String else { return }
            guard let message = data[1] as? String else { return }
            
            //Determine who send the message.
            for (index, user) in onlineUsers.enumerated() {
                let userId = user["userId"]
                if(userId == senderId){
                    
                    //Last message for show review.
                    onlineUsers[index]["lastMessage"] = message
                    
                    //Check if the message was read or not.
                    if(isMessageVcVisible) {
                        onlineUsers[index]["isRead"] = "true"
                    }else{
                        onlineUsers[index]["isRead"] = "false"
                    }
                    
                    //Reload row of user that send the message.
                    let indexpath = IndexPath(row: index, section: 0)
                    self.friendsTableView.reloadRows(at: [indexpath], with: .none)
                    
                    //Store message.
                    var mesInfo: [String:String] = [:]
                    mesInfo["senderId"] = userId
                    mesInfo["message"] = message
                    
                    messages[index].append(mesInfo)
                }
            }
        })
    }
    
    
    //Add all onlining users when logged in.
    func addOnlineUsers() {
        self.friendsTableView.reloadSections([0], with: .none)
        
        //Create an empty message box for each user.
        for index in 0...onlineUsers.count {
            if(index == 0) { continue }
            let message: [[String:String]] = []
            messages.append(message)
        }
    }
    
    //MARK: ADS BANNER
    func requestAdBanner() {
        bannerView = GADBannerView(adSize: kGADAdSizeSmartBannerPortrait)
        GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = [(kGADSimulatorID as! String)]
        bannerView?.adUnitID = "ca-app-pub-3940256099942544/2934735716" //Test Ads ID. Please replace with your Ads banner ID.
        bannerView?.delegate = self
        bannerView?.rootViewController = self
        // bannerView?.load(request)
    }
    
    func addBannerView(bannerView: GADBannerView) {
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bannerView)
        view.addConstraints([NSLayoutConstraint(item: bannerView, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: 0), NSLayoutConstraint(item: bannerView, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1, constant: 0)])
    }
    
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        print("Banner load successfully")
        addBannerView(bannerView: bannerView)
    }
    
    func adView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: GADRequestError) {
        print("Fail to receive Ads")
        print(error)
    }
}


extension FriendsListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return onlineUsers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = friendsTableView.dequeueReusableCell(withIdentifier: "friendCell") as! CustomFriendCell
        
        cell.name.text = onlineUsers[indexPath.row]["userName"]
        cell.MessageReview.text = onlineUsers[indexPath.row]["lastMessage"]
        
        if (onlineUsers[indexPath.row]["isRead"] == "false") {
            cell.MessageReview.font = UIFont.boldSystemFont(ofSize: 16)
            cell.MessageReview.textColor = .black
        }else if (onlineUsers[indexPath.row]["isRead"] == "true") {
            cell.MessageReview.font = UIFont.systemFont(ofSize: 15)
            cell.MessageReview.textColor = .gray
        }
        
        if let profilePicName = onlineUsers[indexPath.row]["picName"] {
            cell.avatar.image = UIImage(named: profilePicName)
            cell.avatar.layer.cornerRadius = cell.avatar.frame.height / 2
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let messagePage = self.storyboard?.instantiateViewController(withIdentifier: "MessageViewController") as! MessageViewController
        messagePage.socket = socket
        messagePage.userIndex = indexPath.row
        messagePage.receiverId = onlineUsers[indexPath.row]["userId"]
        messagePage.friendUserName = onlineUsers[indexPath.row]["userName"]
        messagePage.friendPicName = onlineUsers[indexPath.row]["picName"]
        onlineUsers[indexPath.row]["isRead"] = "true"
        
        navigationController?.show(messagePage, sender: nil)
    }
}
