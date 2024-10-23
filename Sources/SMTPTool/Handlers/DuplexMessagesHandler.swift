//
//  DuplexMessagesHandler.swift
//
//  https://mczachurski.dev
//  Copyright © 2021 Marcin Czachurski and the repository contributors.
//  Licensed under the MIT License.
//
//  Created by Thomas Benninghaus on 13.12.23.
//

import NIO

internal final class DuplexMessagesHandler: ChannelDuplexHandler {
    typealias InboundIn = ByteBuffer
    typealias InboundOut = ByteBuffer
    typealias OutboundIn = ByteBuffer
    typealias OutboundOut = ByteBuffer

    private let handler: ((String) -> Void)?

    init(handler: ((String) -> Void)? = nil) {
        self.handler = handler
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {

        if let handler = self.handler {
            let buffer = self.unwrapInboundIn(data)
            handler("==> \(String(decoding: buffer.readableBytesView, as: UTF8.self))")
        }

        context.fireChannelRead(data)
    }

    func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {

        if let handler = self.handler {
            let buffer = self.unwrapOutboundIn(data)
            handler("<== \(String(decoding: buffer.readableBytesView, as: UTF8.self))")
        }

        context.write(data, promise: promise)
    }
}
