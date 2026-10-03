# Display Presets

Menu bar utility for macOS that saves and switches display arrangements
(position of the laptop screen relative to external monitors) in one click.

## Build & install

```bash
./build.sh            # builds build/Display Presets.app
./build.sh --install  # also copies it to /Applications and launches it
```

Requires macOS 13+ and Xcode command line tools.

## Usage

1. Arrange displays in System Settings → Displays.
2. Menu bar icon → **Save Current Arrangement…** → give it a name.
3. Repeat for each scenario. Switch by clicking a preset or with global hotkeys.

### Global hotkeys (work anywhere, no permissions needed)

| Keys      | Action                                   |
|-----------|------------------------------------------|
| ⌃⌥⌘1…9    | Apply preset #1…9 (order in the menu)    |
| ⌃⌥⌘0      | Next available preset (cycle)            |

A beep means the preset needs a display that is not connected.

### Auto-apply on connect

Menu → **Auto-apply on Connect** → pick a preset (marked ⚡︎). It is applied
automatically ~2 s after exactly that set of displays becomes connected
(e.g. plugging in the monitor or opening the lid). One per display set.

### Keep Mac Awake

Menu → **Keep Mac Awake** stops the Mac and its displays from sleeping while
idle. While it is on, the menu bar icon changes to a cup. The setting is
remembered across restarts. Closing the lid with no external display connected
still puts the Mac to sleep.

### Menu

- Each preset shows a miniature of its arrangement: the built-in display is
  filled, external ones are outlined, a bar along the top marks the main display.
- ✓ marks the preset matching the current arrangement.
- Greyed-out presets need a display that is not connected.
- **Launch at Login** works when the app runs from /Applications.

Presets are stored in `~/Library/Application Support/DisplayPresets/presets.json`.
Displays are matched by UUID, so presets survive reconnects.

## CLI

For Shortcuts, Raycast or hotkey tools:

```bash
B="/Applications/Display Presets.app/Contents/MacOS/DisplayPresets"
"$B" list | current | save <name> | apply <name>
```
