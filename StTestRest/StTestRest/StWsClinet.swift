//
//  OpenStomp.swift
//  test_for_fs
//
//  Created by qians on 2019/11/28.
//  Copyright © 2019 qians. All rights reserved.
//

import Foundation
import StompClientLib

// TODO: rename to StWsClinet
class StWsClinet: NSObject, StompClientLibDelegate{
    var socketClient = StompClientLib()
    let pMsg = ProcessMessage()
    var baseTopic = "/u/"
    var topic = ""
    var id = ""
    var token = "[user_ws_token] TODO: request from server when login;"

    let url = NSURL(string: "ws://192.168.11.123:8080/ep-st-websocket/websocket")!
    //let url = NSURL(string: "ws://192.168.31.216:9001/ep-st-websocket/websocket")
    //var url = NSURL(string: "http://server.teclub.cn:8080/ep-st-websocket/websocket")!
    
    @objc func registerSocket() -> Void{
        print("webSocket is Connection:\(url)")
        if (socketClient.isConnected()){
            DisConnect()
            socketClient.reconnect(request: NSURLRequest(url: url as URL) , delegate: self as StompClientLibDelegate)
            print("is connected")
       }else{
            socketClient.openSocketWithURLRequest(request: NSURLRequest(url: url as URL) , delegate: self as StompClientLibDelegate)
        }
    }
    
    // TODO: do this
    //    @objc public func sendToClinet(clientID: Int, cmd: StWsMessage.Command, type: StWsMessage.stType, info: String) -> Void{
    //
    //
    //    }
    //
    //
    //    @objc public func sendToServer(StWsMessage.Command cmd,  StWsMessage.stType type, String json) -> Void{
    //
    //    }
    //
    
    @objc public func sendECHO() -> Void{
        if (socketClient.isConnected()){
            print("do send echo")
            print(StWsMessage.Command.ECHO)
            let stompHeaders:[String: String] = ["content-type": "application/json", "auth": token]
            let mess = StWsMessage(ssid: 0, cmd: StWsMessage.Command.ECHO, type: StWsMessage.MsgType.Request, info: "ECHO Message", from: id, to: "").toString()
            socketClient.sendMessage(message: mess, toDestination: "/app/server", withHeaders: stompHeaders, withReceipt: nil)
        }
        else {
            print("Try To Connect Websocket!")
            self.registerSocket()
        }
    }
//
//    @objc public func doMakeCall(friendId: String, name: String) -> Void{
//        let des = "/app/user/"
//        let toDestination = des + friendId
//        print(toDestination)
//        if (socketClient.isConnected()){
//            print("webrtc do call!")
//            let stompHeaders:[String: String] = ["content-type": "application/json", "auth": token]
//            let mess = StWsMessage(ssid: 0, cmd: StWsMessage.Command.MAKE_CALL, type: StWsMessage.stType.Request, info: name, from: id, to: friendId).toString()
//            socketClient.sendMessage(message: mess, toDestination: toDestination, withHeaders: stompHeaders, withReceipt: nil)
//        }else {
//            print("do call Try To Connect Websocket!")
//            self.registerSocket()
//        }
//    }
//
//    @objc public func doAcceptCall(friendId: String) -> Void{
//        let des = "/app/user/"
//        let toDestination = des + friendId
//        print(toDestination)
//        if (socketClient.isConnected()){
//            print("webrtc Accept call!")
//            let stompHeaders:[String: String] = ["content-type": "application/json", "auth": token]
//            let mess = StWsMessage(ssid: 0, cmd: StWsMessage.Command.ACCEPT_CALL, type: StWsMessage.stType.Request, info: "", from: id, to: friendId).toString()
//            socketClient.sendMessage(message: mess, toDestination: toDestination, withHeaders: stompHeaders, withReceipt: nil)
//        }else {
//            print("do call Try To Connect Websocket!")
//            self.registerSocket()
//        }
//    }
//
//    @objc public func sendOffer(sdp: String, friendId: String) -> Void{
//        let des = "/app/user/"
//        let toDestination = des + friendId
//        if (socketClient.isConnected()){
//            print("webrtc send offer!")
//            let stompHeaders:[String: String] = ["content-type": "application/json", "auth": token]
//            let mess = StWsMessage(ssid: 0, cmd: StWsMessage.Command.CALL_OFFER, type: StWsMessage.stType.Request, info: sdp, from: id, to: friendId).toString()
//            socketClient.sendMessage(message: mess, toDestination: toDestination, withHeaders: stompHeaders, withReceipt: nil)
//        }
//        else {
//            print("send offer Try To Connect Websocket!")
//            self.registerSocket()
//        }
//    }
//
//    @objc public func sendAnswer(sdp: String, friendId: String) -> Void{
//        let des = "/app/user/"
//        let toDestination = des + friendId
//        if (socketClient.isConnected()){
//            print("webrtc send answer!")
//            let stompHeaders:[String: String] = ["content-type": "application/json", "auth": token]
//            let mess = StWsMessage(ssid: 0, cmd: StWsMessage.Command.CALL_ANSWER, type: StWsMessage.stType.Request, info: sdp, from: id, to: friendId).toString()
//            socketClient.sendMessage(message: mess, toDestination: toDestination, withHeaders: stompHeaders, withReceipt: nil)
//        }
//        else {
//            print("send answer Try To Connect Websocket!")
//            self.registerSocket()
//        }
//    }
//
//    @objc public func sendCandidate(sdp: Dictionary<String, String>, friendId: String) -> Void{
//        let des = "/app/user/"
//        let toDestination = des + friendId
//        if (socketClient.isConnected()){
//            print("webrtc send candidate!")
//            let stompHeaders:[String: String] = ["content-type": "application/json", "auth": token]
//            do {
//                let theJSONData = try JSONSerialization.data(withJSONObject: sdp, options: JSONSerialization.WritingOptions())
//                let theJSONText = String(data: theJSONData, encoding: String.Encoding.utf8)
//                let mess = StWsMessage(ssid: 0, cmd: StWsMessage.Command.CALL_CANDIDATE, type: StWsMessage.stType.Request, info: theJSONText!, from: id, to: friendId).toString()
//                socketClient.sendMessage(message: mess, toDestination: toDestination, withHeaders: stompHeaders, withReceipt: nil)
//            } catch {
//                print("error serializing JSON: \(error)")
//            }
//        }
//        else {
//            print("send candidate Try To Connect Websocket!")
//            self.registerSocket()
//        }
//    }
//
//    @objc public func RTCBye(friendId: String) -> Void{
//        let des = "/app/user/"
//        let toDestination = des + friendId
//        if (socketClient.isConnected()){
//            let stompHeaders:[String: String] = ["content-type": "application/json", "auth": token]
//            let mess = StWsMessage(ssid: 0, cmd: StWsMessage.Command.CALL_BYE, type: StWsMessage.stType.Request, info:"", from: id, to: friendId).toString()
//            socketClient.sendMessage(message: mess, toDestination: toDestination, withHeaders: stompHeaders, withReceipt: nil)
//        }
//        else {
//            print("bye Try To Connect Websocket!")
//            self.registerSocket()
//        }
//    }
    
    func stompClientDidConnect(client: StompClientLib!) {
        let ID = UserDefaults.standard.integer(forKey: "id")
        print("ID = \(ID)")
        id = String(ID)
        
        topic = baseTopic + id
        
        print("Socket is Connected : \(topic)")
        socketClient.subscribe(destination: topic)
        print(url)
    }
    
    @objc public func DisConnect() -> Void{
        socketClient.disconnect()
        if (!socketClient.isConnected()) {
            print("已断开！")
        }
    }
    
    @objc public func IsConnected() -> Void{
        if(socketClient.isConnected()){
            print("stomp is connected!")
        }else{
            print("ERROR: please connect again!")
        }
    }
    
    func stompClientDidDisconnect(client: StompClientLib!) {
        print("Socket is Disconnected")
    }
    
    func stompClient(client: StompClientLib!, didReceiveMessageWithJSONBody jsonBody: AnyObject?, withHeader header: [String : String]?, withDestination destination: String) {
        //print("------------------------Get Command---------------------")
        //print("DESTIONATION : \(destination)")
        let jsonMsg = jsonBody as? NSDictionary
        //print(jsonMsg)
        //print("---------------------------------------------------------")
        pMsg.receiveMsg(jsonMsg: jsonMsg!)
    }
    
    func stompClient(client: StompClientLib!, didReceiveMessageWithJSONBody jsonBody: AnyObject?, akaStringBody stringBody: String?, withHeader header: [String : String]?, withDestination destination: String) {
        print("DESTIONATION : \(destination)")
        print("JSON BODY : \(String(describing: jsonBody))")
        print("STRING BODY : \(stringBody ?? "nil")")
    }
    
    func stompClientJSONBody(client: StompClientLib!, didReceiveMessageWithJSONBody jsonBody: String?, withHeader header: [String : String]?, withDestination destination: String) {
        print("DESTIONATION : \(destination)")
        print("String JSON BODY : \(String(describing: jsonBody))")
    }
    
    func serverDidSendReceipt(client: StompClientLib!, withReceiptId receiptId: String) {
        print("Receipt : \(receiptId)")
    }
    
    func serverDidSendError(client: StompClientLib!, withErrorMessage description: String, detailedErrorMessage message: String?) {
        print("Error : \(String(describing: message))")
    }
    
    func serverDidSendPing() {
        print("Server Ping")
    }
}
