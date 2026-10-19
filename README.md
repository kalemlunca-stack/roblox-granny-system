# Door & Key system + Escape loop + smarter AI

This project now includes a more complete horror-game loop with:
- looped round system
- Granny AI with chase/search and ambush behavior
- door unlocking with key validation
- escape win-state tracking
- HUD + overlay feedback
- atmospheric heartbeat-style sound effects

Key updates
- ReplicatedStorage/GrannyAI.lua — now includes simple hide and ambush behavior using `HidePoints` and `AmbushPoints` folders in `workspace.Map`
- ServerScriptService/DoorServer.lua — unlocks doors with tweened motion, state tracking, and door locking behavior
- ServerScriptService/AtmosphereController.lua — ambient heartbeat + horror sound logic based on distance from Granny
- StarterGui/RoundOverlay.lua — end-of-round overlay for win/lose states
- ServerScriptService/GameServer.lua — improved round loop and key distribution

Map setup
Create a Workspace.Map folder with these pieces:
- Map
  - Granny (Model, with Humanoid and PrimaryPart)
  - GrannySpawn (Part)
  - PatrolPoints (Folder of waypoints)
  - HidePoints (Folder of Part positions or Models) — used by Granny to hide/peek around corners
  - AmbushPoints (Folder of Part positions or Models) — used by Granny to wait in ambush
  - PlayerSpawn (SpawnLocation or Part/Folder)
  - EscapeZone (Part) — players must touch this to escape
  - Doors (Folder) — door models to unlock with keys
  - Items (Folder) — optional items reset each round

Door usage
- Place doors in Workspace.Doors
- The keys are given automatically to players each round by GameServer
- Use a Tool named `Key` or `Key_<DoorName>` while facing the door and within range
- A door will unlock via tween animation and set `Locked = false` on the model

AI behavior notes
- Granny will patrol and then move to ambush points if no player is detected
- If a player is lost, Granny enters a search state and investigates the last known position
- If players make noise or trigger an event, the AI can move toward the noise location

Atmosphere and effects
- The AtmosphereController script listens to each player and plays a heartbeat sound when Granny gets close
- The project is ready for more audio/artifacts like footsteps, static, and ambient sound assets under the Granny model or in a dedicated folder

Next ideas to continue expanding the game
- Add random item placement and objective clues
- Add flashlight battery + panic meter
- Add generator events and power-out states
- Add end-of-round scoreboard and reward currency
- Add hidey spots and creep-travel map loops
- Add more dynamic sounds: footsteps, whispering, thunder, radio static

Repository URL: https://github.com/kalemlunca-stack/roblox-granny-system
