# Batch 09 — Approved Hollow Creek Hotspot Artwork

## Scope and artwork handling

Nine approved final object illustrations were imported without redraw, regeneration, recolouring, cropping, or replacement. Original object filenames were preserved. The 1024 × 1024 masters remain under `assets/ui/repair_hotspots/hollow_creek/source/`; 256 × 256 lossless runtime derivatives live under `runtime/`.

## Manifest mapping

The approved objects map one-to-one to the existing `front_door`, `kitchen_window`, `living_room`, `fireplace`, `pantry`, `upstairs_bedroom`, `barn`, `rear_escape`, and `perimeter_traps` hotspot IDs. `docs/REPAIR_HOTSPOT_ASSET_MANIFEST.csv` records the associated task ID, physical object and runtime path.

## Import and memory configuration

- Runtime textures: lossless `CompressedTexture2D`, alpha-border fixing enabled, mipmaps disabled, no size limit. This is appropriate for small portrait UI elements that never recede in 3D.
- Approximate decoded runtime footprint: 9 × 256 × 256 × 4 bytes = 2.25 MiB before engine overhead.
- The master `source/` folder contains `.gdignore`, preserving approved masters in Git while excluding their 36 MiB decoded footprint from Godot import/export.

## State and animation integration

The existing gameplay-owned task and residence states now drive full-object available, selected, locked, completed and insufficient-material presentations. Whole-object float/pulse, selected scale/rim, unlock sweep, completion badge and existing repair burst are presentation-only and reduced-motion aware.

## Technical report

- No separate contact-shadow layer was supplied; the approved contact shadow remains within each transparent flattened object canvas.
- No internal moving-part layers were supplied. These task markers require only whole-object UI animation, so this does not block integration.
- The old Hollow Creek ring/construction-item proxy remains solely as a safe fallback if an approved runtime texture is missing; automated verification confirms fallback usage is zero for all nine implemented IDs.
