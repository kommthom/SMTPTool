//
//  ErrorResponse.swift
//
//
//  Created by Thomas Benninghaus on 12.12.23.
//

/// Error response object
public struct SmtpToolErrorResponse: Decodable {
    /// Error messsage
    public let message: String
}
