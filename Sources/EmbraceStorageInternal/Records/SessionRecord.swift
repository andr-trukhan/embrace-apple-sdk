//
//  Copyright © 2024 Embrace Mobile, Inc. All rights reserved.
//

import Foundation
import EmbraceCommonInternal
import CoreData

/// Represents a session in the storage
public class SessionRecord: NSManagedObject {
    @NSManaged public var idRaw: String // SessionIdentifier
    @NSManaged public var processIdRaw: String // ProcessIdentifier
    @NSManaged public var state: String
    @NSManaged public var traceId: String
    @NSManaged public var spanId: String
    @NSManaged public var startTime: Date
    @NSManaged public var endTime: Date?
    @NSManaged public var lastHeartbeatTime: Date
    @NSManaged public var crashReportId: String?

    /// Used to mark if the session is the first to occur during this process
    @NSManaged public var coldStart: Bool

    /// Used to mark the session ended in an expected manner
    @NSManaged public var cleanExit: Bool

    /// Used to mark the session that is active when the application was explicitly terminated by the user and/or system
    @NSManaged public var appTerminated: Bool

    public var id: SessionIdentifier? {
        return SessionIdentifier(string: idRaw)
    }

    public var processId: ProcessIdentifier? {
        return ProcessIdentifier(hex: processIdRaw)
    }

    public static func create(
        context: NSManagedObjectContext,
        id: SessionIdentifier,
        processId: ProcessIdentifier,
        state: SessionState,
        traceId: String,
        spanId: String,
        startTime: Date,
        endTime: Date? = nil,
        lastHeartbeatTime: Date? = nil,
        crashReportId: String? = nil,
        coldStart: Bool = false,
        cleanExit: Bool = false,
        appTerminated: Bool = false
    ) -> SessionRecord {
        let record = SessionRecord(context: context)
        record.idRaw = id.toString
        record.processIdRaw = processId.hex
        record.state = state.rawValue
        record.traceId = traceId
        record.spanId = spanId
        record.startTime = startTime
        record.endTime = endTime
        record.lastHeartbeatTime = lastHeartbeatTime ?? startTime
        record.crashReportId = crashReportId
        record.coldStart = coldStart
        record.cleanExit = cleanExit
        record.appTerminated = appTerminated

        return record
    }

    static func createFetchRequest() -> NSFetchRequest<SessionRecord> {
        return NSFetchRequest<SessionRecord>(entityName: entityName)
    }
}

extension SessionRecord: EmbraceStorageRecord {
    public static var entityName = "SessionRecord"

    static public var entityDescription: NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = entityName
        entity.managedObjectClassName = NSStringFromClass(SessionRecord.self)

        let idAttribute = NSAttributeDescription()
        idAttribute.name = "idRaw"
        idAttribute.attributeType = .stringAttributeType

        let processIdAttribute = NSAttributeDescription()
        processIdAttribute.name = "processIdRaw"
        processIdAttribute.attributeType = .stringAttributeType

        let stateAttribute = NSAttributeDescription()
        stateAttribute.name = "state"
        stateAttribute.attributeType = .stringAttributeType

        let traceIdAttribute = NSAttributeDescription()
        traceIdAttribute.name = "traceId"
        traceIdAttribute.attributeType = .stringAttributeType

        let spanIdAttribute = NSAttributeDescription()
        spanIdAttribute.name = "spanId"
        spanIdAttribute.attributeType = .stringAttributeType

        let startTimeAttribute = NSAttributeDescription()
        startTimeAttribute.name = "startTime"
        startTimeAttribute.attributeType = .dateAttributeType

        let endTimeAttribute = NSAttributeDescription()
        endTimeAttribute.name = "endTime"
        endTimeAttribute.attributeType = .dateAttributeType

        let lastHeartbeatTimeAttribute = NSAttributeDescription()
        lastHeartbeatTimeAttribute.name = "lastHeartbeatTime"
        lastHeartbeatTimeAttribute.attributeType = .dateAttributeType

        let crashReportIdAttribute = NSAttributeDescription()
        crashReportIdAttribute.name = "crashReportId"
        crashReportIdAttribute.attributeType = .stringAttributeType

        let coldStartAttribute = NSAttributeDescription()
        coldStartAttribute.name = "coldStart"
        coldStartAttribute.attributeType = .booleanAttributeType

        let cleanExitAttribute = NSAttributeDescription()
        cleanExitAttribute.name = "cleanExit"
        cleanExitAttribute.attributeType = .booleanAttributeType

        let appTerminatedAttribute = NSAttributeDescription()
        appTerminatedAttribute.name = "appTerminated"
        appTerminatedAttribute.attributeType = .booleanAttributeType

        entity.properties = [
            idAttribute,
            processIdAttribute,
            stateAttribute,
            traceIdAttribute,
            spanIdAttribute,
            startTimeAttribute,
            endTimeAttribute,
            lastHeartbeatTimeAttribute,
            crashReportIdAttribute,
            coldStartAttribute,
            cleanExitAttribute,
            appTerminatedAttribute
        ]

        return entity
    }
}
