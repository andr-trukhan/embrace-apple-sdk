//
//  Copyright © 2025 Embrace Mobile, Inc. All rights reserved.
//

import Foundation

public enum MetadataRecordType: String, Codable {
    /// Resource that is attached to session and logs data
    case resource

    /// Embrace-generated resource that is deemed required and cannot be removed by the user of the SDK
    case requiredResource

    /// Custom property attached to session and logs data and that can be manipulated by the user of the SDK
    case customProperty

    /// Persona tag attached to session and logs data and that can be manipulated by the user of the SDK
    case personaTag
}

public enum MetadataRecordLifespan: String, Codable {
    /// Value tied to a specific session
    case session

    /// Value tied to multiple sessions within a single process
    case process

    /// Value tied to all sessions until explicitly removed
    case permanent
}

public protocol EmbraceMetadata {
    var key: String { get set }
    var value: String { get set }
    var typeRaw: String { get set }
    var lifespanRaw: String { get set }
    var lifespanId: String { get set }
    var collectedAt: Date { get set }
}

public extension EmbraceMetadata {
    var type: MetadataRecordType? {
        return MetadataRecordType(rawValue: typeRaw)
    }

    var lifespan: MetadataRecordLifespan? {
        return MetadataRecordLifespan(rawValue: lifespanRaw)
    }
}
