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

## Experimental stopped-clock sprite test

The `TEST_STATIC_STOPPED_CLOCKS` flag near the top of
`42/media/lua/shared/BPC_ClockState.lua` is enabled for an opt-in-to-development
visual experiment. When a discovered clock loses power, the mod reassigns the
original vanilla clock sprite from the game's `clocks.txt`. When a powered battery
is inserted, it restores the sprite the object had before stopping. No world
objects are replaced or removed. To disable the experiment, change the flag to
`false`; previously affected clocks will restore their saved sprite the next
time their context menu is opened. Test in a backup save because Build 42 may
continue animating clock hands even after reassigning a static sprite.

## Current limits

This version tracks clock time in per-object mod data. The experimental sprite
switch **is not proven to stop the game's animated hands**; the physical hands
may still show the game's current time. The menu recognizes the clock tiles
and animated replacement sprites declared in Build 42's generated `clocks.txt`,
as well as the previously recognized Wall Clock variants. Modded clocks with other
sprites are not automatically recognized.
Multiplayer server-authoritative interaction and in-game validation remain outstanding.
