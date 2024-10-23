//
//  EmailAddress.swift
//
//  https://mczachurski.dev
//  Copyright © 2021 Marcin Czachurski and the repository contributors.
//  Licensed under the MIT License.
//
//  Created by Thomas Benninghaus on 13.12.23.
//

public struct EmailAddress: Sendable & Codable {
    public let address: String
    public let name: String?

    public init(address: String, name: String? = nil) {
        self.address = address
        self.name = name
    }
}
