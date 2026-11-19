# Battery-Powered Clocks

A Project Zomboid **Build 42** mod that gives wall clocks removable batteries.

## Installation

Copy this repository to your Zomboid mods folder and enable **Battery-Powered Clocks**.
The Build 42 manifest and code are in `42/`.
The `common/` directory is intentionally present for Build 42 mod discovery. For an existing save,
enable the mod in that save's mod list and restart the game before testing.


## Behavior

Right-click a wall clock to inspect its indicated time and remaining battery charge, remove
its battery, insert a `Base.Battery` from your inventory, or set an out-of-sync running
clock when carrying a watch. Watches do not need to be equipped. Inserting a replacement
battery can set the time automatically (sandbox option), but only if you carry a watch.
Otherwise the clock resumes from its frozen time. Empty and removed batteries stop the
clock's simulated time.

Only clocks that a player encounters through the world-object context menu receive
persistent `BPC_Clock` data on their individual world object. There is no global registry
or map-wide scan. Charge and displayed time are advanced lazily using elapsed in-game hours,
including when the clock was unloaded.

## Sandbox options

- `BatteryPoweredClocks.DrainPerDay`: percentage points drained per in-game day (default 0.5).
- `BatteryPoweredClocks.MinInitialCharge`: minimum randomly rolled starting charge (default 20%).
- `BatteryPoweredClocks.AgeInitialBatteries`: subtract elapsed in-game days of drain when first discovered (default on).
- `BatteryPoweredClocks.AutoSetOnReplace`: auto-sync on battery insertion if the player has a watch (default on).

## Current limits

This version tracks the clock time in per-object mod data and shows it in the context
menu. **It does not override the vanilla animated clock-hand rendering**; the physical
hands may still show the game's current time. It recognizes the known Wall Clock and
Square Wall Clock tile sprites, not every decorative clock or modded sprite.
Multiplayer server-authoritative interaction and in-game validation remain outstanding.
