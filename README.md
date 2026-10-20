# Roblox horror game system

This project now includes iterative horror-game systems for a more complete stealth loop:
- Granny AI chase/search/ambush
- key-based door unlocking
- escape/win state and round resets
- XP/coins progression and leaderstats
- flashlight battery + panic meter
- generator power outage system
- dynamic horror audio event system
- stealth hide system via HideSpots

New hide system
- Put parts or models inside Workspace.Map.HideSpots.
- Players can stand near a hide spot and press H to hide.
- The StealthManager tracks `IsHidden` and `StealthLevel` on each player.
- Hidden players are harder to detect and can reduce noise while remaining hidden.
- The hide UI in StarterPlayer/HideClient.lua appears when players are near a hide spot.

Map setup
Create a Workspace.Map folder with:
- Granny
- GrannySpawn
- PatrolPoints
- HidePoints
- AmbushPoints
- HideSpots
- PlayerSpawn
- EscapeZone
- Doors
- Items
- Generator

Recommended next upgrades
- add actual stealth-aware Granny detection (ignoring hidden players when behind cover)
- add hide spot sound effects and vanish animations
- add more objective-driven rounds and map progression
- add final polish for scoreboard, lobby, checkpoint, and save state

Repository URL: https://github.com/kalemlunca-stack/roblox-granny-system
