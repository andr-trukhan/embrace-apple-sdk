//
//  Copyright © 2024 Embrace Mobile, Inc. All rights reserved.
//

import Foundation
import EmbraceCommonInternal
import EmbraceStorageInternal
import CoreData

public class MetadataRecordTmp: NSManagedObject {
    @NSManaged var key: String
    @NSManaged var value: String
    @NSManaged var type: String
    @NSManaged var lifespan: String
    @NSManaged var lifespanId: String
    @NSManaged var collectedAt: Date

    class func create(
        context: NSManagedObjectContext,
        key: String,
        value: String,
        type: String,
        lifespan: String,
        lifespanId: String,
        collectedAt: Date = Date()
    ) -> MetadataRecordTmp {
        let record = MetadataRecordTmp(context: context)
        record.key = key
        record.value = value
        record.type = type
        record.lifespan = lifespan
        record.lifespanId = lifespanId
        record.collectedAt = collectedAt

        return record
    }

    class func create(context: NSManagedObjectContext, record: MetadataRecord) -> MetadataRecordTmp {
        return create(
            context: context,
            key: record.key,
            value: record.value.description,
            type: record.type.rawValue,
            lifespan: record.lifespan.rawValue,
            lifespanId: record.lifespanId,
            collectedAt: record.collectedAt
        )
    }
}

extension MetadataRecordTmp {
    static let entityName = "MetadataRecordTmp"

    static var entityDescription: NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = entityName
        entity.managedObjectClassName = NSStringFromClass(MetadataRecordTmp.self)

        let keyAttribute = NSAttributeDescription()
        keyAttribute.name = "key"
        keyAttribute.attributeType = .stringAttributeType

        let valueAttribute = NSAttributeDescription()
        valueAttribute.name = "value"
        valueAttribute.attributeType = .stringAttributeType

        let typeAttribute = NSAttributeDescription()
        typeAttribute.name = "type"
        typeAttribute.attributeType = .stringAttributeType

        let lifespanAttribute = NSAttributeDescription()
        lifespanAttribute.name = "lifespan"
        lifespanAttribute.attributeType = .stringAttributeType

        let lifespanIdAttribute = NSAttributeDescription()
        lifespanIdAttribute.name = "lifespanId"
        lifespanIdAttribute.attributeType = .stringAttributeType

        let dateAttribute = NSAttributeDescription()
        dateAttribute.name = "collectedAt"
        dateAttribute.attributeType = .dateAttributeType

        entity.properties = [keyAttribute, valueAttribute, typeAttribute, lifespanAttribute, lifespanIdAttribute, dateAttribute]
        return entity
    }
}
