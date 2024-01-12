//
//  HomeViewModel.swift
//  NFCTokens
//
//  Created by Ryan Helgeson on 12/30/22.
//

import Foundation
import CoreNFC

// MARK: - HomeViewModelDelegate
protocol HomeViewModelDelegate {
    func userUpdated(_ user: NFCUser)
    func paymentSuccess(_ user: NFCUser)
    func noUserFound()
}

// MARK: - HomeViewModel
class HomeViewModel: NSObject {
    let nfcService: NFCService = NFCService()
    
    // MARK: - Properties
    var currUser: NFCUser?
    var selectedReloadAmount: ReloadAmount?
    var delegate: HomeViewModelDelegate?
    
    // MARK: - Setup NFCReaderSessions
    func doReload() {
        if let user = currUser,
           let amount = selectedReloadAmount {
            setupSession(action: .reloadUser(user: user, amount: amount))
        }
    }
    
    func doCreateNewUser() {
        let user = NFCUser(firstName: "Amanda", lastName: "Gonzalez", accountValue: 0.00, id: 1)
        setupSession(action: .createUser(user: user))
    }
    
    func readUser() {
        setupSession(action: .readUser)
    }
    
    private func setupSession(action: NFCAction) {
        nfcService.delegate = self
        nfcService.setupSession(action: action)
    }
}

extension HomeViewModel: NFCServiceDelegate {
    func reloadCompleted(user: NFCUser) {
        NFCLogger.log("Successfully reloaded money to \(user.name)")
        self.delegate?.paymentSuccess(user)
    }
    
    func didReadUser(user: NFCUser) {
        NFCLogger.log("Successfully read user: \(user.name)")
        self.currUser = user
        self.delegate?.userUpdated(user)
    }
    
    func nfcFinishedWithError(error: NFCError) {
        // TODO: - Handle Error
        switch error {
        case .userNotFound:
            self.delegate?.noUserFound()
            break
        default:
            break
        }
    }
}
