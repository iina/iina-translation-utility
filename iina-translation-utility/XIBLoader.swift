//
//  XIBLoader.swift
//  iina-translation-utility
//
//  Created by lhc on 23/10/2017.
//  Copyright © 2017 Collider LI. All rights reserved.
//

import Cocoa

class XIBLoader: NSObject {

  var url: URL

  var titles: [String: String] = [:]

  var classes: [String: String] = [:]

  var currentTableColumnId: String?
  var currentSegmentedCellId: String?
  var currentSegmentCount = 0

  private var isInTableColumn = false

  init(_ url: URL) {
    self.url = url
  }

  func parse() -> Bool {
    if let p = XMLParser(contentsOf: url) {
      p.delegate = self
      p.parse()
      return true
    } else {
      return false
    }
  }
}


extension XIBLoader: XMLParserDelegate {

  func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
    guard !["popUpButtonCell", "tableViewCell"].contains(elementName) else { return }

    if let id = attributeDict["id"] {
      if elementName == "tableColumn" {
        currentTableColumnId = id
      } else if elementName == "segmentedCell" {
        currentSegmentedCellId = id
        currentSegmentCount = 0
      }
      if let title = attributeDict["title"] {
        addTitle(key: "\(id).title", value: title, class: elementName)
      }
      if let label = attributeDict["label"] {
        addTitle(key: "\(id).label", value: label, class: elementName)
      }
      if let placeholder = attributeDict["placeholderString"] {
        addTitle(key: "\(id).placeholderString", value: placeholder, class: elementName)
      }
    }
    if elementName == "tableHeaderCell", let columnId = currentTableColumnId, let title = attributeDict["title"] {
      // headerCell
      addTitle(key: "\(columnId).headerCell.title", value: title, class: "tableColumn")
    }
    if elementName == "segment", let cellId = currentSegmentedCellId, let label = attributeDict["label"] {
      addTitle(key: "\(cellId).ibShadowedLabels[\(currentSegmentCount)]", value: label, class: "segmentedCell")
      currentSegmentCount += 1
    }
    if elementName == "tableColumn" {
      isInTableColumn = true
    }
  }

  func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
    if elementName == "tableColumn" {
      currentTableColumnId = nil
    } else if elementName == "segmentedCell" {
      currentSegmentedCellId = nil
    } else if elementName == "tableCellView" {
      isInTableColumn = false
    }
  }

  private func addTitle(key: String, value: String, class cls: String?) {
    titles[key] = value
    if let cls = cls {
      classes[key] = "NS" + cls.prefix(1).uppercased() + cls.dropFirst()
    }
  }
}
