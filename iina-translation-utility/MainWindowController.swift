//
//  MainWindowController.swift
//  iina-translation-utility
//
//  Created by lhc on 23/10/2017.
//  Copyright © 2017 Collider LI. All rights reserved.
//

import Cocoa

fileprivate extension NSUserInterfaceItemIdentifier {
  static let keyColumn = NSUserInterfaceItemIdentifier("Key")
  static let valueColumn = NSUserInterfaceItemIdentifier("Value")
}

class MainWindowController: NSWindowController {

  override var windowNibName: NSNib.Name {
    return "MainWindowController"
  }

  @IBOutlet weak var languagePopupButton: NSPopUpButton!
  @IBOutlet weak var baseLanguagePopupButton: NSPopUpButton!

  @IBOutlet weak var mainSplitView: ThinSplitView!
  @IBOutlet weak var filelistOutlineView: NSOutlineView!
  @IBOutlet weak var mainTableView: NSTableView!

  @IBOutlet var editingPopover: NSPopover!
  @IBOutlet weak var popoverBaseTextField: NSTextField!
  @IBOutlet weak var popoverTranslationTextField: NSTextField!

  @IBOutlet weak var fileStatusImage: NSImageView!
  @IBOutlet weak var fileMessageTextField: NSTextField!
  @IBOutlet weak var fileNextIssueButton: NSButton!

  @IBOutlet weak var searchField: NSSearchField!

  var projectURL: URL?

  var lProjURLs: [URL] = []
  var selectedLangURL: URL?
  var selectedBaseLangURL: URL?

  var localizableFiles: [LocalizableFile] = []
  var selectedFile: LocalizableFile?

  var displayedItems: [LocalizationItem] = []

  var editingRow: Int = 0

  override func windowDidLoad() {
    super.windowDidLoad()

    window?.isMovableByWindowBackground = true

    loadProject()

    mainSplitView.setPosition(250, ofDividerAt: 0)

    filelistOutlineView.dataSource = self
    filelistOutlineView.delegate = self
    mainTableView.dataSource = self
    mainTableView.delegate = self
    mainTableView.doubleAction = #selector(self.tableViewDoubleClickAction)
  }

  func loadProject() {
    guard let url = projectURL else { return }

    guard let lProjURLs = try? FileManager.default
      .contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants])
      .filter { $0.hasDirectoryPath && $0.lastPathComponent.hasSuffix(".lproj") }, lProjURLs.count > 1 else {
        Utils.showAlert(message: "Cannot load the project.")
        exit(1)
    }

    self.lProjURLs = lProjURLs

    lProjURLs.forEach { url in
      let item = languagePopupButton.menu?.addItem(withTitle: url.lastPathComponent, action: nil, keyEquivalent: "")
      item?.representedObject = url
      let item2 = baseLanguagePopupButton.menu?.addItem(withTitle: url.lastPathComponent, action: nil, keyEquivalent: "")
      item2?.representedObject = url
    }

    languagePopupButton.select(nil)
    baseLanguagePopupButton.selectItem(withTitle: "Base.lproj")
    selectedBaseLangURL = (baseLanguagePopupButton.selectedItem?.representedObject as? URL)
  }

  private func getLocalizableFiles(url: URL) -> [URL] {
    return try! FileManager.default
      .contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants])
      .filter { $0.pathExtension != "rtf" }
      .sorted { $0.path.localizedStandardCompare($1.path) == .orderedAscending }
  }

  private func loadLanguage() {
    guard let url = selectedLangURL, let baseURL = selectedBaseLangURL else { return }
    let langLocalizableFiles = getLocalizableFiles(url: url).map { NSString(string: $0.lastPathComponent).deletingPathExtension }
    let baseLocalizableFiles = getLocalizableFiles(url: baseURL).map { NSString(string: $0.lastPathComponent).deletingPathExtension }
    let missingFiles = baseLocalizableFiles.filter { !langLocalizableFiles.contains($0) }
    missingFiles.forEach {
      FileManager.default.createFile(atPath: "\(url.path)//\($0).strings", contents: nil)
    }
    localizableFiles = getLocalizableFiles(url: url)
      .map { LocalizableFile(url: $0, basedOn: selectedBaseLangURL) }
    localizableFiles.forEach { $0.update() }
    selectedFile = nil
    displayedItems.removeAll()
    mainTableView.reloadData()
  }

  private func updateStatus() {
    guard let selectedFile = selectedFile else { return }
    selectedFile.checkForIssues(appendMissingValues: false)
    if selectedFile.missingKeyCount == 0 {
      fileStatusImage.image = NSImage(named: NSImage.statusAvailableName)
      fileMessageTextField.stringValue = "No Issue."
      fileNextIssueButton.isHidden = true
    } else {
      fileStatusImage.image = NSImage(named: NSImage.statusUnavailableName)
      fileMessageTextField.stringValue = "Translation missing detected for \(selectedFile.missingKeyCount) keys."
      fileNextIssueButton.isHidden = false
    }
  }

  private func popoverCommitEditing() {
    guard let selectedFile = selectedFile else { return }
    let key = displayedItems[editingRow].key
    let value = popoverTranslationTextField.stringValue
    selectedFile.contentDict[key] = value
    displayedItems[editingRow].localization = value
    selectedFile.saveToDisk()
    selectedFile.checkForIssues(appendMissingValues: false)
    filelistOutlineView.reloadItem(selectedFile)
    updateStatus()
    mainTableView.reloadData(forRowIndexes: IndexSet(integer: editingRow), columnIndexes: IndexSet(0...1))
  }

  @IBAction func mainLanguageChanged(_ sender: Any) {
    selectedLangURL = languagePopupButton.selectedItem?.representedObject as? URL
    loadLanguage()
    displayedItems = selectedFile?.content ?? []
    filelistOutlineView.reloadData()
    mainTableView.reloadData()
  }

  @IBAction func baseLanguageChanged(_ sender: Any) {
    selectedBaseLangURL = baseLanguagePopupButton.selectedItem?.representedObject as? URL
    localizableFiles.forEach {
      $0.baseLanguageURL = selectedBaseLangURL
      $0.update()
    }
    displayedItems = selectedFile?.content ?? []
    filelistOutlineView.reloadData()
    mainTableView.reloadData()
  }

  @IBAction func popoverCancelAction(_ sender: Any) {
    editingPopover.close()
  }

  @IBAction func popoverDoneAction(_ sender: NSButton) {
    editingPopover.close()
    popoverCommitEditing()
  }

  @IBAction func popoverNextAction(_ sender: Any) {
    popoverCommitEditing()
    if mainTableView.numberOfRows > editingRow + 1 {
      showPopOver(for: editingRow + 1)
    } else {
      editingPopover.close()
    }
  }

  @IBAction func nextIssueBtnAction(_ sender: Any) {
    let selectedRow = mainTableView.selectedRow + 1
    if let row = displayedItems[selectedRow...].index(where: { $0.missingTranslations }) {
      mainTableView.scrollRowToVisible(row)
      mainTableView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
    }
  }

  @IBAction func reloadFileAction(_ sender: Any) {
    let file = filelistOutlineView.item(atRow: filelistOutlineView.clickedRow) as! LocalizableFile
    file.update()
    updateStatus()
    filelistOutlineView.reloadItem(file)
  }

  @IBAction func reloadWholeFileAction(_ sender: Any) {
    let file = filelistOutlineView.item(atRow: filelistOutlineView.clickedRow) as! LocalizableFile
    file.update()
    updateStatus()
    displayedItems = selectedFile?.content ?? []
    filelistOutlineView.reloadItem(file)
    mainTableView.reloadData()
  }

  @IBAction func revealInFinderAction(_ sender: Any) {
    let file = filelistOutlineView.item(atRow: filelistOutlineView.clickedRow) as! LocalizableFile
    NSWorkspace.shared.activateFileViewerSelecting([file.url])
  }

  @IBAction func updateAllKeysWithSameBase(_ sender: Any) {
    let row = mainTableView.clickedRow
    let item = displayedItems[row]
    guard let baseString = item.base, baseString.count > 1 else {
      Utils.showAlert(message: "You cannot do this because base translation is too short.")
      return
    }
    _ = Utils.quickPromptPanel(title: "Update all translations",
                           message: "This will update translations for all keys with base translation \"\(item.baseStringForDisplay)\" in current language.",
                           mode: .sheetModal, sheetWindow: window)
    { value in
      self.localizableFiles.forEach { file in
        file.content.forEach { item in
          if item.base == baseString {
            item.localization = value
          }
        }
        file.saveToDisk()
        file.update()
      }
      self.displayedItems = self.selectedFile?.content ?? []
      self.filelistOutlineView.reloadData()
      self.mainTableView.reloadData()
    }
  }

  @IBAction func updateKeyForAllLanguages(_ sender: Any) {
    guard let selectedFile = selectedFile else { return }
    let row = mainTableView.clickedRow
    let item = displayedItems[row]
    _ = Utils.quickPromptPanel(title: "Update translation for all keys",
                               message: "This will update translations for this key  \"\(item.key)\" in all languages.",
      mode: .sheetModal, sheetWindow: window)
    { value in
      self.lProjURLs.forEach { lproj in
        if lproj.lastPathComponent.contains("Base.lproj") { return }
        let url = lproj.appendingPathComponent(selectedFile.url.lastPathComponent)
        let file = LocalizableFile(url: url, basedOn: nil)
        file.loadFile()
        if let item = file.content.first(where: { $0.key == item.key }) {
          item.localization = value
        } else {
          file.content.append(LocalizationItem(key: item.key, base: nil, localization: value))
        }
        file.saveToDisk()
      }
      selectedFile.update()
      self.displayedItems = selectedFile.content
      self.filelistOutlineView.reloadData()
      self.mainTableView.reloadData()
    }
  }

  @IBAction func searchFieldUpdated(_ sender: Any) {
    guard let selectedFile = selectedFile else { return }
    let filterString = searchField.stringValue.lowercased()
    if filterString.count == 0 {
      displayedItems = selectedFile.content
    } else if filterString.count > 1 {
      displayedItems = selectedFile.content.filter {
        ($0.base?.lowercased().contains(filterString) ?? false) ||
        ($0.localization?.lowercased().contains(filterString) ?? false) ||
        $0.key.contains(filterString)
      }
    }
    mainTableView.reloadData()
  }
}


extension MainWindowController: NSOutlineViewDelegate, NSOutlineViewDataSource {

  func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
    return false
  }

  func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
    if (item == nil) {
      return localizableFiles.count
    } else {
      return 0
    }
  }

  func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
    if (item == nil) {
      return localizableFiles[index]
    } else {
      return ""
    }
  }

  func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
    if let url = item as? URL {
      return url.lastPathComponent
    }
    return nil
  }

  func outlineView(_ outlineView: NSOutlineView, isGroupItem item: Any) -> Bool {
    return false
  }

  func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
    let v = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("DataCell"), owner: self) as! StringFileTableCellView
    let file = item as! LocalizableFile
    v.textField?.stringValue = file.url.lastPathComponent
    v.imageView?.image = NSWorkspace.shared.icon(forFile: file.url.path)
    v.statusImageView.image = file.missingKeyCount == 0 ? NSImage(named: NSImage.statusAvailableName) : NSImage(named: NSImage.statusUnavailableName)
    v.statusCountLabel.stringValue = "\(file.missingKeyCount)"
    return v
  }

  func outlineViewSelectionDidChange(_ notification: Notification) {
    selectedFile = filelistOutlineView.item(atRow: filelistOutlineView.selectedRow) as? LocalizableFile
    displayedItems = selectedFile!.content
    mainTableView.reloadData()
    updateStatus()
  }
}

extension MainWindowController: NSTableViewDelegate, NSTableViewDataSource {
  func numberOfRows(in tableView: NSTableView) -> Int {
    return displayedItems.count
  }

  func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
    guard let tableColumn = tableColumn else { return nil }
    switch tableColumn.identifier {
    case .keyColumn:
      return displayedItems[row].key
    case .valueColumn:
      return displayedItems[row]
    default:
      return nil
    }
  }

  @objc
  func tableViewDoubleClickAction(sender: NSTableView) {
    showPopOver(for: mainTableView.selectedRow)
  }

  override func cancelOperation(_ sender: Any?) {
    if editingPopover.isShown {
      editingPopover.close()
    }
  }

  private func showPopOver(for row: Int) {
    guard row >= 0 && row < mainTableView.numberOfRows else { return }
    editingRow = row
    mainTableView.selectRowIndexes(IndexSet(integer: editingRow), byExtendingSelection: false)
    mainTableView.scrollRowToVisible(editingRow)
    if let rowView = mainTableView.rowView(atRow: editingRow, makeIfNecessary: false) {
      let item = displayedItems[row]
      popoverBaseTextField.stringValue = item.base ?? ""
      popoverTranslationTextField.stringValue = item.safeLocalization
      editingPopover.show(relativeTo: rowView.bounds, of: rowView, preferredEdge: .minY)
      popoverTranslationTextField.selectText(nil)
    }
  }
}


class StringFileTableCellView: NSTableCellView {

  @IBOutlet weak var statusImageView: NSImageView!
  @IBOutlet weak var statusCountLabel: NSTextField!

}
