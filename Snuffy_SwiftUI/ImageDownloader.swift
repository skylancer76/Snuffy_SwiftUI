import Foundation

class ImageDownloader: NSObject, URLSessionDownloadDelegate {
    static let shared = ImageDownloader()

    // MARK: - Properties

    private lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.background(withIdentifier: "com.myapp.imagedownloader")
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }()

    private var completionHandlers = [Int: (URL?) -> Void]()

    // MARK: - Download

    func downloadImage(from url: URL, completion: @escaping (URL?) -> Void) {
        let task = session.downloadTask(with: url)
        completionHandlers[task.taskIdentifier] = completion
        task.resume()
    }

    // MARK: - URLSessionDownloadDelegate

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let handler = completionHandlers[downloadTask.taskIdentifier] else { return }
        completionHandlers[downloadTask.taskIdentifier] = nil

        let fileManager = FileManager.default
        guard let originalURL = downloadTask.originalRequest?.url else {
            DispatchQueue.main.async { handler(nil) }
            return
        }
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let destinationURL = cachesDirectory.appendingPathComponent(originalURL.lastPathComponent)

        do {
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            try fileManager.moveItem(at: location, to: destinationURL)
            DispatchQueue.main.async { handler(destinationURL) }
        } catch {
            DispatchQueue.main.async { handler(nil) }
        }
    }
}
