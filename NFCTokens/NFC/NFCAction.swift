//
//  NFCActions.swift
//  NFCTokens
//
//  Created by Ryan Helgeson on 1/9/24.
//

import Foundation


enum NFCAction: Equatable {
    case createUser(user: NFCUser)
    case readUser
    case reloadUser(user: NFCUser, amount: ReloadAmount)
    
    var prompt: String {
        switch self {
        case .createUser:
            return "Hold your device near the tag to reload your account with additional funds."
        case .readUser:
            return "Hold your device near a tag to setup new user."
        case .reloadUser:
            return "Hold your device near a tag to read account data"
        }
    }
}
