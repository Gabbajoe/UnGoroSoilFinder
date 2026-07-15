# Un'Goro Soil Finder

Finds and tracks Un'Goro Soil pile locations on the world map and minimap — even without an active quest.

Un'Goro Soil (used for several classic quests: *Un'Goro Soil*, *Bungle in the Jungle*, *Morrowgrain Research*) only shows up on your map while one of those quests is active in [Questie](https://www.curseforge.com/wow/addons/questie) — and [GatherMate2](https://www.curseforge.com/wow/addons/gathermate2) has support for tracking the dirt piles built in, but it's been left disabled for years.

**Un'Goro Soil Finder** closes that gap. It's a small standalone companion addon — it doesn't modify Questie or GatherMate2 in any way.

## Features

- Ships with **~130 known Un'Goro Dirt Pile locations** right out of the box, sourced from GatherMate2_Data's datamined node database.
- **Automatically learns** any additional pile locations as you loot them — no profession or quest required.
- Shows every known location on both the **world map and minimap**, at all times, regardless of quest status.
- "Soil" toggle checkbox in the **top-right corner** of the world map, which only appears while the Un'Goro Crater zone map itself is open, to show/hide the pins.
- Uses HereBeDragons-Pins for accurate map placement across zoom levels.

## Commands

| Command | Effect |
| --- | --- |
| `/soil` | Show how many locations are known |
| `/soil show` | Show the pins |
| `/soil hide` | Hide the pins |
| `/soil reset` | Clear all recorded locations |

## Installation

Grab the latest release from [CurseForge](https://www.curseforge.com/wow/addons/ungoro-soil-finder) or the [Releases page](../../releases), and extract the `UnGoroSoilFinder` folder into your `Interface/AddOns` directory.

## Credits

- Un'Goro Dirt Pile location data derived from GatherMate2 / GatherMate2_Data by kagaro, xinhuan, nevcairiel (GPLv2).
- [HereBeDragons-2.0 / HereBeDragons-Pins-2.0](https://github.com/Nevcairiel/HereBeDragons) by Nevcairiel.

## License

GPLv2 — see [LICENSE.txt](LICENSE.txt).
