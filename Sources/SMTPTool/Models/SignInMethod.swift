//
//  SignInMethod.swift
//  
//
//  Created by Thomas Benninghaus on 12.12.23.
//

public enum SignInMethod: Sendable {
    case anonymous
    case credentials(username: String, password: String)
}
