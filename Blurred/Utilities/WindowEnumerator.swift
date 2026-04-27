//
//  WindowEnumerator.swift
//  Blurred
//
//  Created by Blurred contributors on 2026-04-26.
//  Copyright © 2026 Dwarves Foundation. All rights reserved.
//

import Cocoa

/// Abstracts window enumeration for testability and future ScreenCaptureKit migration.
/// Implementations must be safe to call from the main thread.
protocol WindowEnumerator {
    func getOnScreenWindows() -> [WindowInfo]
}

final class CGWindowEnumerator: WindowEnumerator {
    func getOnScreenWindows() -> [WindowInfo] {
        let options = CGWindowListOption([.excludeDesktopElements, .optionOnScreenOnly])
        let list = CGWindowListCopyWindowInfo(options, CGWindowID(0)) as? [[String: Any]] ?? []
        // Layer 0 = normal window level; excludes menus, tooltips, and floating panels.
        return list.compactMap { WindowInfo(dict: $0) }.filter { $0.layer == 0 }
    }
}
