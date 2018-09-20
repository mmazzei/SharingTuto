//
//  Credentials.swift
//  SharingTuto
//
//  Created by Matías Mazzei on 05/09/2018.
//  Copyright © 2018 mmazzei. All rights reserved.
//

import Foundation

public struct Credentials: Codable {
    let accessToken: String
    let expiresIn: Int
    let tokenType: String
    let refreshToken: String
    public let accountUsername: String
    let accountId: Int

    public static func decode(from dict: [String:String]) -> Credentials? {
        guard let accessToken = Credentials.EncodingKeys.accessToken.extract(from: dict),
            let expiresIn = Int(Credentials.EncodingKeys.expiresIn.extract(from: dict) ?? ""),
            let tokenType = Credentials.EncodingKeys.tokenType.extract(from: dict),
            let refreshToken = Credentials.EncodingKeys.refreshToken.extract(from: dict),
            let accountUsername = Credentials.EncodingKeys.accountUsername.extract(from: dict),
            let accountId = Int(Credentials.EncodingKeys.accountId.extract(from: dict) ?? "") else {
                return nil
        }

        return Credentials(
            accessToken: accessToken,
            expiresIn: expiresIn,
            tokenType: tokenType,
            refreshToken: refreshToken,
            accountUsername: accountUsername,
            accountId: accountId)
    }

    private enum EncodingKeys: String {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
        case refreshToken = "refresh_token"
        case accountUsername = "account_username"
        case accountId = "account_id"

        func extract(from dict: [String:String]) -> String? {
            return dict[self.rawValue]
        }
    }
}
