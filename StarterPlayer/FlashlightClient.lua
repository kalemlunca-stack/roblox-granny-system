-- FlashlightManager.lua
-- Place in ServerScriptService
-- Handles battery drain, panic accumulation, and flashlight state syncing.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local toggleRemote = ReplicatedStorage:FindFirstChild("FlashlightState")
if not toggleRemote then
    local remote = Instance.new("RemoteEvent")
    remote.Name = "FlashlightState"
    remote.Parent = ReplicatedStorage
    toggleRemote = remote
end

local syncRemote = ReplicatedStorage:FindFirstChild("FlashlightSync")
if not syncRemote then
    local remote = Instance.new("RemoteEvent")
    remote.Name = "FlashlightSync"
    remote.Parent = ReplicatedStorage
    syncRemote = remote
end

local function clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

local function resetPlayerFlashlight(player)
    player:SetAttribute("FlashlightOn", false)
    player:SetAttribute("FlashlightBattery", 100)
    player:SetAttribute("Panic", 0)
end

local function getGrannyModel()
    local map = workspace:FindFirstChild("Map")
    if not map then return nil end
    return map:FindFirstChild("Granny")
end

local function calculatePanic(player)
    local granny = getGrannyModel()
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not granny or not granny.PrimaryPart or not hum or not root then
        return 0
    end

    local dist = (root.Position - granny.PrimaryPart.Position).Magnitude
    local min = 0
    local max = 80
    local value = 1 - (dist / 80)
    if value < 0 then value = 0 end
    return clamp(value * 100, 0, 100)
end

local function updatePlayerState(player)
    local battery = clamp(player:GetAttribute("FlashlightBattery") or 100, 0, 100)
    local flashlightOn = player:GetAttribute("FlashlightOn") == true and battery > 0

    if flashlightOn and battery > 0 then
        battery = battery - 0.23
        if battery < 0 then battery = 0 end
    end

    local panic = calculatePanic(player)
    player:SetAttribute("FlashlightOn", flashlightOn and battery > 0)
    player:SetAttribute("FlashlightBattery", battery)
    player:SetAttribute("Panic", panic)

    syncRemote:FireClient(player, {
        battery = battery,
        panic = panic,
        on = flashlightOn and battery > 0,
    })
end

local function onPlayerAdded(player)
    resetPlayerFlashlight(player)

    toggleRemote.OnServerEvent:Connect(function(speaker, payload)
        if speaker ~= player then return end
        if type(payload) ~= "table" then return end
        local enabled = payload.enabled == true
        local battery = clamp(player:GetAttribute("FlashlightBattery") or 100, 0, 100)
        if enabled and battery <= 0 then
            enabled = false
        end
        player:SetAttribute("FlashlightOn", enabled)
        player:SetAttribute("FlashlightBattery", battery)
    end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _,player in ipairs(Players:GetPlayers()) do
    onPlayerAdded(player)
end

RunService.Heartbeat:Connect(function()
    for _,player in ipairs(Players:GetPlayers()) do
        if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
            updatePlayerState(player)
        end
    end
end)
