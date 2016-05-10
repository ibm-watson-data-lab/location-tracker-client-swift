//
//  UsernamePasswordStore.swift
//  LocationTracker
//
//  Created by Mark Watson on 4/6/16.
//  Copyright © 2016 Mark Watson. All rights reserved.
//

import UIKit

struct UsernamePasswordStore {
    
    static let serviceName: String = "LocationTracker"
    static let usernameKey: String = "Username"
    
    
    // MARK: Save Members
    
    static func saveUsername(username: String) {
        NSUserDefaults.standardUserDefaults().setValue(username, forKey: usernameKey)
        AppState.username = username
    }
    
    static func savePassword(password: String, username: String) {
        deletePassword(username)
        //
        let keychainQuery: [NSObject: AnyObject] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService : serviceName,
            kSecAttrAccount : username,
            kSecValueData: password.dataUsingEncoding(NSUTF8StringEncoding)!
        ]
        let status: OSStatus = SecItemAdd(keychainQuery, nil)
        if (status == errSecSuccess) {
            AppState.password = password
        }
    }
    
    static func saveUsernamePassword(username: String, password: String) {
        self.saveUsername(username)
        self.savePassword(password, username: username)
    }
    
    // MARK: Load Members
    
    static func loadUsername() -> String? {
        if (AppState.username == nil) {
            let defaults = NSUserDefaults.standardUserDefaults()
            AppState.username = defaults.valueForKey(usernameKey) as? String
        }
        return AppState.username;
    }
    
    static func loadPassword(username: String) -> String? {
        if (AppState.password == nil) {
            // load from keychain
            let keychainQuery: [NSObject: AnyObject] =  [
                kSecClass : kSecClassGenericPassword,
                kSecAttrService : serviceName,
                kSecAttrAccount : username,
                kSecReturnData : kCFBooleanTrue,
                kSecMatchLimit : kSecMatchLimitOne]
            var dataTypeRef: AnyObject?
            let status = SecItemCopyMatching(keychainQuery, &dataTypeRef)
            if status == errSecSuccess, let retrievedData = dataTypeRef as! NSData? {
                AppState.password = NSString(data: retrievedData, encoding: NSUTF8StringEncoding) as? String
            }
        }
        return AppState.password
    }
    
    // MARK: Delete Members
    
    static func deleteUsernamePassword() {
        if (AppState.username != nil) {
            deletePassword(AppState.username!)
        }
        deleteUsername()
    }
    
    static func deleteUsername() {
        NSUserDefaults.standardUserDefaults().setValue(nil, forKey: usernameKey)
        AppState.username = nil
    }
    
    static func deletePassword(username: String) {
        let keychainQuery: [NSObject: AnyObject] =  [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: serviceName,
            kSecAttrAccount: username,
            kSecReturnData: kCFBooleanTrue,
            kSecMatchLimit: kSecMatchLimitOne]
        SecItemDelete(keychainQuery)
    }
}
