# SolixMenu

A lightweight macOS menu bar app for monitoring Anker Solix devices.

## Features
- Menu bar status with per-device battery and power details
- Account settings UI for login/logout
- About dialog
- English/Japanese localization

## Requirements
- macOS 26 or later
- Apple Silicon (arm64)

## Build
Open `SolixMenu.xcodeproj` in Xcode and build the `SolixMenu` scheme.

## Usage
1. Launch the app (it runs as a menu bar accessory).
2. Click the menu bar icon to view device status.
3. Open **Account Settings…** to log in or update credentials.
4. Use **About** for app info, **Quit** to exit.

## Localization
- Japanese (`ja`) uses the Japanese strings.
- All other locales use English.

## Limitations
- Requires valid Anker Solix credentials and network access.
- Device availability depends on the Anker Solix APIs and your account.
- No official affiliation with Anker.

## License
MIT (see `LICENSE`).