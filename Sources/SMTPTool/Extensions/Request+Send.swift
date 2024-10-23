//
//  Request+Send.swift
//
//  https://mczachurski.dev
//  Copyright © 2021 Marcin Czachurski and the repository contributors.
//  Licensed under the MIT License.
//
//  Created by Thomas Benninghaus on 13.12.23.
//

import Vapor

public extension Request {
    var smtp: Smtp {
        .init(request: self)
    }

	struct Smtp: Sendable {
        let request: Request
        
        public func send(
			_ email: Email,
			logHandler: (@Sendable (String) -> Void)? = nil
		) -> EventLoopFuture<Result<Bool, Error>> {
            return self.request.application.smtp(
				eventLoop: self.request.eventLoop
			).send(
				email,
				logHandler: logHandler
			)
        }
        
        public func send(
			_ email: Email,
			logHandler: (@Sendable (String) -> Void)? = nil
		) async throws {
            request.logger.info("Send email to \(String(describing: email.to)) with subject \(email.subject)")
            return try await self.request.application.smtp(eventLoop: self.request.eventLoop).send(email, logHandler: logHandler)
        }
    }
}
