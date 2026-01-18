//
//  ImageDownloader.swift
//  Snuffy_SwiftUI
//
//  Created by Pawan Priyatham  on 18/01/26.
//

import Foundation
class ImageDownloader: NSObject, URLSessionDownloadDelegate {
    static let shared = ImageDownloader()
    
    // Create a background URLSession with a unique identifier.
    private lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.background(withIdentifier: "com.myapp.imagedownloader")
        // Adjust cache policy and timeout if needed.
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }()
    
    // A dictionary to store completion handlers associated with each download task.
    private var completionHandlers = [Int: (URL?) -> Void]()
    
    /// Downloads an image from the given URL. The completion returns the local file URL if successful.
    func downloadImage(from url: URL, completion: @escaping (URL?) -> Void) {
        let task = session.downloadTask(with: url)
        completionHandlers[task.taskIdentifier] = completion
        task.resume()
    }
    
    // MARK: - URLSessionDownloadDelegate
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // Retrieve the completion handler for this task.
        guard let handler = completionHandlers[downloadTask.taskIdentifier] else { return }
        completionHandlers[downloadTask.taskIdentifier] = nil
        
        // Get a destination URL in the caches directory.
        let fileManager = FileManager.default
        guard let originalURL = downloadTask.originalRequest?.url else {
            DispatchQueue.main.async { handler(nil) }
            return
        }
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let destinationURL = cachesDirectory.appendingPathComponent(originalURL.lastPathComponent)
        
        do {
            // If a file already exists at the destination, remove it.
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            try fileManager.moveItem(at: location, to: destinationURL)
            DispatchQueue.main.async { handler(destinationURL) }
        } catch {
            print("Error moving downloaded file: \(error)")
            DispatchQueue.main.async { handler(nil) }
        }
    }
    
 
}

