# Haneen App Store screenshot review

Six English (Australia) marketing screenshots, created 13 September 2026 for the owner's review. **Not approved or uploaded to App Store Connect.** Open `index.html` for a gallery with full-size inspection, previous/next controls and individual downloads. `overview.png` shows the complete set.

## Upload files, after owner review

All six files in `exports/` are **1242 × 2688**, opaque RGB PNGs, suitable for the portrait iPhone 6.5-inch screenshot slot shown in this app's App Store Connect media manager. These are screenshots, not video app previews. Do not upload the contact sheet, raw captures, HTML or illustration assets.

| Order | Export | Source |
| --- | --- | --- |
| 1 | `01-daily-companion.png` | Original `../en-AU/01-home.png` |
| 2 | `02-quran.png` | Original `../en-AU/02-quran.png` |
| 3 | `03-feelings.png` | Original `../en-AU/07-all-feelings.png` |
| 4 | `04-dhikr.png` | Original `../en-AU/04-morning-adhkar-dark.png` |
| 5 | `05-prayer.png` | Original `../en-AU/05-prayer-times.png` |
| 6 | `06-widgets.png` | Three intact widget previews clipped from `../en-AU/06-widget-collection.png` |

## Design and fidelity

The reference was Chris Raroque's [Ellie Daily Planner listing](https://apps.apple.com/us/app/ellie-daily-planner/id1602196200): short benefit headlines above prominent real screens, with restrained decorative artwork. Haneen's wording, palette, illustrations and layouts are its own; no Ellie artwork, typography assets or screenshots were incorporated.

Cream `#FCF3E3`, muted olive and one forest-green panel follow the existing app. The approved Simple Companion logo is used for the small brand lockup. The prayer illustration is the app's existing morning artwork.

`assets/peek-companion.png` is a newly generated transparent illustration matching the app's cream cat, dark eye patch and olive scarf. It is decorative art outside the captured UI. Generated using the built-in image tool with `Companion-widgetEvening` as character/style reference. The original generation is retained in the Codex generated-images directory, and the project copy is included here.

App screens are original simulator PNGs placed by HTML/CSS. No scripture, translation, source citation, progress, prayer time or interface element was AI-generated or redrawn. The full Al-Fatihah passage and the complete shown dhikr reward/citation remain visible. On the larger Home/Feelings/Prayer layouts, the bottom of the physical phone continues beyond the canvas. Widget cards use the shipping chooser's own sample values; they are not a claimed live personal schedule. See the raw-source README for capture conditions.

## Rebuild

`node AppStore/Screenshots/Marketing-2026-09-13/render.mjs`

The renderer uses Playwright with the bundled local Chromium. Override `PLAYWRIGHT_MODULE` and `CHROMIUM_PATH` for another machine. It exports the six files from native HTML at 3× resolution, generates the overview, and checks that the review gallery opens and advances between images. Fonts are the macOS system sans-serif; render on macOS for the approved typography. Re-run after updating a source capture.

Checked: image dimensions, opaque RGB output, all images decode, six layouts inspected, headline fit, Qur’an/reward text visibility, clean widget crop, gallery controls. App Store submission remains separate from this review.
