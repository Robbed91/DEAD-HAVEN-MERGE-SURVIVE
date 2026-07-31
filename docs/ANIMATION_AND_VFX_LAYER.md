# Animation and Visual-Effects Layer

This presentation layer is event-driven and state-neutral. It observes the existing `EventBus`, scene controls, merge results, residence completion callbacks, and vehicle-stage signal. No economy, progression, quest, residence, save, navigation, or merge result is calculated by an animation script.

## Runtime architecture

- `MotionFX` contains interruptible button, reveal, bounce, shake, and pulse recipes. A new request kills the prior tween on that target.
- `UIAnimationDirector` binds dynamically created buttons and listens for resource, reward, discovery, survivor, vehicle, chapter, and level events. Dynamic values remain live UI text.
- `AmbientVFX` adds pooled/capped rain, fog, dust, sparks, cloud drift, and light flicker inside environment artwork. It stops processing when hidden and rebuilds its pool when graphics settings change.
- Existing merge-board code remains authoritative and supplies drag lift, target feedback, pull, compression, expansion, contact bounce, particles, producer feedback, discovery, and maximum-level feedback.
- `HotspotVisual` runs a post-completion focus/material/work/install/inspection burst only after the residence system has accepted the task.
- `VehicleVisual` supplies engine vibration, exhaust, suspension, door, headlights, and upgrade reward motion only after `vehicle_stage_changed`.
- Existing `LayeredCharacterRig` supplies reusable survivor and Hollow state animation through `AnimationPlayer`.

## Accessibility and Android policy

- `GameManager.effects_enabled()` is the shared reduced-motion and Low-quality gate.
- Off-screen ambience disables `_process`; transient effects check visibility before allocating tweens.
- Standard quality caps generic atmosphere at 10 particles; High at 18; Low at zero.
- Effects use small controls, draw calls, and existing textures. No pre-rendered video, full-screen particle simulation, gameplay polling, or persistent per-effect allocation is used.
- Reduced motion resolves controls immediately to stable transforms and omits transient overlays.

## Trigger coverage

UI: press/focus, navigation buttons, panels/modals, task reveal, resource change, quest reward, discovery, level/chapter/survivor/vehicle unlock, failure shake, and reusable tutorial pulse.

Merge: drag lift, drop/target pulse, invalid shake, merge pull/compression/expansion/bounce, wood/dust/glow, producer active/empty/recharge, cobweb removal and bubble-pop entry points, discovery, and maximum-level effect.

Environment: wind/cloud drift through layered backgrounds, plus rain/fog/dust/smoke-like motes, lantern/firelight flicker, industrial sparks, and existing character/Hollow rigs. Residence scene presets keep effect density readable on a phone.

Repairs: focus, material-arrival scale-in, work shake, task particles, installed overlay refresh, inspection settle, reward flash, and return to the locked composition.

Vehicles: engine start, exhaust, suspension, wheel/body movement, door opening, headlights, upgrade reward, plus the existing world-map route/marker presentation.

## Verification

`tests/smoke_test_animation_layer.tscn` asserts reduced-motion fallback, visibility gating, vehicle state neutrality, and that resources/profile are unchanged by the presentation layer. Existing merge, residence, vehicle, UI, settings, save, and all-screen smoke tests remain the gameplay regression suite.
