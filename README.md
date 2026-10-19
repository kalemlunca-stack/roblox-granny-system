# Door & Key system + Escape loop

This repository now includes a playable horror loop foundation:
- server-side Granny AI with looped rounds
- door unlocking via key tool
- escape zone + win tracking
- polished round HUD

Files included
- ReplicatedStorage/GrannyAI.lua — AI ModuleScript for Granny (patrol, hearing, sight, chase, attack)
- ServerScriptService/GameServer.lua — looped round manager and key distribution
- ServerScriptService/DoorServer.lua — door unlock validation logic
- ServerScriptService/EscapeManager.lua — escape zone tracking and player escape status
- ServerScriptService/GrannyAnimator.lua — optional animation/sound hooks for Granny state changes
- ReplicatedStorage/Tools/KeyTool/KeyClient.lua — client-side key interaction script
- StarterGui/RoundUI.lua — HUD for timer and escape tracking

Map setup
Create a Workspace.Map folder with these pieces:
- Map
  - Granny (Model, with Humanoid and PrimaryPart)
  - GrannySpawn (Part)
  - PatrolPoints (Folder of waypoints)
  - PlayerSpawn (SpawnLocation or Part/Folder)
  - EscapeZone (Part) — players must touch this to escape
  - Doors (Folder) — door models to unlock with keys
  - Items (Folder) — optional items reset each round

Door usage
- Place each door in Workspace.Doors
- Give each door a name matching the key tool name or set it to `MainDoor` by default
- The included key tool is named `Key`, and the server gives one to each player every round
- Activate the key while aiming at a door within range; the server validates and unlocks it

Escape logic
- Player `Escaped` BoolValue is set when they touch the EscapeZone part in Workspace.Map
- The round ends when all players have escaped or everyone is dead
- GameServer resets all escape values at the start of each round, then loops again automatically

Granny audio/animation hooks
- GrannyAI fires `ReplicatedStorage.GrannyState` with `{state, model}`
- GrannyAnimator listens and plays animation/sound assets if present under the Granny model or ReplicatedStorage.GrannyAnimations
- Example sounds names: Footstep, Scream, Attack

Recommended next upgrades
- Add smarter AI hiding/ambush logic
- Add door animation tweening rather than instant unlock
- Add end-of-round scoreboard and rewards
- Add a real escape UI and fail/win overlays

Repository URL: https://github.com/kalemlunca-stack/roblox-granny-system
