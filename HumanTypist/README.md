# Human Typist

A macOS menu bar app that types clipboard text into any text field with human-like timing.

## Requirements

- macOS
- Xcode (for building)
- Accessibility permission (required for keyboard simulation)

## Build

```bash
cd HumanTypist
xcodebuild -project HumanTypist.xcodeproj -scheme HumanTypist -configuration Debug build
```

The built app is at:
```
~/Library/Developer/Xcode/DerivedData/HumanTypist-*/Build/Products/Debug/HumanTypist.app
```

## Run

```bash
~/Library/Developer/Xcode/DerivedData/HumanTypist-*/Build/Products/Debug/HumanTypist.app/Contents/MacOS/HumanTypist 2>&1 &
```

## View Logs

```bash
# Filter HumanTypist logs
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
4. Press **Ctrl+Option+R** to reload (re-read clipboard on next start)

## Development

### Generate Xcode Project

If `project.yml` changes, regenerate with:

```bash
cd HumanTypist
xcodegen generate
```

### Run Tests

```bash
xcodebuild -project HumanTypist.xcodeproj -scheme HumanTypistTests -configuration Debug test
```
