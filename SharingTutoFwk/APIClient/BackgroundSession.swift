//
//  BackgroundSession.swift
//  SharingTuto
//
//  Created by Matías Mazzei on 12/09/2018.
//  Copyright © 2018 mmazzei. All rights reserved.
//

import Foundation

private struct CurrentUpload: Codable {
    var responseData: Data?
    let callback: ((Result<Data?>) -> Void)?
    let task: URLSessionUploadTask?
    // Because upload tasks from data are not supported in background sessions, we are saving the data into a temporary file.
    let temporaryFile: URL

    enum CodingKeys: String, CodingKey {
        case responseData
        case temporaryFile
        case task
    }
}

// In a extension, to keep the struct default initializer.
extension CurrentUpload {
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        responseData = try values.decode((Data?).self, forKey: .responseData)
        temporaryFile = try values.decode(URL.self, forKey: .temporaryFile)
        callback = nil
        task = nil
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(responseData, forKey: .responseData)
        try container.encode(temporaryFile, forKey: .temporaryFile)
    }
}


public class BackgroundSession: NSObject {
    public static let shared = BackgroundSession()
    public var isUploadingNow: Bool {
        return currentUpload != nil
    }

    private var session: URLSession?
    private var backgroundCompletionHandler: (() -> Void)?

    private static var currentUploadKey = "BackgroundSession.currentUpload"
    private var currentUpload: CurrentUpload? {
        get {
            guard let currentUploadData = Environment.sharedDefaults.data(forKey: BackgroundSession.currentUploadKey),
                let currentUpload = try? PropertyListDecoder().decode(CurrentUpload.self, from: currentUploadData) else {
                    return nil
            }
            return currentUpload
        }
        set {
            if newValue == nil, currentUpload != nil {
                _ = try? FileManager.default.removeItem(at: currentUpload!.temporaryFile)
            }

            let currentUploadData = try? PropertyListEncoder().encode(newValue)
            Environment.sharedDefaults.set(currentUploadData, forKey: BackgroundSession.currentUploadKey)
        }
    }

    private override init() {
        super.init()
    }

    // It looks like the singleton object is kept in memory between succesive calls of the share extension
    // if the host app is not killed. So we needed to add this method to be called each time the extension
    // starts to clean up and forgot the old session.
    public func start() {
        session?.finishTasksAndInvalidate()
        session = nil
        initSession()
    }

    public func uploadTask(with request: URLRequest, from data: Data, callback: @escaping (Result<Data?>) -> Void) {
        guard !isUploadingNow else {
            print("🚀 BackgroundSession - Another upload is being processed right now, please retry again later.")
            return
        }

        print("🚀 BackgroundSession - starting uploadTask")

        let temporaryFileName = UUID().uuidString
        let temporaryFileUrl = FileManager.default.temporaryDirectory.appendingPathComponent(temporaryFileName)
        do {
            try data.write(to: temporaryFileUrl)
        } catch {
            print("🚀 BackgroundSession - Temporary file couldn't be written.")
            return
        }

        initSession()
        let task = session?.uploadTask(with: request, fromFile: temporaryFileUrl)
        currentUpload = CurrentUpload(responseData: nil, callback: callback, task: task, temporaryFile: temporaryFileUrl)
        task?.resume()
    }

    public func cancelUpload() {
        print("🚀 BackgroundSession - cancelling a task")
        currentUpload = nil
        session?.invalidateAndCancel()

        // This could happen if app crashed
        if session == nil {
            NotificationCenter.default.post(Notification(name: Constants.uploadFinishedNotification))
        }
    }

    /// This is only to be called from the AppDelegate `handleEventsForBackgroundURLSession` method.
    public func handleEvents(completionHandler: @escaping () -> Void) {
        print("🚀 BackgroundSession - handleEvents")
        backgroundCompletionHandler = completionHandler
        initSession()
    }

    private func initSession() {
        if session == nil {
            session = Environment.backgroundSession(withDelegate: self)
        }
    }
}

extension BackgroundSession: URLSessionDelegate, URLSessionDataDelegate {
    public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        print("🚀 BackgroundSession - urlSessionDidFinishEvents")
        session.finishTasksAndInvalidate()

        // The completion handler was received from UIKit, so it needs to be executed on main thread
        // https://developer.apple.com/documentation/foundation/url_loading_system/downloading_files_in_the_background -> "Listing 4"
        DispatchQueue.main.async {
            self.backgroundCompletionHandler?()
            self.backgroundCompletionHandler = nil
        }

    }

    // It doesn't matter how the upload finishes or where it started, this method is called at the end (we have at most one upload running at any given time).
    // So it is here where we launches notifications or update the environment flags from.
    public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        print("🚀 BackgroundSession - urlSession:didBecomeInvalidWithError \(String(describing: error))")

        if error != nil {
            currentUpload?.callback?(.error(error!))
        }
        if session == self.session {
            self.session = nil
        }
        currentUpload = nil

        NotificationCenter.default.post(Notification(name: Constants.uploadFinishedNotification))
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        print("🚀 BackgroundSession - urlSession:task:didCompleteWithError \(String(describing: error))")
        if error == nil {
            currentUpload?.callback?(.success(currentUpload?.responseData))
        } else {
            currentUpload?.callback?(.error(error!))
        }

        currentUpload = nil
        session.finishTasksAndInvalidate()
    }

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        print("🚀 BackgroundSession - urlSession:dataTask:didReceive \(data.count) bytes")
        if currentUpload?.responseData == nil {
            currentUpload?.responseData = data
        } else {
            currentUpload?.responseData?.append(data)
        }
    }
}
