# Battery-Powered Clocks

A Project Zomboid **Build 42** mod that gives wall clocks removable batteries.

## Installation

Copy this repository to your Zomboid mods folder and enable **Battery-Powered Clocks**.
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
automatically (sandbox option), but only if you carry a watch.
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

## Experimental stopped-clock runtime sprite

The failed dummy-object experiment is disabled. Previously created dummy objects
are restored to ordinary clocks when their context menu is opened.

The new experiment is enabled by `TEST_RUNTIME_STATIC_CLOCKS = true` in
`42/media/lua/shared/BPC_ClockVisual.lua`. On an encountered clock with a dead
or removed battery, it creates an unregistered `IsoSprite` with a unique name,
loads the existing vanilla static clock tile texture, and assigns the new sprite
to the original world object. The test does not replace any global sprite-manager
entries. Because the new runtime sprite lacks a persistent tile ID, an `OnSave`
handler restores tracked clocks to their original vanilla sprite before the
single-player world save. Working clocks use their original sprite. No vanilla
artwork is bundled.

**Rollback:** Set `TEST_RUNTIME_STATIC_CLOCKS = false`, restart, and interact
with each affected clock to restore the original sprite; then revert this
commit if desired. If the previous experiment left dummies, let the new code
restore them on interaction before reverting. Always test in a backup save.
Runtime sprite rendering and save/reload behavior are unverified inside
Project Zomboid. A chunk saved or unloaded outside the `OnSave` event might
still serialize the unregistered sprite, so use only a disposable backup save.
Stopped clocks revert to their vanilla animated appearance when saved and
can be visually retried by interacting with them again.

## Current limits

This is a single-player visual experiment. It may not stop the game's animated
hands if the engine caches clock-script data independently of the sprite name.
It recognizes the known Build 42 vanilla clock sprites; modded clocks with
other sprites are not automatically recognized. Multiplayer visual changes
are disabled until a supported synchronization method is implemented.
