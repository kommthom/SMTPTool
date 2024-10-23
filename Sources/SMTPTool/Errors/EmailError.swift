//
//  EmailError.swift
//
//  https://mczachurski.dev
//  Copyright © 2021 Marcin Czachurski and the repository contributors.
//  Licensed under the MIT License.
//
//  Created by Thomas Benninghaus on 13.12.23.
//

import Foundation

public enum EmailError: Error {
    case recipientNotSpecified
    case templateTypeNotSpecified
    case languageNotSpecified
    case interpolationsNotComplete
    case buildFromTemplateFailed
}
