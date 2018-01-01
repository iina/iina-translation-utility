//
//  LocalizationItem.swift
//  iina-translation-utility
//
//  Created by Collider LI on 20/12/2017.
//  Copyright © 2017 Collider LI. All rights reserved.
//

import Cocoa

class LocalizationItem: NSObject {

  var key: String
  var base: String?
  var baseClassName: String?
  var localization: String?

  var safeLocalization: String {
    return localization ?? base ?? ""
  }

  var escapedLocalization: String? {
    return localization?.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
  }

  @objc var translationForDisplay: String {
    return localization ?? "Translation Missing"
  }

  @objc var baseStringForDisplay: String {
    return base ?? "<!No base string> This key will be deleted."
  }

  @objc var missingTranslations: Bool {
    return localization == nil
  }

  @objc var missingBase: Bool {
    return base == nil
  }

  @objc var labelColor: NSColor {
    return missingTranslations ? .red : .labelColor
  }

  @objc var baseLabelColor: NSColor {
    return base == nil ? .blue : .secondaryLabelColor
  }

  init(key: String, base: String?, localization: String?) {
    self.key = key
    self.base = base
    self.localization = localization
  }
}
