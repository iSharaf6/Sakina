# Authentic screenshot source assets

Captured 13 September 2026 from the installed Haneen Debug app on an iPhone 17 Pro Max simulator running iOS 26.5. Every PNG is the original **1320 × 2868** portrait capture from `xcrun simctl io ... screenshot`, with no cropping, compositing, generated UI, image editing or resampling. These are source assets for the marketing layouts the user will review; nothing was uploaded.

| File | Actual screen / navigation |
|---|---|
| `01-home.png` | `-yqScreen home`; English Home with calculated next prayer and evening collection entry. |
| `02-quran.png` | `-yqScreen mushaf:1:1`; full Al-Fatihah mushaf page. |
| `03-feelings.png` | `-yqScreen mood:grateful`; normal reading menu → “By You we reach the morning” (2 of 6), Arabic, transliteration, English and source. |
| `04-morning-adhkar-dark.png` | `-yqScreen practice:morning`; normal Next navigation to “Glory and praise, a hundred times” (14 of 26). Dark appearance; transliteration hidden through the real reading controls. Arabic and English reward, conditions and Sahih Muslim citation are visible. Recitation counter remains 0 of 100. |
| `05-prayer-times.png` | Home → next-prayer card; existing prayer-times sheet expanded to its full-height detent. |
| `06-widget-collection.png` | `-yqScreen settings` → Widget collection; actual shipping widget chooser, not the debug widget gallery. This chooser intentionally displays its built-in sample prayer times. |
| `07-all-feelings.png` | `-yqScreen feelings`; normal All feelings overview with the cat feeling choices. The recently visited Grateful chip comes from normal earlier navigation. |
| `08-explore.png` | `-yqScreen explore`; normal Explore overview, nearby places entries and the first three life categories. |

The existing debug routes only opened normal app views. The initial captures used the installed app without changing source or running builds/tests. Home and prayer times were subsequently recaptured after rebuilding the corrected prayer-day display: both now show tomorrow's actual schedule after Isha, with Fajr at 4:34 AM. The five targeted `PrayerScheduleDayTests` also passed on the iPhone 17 Pro Max simulator. Reading positions reflect normal navigation during capture; no completed practices, recitations or streaks were fabricated.

Sample location: central Sydney, **−33.8688, 151.2093**, selected through simulator location services with the app's normal permission flow. Prayer calculations used the app's existing Muslim World League / Standard settings and the actual capture date. The widget chooser uses its own built-in preview times; do not describe those previews as a live personal schedule. No account, email, private note or user contact information is shown.

The simulator status bar was set to 9:41, full signal and 100% battery for capture. Status-bar and simulated-location overrides were cleared afterward; appearance was left light and the app was left on Home. Transliteration remains off in this simulator's app preferences after the dark screenshot.

All eight final images were visually inspected: no permission prompts, menus, errors, keyboard, loading placeholders or horizontal text overflow remain. The prayer and widget screens use the app's normal sheet presentation. Lower content outside a scroll viewport is naturally off-screen. The dark adhkar image includes the complete reward card and its source.

The two additional overview captures used the same installed app and native capture process. The simulator was returned to Home and its status-bar override cleared afterward. No Haneen widget was already placed on SpringBoard during the brief optional check, so no Home Screen widget screenshot was added.
