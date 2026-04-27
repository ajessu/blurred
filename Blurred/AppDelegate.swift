//
//  AppDelegate.swift
//  Dimmer Bar
//
//  Created by phucld on 12/17/19.
//  Copyright © 2019 Dwarves Foundation. All rights reserved.
//

import Cocoa
import SwiftUI
import HotKey

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    let statusBarController = StatusBarController()
    var spaceObserver: Any?
    
    var hotKey: HotKey? {
        didSet {
            guard let hotKey = hotKey else { return }
            
            hotKey.keyDownHandler = {
                DimManager.sharedInstance.setting.isEnabled.toggle()
            }
        }
    }
    
    
    let eventMonitor = EventMonitor(mask: .leftMouseUp) { _ in
        // Hanlde this without delay
        DimManager.sharedInstance.dim(runningApplication: NSWorkspace.shared.frontmostApplication, withDelay: false)
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        checkScreenRecordingPermission()
        hideDockIcon()
        setupAutoStartAtLogin()
        openPrefWindowIfNeeded()
        setupHotKey()
        eventMonitor.start()
        observeSpaceChanges()
    }
    
    func applicationDidChangeScreenParameters(_ notification: Notification) {
        DimManager.sharedInstance.dim(runningApplication: NSWorkspace.shared.frontmostApplication)
    }
    
    func setupHotKey() {
        guard let globalKey = UserDefaults.globalKey else {return}
        hotKey = HotKey(keyCombo: KeyCombo(carbonKeyCode: globalKey.keyCode, carbonModifiers: globalKey.carbonFlags))
    }
    
    func openPrefWindowIfNeeded() {
        if UserDefaults.isOpenPrefWhenOpenApp {
            PreferencesWindowController.shared.window?.makeKeyAndOrderFront(nil)
            if #available(macOS 14.0, *) {
                NSApp.activate()
            } else {
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
    
    func setupAutoStartAtLogin() {
        let isAutoStart = UserDefaults.isStartWhenLogin
        Util.setUpAutoStart(isAutoStart: isAutoStart)
    }
    
    func hideDockIcon() {
        NSApp.setActivationPolicy(.accessory)
    }

    func checkScreenRecordingPermission() {
        if !CGPreflightScreenCaptureAccess(),
           !UserDefaults.standard.bool(forKey: "hasRequestedScreenRecording") {
            CGRequestScreenCaptureAccess()
            UserDefaults.standard.set(true, forKey: "hasRequestedScreenRecording")
        }
    }

    func observeSpaceChanges() {
        spaceObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            DimManager.sharedInstance.dim(runningApplication: NSWorkspace.shared.frontmostApplication)
        }
    }
}
