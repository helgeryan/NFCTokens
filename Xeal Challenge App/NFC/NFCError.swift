//
//  NFCError.swift
//  Xeal Challenge App
//
//  Created by Ryan Helgeson on 1/9/24.
//

import Foundation

enum NFCError: LocalizedError {
    case unavailable
    case readFailure
    case noDataFound
    case userNotFound
    case nfcTagError(error: Error)
    case unknown
    case tagNotCompliant
    case tagReadOnly
    case noTagsFound
    case verifyUser
    
    var localizedDescription: String {
        switch self {
        case .unavailable:
            return "Service unavailable"
        case .readFailure:
            return "NFC Service failed read"
        case .userNotFound:
            return "User not found"
        case .noDataFound:
            return "NFC Tag has no data"
        case .nfcTagError(error: let error):
            return "NFC Tag Error: \(error.localizedDescription)"
        case .unknown:
            return "TODO: - Define this error"
        case .tagNotCompliant:
            return  "Tag is not NDEF compliant."
        case .tagReadOnly:
            return "Tag is read only"
        case .noTagsFound:
            return "No tags found"
        case .verifyUser:
            return "Failed to verify user"
        }
    }
}
