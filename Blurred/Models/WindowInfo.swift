//
//  WindowInfo.swift
//  Dimmer Bar
//
//  Created by phucld on 1/7/20.
//  Copyright © 2020 Dwarves Foundation. All rights reserved.
//

import Foundation
import Cocoa

// The keys that are guaranteed to be available in a window’s information dictionary.
// https://developer.apple.com/documentation/coregraphics/quartz_window_services/required_window_list_keys?language=objc

struct WindowInfo {
    var alpha: Double
    var backingLocationVideoMemory: Bool?
    var bounds: CGRect
    var isOnScreen: Bool?
    var layer: Int
    var memoryUsage: Double
    var name: String?
    var number: Int
    var ownerName: String?
    var ownerPID: Int
    var sharingState: Int
    var storeType: Int
}

extension WindowInfo {
    init?(dict: [String: Any]) {
        guard
            let alpha = dict["kCGWindowAlpha"] as? Double,
            let boundsDict = dict["kCGWindowBounds"] as? NSDictionary,
            let bounds = CGRect(dictionaryRepresentation: boundsDict),
            let layer = dict["kCGWindowLayer"] as? Int,
            let number = dict["kCGWindowNumber"] as? Int,
            let ownerPID = dict["kCGWindowOwnerPID"] as? Int,
            let sharingState = dict["kCGWindowSharingState"] as? Int,
            let storeType = dict["kCGWindowStoreType"] as? Int
        else {
            #if DEBUG
            print("WindowInfo: dropped window – missing required field in \(dict)")
            #endif
            return nil
        }

        self.alpha = alpha
        self.bounds = bounds
        self.layer = layer
        // memoryUsage is optional per Apple docs despite being listed under
        // "required" keys — default to 0 so we don't drop valid windows.
        self.memoryUsage = (dict["kCGWindowMemoryUsage"] as? NSNumber)?.doubleValue ?? 0
        self.number = number
        self.ownerPID = ownerPID
        self.sharingState = sharingState
        self.storeType = storeType

        self.backingLocationVideoMemory = dict["CGWindowBackingLocationVideoMemory"] as? Bool
        self.isOnScreen = dict["kCGWindowIsOnscreen"] as? Bool
        self.name = dict["kCGWindowName"] as? String
        self.ownerName = dict["kCGWindowOwnerName"] as? String
    }
}

