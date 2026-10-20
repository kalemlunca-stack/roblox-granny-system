-- AudioEventManager.lua
-- Place in ServerScriptService
-- Triggers dynamic sound events like whispers, thunder, static, and chase cues based on round state and Granny proximity.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local eventRemote = ReplicatedStorage:FindFirstChild("AudioEvent")
if not eventRemote then
    local remote = Instance.new("RemoteEvent")
    remote.Name = "AudioEvent"
    remote.Parent = ReplicatedStorage
    eventRemote = remote
end

local map = workspace:FindFirstChild("Map")
local granny = map and map:FindFirstChild("Granny")

local function getGrannyRoot()
    if not granny then return nil end
    return granny.PrimaryPart or granny:FindFirstChild("HumanoidRootPart")
end

local function playForPlayer(player, soundName)
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then return end
    local sound = playerGui:FindFirstChild(soundName)
    if not sound then
        sound = Instance.new("Sound")
        sound.Name = soundName
        sound.Parent = playerGui
    end
    if sound.SoundId == "" then
        -- use a default horror audio id by category
        if soundName == "Whisper" then
            sound.SoundId = "rbxassetid://140526013"
        elseif soundName == "Thunder" then
            sound.SoundId = "rbxassetid://911893961"
        elseif soundName == "Static" then
            sound.SoundId = "rbxassetid://185098254"
        elseif soundName == "Chase" then
            sound.SoundId = "rbxassetid://184845761"
        end
    end
    sound.Volume = 0.5
    sound:Play()
end

local function triggerAmbientEvent()
    local index = math.random(1, 3)
    local events = {"Whisper", "Thunder", "Static"}
    local chosen = events[index]
    for _,player in ipairs(Players:GetPlayers()) do
        playForPlayer(player, chosen)
    end
end

local function triggerChaseEvent()
    for _,player in ipairs(Players:GetPlayers()) do
        playForPlayer(player, "Chase")
    end
end

local function syncEventToClients(eventName)
    eventRemote:FireAllClients({eventName = eventName})
end

local lastAmbientCheck = 0
local lastChaseCheck = 0

RunService.Heartbeat:Connect(function()
    local root = getGrannyRoot()
    if not root then return end

    local now = os.clock()
    if now - lastAmbientCheck > 18 then
        lastAmbientCheck = now
        triggerAmbientEvent()
        syncEventToClients("Ambient")
    end

    -- If Granny is close to a player, play chase audio to intensify tension
    for _,player in ipairs(Players:GetPlayers()) do
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local dist = (char.HumanoidRootPart.Position - root.Position).Magnitude
            if dist < 18 and now - lastChaseCheck > 10 then
                lastChaseCheck = now
                triggerChaseEvent()
                syncEventToClients("Chase")
                break
            end
        end
    end
end)

return {
    triggerAmbientEvent = triggerAmbientEvent,
    triggerChaseEvent = triggerChaseEvent,
}
