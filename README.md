# BarChaneg

BarChaneg is a native macOS menu bar utility prototype for tracking and managing apps that may provide menu bar icons.

It was built as a small systems/UI project exploring the boundary between public macOS APIs and the private behavior used by full menu bar managers.

## What it can do

- Show a menu bar app of its own.
- Scan visible top menu bar windows through `CGWindowList`.
- List running regular/accessory apps that are likely menu bar icon providers.
- Save per-app visibility rules:
  - Always Show
  - Hide When Inactive
  - Keep Hidden
  - Observe Only
- Pin providers in the list.
- Activate or quit provider apps. Quitting a provider is the public macOS-safe way to remove many third-party menu bar icons.

## Install from release

1. Download `BarChaneg-0.1.0-macOS.zip` from GitHub Releases.
2. Unzip it.
3. Open `BarChaneg.app`.

The release is ad-hoc signed, not Apple-notarized. macOS may require right-clicking the app and choosing Open the first time.

## macOS limitation

macOS does not provide a public API that lets one app freely move, hide, or reveal every other app's `NSStatusItem`. Tools that fully rearrange third-party menu bar icons typically depend on private behavior, Accessibility permissions, Screen Recording, or fragile visual automation.

This app keeps that boundary explicit: it detects what public APIs expose, stores your intended rules, and performs the controls macOS permits.

## Run

Recommended in this Command Line Tools setup:

```sh
make run
```

If SwiftPM is working on your machine, this also works:

```sh
swift run
```

The app opens a window and adds a small `▣` item to the macOS menu bar.

## Build a release zip

```sh
make package VERSION=0.1.0
```

The zip is written to `.build/release/`.

## Privacy

See [PRIVACY.md](PRIVACY.md).
