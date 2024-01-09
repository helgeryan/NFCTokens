//
//  NFCService.swift
//  Xeal Challenge App
//
//  Created by Ryan Helgeson on 1/7/24.
//

import Foundation
import CoreNFC

enum NFCAction {
    case createUser
    case readUser
    case reloadUser
    
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

enum NFCError {
    case readFailure
    case userNotFound
}

protocol NFCServiceDelegate {
//    func read()
//    func write()
    func didReadUser(user: XealUser)
    func reloadCompleted(user: XealUser)
    func nfcFinishedWithError(error: NFCError)
}

class NFCService: NSObject {
    var session: NFCReaderSession?
    var readUserSession: NFCReaderSession?
    var newUserSession: NFCReaderSession?
    var currentAction: NFCAction?
    var delegate: NFCServiceDelegate?
    
    // MARK: - Setup NFCReaderSessions
    func setupSession(action: NFCAction) {
        currentAction = action
        session = NFCNDEFReaderSession(delegate: self, queue: DispatchQueue.main, invalidateAfterFirstRead: false)
        session?.alertMessage = action.prompt
        session?.begin()
    }
    
//    func setupNewUserSession() {
//        self.newUserSession = NFCNDEFReaderSession(delegate: self, queue: DispatchQueue.main, invalidateAfterFirstRead: false)
//        self.newUserSession?.alertMessage = "Hold your device near a tag to setup new user."
//        self.newUserSession?.begin()
//    }
//    
//    func setupReadUserSession() {
//        self.readUserSession = NFCNDEFReaderSession(delegate: self, queue: DispatchQueue.main, invalidateAfterFirstRead: false)
//        self.readUserSession?.alertMessage = "Hold your device near a tag to read account data"
//        self.readUserSession?.begin()
//    }
    
    func completeNFCSession(message: String) {
        session?.alertMessage = message
        session?.invalidate()
    }
}

// MARK: - NFCNDEFReaderSessionDelegate
extension NFCService: NFCNDEFReaderSessionDelegate {
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
                        self.completeNFCSession(message: "Tag is not NDEF compliant.")
                        break
                    case .readOnly:
                        self.completeNFCSession(message: "Tag is read only")
                        break
                    case .readWrite:
                        if .createUser == self.currentAction {
                            session.writeDemo(tag: tag, completion: { [weak self] user in
                                guard let self = self else {
                                    return
                                }
                                self.delegate?.didReadUser(user: user)
                            })
                        } else if .readUser == self.currentAction {
                            self.readUserAccountInfo(session: session, tag: tag)
                        } else if .reloadUser == self.currentAction{
                            self.updateUserAccountFundsAvailable(session: session, tag: tag)
                        }
                        break
                    @unknown default:
                        session.alertMessage = "Unknown NDEF tag status."
                        session.invalidate()
                        break
                    }
                })
            })
        } else {
            session.alertMessage = "Found no tags, try again."
            session.invalidate()
        }
    }
    
    func readUserAccountInfo(session: NFCNDEFReaderSession, tag: NFCNDEFTag) {
        tag.readNDEF(completionHandler: { mess, error in
            let noUserMessage = "No user found, follow next steps to write a demo user"
            if let payload = mess?.records.first {
                if let user: XealUser = self.decodeStruct(payload) {
//                    self.currUser = user
//                    self.delegate?.userUpdated(user)
                    self.delegate?.didReadUser(user: user)
                    session.alertMessage = "Hello \(user.firstName)!"
                    session.invalidate()
                } else {
                    session.invalidate(errorMessage: noUserMessage)
//                    self.delegate?.noUserFound()
                    self.delegate?.nfcFinishedWithError(error: .userNotFound)
                }
            }
            else if session.sessionHasError(error: error, errorMessage: noUserMessage) {
//                self.delegate?.noUserFound()
                self.delegate?.nfcFinishedWithError(error: .userNotFound)
                return
            } else {
                session.invalidate(errorMessage: noUserMessage)
            }
        })
    }
    
    func updateUserAccountFundsAvailable(session: NFCNDEFReaderSession, tag: NFCNDEFTag) {
        tag.readNDEF(completionHandler: { mess, error in
            if session.sessionHasError(error: error, errorMessage: "Failed to read NDEF") {
                return
            } else if let payload = mess?.records.first {
                if var user: XealUser = self.decodeStruct(payload) { //}, user.id == self.currUser?.id {
//                    if let selectedReloadAmount = self.selectedReloadAmount {
//                        user.accountValue = user.accountValue + selectedReloadAmount.value
                    user.accountValue = user.accountValue + 22.0
                        let message = self.createNewUserMessage(user: user)
                        tag.writeNDEF(message, completionHandler: { error in
                            if session.sessionHasError(error: error, errorMessage: "Failed to process payment") {
                                return
                            }
                            self.delegate?.reloadCompleted(user: user)
                            session.alertMessage = "Processed payment!"
                            session.invalidate()
                        })
//                    } else {
//                        session.invalidate(errorMessage: "No reload amount selected")
//                    }
                } else {
                    session.invalidate(errorMessage: "Failed to verify user")
                }
            } else {
                session.invalidate(errorMessage: "Failed to read user data")
            }
        })
    }
    
    func createNewUserMessage(user: XealUser) -> NFCNDEFMessage {
        let data = try! JSONEncoder().encode(user)

        let newUser = NFCNDEFPayload.init(
            format: .nfcWellKnown,
            type: "T".data(using: .utf8)!,
            identifier: Data(),
            payload: data
        )

        let message = NFCNDEFMessage.init(records: [newUser])
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
