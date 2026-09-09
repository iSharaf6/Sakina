# Yaqeen: moments, not a wellness template

The original `concept.png` was rejected. It is historical exploration, not the implementation specification. The revised UI keeps Yaqeen’s existing geometric book/path mark, forest and ivory palette, native sans-serif typography, Arabic reading font, and reviewed religious catalog.

## References inspected

- Chris Raroque, [How I Make Apps FEEL 10x Better](https://www.youtube.com/watch?v=8mMH6Pq8qnE): read the first-party transcript; studied his breakdown of composed transitions, custom visual identity, haptics, and consistent thin/filled icon states.
- [Luna](https://lunabudgeting.com/): inspected the actual app examples, compact type, consistent icon weights, and manual entry flow.
- [Stoic’s morning homepage on Mobbin](https://mobbin.com/explore/screens/839dd8c6-fd52-486a-a599-39f5242de9ba): inspected the public screenshot for a focused primary action and restrained supporting navigation. Full Mobbin library was sign-in gated.
- The existing Yaqeen Home and Explore screens were built and inspected on iPhone 17 Pro before implementation.

## Decisions

- A conversational Home leads with a feeling, then offers a relevant du’a. Search routes to existing reviewed guidance; it does not simulate generated theological advice.
- The mood rail uses plain words and a moving underline. Colored symbol chips and decorative icon discs from the rejected concept are removed.
- A small folio of tilted leaves uses the existing Yaqeen mark as its artwork. Tapping opens a real reader. Reduced Motion removes the tilt and movement.
- Heroicons 2.2.0 is bundled as template vectors. New interface controls use the same 24-unit, 1.5-unit outline family, with filled variants only for selected tabs/bookmarks. License is in `Sakina/Resources/Heroicons-LICENSE.txt`.
- Home, Explore, Du’as, Saved are primary tabs. Settings is reached from Home’s header. Qibla remains on Home and its existing deep link/App Intent still opens it.
- Favorites use stable reviewed catalog IDs in local UserDefaults and are available in both Du’as and Saved. These new favorites are local to the device, separate from the existing optional Google backup of situations and reflections.
- Reading preserves Arabic, meaning, transliteration preferences, canonical source links, excerpt metadata, contextual notes, and cautions. No source texts were rewritten.
- A finite optional breathing pause uses the locally bundled forest photo. Its 4/6 rhythm is not presented as a religious prescription. No network, audio stream, tracking, score, streak, or notification permission is needed.

## Motion specification

- Press: 0.975 scale, spring response 0.25 s, damping 0.78.
- Mood selection: moving underline and scroll centering, spring response 0.36 s, damping 0.85; light selection feedback.
- Related du’a: 9 pt entry movement plus opacity, following the selected mood.
- Reader: native card-to-reader zoom on iOS 18+, with a standard navigation fallback on iOS 17 and with Reduce Motion.
- Saved state: outline to filled bookmark, 1.08 scale, 0.3 s spring; success feedback.
- Reading disclosures: expansion with 0.35 s damped spring.
- Breathing: bounded three cycles, 4 s inhale / 6 s exhale, with task cancellation when inactive or dismissed. Reduced Motion retains phase text and a static ring.

## Validation and actual app previews

- Built and ran the native app on iPhone 17 Pro / iOS 26.5. Final build passed after the last presentation and search-label refinements.
- The full XCTest suite passed: 23 tests, 0 failures. This includes reviewed Quran integrity checks and four new tests for mood references, bilingual/source/mood search, saved IDs, and combined filtering.
- Exercised Home mood selection, card-to-reader navigation, transliteration disclosure, persistent saves, Saved → Du’as, mood search, Home → Explore search, Settings and prayer sheets, and Qibla/du’a deep links.
- Visually checked Arabic reading, dark appearance, and accessibility extra-large text. Checked the three-cycle breathing completion and the final full-screen presentation. Haptics still need a physical-device feel check.
- Cached immutable guidance search documents. The existing semantic-search XCTest ran in 2.794 s after caching versus 12.597 s before. This is a test-runtime comparison, not a measurement of keystroke latency.
- `home.png`, `duas.png`, `reader.png`, and `breathing.png` are screenshots of the running app. `interaction-preview.mp4` records actual mood selection, reader navigation, saving, transliteration, and Saved navigation. The generated `concept.png` is not a preview of the finished app.
- The simulator was restored to English, light appearance, and standard text size after accessibility checks.

## Generated asset provenance

The built-in image generator produced `Sakina/Assets.xcassets/SanctuaryForest.imageset/forest.jpg` (converted to JPEG for local bundling). Prompt: standalone photographic background, ancient lush moss forest, small clear stream, moss-covered stones, towering trees, ferns, warm golden sun from upper-right canopy, rich forest-green shadows, photorealistic analogue medium-format treatment, no text/logos/UI/people/buildings. The first rejected concept was also generated using the built-in tool and is retained only as design history.
