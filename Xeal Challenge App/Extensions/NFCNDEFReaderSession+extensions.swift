//
//  NFCNDEFReaderSession+extensions.swift
//  Xeal Challenge App
//
//  Created by Ryan Helgeson on 12/29/22.
//

import Foundation
import CoreNFC

extension NFCNDEFReaderSession {
    func sessionHasError(error: Error?, errorMessage: String) -> Bool {
        if error != nil {
            self.invalidate(errorMessage: errorMessage)
            return true
        } else {
            return false
        }
    }
    
    func writeToTag(tag: NFCNDEFTag, message: NFCNDEFMessage) {
        tag.writeNDEF(message, completionHandler: { (error: Error?) in
            if nil != error {
                self.alertMessage = "Write NDEF message fail: \(error!)"
            } else {
                self.alertMessage = "Write NDEF message successful."
            }
            self.invalidate()
        })
    }
    
    func writeDemo(tag: NFCNDEFTag, completion: @escaping (XealUser) -> Void) {
        let user = XealUser(firstName: "Amanda", lastName: "Gonzalez", accountValue: 0.00, id: 1)
        let data = try! JSONEncoder().encode(user)
        
        let customTextPayload2 = NFCNDEFPayload.init(
            format: .nfcWellKnown,
            type: "T".data(using: .utf8)!,
            identifier: Data(),
            payload: data
        )
        
        let message = NFCNDEFMessage.init(records: [customTextPayload2])
        
        tag.writeNDEF(message, completionHandler: { (error: Error?) in
            if nil != error {
                self.alertMessage = "Write NDEF message fail: \(error!)"
            } else {
                self.alertMessage = "Demo user Amanda Gonzalez created!"
                completion(user)
            }
            self.invalidate()
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
