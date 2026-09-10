# Companion artwork throughout Yaqeen

The approved collection-art checkpoint is commit `100d83d`. This pass continues that character, palette, and dry pencil medium with 38 individually generated illustrations. There are now 53 illustrations in `Shared/CompanionAssets.xcassets`, bundled into both the app and widget extension.

The new drawings cover feelings, life groups, prayer times, Qibla, support, saved readings, journaling, privacy, and settings. Related emotions share a drawing when that makes sense, while their native text labels remain distinct. Life group rows, reader introductions, the heart log, breathing pause, navigation tabs, empty states, and prayer cards use the same library. Small functional controls such as back, close, search, playback, and confirmation remain native controls with familiar symbols.

Home Screen widgets use the app's white surfaces, green labels, system typography, and pencil artwork. Dark mode uses the app's dark surfaces with small paper backings to keep charcoal artwork visible. Daily and pinned widgets retain their existing timelines and situation deep links. Prayer timelines, expiry handling, location privacy, and prayer deep links are unchanged. Lock Screen accessories retain their system-controlled monochrome rendering and compact time layout, with typography aligned to the app.

Every illustration was made with the built-in `image_gen.imagegen` tool, using the approved original character reference. `art-plan.json` records the scenes and style. `generation.json` records all prompts and source files. PNG exports use only a 384-pixel resize with `sips`; no programmatically drawn substitutes or third-party artwork were added.

The reference research and its access limitations remain documented in `../CompanionArtwork/DesignNotes.md`. This pass follows the user's approved visual direction. The latest eight attached screenshots were unavailable at their supplied paths; the app itself was inspected instead.

## Verification

- App and widget extension build successfully for the iPhone 17 simulator on iOS 26.5, with no compiler warnings in the final build.
- Existing unit suite: 29 tests pass, zero failures. This covers content integrity, readings, saved-state behavior, Qibla calculations, and scholar content handling.
- All 53 artwork enum values resolve to image sets containing an exported PNG.
- Visually reviewed Home, Explore, feelings, Arabic feelings in dark mode, and the shared production widget card views in both appearances.
- Verified that tapping Family & Parenthood opens the intended topic.
- At the largest accessibility text size, feeling section headings now stack vertically so the title and subtitle do not squeeze each other.
- Widget screenshots are from the debug gallery, which renders the same shared card views used by the extension at small and medium widget dimensions. They are not SpringBoard screenshots. WidgetKit timeline delivery and Home Screen tint customization were not visually exercised.

Run the debug app with `-yqWidgetGallery` to review the widget card views. This gallery is excluded from release builds. Existing `-yqScreen` routes remain available for app screenshots.
