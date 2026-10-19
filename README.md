# roblox-granny-system

Looped Granny-style Roblox horror game system. This repository contains server-side AI and a round manager you can drop into a Roblox place.

Files included
- ReplicatedStorage/GrannyAI.lua — AI ModuleScript for Granny (patrol, hearing, sight, chase, attack)
- ServerScriptService/GameServer.lua — Round manager that spawns/reset granny and items, loops rounds, and broadcasts round state
- StarterGui/RoundUI.lua — example LocalScript that listens to RoundUpdate RemoteEvent and shows a small HUD

Quick setup
1. Open Roblox Studio and create a new place or open your existing place.
2. In ReplicatedStorage, add this ModuleScript and name it `GrannyAI` (paste the file content).
3. In ServerScriptService, add a Script named `GameServer` and paste the GameServer.lua content.
4. In StarterGui, add a LocalScript named `RoundUI` and paste the StarterGui/RoundUI.lua content.

Map layout conventions (create these under `workspace.Map`):
- Map (Model or Folder)
  - Granny (Model) — include a Humanoid and set PrimaryPart to the root part
  - GrannySpawn (Part) — optional; granny will be placed here at round start
  - PatrolPoints (Folder) — Parts named in order (01,02,03...) representing patrol waypoints
  - PlayerSpawn (SpawnLocation or Folder of Parts) — where players spawn each round
  - Items (Folder) — tools/models that should be reset each round

Events and hooks
- ReplicatedStorage.RoundUpdate (RemoteEvent) — created automatically by GameServer if missing. Clients receive {state = "running"|"ended"|..., timeLeft = n}
- ReplicatedStorage.GrannyNoise (BindableEvent) — created automatically. Server forwards a RemoteEvent `GrannyNoiseRemote` if present.
  - To signal a noise from client tools, create a RemoteEvent named `GrannyNoiseRemote` in ReplicatedStorage and call it from the client with a Vector3 position. The server will forward it securely to the bindable which notifies the AI.

Tuning
- Adjust constants in ServerScriptService/GameServer.lua: ROUND_TIME, INTER_ROUND_WAIT, INFINITE_LOOP.
- Adjust GrannyAI patrol/chase/detection parameters by changing the table passed to GrannyAI.new in GameServer.

Next steps I can help with (tell me which):
- Add door/key interaction scripts and examples (items that unlock doors)
- Add animations hooks for Granny states (idle/walk/chase/attack)
- Add sounds and scripted voice lines for ambience and chase
- Add more polished UI (kill/revive states, escape counter, scoreboard)

Repository URL: https://github.com/kalemlunca-stack/roblox-granny-system
