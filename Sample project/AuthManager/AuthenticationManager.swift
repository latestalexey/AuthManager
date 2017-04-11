//
//  AuthenticationManager.swift
//  ChainedAnimations
//
//  Created by Borys Khliebnikov on 3/28/17.
//  Copyright © 2017 Borys Khliebnikov. All rights reserved.
//

import Foundation
import LocalAuthentication

struct KeychainManager {
    
    // MARK: Types
    
    enum KeychainError: Error {
        case noToken
        case unexpectedTokenData
        case unexpectedItemData
        case unhandledError(status: OSStatus)
    }
    
    // MARK: Properties
    
    /// Unique identifier for keychain.
    private let service: String
    
    /// User account name. Used to Login.
    private(set) var account: String
    
    // MARK: Intialization
    
    /// Designated initializer
    ///
    /// - Parameters:
    ///   - service: Unique identifier for keychain. Use custom constant key for this;
    ///   - account: User account name. Used to Login.
    init(service: String, account: String) {
        self.service = service
        self.account = account
    }
    
    // MARK: Keychain access
    
    /// Used to get user token from Keychain
    ///
    /// - Returns:  token string in case of success
    /// - Throws:   KeychainError in case of failure
    func readToken() throws -> String  {
        /*
         Build a query to find the item that matches the service, account and
         access group.
         */
        var query = KeychainManager.keychainQuery(withService: service, account: account)
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecReturnAttributes as String] = kCFBooleanTrue
        query[kSecReturnData as String] = kCFBooleanTrue
        
        // Try to fetch the existing keychain item that matches the query.
        var queryResult: AnyObject?
        let status = withUnsafeMutablePointer(to: &queryResult) {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
        }
        
        // Check the return status and throw an error if appropriate.
        guard status != errSecItemNotFound else { throw KeychainError.noToken }
        guard status == noErr else { throw KeychainError.unhandledError(status: status) }
        
        // Parse the password string from the query result.
        guard let existingItem = queryResult as? [String : AnyObject],
            let passwordData = existingItem[kSecValueData as String] as? Data,
            let password = String(data: passwordData, encoding: String.Encoding.utf8)
            else {
                throw KeychainError.unexpectedTokenData
        }
        
        return password
    }
    
    /// Used to save user token to Keychain
    ///
    /// - Parameter token:  user token string
    /// - Throws:           KeychainError in case of failure
    func saveToken(_ token: String) throws {
        // Encode the password into an Data object.
        let encodedToken = token.data(using: String.Encoding.utf8)!
        
        do {
            // Check for an existing item in the keychain.
            try _ = readToken()
            
            // Update the existing item with the new password.
            var attributesToUpdate = [String : AnyObject]()
            attributesToUpdate[kSecValueData as String] = encodedToken as AnyObject?
            
            let query = KeychainManager.keychainQuery(withService: service, account: account)
            let status = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
            
            // Throw an error if an unexpected status was returned.
            guard status == noErr else { throw KeychainError.unhandledError(status: status) }
        }
        catch KeychainError.noToken {
            /*
             No password was found in the keychain. Create a dictionary to save
             as a new keychain item.
             */
            var newItem = KeychainManager.keychainQuery(withService: service, account: account)
            newItem[kSecValueData as String] = encodedToken as AnyObject?
            
            // Add a the new item to the keychain.
            let status = SecItemAdd(newItem as CFDictionary, nil)
            
            // Throw an error if an unexpected status was returned.
            guard status == noErr else { throw KeychainError.unhandledError(status: status) }
        }
    }
    
    
    /// Used to change user name for Keychain
    ///
    /// - Parameter newAccountName: user name string
    /// - Throws:                   KeychainError in case of failure
    mutating func renameAccount(_ newAccountName: String) throws {
        // Try to update an existing item with the new account name.
        var attributesToUpdate = [String : AnyObject]()
        attributesToUpdate[kSecAttrAccount as String] = newAccountName as AnyObject?
        
        let query = KeychainManager.keychainQuery(withService: service, account: self.account)
        let status = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
        
        // Throw an error if an unexpected status was returned.
        guard status == noErr || status == errSecItemNotFound else { throw KeychainError.unhandledError(status: status) }
        
        self.account = newAccountName
    }
    
    
    /// Used to delete Keychain item
    ///
    /// - Throws: KeychainError in case of failure
    func deleteItem() throws {
        // Delete the existing item from the keychain.
        let query = KeychainManager.keychainQuery(withService: service, account: account)
        let status = SecItemDelete(query as CFDictionary)
        
        // Throw an error if an unexpected status was returned.
        guard status == noErr || status == errSecItemNotFound else { throw KeychainError.unhandledError(status: status) }
    }
    
    // MARK: Convenience
    
    
    /// Used to make query on Keychain
    ///
    /// - Parameters:
    ///   - service:    unique identifier for keychain;
    ///   - account:    user account name. Used to Login;
    /// - Returns:      dictionary of Keychain items
    private static func keychainQuery(withService service: String, account: String? = nil) -> [String : AnyObject] {
        var query = [String : AnyObject]()
        query[kSecClass as String] = kSecClassGenericPassword
        query[kSecAttrService as String] = service as AnyObject?
        
        if let account = account {
            query[kSecAttrAccount as String] = account as AnyObject?
        }
        
        return query
    }
}


@available(iOS 8.0,*)
struct TouchIDManager {
    
    // MARK: Types
    
    private enum TouchIDError: Error, LocalizedError {
        case noError
        var errorDescription: String? {
            switch self {
            case .noError:      return NSLocalizedString("Unspecified error occured",
                                                    comment: "used if TouchID failed and error is nil")
            }
        }
    }
    
    // MARK: Properties
    
    /// TouchID  authentication context
    private static let context = LAContext()
    
    /// Asks if it is possible to use TouchID or for authentication to succeed.
    ///
    /// - Returns: returns true value in case of success and false with error in case of failure
    private static func evaluateTouchID() -> (result: Bool, error: Error?) {
        var error:NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return (false, error)
        }
        return (true, nil)
    }
    
    
    /// Used to request TouchID authentication mechanism
    ///
    /// - Parameters:
    ///   - reason:         user visible reason of asking TouchID authentication. Used default if not specified
    ///   - completion:     returns true value in case of success and false with error in case of failure
    static func requestAccess(reason: String?, completion: @escaping (_ success: Bool, _ error: Error?) -> Void) {
        let evaluation = self.evaluateTouchID()
        guard evaluation.result else {
            completion(evaluation.result, evaluation.error)
            return
        }
        let localizedReason = reason ?? NSLocalizedString("Verify your fingerprint to continue",
                                                          comment: "Description string used for TouchID identification reason")
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: localizedReason) { (requestResult, requestError) in
            guard requestResult == true else {
                // Check if there is an error
                guard let error = requestError else {
                    completion(requestResult, TouchIDError.noError)
                    return
                }
                completion(requestResult, error)
                return
            }
            completion(requestResult,nil)
        }
    }
}
