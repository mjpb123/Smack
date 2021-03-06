//
//  AuthService.swift
//  Smack
//
//  Created by Mariah Baysic on 4/1/20.
//  Copyright © 2020 SpacedOut. All rights reserved.
//
//  For accessing API

import Foundation
import Alamofire
import SwiftyJSON

class AuthService {
    
    static let instance = AuthService()  // Singleton
    
    let defaults = UserDefaults.standard
    
    var isLoggedIn: Bool {
        get {
            return defaults.bool(forKey: LOGGED_IN_KEY)
        }
        set {
            defaults.set(newValue, forKey: LOGGED_IN_KEY)
        }
    }
    
    var authToken: String {
        get {
            return defaults.value(forKey: TOKEN_KEY) as! String
        }
        set {
            defaults.set(newValue, forKey: TOKEN_KEY)
        }
    }
    
    var userEmail: String {
        get {
            return defaults.value(forKey: USER_EMAIL) as! String
        }
        set {
            defaults.set(newValue, forKey: USER_EMAIL)
        }
    }
    
    func registerUser(email: String, password: String, completion: @escaping CompletionHandler) {
        
        let lowerCaseEmail = email.lowercased()
        
        let body: [String: Any] = [
            "email" :  lowerCaseEmail,
            "password" : password
        ]
        
        AF.request(URL_REGISTER, method: .post, parameters: body, encoding: JSONEncoding.default, headers: HTTPHeaders(HEADER)).responseString { (response) in
            if response.error == nil {
                completion(true)
            } else {
                completion(false)
                debugPrint(response.error as Any)
            }
        }
    }
    
    func loginUser(email: String, password: String, completion: @escaping CompletionHandler) {
        
        let lowerCaseEmail = email.lowercased()
        
        let body: [String: Any] = [
            "email" :  lowerCaseEmail,
            "password" : password
        ]
        
        AF.request(URL_LOGIN, method: .post, parameters: body, encoding: JSONEncoding.default, headers: HTTPHeaders(HEADER)).responseJSON { (response) in
            if response.error == nil {
                // Without SwiftyJSON
//                if let json = response.result.value as? Dictionary<String, Any> {
//                    if let email = json["user"] as? String {
//                        self.userEmail = email
//                    }
//                    if let token = json["token"] as? String {
//                        self.authToken = token
//                    }
//                }
                
                // SwiftyJSON
                guard let data = response.data else { return }
                let json = JSON(data)
                self.userEmail = json["user"].stringValue
                self.authToken = json["token"].stringValue
                self.isLoggedIn = true
                
                if self.userEmail == "" {
                    completion(false)
                } else {
                    completion(true)
                }
                
            } else {
                completion(false)
                debugPrint(response.error as Any)
            }
        }
    }
    
    func createUser(name: String, email: String, avatarName: String, avatarColor: String, completion: @escaping CompletionHandler) {
        
        let lowerCaseEmail = email.lowercased()
        
        let body: [String: Any] = [
            "name" : name,
            "email" :  lowerCaseEmail,
            "avatarName" : avatarName,
            "avatarColor" : avatarColor
        ]
        
        AF.request(URL_ADD_USER, method: .post, parameters: body, encoding: JSONEncoding.default, headers: HTTPHeaders(BEARER_HEADER)).responseJSON { (response) in
            if response.error == nil {
                guard let data = response.data else { return }
                self.setUserInfo(data: data)
                
                completion(true)
            } else {
                completion(false)
                debugPrint(response.error as Any)
            }
        }
    }
    
    func findUserByEmail(completion: @escaping CompletionHandler) {
        AF.request("\(URL_GET_USER_BY_EMAIL)\(userEmail)", method: .get, parameters: nil, encoding: JSONEncoding.default, headers: HTTPHeaders(BEARER_HEADER)).responseJSON { (response) in
            if response.error == nil {
                guard let data = response.data else { return }
                self.setUserInfo(data: data)
                print("TOKEN: \(self.authToken)")
                
                completion(true)
            } else {
                completion(false)
                debugPrint(response.error as Any)
            }
        }
    }
    
    func setUserInfo(data: Data) {
        let json = JSON(data)
        let id = json["_id"].stringValue
        let color = json["avatarColor"].stringValue
        let avatarName = json["avatarName"].stringValue
        let email = json["email"].stringValue
        let name = json["name"].stringValue
        
        UserDataService.instance.setUserData(id: id, color: color, avatarName: avatarName, email: email, name: name)
    }
}
