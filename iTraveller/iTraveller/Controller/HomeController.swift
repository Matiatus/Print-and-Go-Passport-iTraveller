//
//  HomeController.swift
//  iTraveller
//
//  Created by MAS on 3/20/19.
//  Copyright © 2019 PrintAndGo. All rights reserved.
//

import UIKit
import Alamofire

class HomeController: UIViewController {

    @IBOutlet weak var showCredentialsButton: UIButton!
    @IBOutlet weak var downloadPassportButton: UIButton!
    @IBOutlet weak var showPassportButton: UIButton!
    var username : String = ""
    var csrf: String = ""
    let urlString = baseURL + "/currentpassport"
    var passportString : String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)

        if let receivedData = KeyChain.load(key: username + "passport") {
            if let savedPassportString = String(data: receivedData, encoding: .utf8){
                passportString = savedPassportString
            }
        }
    }
    
    @objc func appMovedToBackground() {
        performSegue(withIdentifier: "logout", sender: self)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    @IBAction func showCredentialsPressed(_ sender: Any) {
        if Reachability.isConnectedToNetwork(){
            performSegue(withIdentifier: "showCredentials", sender: self)
        }else{
            createAlert(title: "Error", message: "Internet Connection not Available!",sender: self)
        }
    }
    
    @IBAction func showPassportPressed(_ sender: Any) {
        if passportString.isEmpty {
            createAlert(title: "Error", message: "There isn't any downloaded passport present",sender: self)
        } else {
            performSegue(withIdentifier: "showPassport", sender: self)
        }
        
    }
    
    @IBAction func downloadPassportPressed(_ sender: Any) {
        let parameters: [String: String] = [
            "_csrf": self.csrf
        ]
        
        if !Reachability.isConnectedToNetwork(){
            createAlert(title: "Error", message: "Internet Connection not Available!",sender: self)
        } else {
            AF.request(self.urlString, method: .get, parameters: parameters)
                .response { response in
                    switch response.result {
                    case .success:
                        if let responseData = response.data, let utf8Text = String(data: responseData, encoding: .utf8) {
                            self.passportString = utf8Text
                            print(self.passportString)
                            createAlert(title: "Success", message: "Your passport has been downloaded", sender: self)
                        }
                    case .failure( _):
                        createAlert(title: "Connection Failure", message: "Cannot connect to the server", sender: self)
                    }
            }
            
            let status = KeyChain.save(key: username + "passport", data: passportString.data(using: .utf8)!)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showCredentials" {
            let credentialsController = segue.destination as! CredentialsController
            credentialsController.csrf = self.csrf
        } else if segue.identifier == "showPassport" {
            let showPassportController = segue.destination as! ShowPassportController
            showPassportController.passportString = self.passportString
        }
    }
}


class KeyChain {
    
    class func save(key: String, data: Data) -> OSStatus {
        let query = [
            kSecClass as String       : kSecClassGenericPassword as String,
            kSecAttrAccount as String : key,
            kSecValueData as String   : data ] as [String : Any]
        
        SecItemDelete(query as CFDictionary)
        
        return SecItemAdd(query as CFDictionary, nil)
    }
    
    class func load(key: String) -> Data? {
        let query = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrAccount as String : key,
            kSecReturnData as String  : kCFBooleanTrue,
            kSecMatchLimit as String  : kSecMatchLimitOne ] as [String : Any]
        
        var dataTypeRef: AnyObject? = nil
        
        let status: OSStatus = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == noErr {
            return dataTypeRef as! Data?
        } else {
            return nil
        }
    }
    
    class func delete(key: String) {
        let query = [
            kSecClass as String       : kSecClassGenericPassword as String,
            kSecAttrAccount as String : key,
            kSecValueData as String   : Data() ] as [String : Any]
        
        SecItemDelete(query as CFDictionary)
    }
    
    class func createUniqueID() -> String {
        let uuid: CFUUID = CFUUIDCreate(nil)
        let cfStr: CFString = CFUUIDCreateString(nil, uuid)
        
        let swiftString: String = cfStr as String
        return swiftString
    }
}
