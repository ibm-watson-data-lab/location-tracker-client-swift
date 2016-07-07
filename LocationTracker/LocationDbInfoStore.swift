//
//  LocationTrackerDbInfoStore.swift
//  LocationTracker
//
//  Created by Mark Watson on 4/6/16.
//  Copyright © 2016 Mark Watson. All rights reserved.
//

import UIKit

struct LocationDbInfoStore {

    static let serviceName: String = "LocationDb"
    static let apiKeyKey: String = "ApiKey"
    static let dbNameKey: String = "DbName"
    static let dbHostKey: String = "DbHost"
    static let dbHostProtocolKey: String = "DbHostProtocol"
    
    // MARK: Save Members
    
    static func saveApiKey(apiKey: String) {
        NSUserDefaults.standardUserDefaults().setValue(apiKey, forKey: apiKeyKey)
        AppState.locationDbApiKey = apiKey
    }
    
    static func saveApiPassword(apiPassword: String, apiKey: String) {
        deleteApiPassword(apiKey)
        //
        let keychainQuery: [NSObject: AnyObject] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService : serviceName,
            kSecAttrAccount : apiKey,
            kSecValueData: apiPassword.dataUsingEncoding(NSUTF8StringEncoding)!
        ]
        let status: OSStatus = SecItemAdd(keychainQuery, nil)
        if (status == errSecSuccess) {
            AppState.locationDbApiPassword = apiPassword
        }
    }
    
    static func saveDbName(dbName: String) {
        NSUserDefaults.standardUserDefaults().setValue(dbName, forKey: dbNameKey)
        AppState.locationDbName = dbName
    }
    
    static func saveDbHost(dbHost: String) {
        NSUserDefaults.standardUserDefaults().setValue(dbHost, forKey: dbHostKey)
        AppState.locationDbHost = dbHost
    }
    
    static func saveDbHostProtocol(dbHostProtocol: String) {
        NSUserDefaults.standardUserDefaults().setValue(dbHostProtocol, forKey: dbHostProtocolKey)
        AppState.locationDbHostProtocol = dbHostProtocol
    }
    
    static func saveApiKeyPasswordDbNameHost(apiKey: String, apiPassword: String, dbName: String, dbHost: String, dbHostProtocol: String?) {
        self.saveApiKey(apiKey)
        self.saveApiPassword(apiPassword, apiKey: apiKey)
        self.saveDbName(dbName)
        self.saveDbHost(dbHost)
        if (dbHostProtocol != nil) {
            self.saveDbHostProtocol(dbHostProtocol!)
        }
        else {
            self.deleteDbHostProtocol()
        }
    }
    
    // MARK: Load Members
    
    static func loadApiKey() -> String? {
        if (AppState.locationDbApiKey == nil) {
            let defaults = NSUserDefaults.standardUserDefaults()
            AppState.locationDbApiKey = defaults.valueForKey(apiKeyKey) as? String
        }
        return AppState.locationDbApiKey;
    }
    
    static func loadApiPassword(apiKey: String) -> String? {
        if (AppState.locationDbApiPassword == nil) {
            // load from keychain
            let keychainQuery: [NSObject: AnyObject] =  [
                kSecClass : kSecClassGenericPassword,
                kSecAttrService : serviceName,
                kSecAttrAccount : apiKey,
                kSecReturnData : kCFBooleanTrue,
                kSecMatchLimit : kSecMatchLimitOne]
            var dataTypeRef: AnyObject?
            let status = SecItemCopyMatching(keychainQuery, &dataTypeRef)
            if status == errSecSuccess, let retrievedData = dataTypeRef as! NSData? {
                AppState.locationDbApiPassword = NSString(data: retrievedData, encoding: NSUTF8StringEncoding) as? String
            }
        }
        return AppState.locationDbApiPassword
    }
    
    static func loadDbName() -> String? {
        if (AppState.locationDbName == nil) {
            let defaults = NSUserDefaults.standardUserDefaults()
            AppState.locationDbName = defaults.valueForKey(dbNameKey) as? String
        }
        return AppState.locationDbName;
    }
    
    static func loadDbHost() -> String? {
        if (AppState.locationDbHost == nil) {
            let defaults = NSUserDefaults.standardUserDefaults()
            AppState.locationDbHost = defaults.valueForKey(dbHostKey) as? String
        }
        return AppState.locationDbHost;
    }
    
    static func loadDbHostProtocol() -> String? {
        if (AppState.locationDbHostProtocol == nil) {
            let defaults = NSUserDefaults.standardUserDefaults()
            AppState.locationDbHostProtocol = defaults.valueForKey(dbHostProtocolKey) as? String
        }
        return AppState.locationDbHostProtocol;
    }
    
    // MARK: Delete Members
    
    static func deleteApiKeyPasswordDbNameHost() {
        deleteDbHostProtocol()
        deleteDbHost()
        deleteDbName()
        if (AppState.locationDbApiKey != nil) {
            deleteApiPassword(AppState.locationDbApiKey!)
        }
        deleteApiKey()
    }
    
    static func deleteApiKey() {
        NSUserDefaults.standardUserDefaults().setValue(nil, forKey: apiKeyKey)
        AppState.locationDbApiKey = nil
    }
    
    static func deleteApiPassword(apiKey: String) -> Bool {
        let keychainQuery: [NSObject: AnyObject] =  [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: serviceName,
            kSecAttrAccount: apiKey]
        let status = SecItemDelete(keychainQuery)
        return (status == errSecSuccess)
    }
    
    static func deleteDbName() {
        NSUserDefaults.standardUserDefaults().setValue(nil, forKey: dbNameKey)
        AppState.locationDbName = nil
    }
    
    static func deleteDbHost() {
        NSUserDefaults.standardUserDefaults().setValue(nil, forKey: dbHostKey)
        AppState.locationDbHost = nil
    }
    
    static func deleteDbHostProtocol() {
        NSUserDefaults.standardUserDefaults().setValue(nil, forKey: dbHostProtocolKey)
        AppState.locationDbHostProtocol = nil
    }
}
