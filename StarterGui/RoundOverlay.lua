-- AtmosphereController.lua
-- Place in ServerScriptService
-- Adds ambient horror effects like heartbeat, nearby thunder, and low-volume ambience based on Granny distance.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local roundEvent = ReplicatedStorage:FindFirstChild("RoundUpdate")
local map = workspace:FindFirstChild("Map")
local grannyModel = map and map:FindFirstChild("Granny")

local function ensureSound(parent, name, soundId, volume, looped)
    local sound = parent:FindFirstChild(name)
    if not sound then
        sound = Instance.new("Sound")
        sound.Name = name
        sound.SoundId = soundId
        sound.Volume = volume
        sound.Looped = looped or false
        sound.Parent = parent
    end
    return sound
end

local function prepareEnvironmentSounds()
    if not map then return end
    local granny = map:FindFirstChild("Granny")
    if not granny then return end

    ensureSound(granny, "Heartbeat", "rbxassetid://182948364", 0.7, true)
    ensureSound(granny, "Ambience", "rbxassetid://911893961", 0.2, true)
    ensureSound(granny, "Scream", "rbxassetid://91341313", 1.2, false)
end

local function updatePlayerAtmosphere(player)
    if not player.Character then return end
    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
    local hum = player.Character:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    if not grannyModel or not grannyModel.PrimaryPart then return end
    local dist = (hrp.Position - grannyModel.PrimaryPart.Position).Magnitude

    local heartbeat = player.Character:FindFirstChild("HeartbeatSound")
    if not heartbeat then
        heartbeat = Instance.new("Sound")
        heartbeat.Name = "HeartbeatSound"
        heartbeat.SoundId = "rbxassetid://182948364"
        heartbeat.Volume = 0.4
        heartbeat.Looped = true
        heartbeat.Parent = player.Character
    end

    if dist < 20 then
        heartbeat.Volume = 1.0
        if not heartbeat.IsPlaying then heartbeat:Play() end
    elseif dist < 40 then
        heartbeat.Volume = 0.5
        if not heartbeat.IsPlaying then heartbeat:Play() end
    else
        heartbeat.Volume = 0.1
        if heartbeat.IsPlaying then heartbeat:Stop() end
    end
end

prepareEnvironmentSounds()

RunService.Heartbeat:Connect(function()
    for _,player in ipairs(Players:GetPlayers()) do
        updatePlayerAtmosphere(player)
    end
end)
