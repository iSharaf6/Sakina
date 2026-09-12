# Yaqeen Scholar Review — implementation design specification

Accepted visual references:

- `scholar-dashboard-queue-concept.png` — primary review queue at 1536×1024
- `scholar-dashboard-editor-concept.png` — Arabic insight editor at 1536×1024

These references define the visual system and information architecture. UI text and controls remain code-native.

## Product surface

Private editorial tool for one invited scholar and one admin. It reviews a specific `(situation_id, verse_key)` pair, preserves the existing Qur’an and app context, records original Arabic scholarly prose, generates an editable English draft server-side, and requires human review before publication.

The dashboard must never expose users’ bookmarks, reflections, searches, prayer location, or Google Drive backup.

## Layout and container model

- Desktop reference viewport: 1536×1024.
- Persistent 304 px forest sidebar.
- Queue state: 836 px open list/table workspace plus 396 px context rail.
- Editor state: source context occupies roughly 40% of the remaining canvas; editor occupies roughly 60%.
- Prefer open regions, dividers, table rows, and one preview frame. Do not wrap every region in a floating card.
- Tablet collapses the context rail into a drawer. Mobile uses a single column with navigation in a sheet and source context before the editor.

## Color lock

| Token | Value | Use |
| --- | --- | --- |
| `forest-950` | `#173F37` | primary text, buttons, sidebar depth |
| `forest-800` | `#2B5148` | interactive forest |
| `ivory` | `#F8F5ED` | page background |
| `surface` | `#FFFCF5` | editor/list surfaces |
| `muted` | `#65766F` | secondary copy |
| `sage` | `#DCE7E1` | selected row/tab |
| `sand` | `#E5DED1` | quiet supporting state |
| `hairline` | `#DDD7CB` | one-pixel borders and dividers |
| `warning` | `#D78A16` | review/change status dot only |

No gradients, glows, neon, translucent color washes, or palette substitutions.

## Typography

- UI chrome: SF Pro/Inter-style sans-serif, 14–16 px, 500–600 weight, 1.35–1.55 line height.
- Product/page titles: dignified serif or editorial display face, 36–48 px desktop, semibold.
- Section titles: same editorial face, 18–24 px.
- Qur’anic Arabic: a dignified Arabic reading face, 25–31 px, generous line height, RTL.
- Arabic editor: readable Arabic system face, 20–24 px, RTL and right aligned.
- Avoid browser-default typography in buttons, inputs, tabs, and table cells.

## Spacing, shape, and elevation

- Spacing scale: 4, 8, 12, 16, 20, 24, 32, 40, 48.
- Control height: 44–54 px.
- Radius: 10 px controls, 16 px panels, 20 px major outer shell.
- Border: one pixel `hairline`; focused editor uses one pixel `forest-800`.
- Shadows are restrained and used only for the outer shell/drawer, never every row.

## Component families

- `AppShell`: sidebar, top command bar, responsive navigation.
- `SidebarNav`: six fixed destinations plus account identity.
- `SearchField` and `ReviewFilter`: search plus Needs review/Changed/All.
- `ReviewTable`/`ReviewRow`: stable row anatomy; selected variant uses sage.
- `SourceContext`: situation, ayah, approved meaning, existing orientation.
- `InsightEditor`: RTL Arabic field, references editor, translation state, preview.
- `StatusMark`: a small semantic dot plus text; not a decorative badge.
- `CommandButton`: primary forest, secondary bordered, disabled muted.
- `ProfileEditor`: supplied identity/photo/social links with optional fields clearly empty.

## Icon inventory

- Brand: open-book/path mark, thin off-white outline.
- Review queue: three horizontal lines with leading dots.
- Drafts: outlined document.
- Submitted: outlined paper plane.
- Published: outlined check in circle.
- Scholar profile: outlined person.
- Search: 18 px outline magnifier.
- Back: 18 px left chevron.
- Pagination: 16 px chevrons.
- Empty preview: quiet outlined open book.

Icons use a consistent rounded 1.5–2 px stroke, inherit current color, and remain optically centered.

## Allowed primary-screen copy

Sidebar: `Yaqeen Review`, `Review queue`, `Drafts`, `Submitted`, `Published`, `Scholar profile`, `Editorial contributor`, `Scholar`.

Queue: `Review queue`, `Search situations or ayat`, `Needs review`, `Changed`, `All`, `Situation`, `Ayah`, `Orientation`, `Status`, `Action`, `Existing app orientation`, `Open review`, `Source context`, `Existing English meaning`, `Why this reading`.

Editor: `Review insight`, `Review queue / 4:35`, `Save draft`, `Submit for publication`, `Full Arabic ayah`, `Approved English meaning`, `Arabic insight`, `Write the scholar’s original explanation in Arabic`, `Sources and references`, `Add a book, tafsir, hadith reference, or URL`, `Add reference`, `English translation`, `Not generated`, `Generate English draft`, `The Arabic is saved first. Translation never changes Qur’anic text.`, `Preview`, `Arabic`, `English`, `Add Arabic insight to preview`.

Role-based intentional deviation: the scholar sees `Submit for publication`; only an admin sees `Publish` or `Archive`.

## Interaction and motion

- Selecting a queue row updates the context rail without navigation.
- `Open review` routes to the editor while preserving queue/filter state.
- Draft saves produce one quiet success state. Submission requires non-empty Arabic.
- Translation is disabled until the Arabic draft is saved.
- Arabic/English preview swaps with a 160–220 ms opacity transition.
- Respect `prefers-reduced-motion`; no decorative movement.

## Prohibited additions

No public registration, fake metrics, charts, analytics cards, open social feed, comments, instant-fatwa language, AI sparkle branding, decorative pills, marketing hero, streaks, leaderboards, or fabricated scholar qualifications and insight content.
