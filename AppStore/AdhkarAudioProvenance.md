# Morning and evening adhkar audio provenance

Recorded 16 September 2026 for Haneen 1.0 (2).

## Attribution and permission

Both full recordings are credited to **Abu Islam — المنشد أبو إسلام**. The source account is `ahmed-saber-458881404` on SoundCloud.

On 16 September 2026, Haneen's developer reported in this working conversation that the creator had given permission to download the recordings and add them to the app. This entry records that user-reported permission. It does not assert a public-domain status, a Creative Commons licence, a written licence on file, or any broader grant beyond the permission reported. No separate written permission document was supplied with this entry.

## Source recordings and bundled files

| Collection | Original recording | Bundled file | Estimated duration |
|---|---|---|---|
| Morning — أذكار الصباح | [Morning recording](https://soundcloud.com/ahmed-saber-458881404/zr1jlpx1apjh) | `Sakina/Resources/Adhkar/adhkar-morning.mp3` | 21:31.938 (1,291.937938 seconds) |
| Evening — أذكار المساء | [Evening recording](https://soundcloud.com/ahmed-saber-458881404/b1wxqzar07gb) | `Sakina/Resources/Adhkar/adhkar-evening.mp3` | 22:12.793 (1,332.793437 seconds) |

The mapping follows the original recording titles; the morning source is `zr1jlpx1apjh` and the evening source is `b1wxqzar07gb`.

SHA-256 hashes measured from the bundled files on 16 September 2026:

```text
b2d2980717523a2dec601fe931b67a50694ab34eb29766688d0d08712021705b  adhkar-morning.mp3
df71c0e237778a709c338071d8031624f40778e6de7fd8684366d34a32ae6b98  adhkar-evening.mp3
```

Durations were measured using macOS `afinfo`; both files are stereo MP3 audio at 44,100 Hz and approximately 128 kbit/s. These are complete recordings. Fifteen individual excerpts (seven morning, eight evening) are mapped in `AdhkarAudioSections.json`. The mapping uses local Arabic speech recognition, separate boundary crops and waveform pause/matching checks; it is not a claim of human listening or scholarly review. Each excerpt plays one recitation and does not advance the app's repetition counter. Uncertain or differently worded passages have no per-entry playback button; no displayed religious text was changed to match automatic transcription.

## In-app delivery and privacy

The recordings are bundled with the app for native, offline playback. Playback reads the local resources and does not require a SoundCloud request, account or download. Haneen does not use a SoundCloud SDK, API or embedded player.

An optional source link may open the original recording in the SoundCloud app or browser only when the user taps it. SoundCloud's own privacy and cookie policies apply to that external visit. The source links provide attribution and access to the original publication; they are not presented as the permission record.

## Release verification

Local validation on 16 September 2026:

- Simulator build and launch succeeded. Seventeen focused XCTest cases passed, with no failures or skips. They cover decoding the bundled files, duration/range validation, rapid recording changes, cancellation, bounded excerpt completion, seeking, replay after reaching the end, the Qur’an-player handoff, and chapter IDs.
- The English/light and Arabic/dark interfaces were checked in the simulator. Full playback, pause, skipping, opening the player, playing the Surah an-Nas excerpt and stopping the excerpt when changing the displayed reading were exercised.
- Evening playback continued while the simulator was locked; the displayed position advanced from 0:19 before locking to 4:27 after unlocking. Lock-screen media controls were not shown by this simulator, so their physical-device behavior remains unverified.

Before submission, verify that the selected archive contains both files, both recordings play on a physical iPhone with networking disabled, lock-screen/headphone controls work, and the external source action opens the matching source URL. This document does not claim a completed physical-device playback test or an uploaded build.
