# Home and Settings artwork

The prayer summary and its location setup state now use the same adaptive white paper surface and thin border as the other cards. The next prayer receives a soft green highlight. The existing six celestial illustrations sit directly on the card; the previous dark-matte scenes are no longer used here. Time calculation, timezone formatting, countdowns, and spoken schedule descriptions are unchanged.

Home now contains the time-of-day recommendation and the Tasbih, Daily goals, Ruqyah, and Why dhikr shortcuts. Reading progress still comes from the existing stores. Du’a opens directly to feelings and collections. Home’s older duplicate recommendation tile now opens the full Du’a library; the existing daily-goal progress card remains available.

26 generated illustrations replace the old Settings image and add 25 new assets. The shared catalog now contains 78 named illustrations. Settings has a prominent cat on a cog, a calculator, globe, language bubbles, reciter headphones, reading books, bell, clock, and haptics artwork. The same family covers nearby mosque/food rows, results explanations, support, social and account actions, Ruqyah etiquette, and Qibla/Scholar content states. Familiar small navigation, selection, playback, and system controls remain native.

All scenes and final source paths are recorded in `home-settings-generation.json`. Seven generated black backgrounds were caught during simulator review and corrected through image generation. The selected images were exported at 384 × 384; their corners were checked for a clean white or transparent background. The paper backing remains available in dark mode.

Settings-style rows stack vertically at accessibility text sizes, giving the title, subtitle, and trailing control the full row width.

## Verification

- Debug app and widget build succeeded.
- Existing unit suite: 29 tests passed, zero failures.
- Opened every moved Home shortcut and the Right now collection in the simulator; Tasbih also reached the individual counter.
- Reviewed Home, Du’a collections, Settings, nearby mosque/food rows, and the nearby results explanation.
- Reviewed the six-prayer gallery in English and the prayer card in Arabic at the largest Dynamic Type size. These gallery screenshots use fixture times, not live local prayer times.
- Verified all 78 artwork enum cases resolve to bundled image files; `git diff --check` passed.

Previews: `prayer-cards-white.png`, `prayer-cards-white-arabic-large.png`, `duas-collections.png`, `nearby-artwork.png`, `settings-artwork.png`, `settings-artwork-large.png`, and `home-practice-artwork.png`.
