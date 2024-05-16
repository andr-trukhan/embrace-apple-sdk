//
//  Copyright © 2023 Embrace Mobile, Inc. All rights reserved.
//

import Foundation
import EmbraceCommon
import GRDB

public typealias Storage = EmbraceStorageMetadataFetcher & LogRepository

/// Class in charge of storing all the data captured by the Embrace SDK.
/// It provides an abstraction layer over a GRDB SQLite database.
public class EmbraceStorage: Storage {
    public private(set) var options: Options
    public private(set) var dbQueue: DatabaseQueue

    /// Returns an EmbraceStorage instance initialized on the given path.
    /// - Parameters:
    ///   - baseUrl: URL containing the path when the database will be stored.
    public init(options: Options) throws {
        self.options = options
        dbQueue = try Self.createDBQueue(options: options)
    }

    /// Performs any DB migrations
    /// - Parameters:
    ///   - resetIfError: If true and the migrations fail the DB will be reset entirely.
    public func performMigration(
        resetIfError: Bool = true,
        service: MigrationServiceProtocol = MigrationService()
    ) throws {
        do {
            try service.perform(dbQueue, migrations: .current)
        } catch let error {
            if resetIfError {
                ConsoleLog.error("Error performing migrations, resetting EmbraceStorage: \(error)")
                try reset(migrationService: service)
            } else {
                ConsoleLog.error("Error performing migrations. Reset not enabled: \(error)")
                throw error // re-throw error if auto-recover is not enabled
            }
        }
    }

    /// Deletes the database and recreates it from scratch
    func reset(migrationService: MigrationServiceProtocol = MigrationService()) throws {
        if let fileURL = options.fileURL {
            try FileManager.default.removeItem(at: fileURL)
        }

        dbQueue = try Self.createDBQueue(options: options)
        try performMigration(resetIfError: false, service: migrationService) // Do not perpetuate loop
    }
}

// MARK: - Sync operations
extension EmbraceStorage {
    /// Updates a record in the storage synchronously.
    /// - Parameter record: `PersistableRecord` to update
    public func update(record: PersistableRecord) throws {
        try dbQueue.write { db in
            try record.update(db)
        }
    }

    /// Deletes a record from the storage synchronously.
    /// - Parameter record: `PersistableRecord` to delete
    /// - Returns: Boolean indicating if the record was successfuly deleted
    @discardableResult public func delete(record: PersistableRecord) throws -> Bool {
        try dbQueue.write { db in
            return try record.delete(db)
        }
    }

    /// Fetches all the records of the given type in the storage synchronously.
    /// - Returns: Array containing all the records of the given type
    public func fetchAll<T: FetchableRecord & TableRecord>() throws -> [T] {
        try dbQueue.read { db in
            return try T.fetchAll(db)
        }
    }

    /// Executes the given SQL query synchronously.
    /// - Parameters:
    ///   - sql: SQL query to execute
    ///   - arguments: Arguments for the query, if any
    public func executeQuery(_ sql: String, arguments: StatementArguments?) throws {
        try dbQueue.write { db in
            try db.execute(sql: sql, arguments: arguments ?? StatementArguments())
        }
    }
}

// MARK: - Async operations
extension EmbraceStorage {
    /// Updates a record in the storage asynchronously.
    /// - Parameters:
    ///   - record: `PersistableRecord` to update
    ///   - completion: Completion block called with an `Error` on failure
    public func updateAsync(record: PersistableRecord, completion: ((Result<(), Error>) -> Void)?) {
        dbWriteAsync(block: { db in
            try record.update(db)
        }, completion: completion)
    }

    /// Deletes a record from the storage asynchronously.
    /// - Parameters:
    ///   - record: `PersistableRecord` to delete
    ///   - completion: Completion block called with an `Error` on failure
    /// - Returns: Boolean indicating if the record was successfuly deleted
    public func deleteAsync(record: PersistableRecord, completion: ((Result<Void, Error>) -> Void)?) {
        dbWriteAsync(block: { db in
            try record.delete(db)
        }, completion: completion)
    }

    /// Fetches all the records of the given type in the storage asynchronously.
    /// - Parameter completion: Completion block called with an array `[T]` with the fetch result on success, or an `Error` on failure
    /// - Returns: Array containing all the records of the given type
    public func fetchAllAsync<T: FetchableRecord & TableRecord>(completion: @escaping (Result<[T], Error>) -> Void) {
        dbFetchAsync(block: { db in
            return try T.fetchAll(db)
        }, completion: completion)
    }

    /// Executes the given SQL query asynchronously.
    /// - Parameters:
    ///   - sql: SQL query to execute
    ///   - arguments: Arguments for the query, if any
    ///   - completion: Completion block called with an `Error` on failure
    public func executeQueryAsync(
        _ sql: String,
        arguments: StatementArguments?,
        completion: ((Result<Void, Error>) -> Void)?
    ) {
        dbWriteAsync(block: { db in
            try db.execute(sql: sql, arguments: arguments ?? StatementArguments())
        }, completion: completion)
    }
}

extension EmbraceStorage {

    private static func createDBQueue(options: EmbraceStorage.Options) throws -> DatabaseQueue {
        if case let .inMemory(name) = options.storageMechanism {
            return try DatabaseQueue(named: name)
        } else if case let .onDisk(baseURL, _) = options.storageMechanism, let fileURL = options.fileURL {
            // create base directory if necessary
            try FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true)
            return try EmbraceStorage.getDBQueueIfPossible(at: fileURL)
        } else {
            fatalError("Unsupported storage mechansim added")
        }
    }

    /// Will attempt to create or open the DB File. If first attempt fails due to GRDB error, it'll assume the existing DB is corruped and try again after deleting the existing DB file.
    private static func getDBQueueIfPossible(at fileURL: URL) throws -> DatabaseQueue {
        do {
            return try DatabaseQueue(path: fileURL.path)
        } catch {
            if let dbError = error as? DatabaseError {
                ConsoleLog.error(
                    """
                    GRDB Failed to initialize EmbraceStorage.
                    Will attempt to remove existing file and create a new DB.
                    Message: \(dbError.message ?? "[empty message]"),
                    Result Code: \(dbError.resultCode),
                    SQLite Extended Code: \(dbError.extendedResultCode)
                    """
                )
            } else {
                ConsoleLog.error(
                    """
                    Unknown error while trying to initialize EmbraceStorage: \(error)
                    Will attempt to recover by deleting existing DB.
                    """
                )
            }
        }

        try EmbraceStorage.deleteDBFile(at: fileURL)

        return try DatabaseQueue(path: fileURL.path)
    }

    /// Will attempt to delete the provided file.
    private static func deleteDBFile(at fileURL: URL) throws {
        do {
            let fileURL = URL(fileURLWithPath: fileURL.path)
            try FileManager.default.removeItem(at: fileURL)
        } catch let error {
            ConsoleLog.error(
                """
                EmbraceStorage failed to remove DB file.
                Error: \(error.localizedDescription)
                Filepath: \(fileURL)
                """
            )
        }
    }
}
