//
//  Util.swift
//  Dimmer Bar
//
//  Created by phucld on 1/7/20.
//  Copyright © 2020 Dwarves Foundation. All rights reserved.
//

import SwiftUI
import Foundation
import ServiceManagement

enum Util {
    static func setUpAutoStart(isAutoStart: Bool) {
        if #available(macOS 13.0, *) {
            let service = SMAppService.mainApp
            do {
                if isAutoStart {
                    try service.register()
                } else {
                    try service.unregister()
                }
            } catch {
                print("Failed to \(isAutoStart ? "register" : "unregister") login item: \(error)")
            }
        } else {
            let launcherAppId = "foundation.dwarves.blurredlauncher"
            let runningApps = NSWorkspace.shared.runningApplications
            let isRunning = !runningApps.filter { $0.bundleIdentifier == launcherAppId }.isEmpty
            
            SMLoginItemSetEnabled(launcherAppId as CFString, isAutoStart)
            
            if isRunning {
                DistributedNotificationCenter.default().post(name: Notification.Name("killLauncher"),
                                                             object: Bundle.main.bundleIdentifier!)
            }
        }
    }
}
