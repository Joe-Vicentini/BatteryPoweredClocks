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

## Experimental stopped-clock object replacement

The Build 42 object-swap experiment is enabled by `TEST_DUMMY_CLOCKS = true`
in `42/media/lua/shared/BPC_ClockSwap.lua`. Only encountered clocks are affected.
A running clock remains untouched. When power is lost (or an unvisited clock
is discovered already drained), the original clock object is removed from its
square and replaced at the same position with a plain `IsoObject` using its
original static vanilla clock sprite. Its battery state is copied into the
dummy's mod data. Removing a dead battery and inserting a charged battery work
through the same context menu, and inserting a charged battery creates a new
normal clock object with the saved sprite and data.

**Rollback:** Before reverting this commit, set `TEST_DUMMY_CLOCKS = false`,
restart the game, and right-click each affected dummy to recreate a normal
clock object. Only then revert the commit. Use a backup save: if the game
associates hands with the sprite instead of the object, the replacement may
still animate. Runtime swapping and multiplayer synchronization are not
in-game validated; this experiment performs object swaps only in single-player.

## Current limits

This mod tracks clock time in per-object mod data. Whether the dummy object
stops vanilla hand animation remains an in-game experiment. It recognizes the
clock sprites defined in Build 42's generated `clocks.txt`, plus two previously
known variants. Multiplayer object swaps are disabled until server authority
can be implemented and tested.
