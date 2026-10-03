# Graph Report - arrange-displays-presets  (2026-10-03)

## Corpus Check
- 11 files · ~2,791 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 111 nodes · 206 edges · 11 communities (7 shown, 4 thin omitted)
- Extraction: 89% EXTRACTED · 11% INFERRED · 0% AMBIGUOUS · INFERRED: 23 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `37a8542b`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- [[_COMMUNITY_MenuBarController|MenuBarController]]
- [[_COMMUNITY_Preset|Preset]]
- [[_COMMUNITY_.connected|.connected]]
- [[_COMMUNITY_HotKeys|HotKeys]]
- [[_COMMUNITY_Usage|Usage]]
- [[_COMMUNITY_DisplayWatcher|DisplayWatcher]]
- [[_COMMUNITY_.run|.run]]
- [[_COMMUNITY_KeepAwake|KeepAwake]]
- [[_COMMUNITY_AppKit|AppKit]]
- [[_COMMUNITY_build.sh|build.sh]]
- [[_COMMUNITY_Package.swift|Package.swift]]

## God Nodes (most connected - your core abstractions)
1. `MenuBarController` - 24 edges
2. `Preset` - 18 edges
3. `PresetStore` - 15 edges
4. `HotKeys` - 10 edges
5. `ConnectedDisplay` - 9 edges
6. `DisplayPlacement` - 9 edges
7. `DisplayWatcher` - 8 edges
8. `KeepAwake` - 7 edges
9. `DisplayError` - 6 edges
10. `Displays` - 5 edges

## Surprising Connections (you probably didn't know these)
- `MenuBarController` --calls--> `KeepAwake`  [INFERRED]
  Sources/DisplayPresets/MenuBarController.swift → Sources/DisplayPresets/KeepAwake.swift
- `MenuBarController` --calls--> `PresetStore`  [INFERRED]
  Sources/DisplayPresets/MenuBarController.swift → Sources/DisplayPresets/PresetStore.swift
- `MenuBarController` --references--> `DisplayWatcher`  [EXTRACTED]
  Sources/DisplayPresets/MenuBarController.swift → Sources/DisplayPresets/DisplayWatcher.swift
- `MenuBarController` --references--> `HotKeys`  [EXTRACTED]
  Sources/DisplayPresets/MenuBarController.swift → Sources/DisplayPresets/HotKeys.swift

## Import Cycles
- None detected.

## Communities (11 total, 4 thin omitted)

### Community 0 - "MenuBarController"
Cohesion: 0.17
Nodes (9): Error, NSEvent, NSMenu, NSMenuDelegate, NSMenuItem, NSObject, MenuBarController, String (+1 more)

### Community 1 - "Preset"
Cohesion: 0.23
Nodes (10): Codable, Equatable, Set, DisplayPlacement, Preset, PresetStore, Bool, Int32 (+2 more)

### Community 2 - ".connected"
Cohesion: 0.22
Nodes (11): CGDirectDisplayID, CGError, CGPoint, LocalizedError, ConnectedDisplay, DisplayError, cg, missingDisplays (+3 more)

### Community 3 - "HotKeys"
Cohesion: 0.25
Nodes (6): Carbon.HIToolbox, EventHandlerRef, EventHotKeyRef, HotKeys, UInt32, Void

### Community 4 - "Usage"
Cohesion: 0.22
Nodes (8): Auto-apply on connect, Build & install, CLI, Display Presets, Global hotkeys (work anywhere, no permissions needed), Keep Mac Awake, Menu, Usage

### Community 5 - "DisplayWatcher"
Cohesion: 0.32
Nodes (4): CoreGraphics, DispatchWorkItem, DisplayWatcher, Void

### Community 6 - ".run"
Cohesion: 0.25
Nodes (5): Foundation, IOKit.pwr_mgt, CLI, Int32, String

## Knowledge Gaps
- **11 isolated node(s):** `PackageDescription`, `Carbon.HIToolbox`, `IOKit.pwr_mgt`, `ServiceManagement`, `build.sh script` (+6 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **4 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `MenuBarController` connect `MenuBarController` to `Preset`, `HotKeys`, `DisplayWatcher`, `KeepAwake`, `AppKit`?**
  _High betweenness centrality (0.391) - this node is a cross-community bridge._
- **Why does `PresetStore` connect `Preset` to `MenuBarController`, `.run`?**
  _High betweenness centrality (0.142) - this node is a cross-community bridge._
- **Why does `HotKeys` connect `HotKeys` to `MenuBarController`?**
  _High betweenness centrality (0.125) - this node is a cross-community bridge._
- **Are the 2 inferred relationships involving `MenuBarController` (e.g. with `KeepAwake` and `PresetStore`) actually correct?**
  _`MenuBarController` has 2 INFERRED edges - model-reasoned connections that need verification._
- **Are the 2 inferred relationships involving `Preset` (e.g. with `.remove()` and `.toggleAutoApply()`) actually correct?**
  _`Preset` has 2 INFERRED edges - model-reasoned connections that need verification._
- **Are the 4 inferred relationships involving `PresetStore` (e.g. with `.run()` and `MenuBarController`) actually correct?**
  _`PresetStore` has 4 INFERRED edges - model-reasoned connections that need verification._
- **What connects `PackageDescription`, `Carbon.HIToolbox`, `IOKit.pwr_mgt` to the rest of the system?**
  _11 weakly-connected nodes found - possible documentation gaps or missing edges._