//
//  Copyright © 2023 Embrace Mobile, Inc. All rights reserved.
//

import Foundation

/// Enum containing possible error codes
public enum EmbraceUploadErrorCode: Int {
    case invalidMetadata = 1000
    case invalidData = 1001
    case operationCancelled = 1002
}

/// Class in charge of uploading all the data colected by the Embrace SDK.
public class EmbraceUpload {

    public private(set) var options: Options
    public private(set) var queue: DispatchQueue

    let cache: EmbraceUploadCache
    let urlSession: URLSession
    let operationQueue: OperationQueue
    var reachabilityMonitor: EmbraceReachabilityMonitor?

    /// Returns an EmbraceUpload instance initialized on the given path.
    /// - Parameters:
    ///   - options: EmbraceUploadOptions instance
    ///   - queue: DispatchQueue to be used for all upload operations
    public init(options: Options, queue: DispatchQueue) throws {

        self.options = options
        self.queue = queue

        cache = try EmbraceUploadCache(options: options.cache)

        urlSession = URLSession(configuration: options.urlSessionConfiguration)

        operationQueue = OperationQueue()
        operationQueue.underlyingQueue = queue

        // reachability monitor
        if options.redundancy.retryOnInternetConnected {
            reachabilityMonitor = EmbraceReachabilityMonitor(queue: DispatchQueue(label: "com.embrace.upload.reachability"))
            reachabilityMonitor?.onConnectionRegained = { [weak self] in
                self?.retryCachedData()
            }

            reachabilityMonitor?.start()
        }
    }

    /// Attempts to upload all the available cached data.
    public func retryCachedData() {
        queue.async { [weak self] in
            do {
                guard let cachedObjects = try self?.cache.fetchAllUploadData() else {
                    return
                }

                for uploadData in cachedObjects {
                    guard let type = EmbraceUploadType(rawValue: uploadData.type) else {
                        continue
                    }

                    self?.uploadData(
                        id: uploadData.id,
                        data: uploadData.data,
                        type: type,
                        attemptCount: uploadData.attemptCount,
                        completion: nil)
                }
            } catch {
                print("Error retrying cached upload data: \(error.localizedDescription)")
            }
        }
    }

    /// Uploads the given session data
    /// - Parameters:
    ///   - id: Identifier of the session
    ///   - data: Data of the session's payload
    ///   - completion: Completion block called with an `Error` on failure
    public func uploadSession(id: String, data: Data, completion: ((Result<(), Error>) -> Void)?) {
        queue.async { [weak self] in
            self?.uploadData(id: id, data: data, type: .session, completion: completion)
        }
    }

    /// Uploads the given blob data
    /// - Parameters:
    ///   - id: Identifier of the blob
    ///   - data: Data of the blob's payload
    ///   - completion: Completion block called with an `Error` on failure
    public func uploadBlob(id: String, data: Data, completion: ((Result<(), Error>) -> Void)?) {
        queue.async { [weak self] in
            self?.uploadData(id: id, data: data, type: .blob, completion: completion)
        }
    }

    // MARK: - Internal
    private func uploadData(id: String, data: Data, type: EmbraceUploadType, attemptCount: Int = 0, completion: ((Result<(), Error>) -> Void)?) {

        // validate identifier
        guard id.isEmpty == false else {
            completion?(.failure(internalError(code: .invalidMetadata)))
            return
        }

        // validate data
        guard data.isEmpty == false else {
            completion?(.failure(internalError(code: .invalidData)))
            return
        }

        // cache operation
        let cacheOperation = BlockOperation { [weak self] in
            do {
                _ = try self?.cache.saveUploadData(id: id, type: type, data: data)
            } catch {
                print("Error caching upload data: \(error.localizedDescription)")
            }
        }

        // upload operation
        let uploadOperation = EmbraceUploadOperation(
            urlSession: urlSession,
            metadataOptions: options.metadata,
            endpoint: endpointForType(type),
            identifier: id,
            data: data,
            retryCount: options.redundancy.automaticRetryCount,
            attemptCount: attemptCount) { [weak self] (cancelled, count, error) in

                self?.queue.async { [weak self] in
                    self?.handleOperationFinished(id: id, type: type, cancelled: cancelled, attemptCount: count, error: error, completion: completion)
                }
            }

        // queue operations
        uploadOperation.addDependency(cacheOperation)
        operationQueue.addOperation(cacheOperation)
        operationQueue.addOperation(uploadOperation)
    }

    private func handleOperationFinished(
        id: String,
        type: EmbraceUploadType,
        cancelled: Bool,
        attemptCount: Int,
        error: Error?,
        completion: ((Result<(), Error>) -> Void)?) {

        // error?
        if cancelled == true || error != nil {
            // update attempt count in cache
            operationQueue.addOperation { [weak self] in
                do {
                    _ = try self?.cache.updateAttemptCount(id: id, type: type, attemptCount: attemptCount)
                } catch {
                    print("Error updating cache: \(error.localizedDescription)")
                }
            }

            let e: Error = error ?? internalError(code: .operationCancelled)
            completion?(.failure(e))

            return
        }

        // success -> clear cache
        operationQueue.addOperation { [weak self] in
            do {
                _ = try self?.cache.deleteUploadData(id: id, type: type)
            } catch {
                print("Error deleting cache: \(error.localizedDescription)")
            }
        }

        completion?(.success(()))
    }

    private func endpointForType(_ type: EmbraceUploadType) -> URL {
        switch type {
        case .session: return options.endpoints.sessionsURL
        case .blob: return options.endpoints.blobsURL
        }
    }

    private func internalError(code: EmbraceUploadErrorCode) -> Error {
        return NSError(domain: "com.embrace", code: code.rawValue)
    }
}
