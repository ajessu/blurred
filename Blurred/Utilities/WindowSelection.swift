//
//  WindowSelection.swift
//  Blurred
//
//  Created by Blurred contributors on 2026-04-26.
//  Copyright © 2026 Dwarves Foundation. All rights reserved.
//

import Foundation

/// Pure functions for coordinate conversion and per-screen window matching.
enum WindowSelection {

    /// Convert a CG rect (top-left origin) to NS rect (bottom-left origin).
    static func cgToNSRect(_ cgRect: CGRect, primaryScreenHeight: CGFloat) -> NSRect {
        NSRect(
            x: cgRect.origin.x,
            y: primaryScreenHeight - cgRect.origin.y - cgRect.height,
            width: cgRect.width,
            height: cgRect.height
        )
    }

    /// Return the window number of the frontmost window whose center falls on `screenFrame`.
    /// `windowInfos` must be in z-order (as returned by CGWindowListCopyWindowInfo).
    static func frontmostWindow(
        on screenFrame: NSRect,
        from windowInfos: [WindowInfo],
        primaryScreenHeight: CGFloat
    ) -> Int? {
        for info in windowInfos {
            guard info.bounds.width > 0, info.bounds.height > 0 else { continue }
            let nsRect = cgToNSRect(info.bounds, primaryScreenHeight: primaryScreenHeight)
            let center = NSPoint(x: nsRect.midX, y: nsRect.midY)
            if screenFrame.contains(center) {
                return info.number
            }
        }
        return nil
    }

    /// Detect whether the active app is Finder showing the desktop (not a Finder window)
    /// on the given screen. Returns `true` when dimming should be removed for that screen.
    static func isDesktopClick(
        bundleIdentifier: String?,
        windowInfos: [WindowInfo],
        screenFrame: NSRect,
        primaryScreenHeight: CGFloat
    ) -> Bool {
        guard bundleIdentifier == "com.apple.finder" else { return false }
        let finderWindows = windowInfos.filter { $0.ownerName == "Finder" && $0.layer == 0 }
        if finderWindows.isEmpty { return true }
        let hasFinderWindowOnScreen = finderWindows.contains { info in
            let nsRect = cgToNSRect(info.bounds, primaryScreenHeight: primaryScreenHeight)
            return screenFrame.contains(NSPoint(x: nsRect.midX, y: nsRect.midY))
        }
        return !hasFinderWindowOnScreen
    }
}
