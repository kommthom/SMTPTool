//
//  SmtpResponse.swift
//
//  https://mczachurski.dev
//  Copyright © 2021 Marcin Czachurski and the repository contributors.
//  Licensed under the MIT License.
//
//  Created by Thomas Benninghaus on 13.12.23.
//

internal enum SmtpResponse {
    case ok(Int, String)
    case error(String)
}
