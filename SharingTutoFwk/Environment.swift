//
//  Environment.swift
//  SharingTuto
//
//  Created by Matías Mazzei on 05/09/2018.
//  Copyright © 2018 mmazzei. All rights reserved.
//

import Foundation

public struct Constants {
    public static let apiBaseUrl = "https://api.imgur.com/3"
    public static let appGroupIdentifier = "group.ar.com.mmazzei.SharingTuto"

    public static let uploadFinishedNotification = Notification.Name("SharingTuto.uploadFinishedNotification")
}

public struct Environment {
    private init() {}
    private static let credentialsKey = "SharingTuto.credentials"
    private static let backgroundUrlSessionIdentifier = "SharingTuto.backgroundUrlSession"
    private static let uploadTasksRunningKey = "SharingTuto.uploadTasksRunning"

    private static let sharedDefaults: UserDefaults = UserDefaults(suiteName: Constants.appGroupIdentifier)!

    public static func backgroundSession(withDelegate delegate: URLSessionDelegate) -> URLSession {
        let sessionConfig = URLSessionConfiguration.background(withIdentifier: backgroundUrlSessionIdentifier)
        return URLSession(configuration: sessionConfig, delegate: delegate, delegateQueue: nil)
    }

    public static var credentials: Credentials? {
        get {
            guard let credentialsData = sharedDefaults.data(forKey: credentialsKey),
                let user = try? PropertyListDecoder().decode(Credentials.self, from: credentialsData) else {
                    return nil
            }
            return user
        }
        set {
            let credentialsData = try? PropertyListEncoder().encode(newValue)
            sharedDefaults.set(credentialsData, forKey: credentialsKey)
        }
    }

    public static var uploadTasksRunning: Bool {
        get { return sharedDefaults.bool(forKey: uploadTasksRunningKey) }
        set { sharedDefaults.set(newValue, forKey: uploadTasksRunningKey) }
    }
}
