//
//  NFCNDEFReaderSession+extensions.swift
//  NFCTokens
//
//  Created by Ryan Helgeson on 12/29/22.
//

import Foundation
import CoreNFC

extension NFCNDEFReaderSession {
    func writeToTag<T: Codable>(tag: NFCNDEFTag, data: T, confirmationMessage: String = "Write NDEF message successful.", completion: @escaping (T) -> ()) {
        let encodedData = try! JSONEncoder().encode(data)
        
        let payload = NFCNDEFPayload.init(
            format: .nfcWellKnown,
            type: "T".data(using: .utf8)!,
            identifier: Data(),
            payload: encodedData
        )
        
        let message = NFCNDEFMessage.init(records: [payload])
        tag.writeNDEF(message, completionHandler: { (error: Error?) in
            if let error = error {
                self.alertMessage = "Write NDEF message fail: \(error)"
                self.invalidate()
                return completion(data)
            } else {
                self.alertMessage = confirmationMessage
                self.invalidate()
                return completion(data)
            }
        })
    }
    
    func alertMoreThanOneTag() {
        // Restart polling in 500 milliseconds.
        let retryInterval = DispatchTimeInterval.milliseconds(500)
        self.alertMessage = "More than 1 tag is detected. Please remove all tags and try again."
        DispatchQueue.global().asyncAfter(deadline: .now() + retryInterval, execute: {
            self.restartPolling()
        })
    }
}
