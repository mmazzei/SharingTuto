//
//  Environment.swift
//  SharingTuto
//
//  Created by Matías Mazzei on 05/09/2018.
//  Copyright © 2018 mmazzei. All rights reserved.
//

import Foundation

public struct Constants {
    private static let imgurClientId = "e697e3cded0fc0c"

    public static let apiBaseUrl = "https://api.imgur.com/3"
    public static var logInUrl: URL {
        var urlComponents = URLComponents(string: "https://api.imgur.com")!
        urlComponents.path.append("/oauth2/authorize")
        urlComponents.queryItems = [
            URLQueryItem(name: "client_id", value: imgurClientId),
            URLQueryItem(name: "response_type", value: "token"),
            URLQueryItem(name: "state", value: "")
        ]
        return urlComponents.url!
    }

    public static let appGroupIdentifier = "group.ar.com.mmazzei.SharingTuto"

    public static let uploadFinishedNotification = Notification.Name("SharingTuto.uploadFinishedNotification")
}

public struct Environment {
    private init() {}
    private static let credentialsKey = "SharingTuto.credentials"
    private static let backgroundUrlSessionIdentifier = "SharingTuto.backgroundUrlSession"
    private static let sharedContainerIdentifier = Constants.appGroupIdentifier
    private static let uploadTasksRunningKey = "SharingTuto.uploadTasksRunning"

    public static let sharedDefaults: UserDefaults = UserDefaults(suiteName: Constants.appGroupIdentifier)!

    public static func backgroundSession(withDelegate delegate: URLSessionDelegate) -> URLSession {
        let sessionConfig = URLSessionConfiguration.background(withIdentifier: backgroundUrlSessionIdentifier)
        sessionConfig.sharedContainerIdentifier = sharedContainerIdentifier
        return URLSession(configuration: sessionConfig, delegate: delegate, delegateQueue: nil)
    }

    /// Shared directory for App and its extensions
    public static var sharedContainerUrl: URL {
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier:
            // It needs to be put in the "Library/Cache" dir as the extension has troubles writing in "/": https://forums.developer.apple.com/thread/45736
            sharedContainerIdentifier)!.appendingPathComponent("Library/Caches")
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
}
