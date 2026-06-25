# App Review Notes

BarLens is a macOS utility that inspects public menu bar/window metadata and helps users organize likely menu bar icon providers.

Important review context:

- The app does not claim to move or forcibly hide every third-party menu bar icon.
- Apple does not expose a public API for full third-party `NSStatusItem` control, so BarLens uses public APIs and local user rules.
- User data is not collected, transmitted, tracked, or sold.
- Privacy Policy is available in the app's menu and in App Store Connect metadata.
- The app is sandboxed for Mac App Store distribution.

Suggested test path:

1. Launch BarLens.
2. Open the `▣` menu bar item.
3. Choose Refresh Scan.
4. Change a provider rule in the table.
5. Quit and relaunch the app to confirm the local rule persists.
