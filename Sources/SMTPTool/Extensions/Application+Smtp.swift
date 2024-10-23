//
//  Application+Smtp.swift
//
//  https://mczachurski.dev
//  Copyright © 2021 Marcin Czachurski and the repository contributors.
//  Licensed under the MIT License.
//
//  Created by Thomas Benninghaus on 13.12.23.
//

import Vapor

extension Application {
    public struct Smtp {
        public typealias SMTPToolFactory = @Sendable (Application) -> SMTPProviderProtocol
        let application: Application
        
		private final class Storage: @unchecked Sendable {
			var configuration: SmtpConfiguration?
            var makeClient: SMTPToolFactory?
            init() {}
        }
        
        private struct ConfigurationKey: StorageKey {
            typealias Value = Storage
        }
        
        private var storage: Storage {
            get {
                if self.application.storage[ConfigurationKey.self] == nil {
                    self.application.storage[ConfigurationKey.self] = .init()
                    self.application.smtp.use(.prod)
                }
                return self.application.storage[ConfigurationKey.self]!
            }
            nonmutating set {
                self.application.storage[ConfigurationKey.self] = newValue
            }
        }
        
        public struct Provider {
            public static var prod: Self {
                .init {
                    $0.smtp.use { app in
                        guard let config = app.smtp.configuration else {
                            fatalError("SMTPTool not configured, use: application.smtp.configuration = .init()")
                        }
                        return SMTPToolClient(
                            app: app,
                            configuration: config,
                            eventLoop: app.eventLoopGroup.next(),
                            client: app.client
                        )
                    }
                }
            }
            
            public let run: ((Application) -> Void)
            
            public init(_ run: @escaping ((Application) -> Void)) {
                self.run = run
            }
        }
        
        public func use(_ make: @escaping SMTPToolFactory) {
            storage.makeClient = make
        }
        
        public func use(_ provider: Application.Smtp.Provider) {
            provider.run(application)
        }
        
        public var configuration: SmtpConfiguration? {
            get {
                storage.configuration
            }
            nonmutating set {
                storage.configuration = newValue
            }
        }
        
        public func client() -> SMTPProviderProtocol {
            guard let makeClient = storage.makeClient else {
                fatalError("SmtpTool not configured, use: app.smtp.use(.real)")
            }
            return makeClient(application)
        }
    }
    
    public var smtp: Smtp {
        .init(application: self)
    }

    public func smtp(eventLoop: EventLoop) -> SMTPProviderProtocol {
        self.smtp.client().delegating(to: eventLoop)
    }
}
