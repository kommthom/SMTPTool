//
//  Configuration.swift
//
//
//  Created by Thomas Benninghaus on 12.12.23.
//

import Foundation
import NIO
import Vapor

public struct SmtpConfiguration: Sendable {
    public var hostname: String
    public var port: Int
    public var secure: SmtpSecureChannel
    public var connectTimeout:TimeAmount
    public var helloMethod: HelloMethod
    public var signInMethod: SignInMethod

    public init(hostname: String = "",
                port: Int = 465,
                signInMethod: SignInMethod = .anonymous,
                secure: SmtpSecureChannel = .none,
                connectTimeout: TimeAmount = TimeAmount.seconds(10),
                helloMethod: HelloMethod = .helo
    ) {
        self.hostname = hostname
        self.port = port
        self.secure = secure
        self.connectTimeout = connectTimeout
        self.helloMethod = helloMethod
        self.signInMethod = signInMethod
    }
    
    /// It will try to initialize configuration with environment variables:
    /// - SMTPTOOL_PASSWORD
    public static var environment: SmtpConfiguration {
        guard let noReplyEmail = Environment.get("NO_REPLY_EMAIL"),
              let noReplyPassword = Environment.get("NO_REPLY_PASSWORD"),
              let smtpPort = Environment.get("SMTPTOOL_SMTP_PORT"),
              let smtpServer = Environment.get("SMTPTOOL_SMTP_SERVER"),
              let timeOut = Int64(Environment.get("SMTPTOOL_TIMEOUT") ?? "10"),
              let secureString = Environment.get("SMTPTOOL_SECURE"),
              let helloMethod = Environment.get("SMTPTOOL_HALLO_METHOD")
        else {
              fatalError("SmtpTool environmant variables not set")
        }
        let secure: SmtpSecureChannel =
            switch secureString {
            case "startTLS": .startTls
            case "startTlsWhenAvailable": .startTlsWhenAvailable
            case "SSL": .ssl
            default: SmtpSecureChannel.none
            }
        let hello: HelloMethod = switch helloMethod {
            case "HELO": .helo
            case "EHLO": .ehlo
            default: .helo
            }
        return .init(hostname: smtpServer,
                     port: Int(smtpPort) ?? 587,
                     signInMethod: .credentials(username: noReplyEmail, password: noReplyPassword),
                     secure: secure,
                     connectTimeout: TimeAmount.seconds(timeOut),
                     helloMethod: hello)
    }
}
