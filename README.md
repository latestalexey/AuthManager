AuthManager
============

Authentication class for storing Tokens in keychain. Contains TouchID helper.

## Instruction

Copy [AuthenticationManager.swift](https://github.com/steelkiwi/AuthManager/AuthenticationManager.swift) file to your project

Examples:
```swift
// KeychainManager
let keychain = KeychainManager.init(service: "keychain service name", account: "username")
do {
     try keychain.saveToken("token string")
} catch {
      ...handle error
}
        
do {
     userToken = try keychain.readToken()
} catch {
     ...handle error
}      

// TouchIDManager
TouchIDManager.requestAccess(reason: "Reason string for using TouchID") { (result, error) in
           ... 
}
```



