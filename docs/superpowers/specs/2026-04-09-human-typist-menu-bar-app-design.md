# Human Typist — macOS Menu Bar App

## Overview

A menu bar-only macOS app that simulates realistic human typing into any focused text field. Based on the Python script `GPTZeroBypass.py`, ported to native macOS.

## Architecture

### App Type
- **Menu bar agent** — runs as `LSUIElement` (no Dock icon)
- **Floating panel** — NSWindow with tabbed settings, shown on menu bar icon click

### Core Components

```
HumanTypist/
├── App/
│   ├── main.swift              # NSApplication entry point
│   ├── AppDelegate.swift       # Menu bar setup, app lifecycle
│   └── Info.plist              # LSUIElement=true, login item
├── UI/
│   ├── StatusBarController.swift   # NSStatusItem + panel toggle
│   ├── TypingPanel.swift           # NSPanel (floating, non-activating)
│   ├── GeneralTab.swift           # Start on login toggle, etc.
│   ├── ShortcutsTab.swift          # Hotkey configuration
│   └── TypingParamsTab.swift       # WPM, pauses, burst settings
├── Core/
│   ├── TypingEngine.swift          # CGEvent keyboard simulation
│   ├── HotkeyManager.swift         # Carbon RegisterEventHotKey
│   ├── ClipboardMonitor.swift      # Poll pasteboard for new text
│   └── Preferences.swift           # UserDefaults wrapper
└── Resources/
    └── Assets.xcassets
```

## Features

### Typing Engine
- **CGEvent-based keystroke injection** — creates keyboard events at the Quartz event level, same mechanism as hardware typing. No special permissions required.
- **Configurable WPM** with per-burst randomization (like the Python script)
- **Character-level delays** with jitter
- **Punctuation pauses** — longer delay after `,;:`
- **Sentence-end pauses** — longer delay after `.!?`
- **Random micro-pauses** — small chance of hesitation
- **Rare "thinking" pauses** — occasional multi-second pause
- **Burst model** — types in variable-speed bursts, mimics natural typing patterns

### Global Hotkeys (Carbon)
- **Ctrl+Alt+P** — Start typing from clipboard
- **Ctrl+Alt+S** — Stop typing immediately
- **Ctrl+Alt+R** — Reload text from clipboard

Raw Carbon `RegisterEventHotKey` — no external dependencies. Falls back to synthetic key events if needed.

### Clipboard Integration
- On hotkey trigger, read current clipboard contents
- Type it character-by-character with human-like timing
- If clipboard changes while typing, reload on next trigger

### Preferences (UserDefaults)
| Key | Type | Default |
|-----|------|---------|
| `wpmMin` | Int | 25 |
| `wpmMax` | Int | 90 |
| `burstSecondsMin` | Double | 1.0 |
| `burstSecondsMax` | Double | 6.0 |
| `charJitterMin` | Double | 0.0 |
| `charJitterMax` | Double | 0.08 |
| `pauseAfterPunct` | (Double, Double) | (0.08, 0.70) |
| `pauseAfterSentence` | (Double, Double) | (0.25, 1.0) |
| `randomPauseChance` | Double | 0.06 |
| `thinkingPauseChance` | Double | 0.008 |
| `thinkingPauseMin` | Double | 4.5 |
| `thinkingPauseMax` | Double | 8.0 |
| `startAtLogin` | Bool | false |

### Login Item
- `SMAppService.mainApp` (macOS 13+) for login item registration
- Graceful fallback via `LSSharedFileList` on older OS

## UI Design

### Status Bar
- Menu bar icon (keyboard symbol or custom)
- Click toggles floating panel

### Floating Panel (NSPanel)
- **General tab**: Start at login toggle, Quit button
- **Shortcuts tab**: Display current hotkeys (read-only, no rebinding in v1)
- **Typing Params tab**: Sliders/fields for all typing parameters

Tabs via `NSTabView` inside the panel. Panel is non-activating, floating, dismisses on click-outside.

## Technical Notes

### CGEvent Key Injection
```swift
// Pseudocode for typing a character
let source = CGEventSource(stateID: .hidSystemState)
let keyDown = CGEvent(keyboardEventSource: source, virtualKey: vk, keyDown: true)
let keyUp = CGEvent(keyboardEventSource: source, virtualKey: vk, keyDown: false)
keyDown?.post(tap: .cghidEventTap)
keyUp?.post(tap: .cghidEventTap)
```
Special keys (Enter, Space, etc.) map to different virtual key codes. Printable characters require `CGKeyboardSetUnicodeString`.

### Threading
- Typing runs on a **background thread** with `Thread.detachNewThread`
- `stopEvent` flag checked between characters for interruptibility
- UI updates dispatched to main thread via `DispatchQueue.main`

### No External Dependencies
- Pure AppKit + Carbon + CGEvent
- No CocoaPods, no SPM packages (except Apple's frameworks)
- Keyboard symbols via SF Symbols or simple drawn icon

## Scope (v1)
- Menu bar app with floating panel
- Global hotkeys via Carbon
- CGEvent-based typing engine
- Clipboard as text source
- All typing parameters configurable via panel
- Start at login

## Out of Scope (Future)
- Google Docs-specific formatting
- Multiple text sources (file, etc.)
- Hotkey rebinding UI
- Multiple languages/keyboard layouts
