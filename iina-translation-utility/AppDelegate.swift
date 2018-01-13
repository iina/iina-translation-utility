//
//  AppDelegate.swift
//  iina-translation-utility
//
//  Created by lhc on 23/10/2017.
//  Copyright © 2017 Collider LI. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

  var window: MainWindowController!

  @objc func openDocument(_ sender: Any) {
    let panel = NSOpenPanel()
    panel.title = "Please select IINA's XCode project file"
    panel.canCreateDirectories = false
    panel.canChooseFiles = true
    panel.canChooseDirectories = false
    panel.resolvesAliases = true
    panel.allowsMultipleSelection = false
    panel.allowedFileTypes = ["xcodeproj"]
    panel.level = .modalPanel
    panel.begin() { result in
      if result == .OK, let path = panel.url?.path {
        self.loadWindow(projPath: path)
      }
    }
  }

  func application(_ sender: NSApplication, openFile filename: String) -> Bool {
    loadWindow(projPath: filename)
    return true
  }

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    window = MainWindowController()
    openDocument(self)
  }

  func applicationWillTerminate(_ aNotification: Notification) {
    // Insert code here to tear down your application
  }

  private func loadWindow(projPath: String) {
    let url = URL(fileURLWithPath: projPath)
    NSDocumentController.shared.noteNewRecentDocumentURL(url)
    window.projectURL = url.deletingLastPathComponent().appendingPathComponent("iina", isDirectory: true)
    window.showWindow(self)
  }

}

