//
//  DimManager.swift
//  Dimmer Bar
//
//  Created by Trung Phan on 12/23/19.
//  Copyright © 2019 Dwarves Foundation. All rights reserved.
//

import Foundation
import Cocoa
import Combine

enum DimMode: Int {
    case single
    case parallel
}

class DimManager: ObservableObject {
    //MARK: - Variable(s)
    static let sharedInstance = DimManager()
    let setting = SettingObservable()

    @Published private(set) var hasScreenRecordingPermission: Bool = false

    private(set) var windowEnumerator: WindowEnumerator = CGWindowEnumerator()
    private var overlayWindows: [CGDirectDisplayID: NSWindow] = [:]
    private var pendingDimWork: DispatchWorkItem?
    private var cancellableSet: Set<AnyCancellable> = []

    //MARK: - Init
    private init() {
        self.hasScreenRecordingPermission = CGPreflightScreenCaptureAccess()
        self.observerActiveWindowChanged()
        self.observeSettingChanged()
    }

    func dim(runningApplication: NSRunningApplication?, withDelay: Bool = true) {
        pendingDimWork?.cancel()

        guard self.setting.isEnabled else {
            self.removeAllOverlay()
            return
        }

        let delay: TimeInterval = withDelay ? 0.2 : 0
        let work = DispatchWorkItem { [weak self] in
            guard let self = self else { return }

            self.hasScreenRecordingPermission = CGPreflightScreenCaptureAccess()
            guard self.hasScreenRecordingPermission else {
                self.removeAllOverlay()
                return
            }

            let windowInfos = self.windowEnumerator.getOnScreenWindows()
            let screens = NSScreen.screens
            let primaryHeight = screens.first?.frame.height ?? 0
            let color = NSColor.black.withAlphaComponent(CGFloat(self.setting.alpha / 100.0))
            // Re-read frontmost app at execution time to avoid stale capture across delay
            let bundleID = runningApplication?.bundleIdentifier
                ?? NSWorkspace.shared.frontmostApplication?.bundleIdentifier

            // Track which displays are still active
            var activeDisplayIDs = Set<CGDirectDisplayID>()

            for screen in screens {
                let displayID = Self.displayID(for: screen)
                activeDisplayIDs.insert(displayID)
                let screenFrame = screen.frame

                // Per-screen desktop detection
                if WindowSelection.isDesktopClick(
                    bundleIdentifier: bundleID,
                    windowInfos: windowInfos,
                    screenFrame: screenFrame,
                    primaryScreenHeight: primaryHeight
                ) {
                    self.overlayWindows[displayID]?.orderOut(nil)
                    continue
                }

                let targetWindowNumber: Int
                switch self.setting.dimMode {
                case .single:
                    targetWindowNumber = windowInfos.first?.number ?? 0
                case .parallel:
                    targetWindowNumber = WindowSelection.frontmostWindow(
                        on: screenFrame,
                        from: windowInfos,
                        primaryScreenHeight: primaryHeight
                    ) ?? 0
                }

                if targetWindowNumber == 0 {
                    self.overlayWindows[displayID]?.orderOut(nil)
                    continue
                }

                let overlay = self.overlayForScreen(screen, displayID: displayID, color: color)
                // orderOut + order(.below) must be atomic to prevent flicker
                NSDisableScreenUpdates()
                overlay.orderOut(nil)
                overlay.order(.below, relativeTo: targetWindowNumber)
                NSEnableScreenUpdates()
            }

            // Remove overlays for disconnected screens
            let staleIDs = self.overlayWindows.keys.filter { !activeDisplayIDs.contains($0) }
            for id in staleIDs {
                self.overlayWindows.removeValue(forKey: id)?.orderOut(nil)
            }
        }

        pendingDimWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

    func toggleDimming(isEnable: Bool) {
        isEnable ? self.dim(runningApplication: self.getFrontMostApplication()) : self.removeAllOverlay()
    }

    func adjustDimmingLevel(alpha: Double) {
        for overlay in overlayWindows.values {
            overlay.backgroundColor = NSColor.black.withAlphaComponent(CGFloat(alpha / 100.0))
        }
    }
}

//MARK: - Core function Helper Methods
extension DimManager {
    private func getFrontMostApplication() -> NSRunningApplication? {
        return NSWorkspace.shared.frontmostApplication
    }

    static func displayID(for screen: NSScreen) -> CGDirectDisplayID {
        return screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID ?? 0
    }

    private func overlayForScreen(_ screen: NSScreen, displayID: CGDirectDisplayID, color: NSColor) -> NSWindow {
        if let existing = overlayWindows[displayID] {
            existing.setFrame(screen.frame, display: false)
            existing.backgroundColor = color
            return existing
        }

        let overlay = NSWindow(
            contentRect: NSRect(origin: .zero, size: screen.frame.size),
            styleMask: .borderless,
            backing: .buffered,
            defer: false,
            screen: screen
        )
        overlay.isReleasedWhenClosed = false
        overlay.animationBehavior = .none
        overlay.backgroundColor = color
        overlay.ignoresMouseEvents = true
        overlay.collectionBehavior = [.transient, .fullScreenNone]
        overlay.level = .normal
        overlay.setFrame(screen.frame, display: false)

        overlayWindows[displayID] = overlay
        return overlay
    }

    private func removeAllOverlay() {
        let windows = overlayWindows
        overlayWindows.removeAll()
        for (_, window) in windows {
            window.orderOut(nil)
        }
    }
}

extension DimManager {
    private func observeSettingChanged() {
        self.setting.$alpha
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: adjustDimmingLevel)
            .store(in: &cancellableSet)

        self.setting.$isEnabled
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: toggleDimming)
            .store(in: &cancellableSet)

        self.setting.$dimMode
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] _ in
                self?.dim(runningApplication: nil)
            })
            .store(in: &cancellableSet)
    }

    private func observerActiveWindowChanged() {
        let nc = NSWorkspace.shared.notificationCenter
        nc.addObserver(self, selector: #selector(workspaceDidReceiptAppllicatinActiveNotification), name: NSWorkspace.didActivateApplicationNotification, object: nil)
    }

    @objc private func workspaceDidReceiptAppllicatinActiveNotification(ntf: Notification) {
        guard
            let activeAppDict = ntf.userInfo as? [AnyHashable : NSRunningApplication],
            let activeApplication = activeAppDict["NSWorkspaceApplicationKey"]
            else { return }

        self.dim(runningApplication: activeApplication)
    }
}
