//
//  SmtpError.swift
//
//  https://mczachurski.dev
//  Copyright © 2021 Marcin Czachurski and the repository contributors.
//  Licensed under the MIT License.
//
//  Created by Thomas Benninghaus on 13.12.23.
//

import Foundation

struct SmtpError: Error {
    let message: String

    init(_ message: String) {
        self.message = message
    }
}
