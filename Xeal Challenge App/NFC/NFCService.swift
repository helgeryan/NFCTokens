//
//  NFCService.swift
//  Xeal Challenge App
//
//  Created by Ryan Helgeson on 1/7/24.
//

import Foundation
import CoreNFC

protocol NFCServiceDelegate {
    func didReadUser(user: XealUser)
    func reloadCompleted(user: XealUser)
    func nfcFinishedWithError(error: NFCError)
}

class NFCService: NSObject {
    var session: NFCReaderSession?
    var currentAction: NFCAction?
    var delegate: NFCServiceDelegate?
    
    // MARK: - Setup NFCReaderSessions
    func setupSession(action: NFCAction) {
        currentAction = action
        session = NFCNDEFReaderSession(delegate: self, queue: DispatchQueue.main, invalidateAfterFirstRead: false)
        session?.alertMessage = action.prompt
        session?.begin()
    }
    
    func completeNFCSession(message: String) {
        session?.alertMessage = message
        session?.invalidate()
        currentAction = nil
    }
    
    func completeNFCSession(_ error: NFCError, message: String) {
        session?.invalidate(errorMessage: message)
        self.delegate?.nfcFinishedWithError(error: error)
        NFCLogger.error(error)
        currentAction = nil
    }
    
    private func runAction(session: NFCNDEFReaderSession, tag: NFCNDEFTag) {
        switch self.currentAction {
        case .createUser(user: let user):
            session.writeToTag(tag: tag, data: user, confirmationMessage: "Created new user: \(user.name)", completion: { [weak self] user in
                guard let self = self else {
                    return
                }
                self.delegate?.didReadUser(user: user)
            })
            break
        case .readUser:
            self.readUserAccountInfo(session: session, tag: tag)
            break
        case .reloadUser(user: let user, amount: let amount):
            self.updateUserAccountFundsAvailable(session: session, tag: tag, user: user, amount: amount)
            break
        default:
            self.completeNFCSession(message: "No action")
            break
        }
    }
}

// MARK: - NFCNDEFReaderSessionDelegate
extension NFCService: NFCNDEFReaderSessionDelegate {
    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
        NFCLogger.log("NFC Reader opened")
    }
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        // Handle Error
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        // Do nothing, function not called with declaration of: readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag])
    }

    
    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        if tags.count > 1 {
            session.alertMoreThanOneTag()
            return
        }
        
        // Connect to the found tag and write an NDEF message to it.
        if let tag = tags.first {
            session.connect(to: tag, completionHandler: { [weak self] (error: Error?) in
                guard let self = self else {

                    return
                }
                if session.sessionHasError(error: error, errorMessage:  "Unable to connect to tag.") {
                    return
                }
                
                tag.queryNDEFStatus(completionHandler: { (ndefStatus: NFCNDEFStatus, capacity: Int, error: Error?) in
                    if session.sessionHasError(error: error, errorMessage: "Unable to query the NDEF status of tag.") {
                        return
                    }

                    switch ndefStatus {
                    case .notSupported:
                        self.completeNFCSession(.tagNotCompliant, message: "Tag is not NDEF compliant.")
                        break
                    case .readOnly:
                        self.completeNFCSession(.tagReadOnly, message: "Tag is read only")
                        break
                    case .readWrite:
                        self.runAction(session: session, tag: tag)
                        break
                    @unknown default:
                        self.completeNFCSession(.unknown, message: "Unknown error")
                        break
                    }
                })
            })
        } else {
            self.completeNFCSession(.noTagsFound, message: "No tags found, try again")
        }
    }
    
    func readUserAccountInfo(session: NFCNDEFReaderSession, tag: NFCNDEFTag) {
        NFCLogger.log("Begin read user")
        tag.readNDEF(completionHandler: { [weak self] mess, error in
            guard let self = self else {
                NFCLogger.error(NFCError.unavailable)
                return
            }
            let noUserMessage = "No user found, follow next steps to write a demo user"
            if let payload = mess?.records.first {
                if let user: XealUser = self.decodeStruct(payload) {
                    self.delegate?.didReadUser(user: user)
                    session.alertMessage = "Hello \(user.firstName)!"
                    session.invalidate()
                } else {
                    self.completeNFCSession(.userNotFound, message: noUserMessage)
                }
            }
            else if let _ = error {
                self.completeNFCSession(.userNotFound, message: noUserMessage)
                return
            } else {
                self.completeNFCSession(.unknown, message: noUserMessage)
            }
        })
    }
    
    func updateUserAccountFundsAvailable(session: NFCNDEFReaderSession, tag: NFCNDEFTag, user: XealUser, amount: ReloadAmount) {
        NFCLogger.log("Reloading \(amount.dollarString) to \(user.name)")
        tag.readNDEF(completionHandler: { mess, error in
            if session.sessionHasError(error: error, errorMessage: "Failed to read NDEF") {
                return
            } else if let payload = mess?.records.first {
                if var tagUser: XealUser = self.decodeStruct(payload), tagUser.id == user.id {
                    tagUser.accountValue = tagUser.accountValue + amount.value
                    let message = self.createNewUserMessage(user: tagUser)
                    tag.writeNDEF(message, completionHandler: { error in
                        if session.sessionHasError(error: error, errorMessage: "Failed to process payment") {
                            return
                        }
                        self.delegate?.reloadCompleted(user: tagUser)
                        session.alertMessage = "Processed payment!"
                        session.invalidate()
                    })
                } else {
                    session.invalidate(errorMessage: "Failed to verify user")
                }
            } else {
                session.invalidate(errorMessage: "Failed to read user data")
            }
        })
    }
    
    func createNewUserMessage(user: XealUser) -> NFCNDEFMessage {
       return createNFCNDEFMessage(data: user)
    }
    
    func createNFCNDEFMessage<T: Codable>(data: T) -> NFCNDEFMessage {
        let encodedData = try! JSONEncoder().encode(data)

        let payload = NFCNDEFPayload.init(
            format: .nfcWellKnown,
            type: "T".data(using: .utf8)!,
            identifier: Data(),
            payload: encodedData
        )

        let message = NFCNDEFMessage.init(records: [payload])
        return message
    }
    
    // MARK: - Coding
    
    /// Decode a data structure from a NFCNDEFPayload
    ///
    /// ```
    /// let user: XealUser = decodeStruct(payload)
    /// ```
    ///
    /// > Warning: Must specify the type or the Data Structure
    ///
    /// - Returns: Optional struct of type T decoded from the NFCNDEFPayload
    func decodeStruct<T: Codable>(_ message: NFCNDEFPayload) -> T? {
        do {
            let data = try JSONDecoder().decode(T.self, from: message.payload)
            return data
        } catch {
            return nil
        }
    }
}
