//
//  Utility.swift
//  iina-translation-utility
//
//  Created by lhc on 24/10/2017.
//  Copyright © 2017 Collider LI. All rights reserved.
//

import Cocoa

class Utils {

  enum AlertMode {
    case modal
    case nonModal
    case sheet
    case sheetModal
  }

  static func showAlert(message: String, alertStyle: NSAlert.Style = .critical) {
    let alert = NSAlert()
    switch alertStyle {
    case .critical:
      alert.messageText = NSLocalizedString("alert.title_error", comment: "Error")
    case .informational:
      alert.messageText = NSLocalizedString("alert.title_info", comment: "Information")
    case .warning:
      alert.messageText = NSLocalizedString("alert.title_warning", comment: "Warning")
    }
    alert.informativeText = message
    alert.alertStyle = alertStyle
    alert.runModal()
  }

  static func quickPromptPanel(title: String, message: String,
                               mode: AlertMode = .modal, sheetWindow: NSWindow? = nil,
                               ok: @escaping (String) -> Void) -> Bool {
    let panel = NSAlert()
    panel.messageText = title
    panel.informativeText = message
    let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 240, height: 24))
    input.lineBreakMode = .byClipping
    input.usesSingleLineMode = true
    input.cell?.isScrollable = true
    panel.accessoryView = input
    panel.addButton(withTitle: "OK")
    panel.addButton(withTitle: "Cancel")
    panel.window.initialFirstResponder = input
    // handler
    switch mode {
    case .modal:
      let response = panel.runModal()
      if response == .alertFirstButtonReturn {
        ok(input.stringValue)
        return true
      } else {
        return false
      }
    case .sheetModal:
      guard let sheetWindow = sheetWindow else {
        fatalError("No sheet window")
      }
      panel.beginSheetModal(for: sheetWindow) { response in
        if response == .alertFirstButtonReturn {
          ok(input.stringValue)
        }
      }
      return false
    default:
      fatalError("quickPromptPanel: Unsupported mode")
    }
  }

}
