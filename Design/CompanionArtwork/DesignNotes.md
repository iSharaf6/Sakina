# Collection artwork

The September 10 brief keeps the existing Yaqeen layout and replaces the bright symbol tiles. The first pass had treated native icon badges as a substitute for illustration; the user's examples point to something much more personal.

## Reference study

- Chris Raroque, [How I Make Apps FEEL 10x Better](https://www.youtube.com/watch?v=8mMH6Pq8qnE): contextual illustrations, consistent icon weights, restrained motion and haptics. Accessible [notes](https://lilys.ai/en/notes/lilysai-20260813/10x-better-app-design-secrets) and [transcript excerpt](https://glasp.co/youtube/8mMH6Pq8qnE) were reviewed.
- Chris Raroque / Greg Isenberg, [How I Design Apps 10x Better](https://www.youtube.com/watch?v=jSWuepkuFrU), particularly the illustration section at 20:50. The accessible [course notes](https://videohighlight.com/v/jSWuepkuFrU) describe starting from an original character and using that reference for subsequent poses.
- [App Branding Masterclass](https://www.youtube.com/watch?v=JDwxt9fHofk): the accessible [opening transcript](https://glasp.co/youtube/JDwxt9fHofk) introduces the mascot as part of the app's identity.
- The user's screenshots show small animal illustrations, ample white space, and character variations tied to a particular state or achievement. These were visual references; no artwork was copied from Chris's apps.
- Peter Yang's [no-ai-slop](https://github.com/petergyang/no-ai-slop) concerns writing. Its applicable principles here are concrete wording and minimal edits. Existing devotional content was left intact; the search empty-state headline now describes the result directly.

Access limits: the YouTube page fetch was throttled. This is a study of the supplied visuals, accessible notes and transcript excerpts, not a claim to have watched every video on the channel or a private paid playbook.

## Art direction

One cream cat with charcoal ears, an eye patch, a long dark tail and a small moss-green neckerchief. Small dot eyes and uneven pencil contours keep the expression simple. Green, cream, charcoal and occasional ochre connect the drawings; there is no separate rainbow color for each collection.

The cat stretches in the morning, watches the evening moon, sleeps on a cushion, and sits beside a lantern at night. Other collections use objects from the same drawing family: prayer rug, beads, books, rose and olive branch. The artwork is decorative and never substitutes for the collection title or represents a religious figure.

These are original AI-generated pencil-style illustrations made with the built-in image tool, not commissioned hand drawings. The first morning drawing is the character reference for the remaining assets. Prompts and correction prompts are recorded in `generation.json`.

## Integration

All fifteen collections have explicit artwork mappings. The same collection drawing appears in the suggested card, search results and Home shortcuts. Saved and search empty states reuse relevant poses. Utility icons have quiet backgrounds. Existing navigation, text, completion states, reduced-motion behavior, haptics and geometric field are preserved.

Illustrations have no text and are hidden from accessibility because the adjacent native labels describe each action. Charcoal strokes use a pale paper backing in dark mode. Asset files are bundled for offline use.

See `Verification.md` for the final build and screen checks.
