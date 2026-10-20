# Roblox horror game system

This repo includes a looped Granny-style horror game foundation with:
- Granny AI patrol/chase/search and ambush behavior
- door/key unlock flow
- escape loop and round reset
- XP/coins + leaderstats
- flashlight battery and panic meter
- generator/power outage system
- overlays and HUD feedback

Project files
- ReplicatedStorage/GrannyAI.lua
- ServerScriptService/GameServer.lua
- ServerScriptService/DoorServer.lua
- ServerScriptService/EscapeManager.lua
- ServerScriptService/FlashlightManager.lua
- ServerScriptService/GeneratorManager.lua
- StarterGui/RoundUI.lua
- StarterGui/RoundOverlay.lua
- StarterPlayer/FlashlightClient.lua
- StarterPlayer/GeneratorClient.lua
- README.md

Generator setup
- Create a Workspace.Map.Generator model or part.
- Add a ProximityPrompt to the generator to activate it.
- If you omit the prompt, the server script creates one automatically.
- When the generator is activated, the server broadcasts PowerState to all clients.
- Clients use this to dim lighting and show a black-out effect.

Power behavior
- The generator starts in an offline state.
- When triggered, it stays on until round reset.
- When the generator is off, the darkness overlay appears and the scene becomes much more threatening.

Gameplay loop
- Players use keys to unlock doors and reach the escape zone.
- Granny hunts and searches players.
- Lighting and panic pressure increase tension.
- Rounds repeat automatically while the game is running.

Recommended next upgrades
- custom map generation
- more sound effects and startle cues
- hiding spots and stealth mechanics
- end-of-round rewards and progression by map
- more objective-driven events

Repository URL: https://github.com/kalemlunca-stack/roblox-granny-system
