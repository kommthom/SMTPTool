//
//  SMTPToolClient.swift
//
//  https://mczachurski.dev
//  Copyright © 2021 Marcin Czachurski and the repository contributors.
//  Licensed under the MIT License.
//
//  Created by Thomas Benninghaus on 13.12.23.
//

import NIO
//import NIOSSL
import Vapor

/// This is simple implementation of SMTP client service.
/// The implementation was based on Apple SwiftNIO.
///
/// # Usage
///
/// **Set the SMTP server configuration (main.swift).**
///
///```swift
/// import Smtp
///
/// var env = try Environment.detect()
/// try LoggingSystem.bootstrap(from: &env)
///
/// let app = Application(env)
/// defer { app.shutdown() }
///
/// app.smtp.configuration.host = "smtp.server"
/// app.smtp.configuration.username = "johndoe"
/// app.smtp.configuration.password = "passw0rd"
/// app.smtp.configuration.secure = .ssl
///
/// try configure(app)
/// try app.run()
///```
///
/// **Using SMTP client**
///
///```swift
/// let email = Email(from: EmailAddress(address: "john.doe@testxx.com", name: "John Doe"),
///                   to: [EmailAddress("ben.doe@testxx.com")],
///                   subject: "The subject (text)",
///                   body: "This is email body.")
///
/// request.send(email).map { result in
///     switch result {
///     case .success:
///         AppLogger.backend.log("Email has been sent")
///     case .failure(let error):
///         AppLogger.backend.log("Email has not been sent: \(error)")
///     }
/// }
///```
///
/// Channel pipeline:
///
/// ```
/// +-------------------------------------------------------------------+
/// |                                                                   |
/// |       [ Socket.read ]                    [ Socket.write ]         |
/// |              |                                  |                 |
/// +--------------+----------------------------------+-----------------+
///                |                                 /|\
///               \|/                                 |
///          +-----+----------------------------------+-----+
///          |    OpenSSLClientHandler (enabled/disabled)   |
///          +-----+----------------------------------+-----+
///                |                                 /|\
///               \|/                                 |
///          +-----+----------------------------------+-----+
///          |             DuplexMessagesHandler            |
///          +-----+----------------------------------+-----+
///                |                                 /|\
///               \|/                                 |
///          +-----+--------------------------+       |
///          |  InboundLineBasedFrameDecoder  |       |
///          +-----+--------------------------+       |
///                |                                  |
///               \|/                                 |
///          +-----+--------------------------+       |
///          |   InboundSmtpResponseDecoder   |       |
///          +-----+--------------------------+       |
///                |                                  |
///                |                                  |
///                |       +--------------------------+-----+
///                |       |  OutboundSmtpRequestEncoder    |
///                |       +--------------------------+-----+
///                |                                 /|\
///               \|/                                 |
///          +-----+----------------------------------+-----+
///          |               StartTlsHandler                |
///          +-----+----------------------------------+-----+
///                |                                 /|\
///                |                                  |
///               \|/                                 | [write]
///          +-----+--------------------------+       |
///          |   InboundSendEmailHandler      +-------+
///          +--------------------------------+
///```
/// `OpenSSLClientHandler` is enabled only when `.ssl` secure is defined. For `.none` that
/// handler is not added to the pipeline.
///
/// `StartTlsHandler` is responsible for establishing SSL encryption after `STARTTLS`
/// command (this handler adds dynamically `OpenSSLClientHandler` to the pipeline if
/// server supports that encryption.
/*extension Application.Smtp {
    /// Sending an email.
    ///
    /// - parameters:
    ///     - email: Email which will be send.
    ///     - eventLoop: Event lopp which will be used to send email (if nil then event loop from application will be created).
    ///     - logHandler: Callback which can be used for logging/printing of sending status messages.
    /// - returns: An `EventLoopFuture<Result<Bool, Error>>` with information about sent email.
    public func send(_ email: Email, eventLoop: EventLoop? = nil, logHandler: ((String) -> Void)? = nil) -> EventLoopFuture<Result<Bool, Error>> {
        
        let smtpEventLoop = eventLoop ?? self.application.eventLoopGroup.next()
        let emailSentPromise: EventLoopPromise<Void> = smtpEventLoop.makePromise()
        
        let configuration = self.application.smtp.configuration
        
        // Client configuration
        let bootstrap = ClientBootstrap(group: self.application.eventLoopGroup.next())
            .connectTimeout(configuration.connectTimeout)
            .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .channelInitializer { channel in

                let secureChannelFuture = configuration.secure.configureChannel(on: channel, hostname: configuration.hostname)
                return secureChannelFuture.flatMap {

                    let defaultHandlers: [ChannelHandler] = [
                        DuplexMessagesHandler(handler: logHandler),
                        ByteToMessageHandler(InboundLineBasedFrameDecoder()),
                        InboundSmtpResponseDecoder(),
                        MessageToByteHandler(OutboundSmtpRequestEncoder()),
                        StartTlsHandler(configuration: configuration, allDonePromise: emailSentPromise),
                        InboundSendEmailHandler(configuration: configuration,
                                                email: email,
                                                allDonePromise: emailSentPromise)
                    ]

                    return channel.pipeline.addHandlers(defaultHandlers, position: .last)
                }
            }

        // Connect and send email.
        let connection = bootstrap.connect(host: configuration.hostname, port: configuration.port)
        
        connection.cascadeFailure(to: emailSentPromise)
        
        return emailSentPromise.futureResult.map { () -> Result<Bool, Error> in
            connection.whenSuccess { $0.close(mode: CloseMode.all, promise: EventLoopPromise<Void>?(nil)) }
            return Result.success(true)
        }.flatMapError { error -> EventLoopFuture<Result<Bool, Error>> in
            return smtpEventLoop.future(Result.failure(error))
        }
    }
    
    public func send(_ email: Email, eventLoop: EventLoop? = nil, logHandler: ((String) -> Void)? = nil) async throws {
        let result = try await self.send(email, eventLoop: eventLoop, logHandler: logHandler).get()

        switch result {
        case .success(_):
            break
        case .failure(let error):
            throw error
        }
    }
}*/

public struct SMTPToolClient: SMTPProviderProtocol, Sendable {
    let configuration: SmtpConfiguration
    let eventLoop: EventLoop
    let client: Client
    let app: Application
    
    // MARK: Initialization
    public init(app: Application, configuration: SmtpConfiguration, eventLoop: EventLoop, client: Client) {
        self.app = app
        self.configuration = configuration
        self.eventLoop = eventLoop
        self.client = client
    }

    /// Sending an email.
    ///
    /// - parameters:
    ///     - email: Email which will be send.
    ///     - eventLoop: Event lopp which will be used to send email (if nil then event loop from application will be created).
    ///     - logHandler: Callback which can be used for logging/printing of sending status messages.
    /// - returns: An `EventLoopFuture<Result<Bool, Error>>` with information about sent email.
    public func send(
		_ email: Email,
		logHandler: (@Sendable (String) -> Void)? = nil
	) -> EventLoopFuture<Result<Bool, Error>> {
        let emailSentPromise: EventLoopPromise<Void> = eventLoop.makePromise()
        let bootstrap = ClientBootstrap(group: app.eventLoopGroup.next())
            .connectTimeout(configuration.connectTimeout)
            .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .channelInitializer { channel in
                let secureChannelFuture = configuration.secure.configureChannel(on: channel, hostname: configuration.hostname)
                return secureChannelFuture.flatMap {
                    let defaultHandlers: [ChannelHandler] = [
                        DuplexMessagesHandler(handler: logHandler),
                        ByteToMessageHandler(InboundLineBasedFrameDecoder()),
                        InboundSmtpResponseDecoder(),
                        MessageToByteHandler(OutboundSmtpRequestEncoder()),
                        StartTlsHandler(configuration: configuration, allDonePromise: emailSentPromise),
                        InboundSendEmailHandler(configuration: configuration,
                                                email: email,
                                                allDonePromise: emailSentPromise)
                    ]
                    return channel.pipeline.addHandlers(defaultHandlers, position: .last)
                }
            }

        // Connect and send email.
        app.logger.info("email connect \(configuration.hostname):\(configuration.port)")
        let connection = bootstrap.connect(host: configuration.hostname, port: configuration.port)
        connection.cascadeFailure(to: emailSentPromise)
        return emailSentPromise
            .futureResult
            .map { () -> Result<Bool, Error> in
                connection.whenSuccess { $0.close(mode: CloseMode.all, promise: EventLoopPromise<Void>?(nil)) }
                app.logger.info("Send email success")
                return Result.success(true)
            }
            .flatMapError { error -> EventLoopFuture<Result<Bool, Error>> in
                app.logger.info("Send email error \(error.localizedDescription)")
                return eventLoop.future(Result.failure(error))
            }
    }
    
	public func send(
		_ email: Email,
		logHandler: (@Sendable (String) -> Void)? = nil
	) async throws {
        let result = try await self.send(email, logHandler: logHandler).get()
        switch result {
        case .success(_):
            break
        case .failure(let error):
            throw error
        }
    }
    
    public func delegating(
		to eventLoop: EventLoop
	) -> SMTPProviderProtocol {
        SMTPToolClient(app: app, configuration: configuration, eventLoop: eventLoop, client: client.delegating(to: eventLoop))
      }
}
