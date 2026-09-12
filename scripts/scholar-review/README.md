# Archived review-pack workflow

Review tooling is reserved for a future update. The release contains no named contributor acknowledgment, portrait, or review pack. Earlier attributed PDFs have been removed from the repository; a future reviewer can use the generic exporter below.

# Arabic scholar review packs

These PDFs export Haneen's actual life-situation and feeling catalogs. Each entry has its Arabic Qur’an/du’a/hadith text, source references, and a separate ruled response page for the editorial contributor. No insight has been attributed to him. The introductory profile page lets him specify his public name, biography, links and attribution preference.

The files can be printed or annotated in a PDF reader. They are not AcroForm questionnaires. Entry IDs and PDF bookmarks make returned pages easy to match to the app.

## Regenerate on macOS

From the repository root, with Xcode command-line tools installed:

```sh
python3 scripts/scholar-review/export.py build/scholar-review
swift scripts/scholar-review/ReviewPDF.swift build/scholar-review output/pdf
```

The exporter compiles the real Swift catalogs; it does not parse their text with regular expressions. PDF generation uses native CoreText for joined Arabic, bidirectional text and diacritics. Drawing asserts that no text was clipped. The builder emits entry-to-page indexes into the export directory.

The dated release manifest in `Design/ContentReview` preserves the original page indexes and input/output SHA-256 hashes. Keep it when regenerating a new edition. Treat returned insights as draft content until the reviewer indicates which entries he approves for publication.

## Validation for the 12 September 2026 edition

- All 84 life situations and 33 feelings are included, with one response page per entry.
- Life pack: 255 pages. Feelings pack: 102 pages.
- Extracted text contains every stable entry ID; no pages have fewer than 30 words.
- CoreText clipping assertions pass on all pages.
- Covers, content, long passages, response pages and final entries were rendered and visually inspected.
- Qur’anic entries whose source is a recitation hadith use explicit surah labels; hadith numbers are never interpreted as surah numbers.

The protected scholar queue sync is now manual-only: run the “Validate and sync scholar guidance” workflow on `main` with `sync_queue` enabled only if the editorial programme resumes. Normal pushes still run content and security validation, but do not populate the queue.
