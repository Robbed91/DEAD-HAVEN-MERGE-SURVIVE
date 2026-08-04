# Export Size Audit

Date: 2026-08-03
Branch: `visual-production`, commit `b9a3a42` and this update

Performed from a remote environment with no Android SDK, no Godot export
templates, and a network proxy that explicitly policy-denies both
`dl.google.com` and `github.com/godotengine` releases - a real Android
export could not be run here. Everything below was verified without one:
directly measuring tracked file sizes, and directly calling Godot's own
`String.match()` (the same function the exporter uses for
`include_filter`/`exclude_filter`) via a one-off headless script, rather
than assuming or hand-simulating its glob semantics.

## Filter correctness: verified, not assumed

A first attempt at simulating the exclude filter in Python got a very
wrong answer (implied 434 MB would ship) because it assumed `*` in a glob
pattern doesn't cross `/` - i.e. that `docs/*` only matches files directly
inside `docs/`, not nested ones. That assumption is wrong for Godot
specifically. Rather than report that number, it was checked directly
against Godot's real matcher:

```gdscript
"docs/producer-state-captures/live_merge_vfx_electronics.png".matchn("docs/*")  # -> true
"assets/items/construction/source/construction_master.png".matchn("assets/**/source/*")  # -> true
"assets/items/tool/producer_active.png".matchn("assets/**/source/*")  # -> false (correctly kept)
```

Confirmed: Godot's `*` matches any run of characters *including* `/`, so
`docs/*`, `tests/*`, `tools/*`, `android/*`, `assets/concepts/*`,
`assets/manifests/*`, and `assets/**/source/*` in `export_presets.cfg`
all correctly exclude everything nested under them, at any depth,
including every capture screenshot and `.avi` this session and prior
batches added under `docs/*-captures/`. Real runtime assets under
`assets/items/<chain>/*.png` etc. are correctly *not* caught by the
`source/*` exclusion. **The exclude filter itself is correct.**

## Current would-ship weight: close to or over the 200 MB target

Re-running the size calculation with the verified-correct filter
semantics, against everything currently tracked on `visual-production`:

| | Size |
|---|---|
| Total tracked repository | 615.4 MB |
| Excluded by filter (concepts/manifests/source-masters/docs/tests/tools/android) | 403.0 MB |
| **Would-ship source weight (pre-Godot-import-compression)** | **212.4 MB** |

Breakdown of the would-ship 212.4 MB:

| Type | Size |
|---|---|
| `.png` (2009 files) | 183.6 MB |
| `.wav` | 20.1 MB |
| `.jpg` | 6.2 MB |
| `.ttf` + code + data | ~2.5 MB |

This is source weight, not final packed APK size - but it's already at or
past the plan's own 200 MB target *before* Godot's own import/compression
step does anything, because none of that step has happened yet:

- **Every PNG imports as fully lossless** (`compress/mode=0` on every
  `.png.import` file checked) - no VRAM compression (ETC2/ASTC) has been
  applied to any texture yet, including large opaque backgrounds like
  `assets/ui/world_map/world_map_region.png` (3.09 MB, the single largest
  runtime file) or the five residence weather-layer overlays
  (~1.6-1.7 MB each).
- **Every WAV imports uncompressed** (`compress/mode=0` = PCM/Disabled on
  every `.wav.import` file checked, including all 12 music loops at
  ~700-864 KB each). Godot's WAV importer supports `compress/mode=1`
  (IMA-ADPCM, roughly 4x smaller) as a lower-effort alternative to
  re-encoding to Ogg Vorbis.

## What this means for whoever runs Batch 4

The "texture/audio/memory optimisation" step in the release plan is not
optional polish - based on this measurement, it's required to hit the
200 MB target at all. Concretely, in priority order:

1. Trial ETC2 VRAM compression on the largest opaque backgrounds first
   (`world_map_region.png`, the five weather-layer overlays, residence/
   scavenging/dialogue background art) - these are exactly the textures
   the original plan flagged as good ETC2 candidates (large, opaque,
   less transparency-sensitive than UI/item icons). Keep item icons,
   portraits, and UI elements lossless as already planned, since those
   are exactly what ETC2 visibly degrades.
2. Switch WAV import `compress/mode` from `0` (Disabled) to `1` (RAM/
   IMA-ADPCM) for music and ambience loops at minimum - a mechanical,
   low-risk config change, not a re-record. Verify by ear afterward that
   quality is still acceptable; revert per-file if not.
3. Re-run this same measurement after both changes and confirm the actual
   packed APK (not source weight) lands under 200 MB before spending
   further effort - steps 1-2 may already be enough.

## What this audit did not and could not verify

- Actual packed/compressed APK size (needs a real export).
- Whether ETC2 compression visibly degrades any specific texture (needs
  visual comparison on a real device or emulator, per the original plan).
- Runtime VRAM/frame-time/memory impact (needs a real device).

These all still require Batch 4's own device-based verification pass.
