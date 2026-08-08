# Per-residence board save migration

Date: 2026-08-01

Starting commit: `644e396`

Branch: `visual-production`

## Objective

Replace the singular saved merge board with five isolated residence board documents before introducing authored junk layouts or unified residence-board presentation. Preserve every version-1 item and its position exactly once.

## Schema

`BoardState` remains the gameplay-facing autoload. Its existing `items`, `grid`, `storage_order`, producer, merge, task-consumption, and reward APIs refer to the active residence. Inactive boards are serialized snapshots keyed by the five stable residence IDs.

Save version 2 stores:

- `format_version = 2` inside the board payload.
- `active_residence_id`.
- Account-wide `discovered_item_ids`, preventing repeat first-discovery rewards on multiple boards.
- Five residence payloads containing items, positions, producer charges/cooldowns, lock/cobweb/bubble state, storage, capacity, and instance counter.

Changing the active board snapshots the previous residence before loading the destination. The profile's existing `current_residence_id` stays synchronized without introducing another save key.

## Version-1 migration

`SaveManager` now upgrades version 1 to version 2 before `GameManager` applies the data:

1. Read the existing profile residence, falling back to Hollow Creek for an unknown ID.
2. Move the singular legacy board into that residence once.
3. Lift discovery history to account scope.
4. Preserve legacy instance IDs, item IDs, grid coordinates, storage, charges, cooldowns, and presentation flags.
5. Materialize the four missing boards from the current deterministic starting layout.
6. Re-save as version 2.

The legacy payload is never copied into multiple residences. Loading version 2 does not enter the migration branch again.

## Compatibility

- Content IDs, chain order, merge outcomes, task requirements, producer definitions, energy costs, resource values, quest/story data, hotspot data, and residence progression are unchanged.
- Existing public `BoardState` calls continue to operate on the active board.
- This batch deliberately retains the established sparse starting layout; authored boxes/cobwebs are the next separately verified batch.
- No visual, audio, or Android export asset changed.

## Verification

- Godot 4.3 zero-cache import exited successfully. It printed one allocator cleanup diagnostic on shutdown; an immediate import rerun completed cleanly with no parser, import, or resource error.
- Focused merge smoke: switching Hollow Creek -> Redwater -> Hollow Creek preserves independent mutations and exact positions; serialized payload contains five residences.
- Focused save smoke: synthetic version-1 data migrates to the saved residence once, retains its sentinel item coordinate, materializes five boards, saves as version 2, reloads, and recovers from backup corruption.
- Full discovered smoke suite: 33/33 pass.

## Next batch

Author deterministic, residence-specific box/cobweb layouts and enforce covered/cobwebbed interaction, counting, storage, deletion, collection, and merge rules without changing normal merge outcomes.