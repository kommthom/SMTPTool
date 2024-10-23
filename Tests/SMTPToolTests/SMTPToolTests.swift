//
//  SMTPToolTests.swift
//
//
//  Created by Thomas Benninghaus on 01.01.24.
//

import XCTest
import NIO
import Vapor
//import Resources
@testable import SMTPTool

final class SMTPToolTests: XCTestCase {
    func testSendTextMessageOverTSL() throws {
        let app = Application(.testing)
        let eventLoop = app.eventLoopGroup.next()
        defer { app.shutdown() }
        try configure(app)
        let tslSmtpConfiguration = SmtpConfiguration(
			hostname: Environment.get(NeededEnvironmentVariables.SMTPTOOL_SMTP_SERVER.rawValue)!,
			port: Int(Environment.get(NeededEnvironmentVariables.SMTPTOOL_SMTP_PORT.rawValue)!)!,
			signInMethod: .credentials(username: Environment.get(NeededEnvironmentVariables.NO_REPLY_EMAIL.rawValue)!,
			password: Environment.get(NeededEnvironmentVariables.NO_REPLY_PASSWORD.rawValue)!),
			secure: .startTls, helloMethod: .ehlo
		)
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short)
        app.smtp.configuration = tslSmtpConfiguration
        var email = try! Email(from: EmailAddress(address: Environment.get(NeededEnvironmentVariables.NO_REPLY_EMAIL.rawValue)!, name: "Thomas B."),
                          to: [EmailAddress(address: "tbenninghaus@web.de", name: "Ben Doe")],
                          subject: "The subject (over TSL) - \(timestamp)",
                          body: "This is email body.")

        let request = Request(application: app, on: eventLoop)
        try request.smtp.send(email) { message in
            print(message)
        }.flatMapThrowing { result in
            XCTAssertTrue(try result.get())
        }.wait()
    }
}
