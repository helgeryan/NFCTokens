//
//  Logger.swift
//  NFCTokens
//
//  Created by Ryan Helgeson on 1/9/24.
//

import Foundation

class NFCLogger {
    static func log(_ text: String) {
        #if DEBUG
        debugPrint("LOG: \(text)")
        #endif
    }
    
    static func error(_ error: Error) {
        #if DEBUG
        if let nfcError = error as? NFCError {
            debugPrint("ERROR: \(nfcError.nfcDescription)")
        } else {
            debugPrint("ERROR: \(error.localizedDescription)")
        }
        #endif
    }
}
