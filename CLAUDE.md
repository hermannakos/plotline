# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository layout

Two clients share one data file:

- `universes.json` — **single source of truth** for all universe content. Both clients fetch from `https://hermannakos.github.io/plotline/universes.json` so adding/editing entries does not require shipping either client. Generated originally from the inline JS literal that used to live in `index.html`.
- `index.html` — GitHub Pages site. Single self-contained file, no build step. Loads `universes.json` at runtime via `fetch("./universes.json")` inside the `App` component.
- `iOS/Plotline/` — Xcode SwiftUI + SwiftData app. Same data, same design language, native UI.
- `.nojekyll` — required so GitHub Pages serves `index.html` as-is.
- `firebase-debug.log` — incidental log from an unrelated CLI session in the parent directory; not part of the project.

## Web app (`index.html`)

### Run / develop

There is no build, no package manager, no toolchain. To preview locally, just open the file (`open index.html`) or serve the directory (`python3 -m http.server`). React 18 and `@babel/standalone` are loaded from unpkg; the single `<script type="text/babel">` block at the bottom is transpiled in the browser. This means **edits are live on refresh** but also that JSX runtime errors only surface at runtime in the console — there is no type checker or linter.

### Deploy

Push to `main`. GitHub Pages serves the root of the branch. There is no CI.

### Data model (the load-bearing piece)

All content lives in `universes.json` at the repo root, keyed by universe id: `mcu`, `dceu`, `monsterverse`, `starwars`, `arrowverse`. Each universe has `entries: []` where each entry is one of three shapes:

- `type: "Movie"` — `{ id, title, year, type, phase }`
- `type: "Series"` — adds `episodes: <int>` (per-episode watched state is tracked individually)
- `type: "Crossover"` — adds `show` and optional `note`. Used by Arrowverse to interleave multi-show events into a single chronological list. Crossover entries set `show: "CROSSOVER"` and the Arrowverse universe defines a `showColors` map for per-show coloring of regular entries.

`phase` is a free-form string ("Phase 1", "Era 2", "Crisis on Infinite Earths (2019–2020)", etc.). `groupByPhase` preserves insertion order, so **entry order in the array is the watch order** — both within a phase and across phases. Adding new entries: append/insert in the chronological position you want them displayed; do not sort.

Entry `id`s are persistence keys (see below). They must be globally unique within a universe and **must never change** for already-shipped entries, or users will lose their watched state. Convention: `<universe>_<n>` for movies/series, `<universe>_xo_<n>[a|b|c…]` for crossover parts.

### Persistence

State is per-browser, stored in `localStorage` under `plotline_watched_<universeId>` as a JSON array of marker strings:

- For Movies / Crossovers: the entry `id` is in the set when watched.
- For Series: each episode is tracked as `${entry.id}_ep_${n}` (1-indexed). The whole-series checkbox is derived (`isSeriesWatched`) — toggling it adds/removes all episode keys. There is no separate "series watched" key.

`getUpNext` walks `entries` in order and returns the first incomplete item (first unwatched movie/crossover, or first unwatched episode of an in-progress series). Order in the data dictates "Up Next" — keep that in mind when reordering.

### UI structure

- `App` — top-level state (active universe, per-universe watched sets, "jump to" expand id).
- `UpNextCard` — the prominent card derived from `getUpNext`.
- `EntryCard` — handles Movie / Series (expands to per-episode checklist) / Crossover styling. CSS custom properties (`--universe-color`, `--show-color`) drive theming; per-show coloring is opt-in via `universe.showColors[entry.show]`.

## iOS app (`iOS/Plotline/`)

Open `iOS/Plotline/Plotline.xcodeproj` in Xcode (objectVersion 77, file-system synchronized groups — drop new `.swift` files into `Plotline/Plotline/` and Xcode picks them up automatically; no pbxproj editing needed).

- Build / run: ⌘R (default scheme `Plotline`). CLI: `xcodebuild -project iOS/Plotline/Plotline.xcodeproj -scheme Plotline -destination 'generic/platform=iOS Simulator' build`.
- Tests: ⌘U. Single test: `xcodebuild test -project iOS/Plotline/Plotline.xcodeproj -scheme Plotline -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:PlotlineTests/PlotlineTests/<testName>`.

### Architecture

Targets iOS 26+ / Swift 5 with `default-isolation=MainActor`. The app uses `@Observable` state holders (no `ObservableObject`).

- `Models.swift` — `Universe` / `Entry` (Codable, decoded from `universes.json`) and the SwiftData `WatchedMarker` model. The `Entry.Kind` raw values match the JSON strings (`"Movie" | "Series" | "Crossover"`).
- `UniverseStore` — fetches `universes.json` with a Caches-directory fallback so the app opens offline after first launch. Reorders the decoded dictionary to the canonical web order (`mcu, dceu, monsterverse, starwars, arrowverse`).
- `WatchedStore` — wraps `ModelContext` for `WatchedMarker` reads/writes plus an in-memory `Set<String>` lookup. Marker keys deliberately match the web's localStorage scheme (`<entryId>` for movies/crossovers, `<entryId>_ep_<n>` for series episodes) so the conceptual model stays identical across clients. Implements the same helpers as the web (`isSeriesWatched`, `watchedEpisodeCount`, `upNext`, `toggleEntry`, `toggleEpisode`).
- `Theme.swift` — central palette (`Theme.bg`, `Theme.surface`, etc.) mirroring the web CSS variables, plus a `Color.fromHex(_:)` extension. **Do not name it `Color(hex:)`** — that collides with an iOS 26 SDK initializer and produces misleading SourceKit errors.
- `Components.swift` / `ContentView.swift` — the SwiftUI views (universe pills, progress + stats, Up Next card, expandable entry rows with per-episode grid).

SwiftData container is configured in `PlotlineApp.swift` for `WatchedMarker.self` only; on-device persistence, no CloudKit.

### Cross-file SourceKit warnings during edits

When adding or renaming Swift files, SourceKit often emits transient "Cannot find type X in scope" diagnostics for cross-file references that aren't real. Verify with an actual `xcodebuild ... build` before chasing them.
