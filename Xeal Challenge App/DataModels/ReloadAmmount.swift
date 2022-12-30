//
//  ReloadAmmount.swift
//  Xeal Challenge App
//
//  Created by Ryan Helgeson on 12/30/22.
//

import Foundation

struct ReloadAmount: Equatable, Codable {
    var value: Double
    
    var dollarString: String {
        return String(format: "$%0.0f", value)
    }
}
