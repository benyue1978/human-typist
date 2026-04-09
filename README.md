# Human Typist

A macOS menu bar app that types clipboard text into any text field with human-like timing.

## Requirements

- macOS
- Xcode (for building from source)
- Accessibility permission (required for keyboard simulation)

## Installation

1. Download `HumanTypist-x.x.x.zip` from the [latest release](https://github.com/benyue1978/human-typist/releases/latest)
2. Unzip the archive
3. Move `HumanTypist.app` to `/Applications`
4. Remove the quarantine attribute so macOS doesn't block the app:
   ```bash
   xattr -d com.apple.quarantine /Applications/HumanTypist.app
   ```
5. Open `HumanTypist.app` from `/Applications`

If macOS still shows a warning about moving to trash, run the xattr command again and try.

## Build from Source

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
