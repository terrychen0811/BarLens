# App Store Submission Guide

This repository is ready for the App Store preparation stage, but final upload requires a paid Apple Developer account and full Xcode.

## Current app identity

- Product name: BarLens
- Bundle ID: `com.terrychen0811.BarLens`
- Category: Utilities
- Minimum macOS: 14.0
- Sandbox: enabled in `Resources/BarLens.entitlements`
- Privacy manifest: `Resources/PrivacyInfo.xcprivacy`
- Privacy policy: `https://github.com/terrychen0811/BarLens/blob/main/PRIVACY.md`

## Local validation build

```sh
make clean package VERSION=0.2.0
```

This creates a local ad-hoc signed zip at:

```text
.build/release/BarLens-0.2.0-macOS.zip
```

This zip is for GitHub/manual testing, not App Store upload.

## App Store build path

1. Install full Xcode 26 or later.
2. Create an Apple Developer app identifier for `com.terrychen0811.BarLens`.
3. Create a macOS app record in App Store Connect.
4. Open the project in Xcode or create a macOS App target that uses:
   - `Sources/BarLens/main.swift`
   - `Resources/Info.plist`
   - `Resources/BarLens.entitlements`
   - `Resources/PrivacyInfo.xcprivacy`
   - `Resources/AppIcon.icns`
5. Set Signing & Capabilities to your Apple Developer team.
6. Archive the app with Product > Archive.
7. Upload from Organizer to App Store Connect.
8. Fill in the metadata from `AppStore/metadata.md`.
9. Fill in privacy answers from `AppStore/privacy-answers.md`.
10. Add real screenshots captured from the signed app.
11. Submit for App Review with notes from `AppStore/review-notes.md`.

## Important limitation to disclose

BarLens uses public macOS APIs. It does not claim to forcibly move or hide every third-party menu bar icon because macOS does not expose that as a public API.
