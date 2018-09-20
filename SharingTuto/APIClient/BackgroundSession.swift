//
//  BackgroundSession.swift
//  SharingTuto
//
//  Created by Matías Mazzei on 12/09/2018.
//  Copyright © 2018 mmazzei. All rights reserved.
//

import Foundation

class BackgroundSession: NSObject {
    private struct CurrentUpload {
        var responseData: Data?
        var callback: ((Result<Data?>) -> Void)?
        var task: URLSessionUploadTask
        // Because upload tasks from data are not supported in background sessions, we are saving the data into a temporary file.
        var temporaryFile: URL
    }

    static let shared = BackgroundSession()
    var isUploadingNow: Bool {
        return Environment.uploadTasksRunning
    }

    private var session: URLSession?
    private var backgroundCompletionHandler: (() -> Void)?
    private var currentUpload: CurrentUpload? {
        willSet {
            if newValue == nil, currentUpload != nil {
                _ = try? FileManager.default.removeItem(at: currentUpload!.temporaryFile)
            }
        }
    }

    private override init() {
        super.init()
    }

    func uploadTask(with request: URLRequest, from data: Data, callback: @escaping (Result<Data?>) -> Void) {
        guard session == nil, !Environment.uploadTasksRunning else {
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

        session = Environment.backgroundSession(withDelegate: self)

        let task = session?.uploadTask(with: request, fromFile: temporaryFileUrl)
        currentUpload = CurrentUpload(responseData: nil, callback: callback, task: task!, temporaryFile: temporaryFileUrl)
        task?.resume()

        Environment.uploadTasksRunning = true
    }

    func cancelUpload() {
        print("🚀 BackgroundSession - cancelling a task")
        currentUpload = nil
        session?.invalidateAndCancel()

        // This could happen if app crashed
        if session == nil {
            Environment.uploadTasksRunning = false
            NotificationCenter.default.post(Notification(name: Constants.uploadFinishedNotification))
        }
    }

    /// This is only to be called from the AppDelegate `handleEventsForBackgroundURLSession` method.
    func handleEvents(completionHandler: @escaping () -> Void) {
        print("🚀 BackgroundSession - handleEvents")
        backgroundCompletionHandler = completionHandler
        // In case the app has been terminated and opened to finish processing the BG events.
        if session == nil {
            session = Environment.backgroundSession(withDelegate: self)
        }
    }
}

extension BackgroundSession: URLSessionDelegate, URLSessionDataDelegate {
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
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
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        print("🚀 BackgroundSession - urlSession:didBecomeInvalidWithError \(String(describing: error))")

        if error != nil {
            currentUpload?.callback?(.error(error!))
        }
        Environment.uploadTasksRunning = false
        self.session = nil
        currentUpload = nil

        NotificationCenter.default.post(Notification(name: Constants.uploadFinishedNotification))
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        print("🚀 BackgroundSession - urlSession:task:didCompleteWithError \(String(describing: error))")
        if error == nil {
            currentUpload?.callback?(.success(currentUpload?.responseData))
        } else {
            currentUpload?.callback?(.error(error!))
        }

        currentUpload = nil
        session.finishTasksAndInvalidate()
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        print("🚀 BackgroundSession - urlSession:dataTask:didReceive \(data.count) bytes")
        if currentUpload?.responseData == nil {
            currentUpload?.responseData = data
        } else {
            currentUpload?.responseData?.append(data)
        }
    }
}
