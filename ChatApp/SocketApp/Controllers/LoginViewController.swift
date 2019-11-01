//
//  LoginViewController.swift
//  SocketApp
//
//  Created by Phung Duy Thinh on 7/21/18.
//  Copyright © 2018 Phung Duy Thinh. All rights reserved.
//

import UIKit
import SocketIO

class LoginViewController: UIViewController {
    @IBOutlet weak var pic1: UIImageView!
    @IBOutlet weak var pic2: UIImageView!
    @IBOutlet weak var pic3: UIImageView!
    @IBOutlet weak var pic4: UIImageView!
    
    @IBOutlet weak var userNameTextInput: UITextField!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var logInButton: UIButton!
    @IBOutlet weak var fillUsernameNotice: UILabel!
    @IBOutlet weak var chooseProfilePicNotice: UILabel!
    
    var profilePics: [UIImageView] = []
    var picsName: [String] = ["gates", "mark", "steve", "trump"]
    var picChooseIndex: Int = 0
    
    //    let manager = SocketManager(socketURL: URL(string: "http://chat.chhaileng.com:1111")!, config: [.log(true), .path("/"), .connectParams(["token": "ABC438s"])])
//    let manager = SocketManager(socketURL: URL(string: "http://localhost:3150")!, config: [.log(true), .path("/")])
//    var socket:SocketIOClient!
    
    static let manager = SocketManager(socketURL: URL(string: "http://localhost:5000")!, config: [.log(true), .compress])
    static let socket = manager.defaultSocket
    var gradientLayer: CAGradientLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        LoginViewController.self.manager.config = SocketIOClientConfiguration( arrayLiteral: .connectParams(["token": "adssada"]), .secure(true))
        LoginViewController.socket.connect()
        print("\(LoginViewController.self.isSocketConnected())")
    }
    
    class func isSocketConnected() -> Bool{
        if socket.status == .connected {
            return true
        }
        return false
    }
    
    private func setSocketEvents()
    {
        LoginViewController.self.socket.on(clientEvent: .connect) {data, ack in
            print("socket connected");
        };
        
        LoginViewController.self.socket.on("headlines_updated") {data, ack in
            print("adsuhadhusah")
        };
    };
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        createGradientLayer()
    }
    
    
    //MARK: LOGIN BUTTON
    func loginButtonConfig() {
        logInButton.layer.cornerRadius = 5
        logInButton.layer.borderWidth = 1
        logInButton.layer.borderColor = UIColor.white.cgColor
    }
    
    @IBAction func logInButton(_ sender: UIButton) {
        
        //Make sure that user enter username and choose profile pucture.
        guard let userName = userNameTextInput.text, userName != "" else {
            fillUsernameNotice.text = "Please enter user's name."
            return
        }
        
        guard let profilePicname = profilePicName, profilePicname != "" else {
            chooseProfilePicNotice.text = "Please choose a profile picture."
            return
        }
        
        //Connect to socket IO server.
        connectSocket(userName: userName, completion: {
            if (!isLoggedIn) {
                
                //Load Friends List VC
                let presentPage = self.storyboard?.instantiateViewController(withIdentifier: "FriendsListViewController") as! FriendsListViewController
                presentPage.userName = userName
                presentPage.socket = LoginViewController.self.socket
                
                //Store self socket Id
                LoginViewController.self.socket.on("myId", callback: { (data, ack) in
                    if let data = data[0] as? String {
                        myId = data
                    }
                })
                
                //Load online users
                LoginViewController.self.socket.on("usersConnected", callback: { (data, ack) in
                    let OnlineUsers: [[String:String]] = data[0] as! [[String:String]]
                    print("LOGIN VIEW")
                    print("DictArray: ", OnlineUsers)
                    onlineUsers = OnlineUsers
                    myIndex = OnlineUsers.count
                })
                
                let presentNavPage = UINavigationController(rootViewController: presentPage)
                
                let transition = CATransition()
                transition.duration = 0.35
                transition.type = CATransitionType.push
                transition.subtype = CATransitionSubtype.fromRight
                transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
                self.view.window!.layer.add(transition, forKey: kCATransition)
                self.present(presentNavPage, animated: false, completion: {
                    isLoggedIn = true
                })
            }
        })
    }
    
    
    //MARK: CONNECT TO SOCKET
    //Using completion handler to make sure the FriendsListViewController only load when connect was succeed.
    func connectSocket(userName: String, completion: @escaping () -> ()) {
        LoginViewController.socket.on(clientEvent: .connect) { (data, ack) in
            completion()
            let picName = self.picsName[self.picChooseIndex]
            LoginViewController.self.socket.emit("connectName", userName, picName)
        }
        LoginViewController.socket.connect()
    }
    
    
    //MARK: HANDLE CHOOSE PROFILE PICTURE USING TAPGESTURERECOGNIZER
    func chooseProfilePic() {
        profilePics = [pic1, pic2, pic3, pic4]
        for (index, pic) in profilePics.enumerated() {
            let gesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture))
            gesture.numberOfTapsRequired = 1
            gesture.numberOfTouchesRequired = 1
            pic.addGestureRecognizer(gesture)
            pic.tag = index
            pic.image = UIImage(named: picsName[index])
            pic.layer.cornerRadius = pic.frame.height / 2
        }
    }
    
    @objc func handleTapGesture(sender: UITapGestureRecognizer) {
        print("ESCOLHA UM")
        print("Choose Choose Choose")
        for pic in profilePics {
            pic.layer.borderWidth = 0
        }
        sender.view?.layer.borderWidth = 5
        sender.view?.layer.borderColor = UIColor.white.cgColor
        picChooseIndex = (sender.view?.tag)!
        profilePicName = picsName[picChooseIndex]
    }
    
    
    //MARK: SET GRADIENT BACKGROUND
    func createGradientLayer() {
        gradientLayer = CAGradientLayer()
        gradientLayer.frame = self.view.bounds
        gradientLayer.colors = [UIColor(red: 96/255, green: 120/255, blue: 234/255, alpha: 1.0).cgColor,
                                UIColor(red: 23/255, green: 234/255, blue: 217/255, alpha: 1.0).cgColor]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.startPoint = CGPoint(x: 1, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0, y: 1)
        self.backgroundView.layer.addSublayer(gradientLayer)
    }
}
