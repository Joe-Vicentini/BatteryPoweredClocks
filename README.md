# Clocks Have Batteries

A Project Zomboid **Build 42** mod that gives wall clocks removable batteries.

## Installation

Copy this repository to your Zomboid mods folder and enable **Clocks Have Batteries**.
The Build 42 manifest and code are in `42/`.
The `common/` directory is intentionally present for Build 42 mod discovery. For an existing save,
enable the mod in that save's mod list and restart the game before testing.


## Behavior

Right-click a wall clock to remove its battery (with remaining charge shown), or select
a specific `Base.Battery` from the **Insert clock battery** submenu. Each battery is
listed with its current display name and rounded charge, including batteries inside
carried containers. When no batteries are carried, the submenu instead shows a disabled
"No batteries found in inventory" entry. You can set an out-of-sync running clock
when carrying a watch.
Watches do not need to be equipped. Inserting a replacement battery can set the time
automatically, but only if you carry a watch.
Otherwise the clock resumes from its frozen time. Empty and removed batteries stop the
clock's simulated time.

Only clocks that a player encounters through the world-object context menu receive
persistent `BPC_Clock` data on their individual world object. There is no global registry
or map-wide scan. Charge and displayed time are advanced lazily using elapsed in-game hours,
including when the clock was unloaded.

## Sandbox options

- `BatteryPoweredClocks.DrainPerDay`: percentage points drained per in-game day (default 0.5).
- `BatteryPoweredClocks.MinInitialCharge`: minimum randomly rolled starting charge (default 20%).
- `BatteryPoweredClocks.NoBatteryChance`: chance that a newly initialized wall clock has no battery (default 5%).

Clocks always lose charge for elapsed in-game days before first discovery. Inserting a
battery always synchronizes the time when the player carries a watch.

## Stopped-clock visuals and loaded clocks

In single-player, stopped clocks retain their registered vanilla main sprite.
The mod uses the matching vanilla static clock tile as an overlay instead of
assigning a runtime-only sprite, so chunk serialization never needs the
temporary `BPC_Stopped_*` sprite ID. Existing clocks with a legacy runtime
sprite are restored to their original tile when loaded. No artwork is bundled.

Clocks are initialized or refreshed when their 10x10 chunk loads, including
clocks that are already depleted on first encounter. Loaded clocks are checked
once per in-game minute so batteries reaching 0% stop without a context-menu
interaction. A small initial-chunk scan covers loading an existing save.
Unloaded clocks continue to use elapsed-world-time calculations.

**Visual limitation:** The static overlay uses registered vanilla artwork, but
its ability to cover Build 42's separately rendered moving hands is not yet
confirmed in game. Verify this on a disposable backup save before relying on it.
The mod retains any previous overlay and restores it when the clock is powered.
The previous dummy-object experiment remains disabled, with compatibility
restoration for old dummies until that migration can be retired.

## Current limits

The clock state and overlay are implemented for single-player. Multiplayer
visual handling and authoritative clock state remain unimplemented. Modded
clock sprites not on the known Build 42 list are not automatically recognized.
