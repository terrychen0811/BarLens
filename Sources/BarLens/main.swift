import AppKit
import CoreGraphics
import Foundation

enum AppConstants {
    static let name = "BarLens"
    static let supportURL = URL(string: "https://github.com/terrychen0811/BarLens/issues")!
    static let privacyURL = URL(string: "https://github.com/terrychen0811/BarLens/blob/main/PRIVACY.md")!
}

enum VisibilityRule: String, Codable, CaseIterable {
    case alwaysShow = "Always Show"
    case hideWhenInactive = "Hide When Inactive"
    case keepHidden = "Keep Hidden"
    case observeOnly = "Observe Only"

    var shortTitle: String {
        switch self {
        case .alwaysShow: "Show"
        case .hideWhenInactive: "Auto"
        case .keepHidden: "Hide"
        case .observeOnly: "Watch"
        }
    }
}

struct BarItemRule: Codable, Equatable {
    var bundleIdentifier: String
    var displayName: String
    var rule: VisibilityRule
    var isPinned: Bool
    var notes: String
}

struct MenuBarWindow: Hashable {
    var ownerName: String
    var windowName: String
    var layer: Int
    var frame: CGRect
}

struct CandidateApp: Hashable {
    var name: String
    var bundleIdentifier: String
    var processIdentifier: pid_t
    var isRunning: Bool
    var activationPolicy: NSApplication.ActivationPolicy
    var icon: NSImage?
}

final class BundleButton: NSButton {
    var bundleIdentifier: String = ""
}

final class BundlePopUpButton: NSPopUpButton {
    var bundleIdentifier: String = ""
}

final class RulesStore {
    private let rulesURL: URL

    init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent(AppConstants.name, isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        rulesURL = base.appendingPathComponent("rules.json")
    }

    func load() -> [String: BarItemRule] {
        guard let data = try? Data(contentsOf: rulesURL) else { return [:] }
        let rules = (try? JSONDecoder().decode([BarItemRule].self, from: data)) ?? []
        return Dictionary(uniqueKeysWithValues: rules.map { ($0.bundleIdentifier, $0) })
    }

    func save(_ rules: [String: BarItemRule]) {
        let sorted = rules.values.sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
        guard let data = try? JSONEncoder.pretty.encode(sorted) else { return }
        try? data.write(to: rulesURL, options: .atomic)
    }
}

extension JSONEncoder {
    static var pretty: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}

final class MenuBarScanner {
    func scanWindows() -> [MenuBarWindow] {
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let raw = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return []
        }

        return raw.compactMap { info in
            let owner = info[kCGWindowOwnerName as String] as? String ?? "Unknown"
            let name = info[kCGWindowName as String] as? String ?? ""
            let layer = info[kCGWindowLayer as String] as? Int ?? 0
            guard let bounds = info[kCGWindowBounds as String] as? [String: Any],
                  let x = bounds["X"] as? CGFloat,
                  let y = bounds["Y"] as? CGFloat,
                  let width = bounds["Width"] as? CGFloat,
                  let height = bounds["Height"] as? CGFloat else {
                return nil
            }
            let frame = CGRect(x: x, y: y, width: width, height: height)
            let isTopBand = y <= 40 && height <= 44
            let isMenuLayer = layer >= 20
            let isNamedMenu = name.localizedCaseInsensitiveContains("menu")
                || name.localizedCaseInsensitiveContains("status")
            guard isTopBand && (isMenuLayer || isNamedMenu) else { return nil }
            return MenuBarWindow(ownerName: owner, windowName: name, layer: layer, frame: frame)
        }
        .sorted { $0.frame.minX < $1.frame.minX }
    }

    func candidateApps() -> [CandidateApp] {
        NSWorkspace.shared.runningApplications.compactMap { app in
            guard app.activationPolicy == .accessory || app.activationPolicy == .regular else {
                return nil
            }
            let name = app.localizedName ?? app.bundleIdentifier ?? "Unknown App"
            let bundleIdentifier = app.bundleIdentifier ?? "pid:\(app.processIdentifier)"
            let lowerName = name.lowercased()
            let systemNoise = ["finder", "window server", "dock", "systemuiserver", "notification center"]
            guard !systemNoise.contains(lowerName) else { return nil }
            return CandidateApp(
                name: name,
                bundleIdentifier: bundleIdentifier,
                processIdentifier: app.processIdentifier,
                isRunning: !app.isTerminated,
                activationPolicy: app.activationPolicy,
                icon: app.icon
            )
        }
        .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}

final class AppModel {
    private let scanner = MenuBarScanner()
    private let store = RulesStore()
    private(set) var rules: [String: BarItemRule]
    private(set) var windows: [MenuBarWindow] = []
    private(set) var candidates: [CandidateApp] = []

    init() {
        rules = store.load()
        refresh()
    }

    func refresh() {
        windows = scanner.scanWindows()
        candidates = scanner.candidateApps()
        for app in candidates where rules[app.bundleIdentifier] == nil {
            rules[app.bundleIdentifier] = BarItemRule(
                bundleIdentifier: app.bundleIdentifier,
                displayName: app.name,
                rule: .observeOnly,
                isPinned: false,
                notes: ""
            )
        }
        store.save(rules)
    }

    func updateRule(for bundleIdentifier: String, rule: VisibilityRule) {
        guard var item = rules[bundleIdentifier] else { return }
        item.rule = rule
        rules[bundleIdentifier] = item
        store.save(rules)
    }

    func togglePinned(_ bundleIdentifier: String) {
        guard var item = rules[bundleIdentifier] else { return }
        item.isPinned.toggle()
        rules[bundleIdentifier] = item
        store.save(rules)
    }

    func terminate(_ bundleIdentifier: String) {
        guard let app = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == bundleIdentifier }) else {
            return
        }
        app.terminate()
    }

    func activate(_ bundleIdentifier: String) {
        guard let app = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == bundleIdentifier }) else {
            return
        }
        app.activate()
    }
}

final class MenuBarViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    private let model: AppModel
    private let countLabel = NSTextField(labelWithString: "")
    private let windowLabel = NSTextField(labelWithString: "")
    private let tableView = NSTableView()
    private let scrollView = NSScrollView()
    private let limitationLabel = NSTextField(wrappingLabelWithString: "macOS does not expose a public API to move or hide every third-party menu bar icon. BarLens detects visible menu bar windows, tracks likely status-item apps, and applies the controls macOS allows: observe, pin rules, activate, and quit providers.")
    private var searchField = NSSearchField()
    private var filtered: [CandidateApp] = []

    init(model: AppModel) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 760, height: 560))
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        buildUI()
        reloadData()
    }

    private func buildUI() {
        let title = NSTextField(labelWithString: AppConstants.name)
        title.font = .systemFont(ofSize: 28, weight: .bold)
        title.textColor = .labelColor

        let subtitle = NSTextField(labelWithString: "Menu bar visibility console")
        subtitle.font = .systemFont(ofSize: 13, weight: .medium)
        subtitle.textColor = .secondaryLabelColor

        let refreshButton = NSButton(title: "Refresh", target: self, action: #selector(refresh))
        refreshButton.bezelStyle = .rounded

        let quitHiddenButton = NSButton(title: "Quit Hidden", target: self, action: #selector(quitHiddenProviders))
        quitHiddenButton.bezelStyle = .rounded

        searchField.placeholderString = "Filter apps"
        searchField.target = self
        searchField.action = #selector(searchChanged)

        countLabel.font = .monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        countLabel.textColor = .secondaryLabelColor
        windowLabel.font = .monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        windowLabel.textColor = .secondaryLabelColor

        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let header = NSStackView(views: [title, subtitle, spacer, countLabel, windowLabel, refreshButton, quitHiddenButton])
        header.orientation = .horizontal
        header.alignment = .centerY
        header.spacing = 12

        limitationLabel.font = .systemFont(ofSize: 12)
        limitationLabel.textColor = .secondaryLabelColor
        limitationLabel.maximumNumberOfLines = 3

        configureTable()

        let main = NSStackView(views: [header, searchField, limitationLabel, scrollView])
        main.orientation = .vertical
        main.alignment = .leading
        main.spacing = 12
        main.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(main)

        NSLayoutConstraint.activate([
            main.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 18),
            main.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -18),
            main.topAnchor.constraint(equalTo: view.topAnchor, constant: 18),
            main.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -18),
            header.widthAnchor.constraint(equalTo: main.widthAnchor),
            searchField.widthAnchor.constraint(equalTo: main.widthAnchor),
            limitationLabel.widthAnchor.constraint(equalTo: main.widthAnchor),
            scrollView.widthAnchor.constraint(equalTo: main.widthAnchor),
            scrollView.heightAnchor.constraint(greaterThanOrEqualToConstant: 380)
        ])
    }

    private func configureTable() {
        tableView.usesAlternatingRowBackgroundColors = true
        tableView.rowHeight = 42
        tableView.headerView = NSTableHeaderView()
        tableView.delegate = self
        tableView.dataSource = self

        addColumn("app", title: "App", width: 230)
        addColumn("rule", title: "Rule", width: 170)
        addColumn("status", title: "Status", width: 120)
        addColumn("actions", title: "Actions", width: 210)

        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .lineBorder
    }

    private func addColumn(_ identifier: String, title: String, width: CGFloat) {
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(identifier))
        column.title = title
        column.width = width
        tableView.addTableColumn(column)
    }

    private func reloadData() {
        let query = searchField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if query.isEmpty {
            filtered = model.candidates
        } else {
            filtered = model.candidates.filter {
                $0.name.localizedCaseInsensitiveContains(query)
                    || $0.bundleIdentifier.localizedCaseInsensitiveContains(query)
            }
        }
        countLabel.stringValue = "\(model.candidates.count) providers"
        windowLabel.stringValue = "\(model.windows.count) visible menu windows"
        tableView.reloadData()
    }

    @objc private func refresh() {
        model.refresh()
        reloadData()
    }

    @objc private func searchChanged() {
        reloadData()
    }

    @objc private func quitHiddenProviders() {
        for item in model.rules.values where item.rule == .keepHidden {
            model.terminate(item.bundleIdentifier)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.refresh()
        }
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        filtered.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row < filtered.count, let tableColumn else { return nil }
        let app = filtered[row]
        let rule = model.rules[app.bundleIdentifier]?.rule ?? .observeOnly
        let pinned = model.rules[app.bundleIdentifier]?.isPinned ?? false

        switch tableColumn.identifier.rawValue {
        case "app":
            return appCell(app: app, pinned: pinned)
        case "rule":
            return ruleCell(app: app, rule: rule)
        case "status":
            let text = "\(app.activationPolicy == .accessory ? "menu/helper" : "regular") · pid \(app.processIdentifier)"
            return labelCell(text, color: .secondaryLabelColor)
        case "actions":
            return actionsCell(app: app)
        default:
            return nil
        }
    }

    private func appCell(app: CandidateApp, pinned: Bool) -> NSView {
        let image = NSImageView()
        image.image = app.icon
        image.imageScaling = .scaleProportionallyUpOrDown
        image.translatesAutoresizingMaskIntoConstraints = false
        image.widthAnchor.constraint(equalToConstant: 24).isActive = true
        image.heightAnchor.constraint(equalToConstant: 24).isActive = true

        let name = NSTextField(labelWithString: pinned ? "● \(app.name)" : app.name)
        name.font = .systemFont(ofSize: 13, weight: pinned ? .semibold : .regular)
        name.lineBreakMode = .byTruncatingTail

        let bundle = NSTextField(labelWithString: app.bundleIdentifier)
        bundle.font = .systemFont(ofSize: 10)
        bundle.textColor = .tertiaryLabelColor
        bundle.lineBreakMode = .byTruncatingMiddle

        let text = NSStackView(views: [name, bundle])
        text.orientation = .vertical
        text.spacing = 2

        let stack = NSStackView(views: [image, text])
        stack.orientation = .horizontal
        stack.alignment = .centerY
        stack.spacing = 9
        return stack
    }

    private func ruleCell(app: CandidateApp, rule: VisibilityRule) -> NSView {
        let popup = BundlePopUpButton()
        popup.addItems(withTitles: VisibilityRule.allCases.map(\.rawValue))
        popup.selectItem(withTitle: rule.rawValue)
        popup.target = self
        popup.action = #selector(ruleChanged(_:))
        popup.bundleIdentifier = app.bundleIdentifier
        popup.bezelStyle = .rounded
        return popup
    }

    private func actionsCell(app: CandidateApp) -> NSView {
        let pin = BundleButton(title: "Pin", target: self, action: #selector(pinChanged(_:)))
        pin.bundleIdentifier = app.bundleIdentifier
        pin.bezelStyle = .rounded

        let show = BundleButton(title: "Open", target: self, action: #selector(openProvider(_:)))
        show.bundleIdentifier = app.bundleIdentifier
        show.bezelStyle = .rounded

        let quit = BundleButton(title: "Quit", target: self, action: #selector(quitProvider(_:)))
        quit.bundleIdentifier = app.bundleIdentifier
        quit.bezelStyle = .rounded

        let stack = NSStackView(views: [pin, show, quit])
        stack.orientation = .horizontal
        stack.spacing = 6
        return stack
    }

    private func labelCell(_ text: String, color: NSColor) -> NSView {
        let label = NSTextField(labelWithString: text)
        label.font = .systemFont(ofSize: 12)
        label.textColor = color
        label.lineBreakMode = .byTruncatingTail
        return label
    }

    @objc private func ruleChanged(_ sender: BundlePopUpButton) {
        guard let title = sender.selectedItem?.title,
              let rule = VisibilityRule(rawValue: title) else {
            return
        }
        model.updateRule(for: sender.bundleIdentifier, rule: rule)
        reloadData()
    }

    @objc private func pinChanged(_ sender: BundleButton) {
        model.togglePinned(sender.bundleIdentifier)
        reloadData()
    }

    @objc private func openProvider(_ sender: BundleButton) {
        model.activate(sender.bundleIdentifier)
    }

    @objc private func quitProvider(_ sender: BundleButton) {
        model.terminate(sender.bundleIdentifier)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.refresh()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let model = AppModel()
    private var statusItem: NSStatusItem?
    private var window: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        installStatusItem()
        showWindow(nil)
    }

    private func installStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = "▣"
        item.button?.toolTip = AppConstants.name

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Open BarLens", action: #selector(showWindow(_:)), keyEquivalent: "o"))
        menu.addItem(NSMenuItem(title: "Refresh Scan", action: #selector(refreshScan(_:)), keyEquivalent: "r"))
        menu.addItem(NSMenuItem(title: "Privacy Policy", action: #selector(openPrivacyPolicy(_:)), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Support", action: #selector(openSupport(_:)), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        menu.items.forEach { $0.target = self }
        item.menu = menu
        statusItem = item
    }

    @objc private func showWindow(_ sender: Any?) {
        if window == nil {
            let controller = MenuBarViewController(model: model)
            let newWindow = NSWindow(contentViewController: controller)
            newWindow.title = AppConstants.name
            newWindow.setContentSize(NSSize(width: 760, height: 560))
            newWindow.styleMask = [.titled, .closable, .miniaturizable, .resizable]
            newWindow.isReleasedWhenClosed = false
            window = newWindow
        }
        window?.center()
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func refreshScan(_ sender: Any?) {
        model.refresh()
        showWindow(nil)
    }

    @objc private func openPrivacyPolicy(_ sender: Any?) {
        NSWorkspace.shared.open(AppConstants.privacyURL)
    }

    @objc private func openSupport(_ sender: Any?) {
        NSWorkspace.shared.open(AppConstants.supportURL)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
