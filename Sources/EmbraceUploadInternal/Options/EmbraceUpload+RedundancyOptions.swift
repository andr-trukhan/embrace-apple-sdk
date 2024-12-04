//
//  Copyright © 2024 Embrace Mobile, Inc. All rights reserved.
//

import Foundation

public extension EmbraceUpload {
    class RedundancyOptions {
        /// Total amount of times a request will be immediately retried in case of error. Use 0 to disable.
        public var automaticRetryCount: Int

        /// Total amount of times a request could be retried.
        public var maximumAmountOfRetries: Int

        /// Enable to automatically try to send any unsent cached data when the phone regains internet connection.
        public var retryOnInternetConnected: Bool

        /// Defines the behavior to use when retrying requests
        public var exponentialBackoffBehavior: ExponentialBackoff

        public init(
            automaticRetryCount: Int = 3,
            maximumAmountOfRetries: Int = 20,
            retryOnInternetConnected: Bool = true,
            exponentialBackoffBehavior: ExponentialBackoff = .init()
        ) {
            self.automaticRetryCount = automaticRetryCount
            self.maximumAmountOfRetries = maximumAmountOfRetries
            self.retryOnInternetConnected = retryOnInternetConnected
            self.exponentialBackoffBehavior = exponentialBackoffBehavior
        }
    }
}
