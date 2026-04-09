# Human Typist

A macOS menu bar app that types clipboard text into any text field with human-like timing.

## Requirements

- macOS
- Xcode (for building)
- Accessibility permission (required for keyboard simulation)

## Build

```bash
xcodebuild -project HumanTypist/HumanTypist.xcodeproj -scheme HumanTypist -configuration Release build
```

The built app is at:
```
~/Library/Developer/Xcode/DerivedData/HumanTypist-*/Build/Products/Release/HumanTypist.app
```

## Run

```bash
~/Library/Developer/Xcode/DerivedData/HumanTypist-*/Build/Products/Release/HumanTypist.app/Contents/MacOS/HumanTypist 2>&1 &
```

## View Logs

```bash
log show --predicate 'process == "HumanTypist"' --style compact
```

Or open **Console.app** and filter for "HumanTypist".

## Accessibility Permission

On first run, the app will prompt for Accessibility permission. If denied:

```bash
sudo tccutil reset Accessibility
```

Then re-launch the app.

## Usage

1. Copy text to clipboard
2. Press **Ctrl+Option+P** — countdown begins, then typing starts
3. Press **Ctrl+Option+S** to stop at any time

## Development

### Generate Xcode Project

If `project.yml` changes, regenerate with:

```bash
cd HumanTypist && xcodegen generate
```

### Run Tests

```bash
xcodebuild -project HumanTypist/HumanTypist.xcodeproj -scheme HumanTypistTests -configuration Debug test
```
