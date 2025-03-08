# Hide XQuartz From Dock

A simple bash script to hide or show XQuartz from the macOS dock.

## Features

- Hide XQuartz from the dock while keeping it running
- Automatic backup of original settings
- Safe restoration from backup

## Usage

Simply double-click `hide_xquartz_from_dock.command`

## How it Works

The script modifies XQuartz's `Info.plist` file by adding the `LSUIElement` key, which tells macOS to run XQuartz as an agent application (without a dock icon). Before making any changes, it creates a timestamped backup of the original `Info.plist` file.
