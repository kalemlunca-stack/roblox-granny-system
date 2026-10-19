# Door & Key system + Granny animation hooks

This patch adds:
- ServerScriptService/DoorServer.lua — server-side handling for unlocking doors with keys (UseKeyRemote RemoteEvent)
- ServerScriptService/GrannyAnimator.lua — listens for GrannyState BindableEvent and plays animations/sounds on the Granny model
- ReplicatedStorage/GrannyAI.lua — updated to emit a BindableEvent (GrannyState) with state changes
- ReplicatedStorage/Tools/KeyTool/KeyClient.lua — example LocalScript to place inside a Tool named "Key"; it requests unlocking of a target door via UseKeyRemote

How doors work
1. Create a folder in Workspace named "Doors".
2. Add door Models inside it. Each door Model should contain one or more BaseParts representing the door geometry.
3. Optionally add a Bool attribute `Locked` (defaults to true if missing) and a Sound named `Unlock` under the door model.
4. To unlock, give players a Tool named `Key` (or `Key_<DoorName>` for door-specific keys) with an optional attribute `KeyName` set to the door's name. Place that Tool under ReplicatedStorage.Tools and give it to players when the round starts.

Notes on the Key Tool
- The example LocalScript expects the Tool to be named "Key" or "Key_<DoorName>" and placed in ReplicatedStorage.Tools.KeyTool as a template.
- When the player activates the tool while looking at a door (and in range), it sends a UseKeyRemote event to the server with the door's name. The server validates the player has a key tool and then unlocks the door.

Granny animations & sounds
- GrannyAI now fires a BindableEvent `ReplicatedStorage.GrannyState` with a payload {state = <string>, model = <grannyModel>} when the AI changes state (idle, patrol, chase, attack, investigate, search).
- GrannyAnimator listens for that and plays Animation objects and Sound instances on the granny model. To use it, either:
  - Put Animation objects under workspace.Map.Granny.Animations named Idle, Patrol, Chase, Attack, Investigate, Search; or
  - Put them under ReplicatedStorage.GrannyAnimations with those names.
- Add Sound instances under workspace.Map.Granny named Footstep, Scream, Attack, Unlock (Unlock is used for doors).

Next steps you might want:
- Add a server script to give Key tools to players at round start (GameServer can be updated to clone tools from ReplicatedStorage.Tools into player.Backpack).
- Replace the simple door opening with a hinge/tween for smooth animation.
- Add visual indicators (ProximityPrompt) so players know a door is locked and can interact.

