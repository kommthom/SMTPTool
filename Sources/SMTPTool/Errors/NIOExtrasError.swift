//
//  NIOExtrasError.swift
//
//  https://mczachurski.dev
//  Copyright © 2021 Marcin Czachurski and the repository contributors.
//  Licensed under the MIT License.
//
//  Created by Thomas Benninghaus on 13.12.23.
//

import NIO

internal protocol NIOExtrasError: Equatable, Error { }

/// Errors that are raised in NIOExtras.
internal enum NIOExtrasErrors {

    /// Error indicating that after an operation some unused bytes are left.
    public struct LeftOverBytesError: NIOExtrasError {
        public let leftOverBytes: ByteBuffer
    }
}
