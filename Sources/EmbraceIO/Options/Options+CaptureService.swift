//
//  Copyright © 2023 Embrace Mobile, Inc. All rights reserved.
//

import Foundation
import EmbraceCaptureService
import EmbraceCore
import EmbraceCommon
import EmbraceCrash
import EmbraceOTel

public extension Embrace.Options {

    /// Convenience initializer for `Embrace.Options` that automatically includes the the default `CaptureServices` and `CrashReporter`,
    /// You can see list of platform service defaults in ``CaptureServiceFactory.platformCaptureServices``.
    ///
    /// If you wish to customize which `CaptureServices` and `CrashReporter` are installed, please refer to the `Embrace.Options`
    /// initializer found in the `EmbraceCore` target.
    ///
    /// - Parameters:
    ///   - appId: The `appId` of the project.
    ///   - appGroupId: The app group identifier used by the app, if any.
    ///   - platform: `Platform` in which the app will run. Defaults to `.iOS`.
    ///   - endpoints: `Embrace.Endpoints` instance.
    ///   - export: `OpenTelemetryExport` object to export telemetry outside of the Embrace backend.
    @objc convenience init(
        appId: String,
        appGroupId: String? = nil,
        platform: Platform = .default,
        endpoints: Embrace.Endpoints? = nil,
        export: OpenTelemetryExport? = nil
    ) {
        self.init(
            appId: appId,
            appGroupId: appGroupId,
            platform: platform,
            endpoints: endpoints,
            captureServices: .automatic,
            crashReporter: EmbraceCrashReporter(),
            export: export
        )
    }

    /// Convenience initializer for `Embrace.Options` that automatically includes the the default `CaptureServices` and `CrashReporter`,
    /// You can see list of platform service defaults in ``CaptureServiceFactory.platformCaptureServices``.
    ///
    /// If you wish to customize which `CaptureServices` and `CrashReporter` are installed, please refer to the `Embrace.Options`
    /// initializer found in the `EmbraceCore` target.
    ///
    /// - Parameters:
    ///   - appId: The `appId` of the project.
    ///   - appGroupId: The app group identifier used by the app, if any.
    ///   - platform: `Platform` in which the app will run. Defaults to `.iOS`.
    @objc convenience init(
        appId: String,
        appGroupId: String? = nil,
        platform: Platform = .default
    ) {
        self.init(
            appId: appId,
            appGroupId: appGroupId,
            platform: platform,
            captureServices: .automatic,
            crashReporter: EmbraceCrashReporter()
        )
    }
}

extension Embrace.Options: ExpressibleByStringLiteral {
    public convenience init(stringLiteral value: String) {
        self.init(appId: value)
    }
}

public extension Array where Element == CaptureService {
    static var automatic: [CaptureService] {
        return CaptureServiceFactory.platformCaptureServices
    }
}
