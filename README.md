# Roblox horror game system

The project includes a substantial horror-game loop with:
- Granny AI chase/search and ambush behavior
- key-based door unlocking
- round loop and escape win logic
- XP/coins progression and leaderstats
- flashlight battery + panic meter
- generator power outage system
- dynamic audio scares and ambience events

Project files
- ReplicatedStorage/GrannyAI.lua
- ServerScriptService/GameServer.lua
- ServerScriptService/DoorServer.lua
- ServerScriptService/EscapeManager.lua
- ServerScriptService/FlashlightManager.lua
- ServerScriptService/GeneratorManager.lua
- ServerScriptService/AudioEventManager.lua
- StarterPlayer/FlashlightClient.lua
- StarterPlayer/GeneratorClient.lua
- StarterPlayer/AudioClient.lua
- README.md

Dynamic audio system
- AudioEventManager triggers ambient whisper/thunder/static events at intervals.
- When players are near Granny, a chase cue plays to intensify terror.
- Sounds are broadcast via a RemoteEvent to each client.

Recommended next steps
- add hiding/stealth behavior and object-based cover
- add progression by map and unlockables
- add smoother UI transitions and real end-of-round lobby screens
- add chaotic effects like localized sound propagation and random scare triggers

Repository URL: https://github.com/kalemlunca-stack/roblox-granny-system
