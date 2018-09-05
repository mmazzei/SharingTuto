//
//  Environment.swift
//  SharingTuto
//
//  Created by Matías Mazzei on 05/09/2018.
//  Copyright © 2018 mmazzei. All rights reserved.
//

import Foundation

struct Constants {
    static let apiBaseUrl = "https://api.imgur.com/3"
}

struct Environment {
    private init() {}
    private static let credentialsKey = "SharingTuto.credentials"

    static var credentials: Credentials? {
        get {
            guard let credentialsData = UserDefaults.standard.data(forKey: credentialsKey),
                let user = try? PropertyListDecoder().decode(Credentials.self, from: credentialsData) else {
                    return nil
            }
            return user
        }
        set {
            let credentialsData = try? PropertyListEncoder().encode(newValue)
            UserDefaults.standard.set(credentialsData, forKey: credentialsKey)
        }
    }
}
