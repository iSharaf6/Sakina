# Yaqeen · white and green

## References actually reviewed
- Chris Raroque’s [Luna Budgeting](https://lunabudgeting.com): all nine public gallery assets, covering budget, accounts, reports, settings, reminders and recurring expenses.
- Chris’s [Amy Food Journal](https://www.amyfoodjournal.com): thirteen public feature screens covering editing, goals, reminders, saved items, nutrition, widgets and settings.
- [Pillars](https://apps.apple.com/au/app/pillars-prayer-times-qibla/id1559086853): public App Store prayer, Qibla and tracker screens for category navigation.
- [Mobbin’s Stoic reference](https://mobbin.com/explore/screens/839dd8c6-fd52-486a-a599-39f5242de9ba), previously reviewed.

AppLlama’s installed skills were used. Its MCP connector is unavailable, Luna Budgeting/Pillars were absent from its public catalog, and full competitor journeys are subscription gated. These are the available public screens, not a claim to have inspected private app screens.

## Design decisions
White is the primary surface. Green marks actions, selection and a single featured reading. Neutral text and thin neutral borders carry hierarchy. Rounded system typography follows the compact, friendly character of Luna and Amy. Preserve Yaqeen’s original vector identity and reviewed Arabic typography.

Home prioritizes a conversational search field, text-only mood selection and a short Arabic preview. The full Arabic, meaning, applicability and canonical source remain together in the reader. Keep reading, saved items, daily guidance and an optional 30-second nature pause as useful return paths.

Use 20pt screen gutters, 16–20pt component radii, 44pt minimum actions, native navigation and segmented controls. Heroicons is the coherent custom navigation family. Native system components keep their standard affordances.

Motion: immediate 70ms touch feedback; restrained 220ms release; native reading navigation; smooth mood selection; no rotating card stacks. Reduce Motion removes movement. No new remote runtime dependency or animation framework.

## Verification
See Verification.md for the final build, simulator and test evidence.
