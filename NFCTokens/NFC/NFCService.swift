//
//  NFCService.swift
//  Xeal Challenge App
//
//  Created by Ryan Helgeson on 1/7/24.
//

import Foundation
import CoreNFC

protocol NFCServiceDelegate {
    func didReadUser(user: NFCUser)
    func reloadCompleted(user: NFCUser)
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
    
    private func completeNFCSession(message: String) {
        DispatchQueue.main.async {
            self.session?.alertMessage = message
            self.session?.invalidate()
            self.currentAction = nil
        }
    }
    
    private func completeNFCSession(_ error: NFCError, message: String) {
        DispatchQueue.main.async {
            NFCLogger.error(error)
            self.session?.invalidate(errorMessage: message)
            self.delegate?.nfcFinishedWithError(error: error)
            self.currentAction = nil
        }
    }
    
    private func runAction(session: NFCNDEFReaderSession, tag: NFCNDEFTag) async {
        switch self.currentAction {
        case .createUser(user: let user):
            await self.creatUser(session: session, tag: tag, user: user)
            break
        case .readUser:
            await self.readUserAccountInfo(session: session, tag: tag)
            break
        case .reloadUser(user: let user, amount: let amount):
            await self.updateUserAccountFundsAvailable(session: session, tag: tag, user: user, amount: amount)
            break
        default:
            self.completeNFCSession(message: "No action")
            break
        }
    }
    
    private func connect( session: NFCNDEFReaderSession, tag: NFCNDEFTag) async -> Error? {
        await withCheckedContinuation { continuation in
            session.connect(to: tag, completionHandler: { [weak self] (error: Error?) in
                guard let _ = self else {
                    NFCLogger.error(NFCError.unavailable)
                    continuation.resume(returning: NFCError.unavailable)
                    return
                }
                if let error = error {
                    continuation.resume(returning: error)
                    return
                }
                
                continuation.resume(returning: nil)
            })
        }
    }
    
    private func queryStatus(session: NFCNDEFReaderSession, tag: NFCNDEFTag) async -> NFCError? {
        await withCheckedContinuation { continuation in
            tag.queryNDEFStatus(completionHandler: { (ndefStatus: NFCNDEFStatus, capacity: Int, error: Error?) in
                if let error = error {
                    continuation.resume(returning: .nfcTagError(error: error))
                    return
                }
                
                switch ndefStatus {
                case .notSupported:
                    continuation.resume(returning: NFCError.tagNotCompliant)
                    break
                case .readOnly:
                    continuation.resume(returning: NFCError.tagReadOnly)
                    break
                case .readWrite:
                    continuation.resume(returning: nil)
                    break
                @unknown default:
                    continuation.resume(returning: NFCError.unknown)
                    break
                }
            })
        }
    }

    // MARK: - Coding
    
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
    
    /// Decode a data structure from a NFCNDEFPayload
    ///
    /// ```
    /// let user: NFCUser = decodeStruct(payload)
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
    
    private func read(session: NFCNDEFReaderSession, tag: NFCNDEFTag) async -> Result<NFCNDEFPayload, NFCError>  {
        await withCheckedContinuation { continuation in
            tag.readNDEF(completionHandler: { mess, error in
                if let payload = mess?.records.first {
                    continuation.resume(returning: .success(payload))
                }
                else if let error = error {
                    continuation.resume(returning: .failure(NFCError.nfcTagError(error: error)))
                    return
                } else {
                    continuation.resume(returning: .failure(NFCError.unknown))
                }
            })
        }
    }
    
    private func write<T: Codable>(session: NFCNDEFReaderSession, tag: NFCNDEFTag, data: T) async -> Result<T, NFCError>  {
        await withCheckedContinuation { continuation in
            let message = createNFCNDEFMessage(data: data)
            tag.writeNDEF(message, completionHandler: { error in
                if let error = error {
                    continuation.resume(returning: .failure(NFCError.nfcTagError(error: error)))
                    return
                } else {
                    continuation.resume(returning: .success(data))
                }
            })
        }
    }
    
    // MARK: - Actions
    private func readUserAccountInfo(session: NFCNDEFReaderSession, tag: NFCNDEFTag) async {
        NFCLogger.log("Begin read user")
        let result = await read(session: session, tag: tag)
        let noUserMessage = "No user found, follow next steps to write a demo user"
        
        switch result {
        case .success(let payload):
            if let user: NFCUser = self.decodeStruct(payload) {
                DispatchQueue.main.async {
                    self.delegate?.didReadUser(user: user)
                    session.alertMessage = "Hello \(user.firstName)!"
                    session.invalidate()
                }
                return
            } else {
                self.completeNFCSession(.userNotFound, message: noUserMessage)
                return
            }
        case .failure(_):
            self.completeNFCSession(.userNotFound, message: noUserMessage)
            return
        }
    }
    
    private func updateUserAccountFundsAvailable(session: NFCNDEFReaderSession, tag: NFCNDEFTag, user: NFCUser, amount: ReloadAmount) async {
        NFCLogger.log("Reloading \(amount.dollarString) to \(user.name)")
        
        let result = await read(session: session, tag: tag)
        let noUserMessage = "No user found, follow next steps to write a demo user"
        
        switch result {
        case .success(let payload):
            if var tagUser: NFCUser = self.decodeStruct(payload), tagUser.id == user.id {
                tagUser.accountValue = tagUser.accountValue + amount.value
                let result = await write(session: session, tag: tag, data: tagUser)
                switch result {
                case .success(let data):
                    DispatchQueue.main.async {
                        self.delegate?.reloadCompleted(user: data)
                    }
                    self.completeNFCSession(message: "Processed payment!")
                    break
                case .failure(let error):
                    self.completeNFCSession( error, message: "Failed to write updated user data")
                   break
                }
            } else {
                self.completeNFCSession(.verifyUser, message: "Failed to verify user")
            }
            break
        case .failure(_):
            self.completeNFCSession(.userNotFound, message: noUserMessage)
            break
        }
    }
    
    private func creatUser(session: NFCNDEFReaderSession, tag: NFCNDEFTag, user: NFCUser) async {
        let result = await write(session: session, tag: tag, data: user)
        switch result {
        case .success(let data):
            DispatchQueue.main.async {
                self.delegate?.didReadUser(user: data)
            }
            self.completeNFCSession(message: "Created new user: \(data.name)!")
            return
        case .failure(let error):
            self.completeNFCSession(error, message: "Failed to create user")
            return
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
            Task {
                // Connect to the tag
                if let error = await self.connect(session: session, tag: tag) {
                    self.completeNFCSession(.nfcTagError(error: error), message: "Unable to connect")
                    return
                }
                
                // Query the tag, if error don't do action
                if let error = await self.queryStatus(session: session, tag: tag) {
                    self.completeNFCSession(error, message: "Tag is not read/write")
                    return
                }
                
                // Perform the action
                await self.runAction(session: session, tag: tag)
            }
        } else {
            self.completeNFCSession(.noTagsFound, message: "No tags found, try again")
        }
    }
}
