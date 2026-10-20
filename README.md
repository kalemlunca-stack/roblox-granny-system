# Roblox horror game systems

This repository contains a looped horror-game foundation with:
- Granny AI chase/search and ambush behavior
- key-based door unlocking
- escape or death loop
- XP/coins + leaderstats
- flashlight + panic meter
- generator power state
- dynamic horror audio scares
- hide spot stealth
- progression with unlocked maps and profile stats

Project files
- ReplicatedStorage/GrannyAI.lua
- ServerScriptService/GameServer.lua
- ServerScriptService/DoorServer.lua
- ServerScriptService/EscapeManager.lua
- ServerScriptService/FlashlightManager.lua
- ServerScriptService/GeneratorManager.lua
- ServerScriptService/AudioEventManager.lua
- ServerScriptService/StealthManager.lua
- ServerScriptService/ProgressionManager.lua
- StarterPlayer/FlashlightClient.lua
- StarterPlayer/GeneratorClient.lua
- StarterPlayer/AudioClient.lua
- StarterPlayer/HideClient.lua
- StarterPlayer/ProgressionClient.lua
- README.md

Progression setup
- The ProgressionManager stores a simple profile per player in a DataStore.
- Each player starts with `Default` unlocked.
- After a round, their score is compared to best score and new maps can be unlocked.
- A `Profile` attribute is attached to each player and mirrored to the UI.

Recommended next upgrades
- add multiple real map variants and transitions
- add lobby and round summary screens
- add saveable unlockables and custom skins
- add more hostile AI behavior with different enemy patterns

Repository URL: https://github.com/kalemlunca-stack/roblox-granny-system
