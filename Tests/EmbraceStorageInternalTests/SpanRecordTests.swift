//
//  Copyright © 2023 Embrace Mobile, Inc. All rights reserved.
//

import XCTest
import TestSupport
import EmbraceCommonInternal
@testable import EmbraceStorageInternal

class SpanRecordTests: XCTestCase {
    var storage: EmbraceStorage!

    override func setUpWithError() throws {
        storage = try EmbraceStorage.createInMemoryDb()
    }

    override func tearDownWithError() throws {
        storage.coreData.destroy()
    }

    func test_upsertSpan() throws {
        // given inserted span
        storage.upsertSpan(
            id: "id",
            name: "a name",
            traceId: "tradeId",
            type: .performance,
            data: Data(),
            startTime: Date()
        )

        // then span should exist in storage
        let spans: [SpanRecord] = storage.fetchAll()
        XCTAssertEqual(spans.count, 1)
        XCTAssertEqual(spans[0].id, "id")
    }

    func test_fetchSpan() throws {
        // given inserted span
        let original = storage.upsertSpan(
            id: "id",
            name: "a name",
            traceId: TestConstants.traceId,
            type: .performance,
            data: Data(),
            startTime: Date(),
            endTime: nil
        )

        // when fetching the span
        let span = storage.fetchSpan(id: "id", traceId: TestConstants.traceId)

        // then the span should be valid
        XCTAssertNotNil(span)
        XCTAssertEqual(original, span)
    }

    func test_cleanUpSpans() throws {
        // given inserted spans
        storage.upsertSpan(
            id: "id1",
            name: "a name 1",
            traceId: TestConstants.traceId,
            type: .performance,
            data: Data(),
            startTime: Date(timeIntervalSince1970: 0),
            endTime: Date(timeIntervalSince1970: 10)
        )
        storage.upsertSpan(
            id: "id2",
            name: "a name 2",
            traceId: TestConstants.traceId,
            type: .performance,
            data: Data(),
            startTime: Date(timeIntervalSince1970: 0),
            endTime: Date(timeIntervalSince1970: 20)
        )
        storage.upsertSpan(
            id: "id3",
            name: "a name 3",
            traceId: TestConstants.traceId,
            type: .performance,
            data: Data(),
            startTime: Date(timeIntervalSince1970: 0)
        )

        // when cleaning up spans with a date
        storage.cleanUpSpans(date: Date(timeIntervalSince1970: 15))

        // then closed spans older than that date are removed
        // and open spans remain untouched
        let spans: [SpanRecord] = storage.fetchAll()
        XCTAssertEqual(spans.count, 2)
        XCTAssertNil(spans.first(where: { $0.id == "id1" }))
        XCTAssertNotNil(spans.first(where: { $0.id == "id2" }))

        let span3 = spans.first(where: { $0.id == "id3" })
        XCTAssertNotNil(span3)
        XCTAssertNil(span3!.endTime)
    }

    func test_cleanUpSpans_noDate() throws {
        // given insterted spans
        storage.upsertSpan(
            id: "id1",
            name: "a name 1",
            traceId: TestConstants.traceId,
            type: .performance,
            data: Data(),
            startTime: Date(timeIntervalSince1970: 0),
            endTime: Date(timeIntervalSince1970: 10)
        )
        storage.upsertSpan(
            id: "id2",
            name: "a name 2",
            traceId: TestConstants.traceId,
            type: .performance,
            data: Data(),
            startTime: Date(timeIntervalSince1970: 0),
            endTime: Date(timeIntervalSince1970: 20)
        )
        storage.upsertSpan(
            id: "id3",
            name: "a name 3",
            traceId: TestConstants.traceId,
            type: .performance,
            data: Data(),
            startTime: Date(timeIntervalSince1970: 0)
        )

        // when cleaning up spans without a date
        storage.cleanUpSpans(date: nil)

        // then all closed spans are removed
        // and open spans remain untouched
        let spans: [SpanRecord] = storage.fetchAll()
        XCTAssertEqual(spans.count, 1)
        XCTAssertEqual(spans[0].id, "id3")
        XCTAssertNil(spans[0].endTime)
    }

    func test_closeOpenSpans() throws {
        // given insterted spans
        storage.upsertSpan(
            id: "id1",
            name: "a name 1",
            traceId: TestConstants.traceId,
            type: .performance, data: Data(),
            startTime: Date(timeIntervalSince1970: 0),
            endTime: Date(timeIntervalSince1970: 10)
        )
        storage.upsertSpan(
            id: "id2",
            name: "a name 2",
            traceId: TestConstants.traceId,
            type: .performance,
            data: Data(),
            startTime: Date(timeIntervalSince1970: 1),
            processIdentifier: TestConstants.processId
        )
        storage.upsertSpan(
            id: "id3",
            name: "a name 3",
            traceId: TestConstants.traceId,
            type: .performance,
            data: Data(),
            startTime: Date(timeIntervalSince1970: 2)
        )

        // when closing the spans
        let now = Date()
        storage.closeOpenSpans(endTime: now)

        // then all spans are correctly closed
        let spans: [SpanRecord] = storage.fetchAll()
        XCTAssertEqual(spans.count, 3)

        let span1 = spans.first(where: { $0.id == "id1" })
        XCTAssertNotNil(span1!.endTime)
        XCTAssertNotEqual(span1!.endTime!.timeIntervalSince1970, now.timeIntervalSince1970, accuracy: 0.1)

        let span2 = spans.first(where: { $0.id == "id2" })
        XCTAssertEqual(span2!.endTime!.timeIntervalSince1970, now.timeIntervalSince1970, accuracy: 0.1)

        let span3 = spans.first(where: { $0.id == "id3" })
        XCTAssertNil(span3!.endTime)
    }
}
