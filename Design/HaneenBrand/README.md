# Haneen artwork, 13 September 2026

The current installed icon uses `AppIcon-Cream.png`, refined with the user's warm ivory swatch. See [the cream icon notes and prompt](CreamIcon-2026-09-13.md). The earlier sage version below is retained as design history.

Generated using the built-in image generation tool. No external model or API key. Original generation outputs remain in the Codex generated-images directory. The approved assets live in Shared/CompanionAssets.xcassets.

- YaqeenBrand: cat beside an olive Qur’an on an ochre rehal. Transparent master, used directly inside the app. Legacy catalog name retained to preserve references.
- Companion-settings: cat on olive gear, genuine transparent background including the cog opening.
- Companion-kaaba: isolated pencil Kaaba with gold belt and door, used above the Qibla screen and at the compass pointer tip.
- AppIcon: opaque warm ivory canvas, generated from the transparent brand master at required sizes by `swift Design/HaneenBrand/package-icons.swift`. The ivory canvas belongs only to the installed app icon.

## Brand prompt
Use case: logo-brand. Create the final brand mark for Haneen, an Islamic Quran and dua app. References show the existing colored-pencil illustration style and the exact cream cat with dark brown ears/eye patch and small olive scarf. Draw a prominent olive-green closed Quran, with restrained gold border ornament and cream page edges, elevated on a warm ochre wooden X-shaped rehal. The friendly cream cat curls closely around the SIDE and behind the Quran stand, face visible looking toward the book. The Quran and stand must read first, the cat second. Cat is not on top of the Quran. Compact iconic balanced silhouette occupying 86% of the square. Hand-drawn colored pencil texture, confident dark brown outlines, simplified details readable at 32px. Genuine transparent alpha background, no white plate, no shadow backdrop, no app tile, no crescent, no star, no text, no Arabic lettering, no watermark. One mark only.

References: Companion-quran and Companion-settings original artwork.

## Settings prompt
Use case: background-extraction. Edit target: the supplied Haneen settings artwork. Keep the existing cream and dark-brown cat, olive scarf, olive gear/cog, pencil texture, pose, shapes, colours and composition unchanged. Remove the white paper background COMPLETELY, including the empty round hole through the centre of the cog. Those spaces must have genuine transparent alpha. Preserve the cream fur as opaque cream and all outlines. No tile, no drop shadow, no coloured backdrop, no added elements. Output the isolated identical cat-on-cog illustration on transparency.

## Final Kaaba prompt
Create an isolated colored-pencil illustration of the Kaaba, in the same line weight and olive/warm-gold pencil style as the reference. No cat or cog. Charcoal-black three-quarter cube, restrained gold belt and gold door, simple shapes with no lettering. Small warm cream edge. IMPORTANT: use the exact SAME genuinely transparent background/alpha as this reference image. Do NOT DRAW A CHECKERBOARD. Do NOT add any background pixels, shadows, ground or white paper. Transparent PNG asset ready for a dark-mode iOS app.

Reference: the generated transparent settings artwork. Two earlier Kaaba outputs had flattened checkerboard backgrounds and were rejected; neither is bundled.

## Kaaba production background correction
The third output still had an opaque black background. A final image-tool edit used: “Preserve this exact Kaaba artwork. Replace ONLY the black background outside the Kaaba silhouette with completely solid pure white #FFFFFF. All surrounding space must be flat white. No shadow, no checkerboard, no off-white texture on background. Keep the black Kaaba, cream outline, gold belt and door unchanged. This is a production asset for an existing app that automatically renders edge-connected pure-white paper transparent.”

This final paper asset is bundled and displayed through the existing `CompanionImage` edge-paper renderer. The brand and settings masters have native alpha; the Kaaba gains transparency at display time through the same pipeline as the original companion illustrations.

## Earlier sage Home Screen icon
The previous installed icon used `AppIcon-Sage.png`, generated with a muted sage background (#A3B49B). The in-app brand stays transparent. The packaging script now uses the cream master; run `swift Design/HaneenBrand/package-icons.swift` from the repository root.
