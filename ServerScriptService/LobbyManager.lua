-- LobbyManager.lua
-- Place in ServerScriptService
-- Handles lobby state and round transitions with a clean start-of-round sequence.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local lobbyEvent = ReplicatedStorage:FindFirstChild("LobbyState")
if not lobbyEvent then
    local re = Instance.new("RemoteEvent")
    re.Name = "LobbyState"
    re.Parent = ReplicatedStorage
    lobbyEvent = re
end

local lobbyState = {
    active = false,
    countdown = 5,
}

local function broadcastLobbyState()
    lobbyEvent:FireAllClients({
        active = lobbyState.active,
        countdown = lobbyState.countdown,
    })
end

local function beginLobbyCountdown()
    lobbyState.active = true
    lobbyState.countdown = 5
    broadcastLobbyState()

    while lobbyState.active and lobbyState.countdown > 0 do
        task.wait(1)
        lobbyState.countdown = lobbyState.countdown - 1
        broadcastLobbyState()
    end

    lobbyState.active = false
    lobbyState.countdown = 0
    broadcastLobbyState()
end

local function resetLobby()
    lobbyState.active = false
    lobbyState.countdown = 5
    broadcastLobbyState()
end

Players.PlayerAdded:Connect(function()
    resetLobby()
end)

return {
    beginLobbyCountdown = beginLobbyCountdown,
    resetLobby = resetLobby,
    broadcastLobbyState = broadcastLobbyState,
}
