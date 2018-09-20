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

    static let uploadFinishedNotification = Notification.Name("SharingTuto.uploadFinishedNotification")
}

struct Environment {
    private init() {}
    private static let credentialsKey = "SharingTuto.credentials"
    private static let backgroundUrlSessionIdentifier = "SharingTuto.backgroundUrlSession"
    private static let uploadTasksRunningKey = "SharingTuto.uploadTasksRunning"

    static func backgroundSession(withDelegate delegate: URLSessionDelegate) -> URLSession {
        let sessionConfig = URLSessionConfiguration.background(withIdentifier: backgroundUrlSessionIdentifier)
        return URLSession(configuration: sessionConfig, delegate: delegate, delegateQueue: nil)
    }

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

    static var uploadTasksRunning: Bool {
        get { return UserDefaults.standard.bool(forKey: uploadTasksRunningKey) }
        set { UserDefaults.standard.set(newValue, forKey: uploadTasksRunningKey) }
    }
}
