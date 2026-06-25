# Mac App Store Release Checklist

## Apple account

- Enroll in the Apple Developer Program.
- Accept current Apple Developer and App Store Connect agreements.
- Create the app record in App Store Connect using bundle ID `com.terrychen0811.BarLens`.

## Build requirements

- Use full Xcode, not Command Line Tools only.
- As of April 28, 2026, Apple says uploads to App Store Connect need to be built with Xcode 26 Release Candidate or later and the latest SDK.
- Archive with Mac App Store signing, not ad-hoc signing.
- Confirm the app remains sandboxed with `com.apple.security.app-sandbox`.

## App Store Connect metadata

- Name: BarLens
- Subtitle: Inspect your Mac menu bar
- Category: Utilities
- Age rating: 4+
- Privacy Policy URL: `https://github.com/terrychen0811/BarLens/blob/main/PRIVACY.md`
- Support URL: `https://github.com/terrychen0811/BarLens/issues`
- Privacy answers: App does not collect data.

## Assets

- App icon: `Resources/AppIcon.icns`
- Screenshots: capture from a real macOS run after installing the signed build.
- Optional app preview video: not required for first submission.

## Final validation

- Build and run locally.
- Verify privacy and support menu links.
- Verify app persists rules after relaunch.
- Upload through Xcode Organizer or Transporter.
