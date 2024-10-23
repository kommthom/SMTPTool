//
//  Email.swift
//
//  https://mczachurski.dev
//  Copyright © 2021 Marcin Czachurski and the repository contributors.
//  Licensed under the MIT License.
//
//  Created by Thomas Benninghaus on 13.12.23.
//

import Vapor
import Foundation
import NIO

public struct Email: Content, Sendable {
    public let from: EmailAddress
    public let to: [EmailAddress]?
    public let cc: [EmailAddress]?
    public let bcc: [EmailAddress]?
    public let subject: String
    public let body: String
    public let isBodyHtml: Bool
    public let replyTo: EmailAddress?
    public let reference : String?
    public let dateFormatted: String
    public let uuid : String

    internal var attachments: [Attachment] = []
    
    private enum CodingKeys: String, CodingKey {
        case from
        case to
        case replyTo = "h:Reply-To"
        case cc
        case bcc
        case subject
        case body
        case isBodyHtml
        case reference
        case dateFormatted
        case uuid
        case attachments
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(from, forKey: .from)
        try container.encode(to, forKey: .to)
        try container.encode(cc, forKey: .cc)
        try container.encode(bcc, forKey: .bcc)
        try container.encode(subject, forKey: .subject)
        try container.encode(body, forKey: .body)
        try container.encode(isBodyHtml, forKey: .isBodyHtml)
        try container.encode(reference, forKey: .reference)
        try container.encode(dateFormatted, forKey: .dateFormatted)
        try container.encode(uuid, forKey: .uuid)
        try container.encode(attachments, forKey: .attachments)

    }
    
    public init(from: EmailAddress, to: [EmailAddress]? = nil, cc: [EmailAddress]? = nil, bcc: [EmailAddress]? = nil, subject: String, body: String, isBodyHtml: Bool = true, replyTo: EmailAddress? = nil, reference: String? = nil, attachments:  [Attachment]? = nil ) throws {
        if (to?.isEmpty ?? true) == true && (cc?.isEmpty ?? true) == true && (bcc?.isEmpty ?? true) == true {
            throw EmailError.recipientNotSpecified
        }
        self.from = from
        self.to = to
        self.cc = cc
        self.bcc = bcc
        self.subject = subject
        self.body = body
        self.isBodyHtml = isBodyHtml
        self.replyTo = replyTo
        self.reference = reference
        
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"

        self.dateFormatted = dateFormatter.string(from: date)
        self.uuid = "<\(date.timeIntervalSince1970)\(self.from.address.drop { $0 != "@" })>"
        self.attachments = attachments ?? []
    }

    public mutating func addAttachment(_ attachment: Attachment) {
        self.attachments.append(attachment)
    }
}

extension Email {
    internal func write(to out: inout ByteBuffer) {

        out.writeString("From: \(self.formatMIME(emailAddress: self.from))\r\n")

        if let to = self.to {
            let toAddresses = to.map { self.formatMIME(emailAddress: $0) }.joined(separator: ", ")
            out.writeString("To: \(toAddresses)\r\n")
        }

        if let cc = self.cc {
            let ccAddresses = cc.map { self.formatMIME(emailAddress: $0) }.joined(separator: ", ")
            out.writeString("Cc: \(ccAddresses)\r\n")
        }

        if let replyTo = self.replyTo {
            out.writeString("Reply-to: \(self.formatMIME(emailAddress:replyTo))\r\n")
        }

        out.writeString("Subject: \(self.subject)\r\n")
        out.writeString("Date: \(self.dateFormatted)\r\n")
        out.writeString("Message-ID: \(self.uuid)\r\n")

        if let reference = self.reference {
            out.writeString("In-Reply-To: \(reference)\r\n")
            out.writeString("References: \(reference)\r\n")
        }

        let boundary = self.boundary()
        if self.attachments.count > 0 {
            out.writeString("Content-type: multipart/mixed; boundary=\"\(boundary)\"\r\n")
            out.writeString("Mime-Version: 1.0\r\n\r\n")
        } else if self.isBodyHtml {
            out.writeString("Content-Type: text/html; charset=\"UTF-8\"\r\n")
            out.writeString("Mime-Version: 1.0\r\n\r\n")
        } else {
            out.writeString("Content-Type: text/plain; charset=\"UTF-8\"\r\n")
            out.writeString("Mime-Version: 1.0\r\n\r\n")
        }

        if self.attachments.count > 0 {

            if self.isBodyHtml {
                out.writeString("--\(boundary)\r\n")
                out.writeString("Content-Type: text/html; charset=\"UTF-8\"\r\n\r\n")
                out.writeString("\(self.body)\r\n")
                out.writeString("--\(boundary)\r\n")
            } else {
                out.writeString("--\(boundary)\r\n")
                out.writeString("Content-Type: text/plain; charset=\"UTF-8\"\r\n\r\n")
                out.writeString("\(self.body)\r\n\r\n")
                out.writeString("--\(boundary)\r\n")
            }

            for attachment in self.attachments {
                out.writeString("Content-type: \(attachment.contentType)\r\n")
                out.writeString("Content-Transfer-Encoding: base64\r\n")
                out.writeString("Content-Disposition: attachment; filename=\"\(attachment.name)\"\r\n\r\n")
                out.writeString("\(attachment.data.base64EncodedString())\r\n")
                out.writeString("--\(boundary)\r\n")
            }

        } else {
            out.writeString(self.body)
        }

        out.writeString("\r\n.")
    }

    private func boundary() -> String {
        return UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
    }

    func formatMIME(emailAddress: EmailAddress) -> String {
        if let name = emailAddress.name {
            return "\(name) <\(emailAddress.address)>"
        } else {
            return emailAddress.address
        }
    }
}
