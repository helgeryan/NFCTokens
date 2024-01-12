//
//  NFCUser.swift
//  Xeal Challenge App
//
//  Created by Ryan Helgeson on 12/30/22.
//

import Foundation

struct NFCUser: Equatable, Codable {
    // MARK: - Properties
    var firstName: String
    var lastName: String
    var accountValue: Double
    var id: Int
    
    // MARK: - Helpers
    var name: String {
        var nameString = ""
        nameString = firstName
        if nameString.isEmpty {
            nameString = lastName
        } else {
            nameString.append(" \(lastName)")
        }
        return nameString
    }
    
    var fundsAvailable: String {
        let fundsAvailable = String(format: "$%0.2f", self.accountValue)
        return fundsAvailable
    }
}
