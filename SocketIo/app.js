var express = require('express');
var socket = require('socket.io');

//App setup
var app = express();
var server = app.listen(5000, '192.168.1.9'); //Replace this ip address with your

//Socket setup
var io = socket(server);
var users = [];

//This function occur whenever someone connect to socket
io.on('connection', function(socket){
    
    //Socket.emit will send back to that user some data
    socket.emit("usersConnected", users);
    socket.emit("myId", socket.id);

    //Client send name and profile picture name to server
    socket.on("connectName", function(userName, picName){
        console.log('Someone was connected: ', userName, "ID: ", socket.id);

        //Store client information to userInfo like a dictionary
        var userInfo = new Object();
        userInfo.userId = socket.id;
        userInfo.userName = userName;
        userInfo.picName = picName;
        userInfo.lastMessage = "";

        users.push(userInfo);
        
        //This line tell all clients that someone was connected
        socket.broadcast.emit("userLoggedIn", userInfo);

        //This line receive signal that a client want to send a private message to other.
        //with receiver ID and the message
        socket.on("sendMessageTo", function(receiverId, message){
            
            //This line send the private message to other client
            socket.broadcast.to(receiverId).emit("privateMessage", socket.id, message, userName);
        });
    
        //Use this block of code to send message to all client.
        // socket.on("sendMessage", function(data){
        //     console.log(data);
        //     io.sockets.emit("senToAllUsers", data);
        // });

        //If someone disconnect, we will remove infomation from dictionary
        //and tell all other clients that someone was disconnected
        socket.on("disconnect", function() {
            for( var i = 0, len = users.length; i < len; ++i ){
                var c = users[i];

                if(c.userId == socket.id){
                    socket.broadcast.emit("userDisconnect", userInfo, i);
                    users.splice(i,1);
                    break;
                }
            }
        });
    });
});