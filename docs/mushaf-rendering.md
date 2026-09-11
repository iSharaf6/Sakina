# Traditional and Digital Qur’an readers

Traditional preserves the ornamental, fixed Uthmani pages. Digital reflows
Uthmani, Tajweed or IndoPak at the chosen text size, with optional English
meaning and transliteration beneath each ayah. Digital never compresses the
text into a fixed page height. Both views support the shared System/Light/Dark
appearance. Changing script, size or reading aids opens Digital; returning to
Traditional preserves those reading-aid preferences for later.

The reader and app Settings use the same `translationVisible`,
`transliterationVisible` and `arabicScale` keys and the same appearance sheet.
An idempotent migration imports legacy reader settings only when the shared
setting has no explicit value. Selecting an ayah highlights it and opens a
Listen/Save/More dock. A dismissible first-use hint explains the interaction.
The printed surah and juz cartouches have chevrons and open their pickers.

IndoPak uses the unmodified Quran Foundation / QuranWBW Nastaleeq Waqf Lazim
v4.2.1 font (`AlQuran-IndoPak-by-QuranWBW`). Its private-use pause signs are
retained; only layout whitespace and invisible controls are normalized.
Font source: <https://verses.quran.foundation/fonts/quran/hafs/nastaleeq/indopak/indopak-nastaleeq-waqf-lazim-v4.2.1.ttf>.
`scratchpad/gen/bundle_transliteration.py` bundles the word transliterations
from the cached Quran Foundation page responses, with all 6,236 verse keys
validated. Arabic source text is not rewritten.

The fitted Uthmani reader uses Quran Foundation's modern Madani page/line
placement (mushaf 1), with QPC Hafs Unicode words and the matching bundled
UthmanicHafs v18 font. It preserves the published line breaks without bundling
604 separate page fonts. It is not a scanned page or a claim of pixel-identical
QCF calligraphy. The 15 rows fill the available reading area; the two opening
pages retain their shorter centred composition.

Source: [Quran Foundation font and layout guide](https://api-docs.quran.com/docs/tutorials/fonts/font-rendering/).
Build-time requests use `/api/v4/verses/by_page/{page}` with
`words=true&word_fields=text_qpc_hafs,code_v2&mushaf=1&per_page=50`.
The returned **word** page numbers determine placement, because the endpoint's
verse page grouping can differ between editions. Words spanning pages retain
the same canonical verse key and their original positions.

Run `python3 scratchpad/gen/fetch_mushaf_lines.py` to reproduce the bundled
`Sakina/Resources/mushaf-lines.json`. It caches source responses under the ignored
`build/mushaf-source-v2` directory, validates all 6,236 ayat, 604 pages, sequential
word positions and exactly one matching end marker per verse before replacing
the bundle atomically. There is one documented metadata correction: the API
puts 84:21's end marker on line 13 after its last words on line 14. The marker
stays after those words on line 14. No Arabic text is edited.

`Shared/Resources/quran.json` remains unchanged and supplies search, copied text,
translation, recitation identities and VoiceOver labels. QPC display strings
also resolve the old font/Unicode mismatch in the flowing Uthmani reader and
ayah sheets. Legacy Tajweed fallback applies to an entire word rather than
separating a combining mark from its base letters; its canonical text and
colour-span offsets are preserved.

`PrintedMushafCanvas` shapes complete words through CoreText. It measures ink
bounds as well as advance widths, keeps one font size per page and justifies
only the spaces between words. Each verse remains tappable, accessible,
highlightable and connected to recitation. Saved place includes the printed
page as well as the verse key so a verse spanning two pages resumes correctly.

The generated `MushafOrnament` asset contains decoration only. A luminance mask
applies the reader's light/dark paper palette without a white image rectangle.
The toolbar retains surah navigation, focus mode and a reading menu; page
numbers open the page picker. Focus mode hides the app tabs. Adjustable type
and translations remain available in the flowing layouts.

Validation: the XCTest suite checks all display characters against the bundled
font, all page bounds and verse hit targets at compact phone dimensions,
canonical content integrity, QPC coverage and legacy combining-mark fallback.
It also checks preference migration, complete transliteration coverage,
IndoPak glyph coverage and pause-sign preservation, and growing Digital text
layouts across all three scripts at regular and enlarged sizes.
