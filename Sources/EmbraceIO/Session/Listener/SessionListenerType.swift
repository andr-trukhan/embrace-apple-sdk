//
//  Copyright © 2023 Embrace Mobile, Inc. All rights reserved.
//

import Foundation

public enum SessionListenerType {
    case automatic
    case explicit
    case iOSApp
    case tvOSApp
}

enum SessionListenerFactory {
    static func resolve(type: SessionListenerType, with controller: SessionController) -> SessionListener {
        switch type {
        case .automatic:
            return determineForPlatform(controller: controller)
        case .explicit:
            return ExplicitSessionListener(controller: controller)
//        case .iOSApp:
//        case .tvOSApp:
        default:
            return ExplicitSessionListener(controller: controller)
        }
    }

    static func determineForPlatform(controller: SessionControllable) -> SessionListener {
        #if os(iOS)
        return iOSAppListener(controller: controller)
        #else
        return ExplicitSessionListener(controller: controller)
        #endif
    }
}
