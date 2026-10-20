-- StealthManager.lua
-- Place in ServerScriptService
-- Enables hide spots (parts or models) where players can enter a stealth state to avoid Granny detection.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local hideRemote = ReplicatedStorage:FindFirstChild("HideState")
if not hideRemote then
    local remote = Instance.new("RemoteEvent")
    remote.Name = "HideState"
    remote.Parent = ReplicatedStorage
    hideRemote = remote
end

local function getMapHideSpots()
    local map = workspace:FindFirstChild("Map")
    if not map then return {} end
    local folder = map:FindFirstChild("HideSpots")
    if not folder then return {} end
    local spots = {}
    for _,obj in ipairs(folder:GetChildren()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            table.insert(spots, obj)
        end
    end
    return spots
end

local function getLocalSpotObject(player)
    local char = player.Character
    if not char then return nil end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    for _,spot in ipairs(getMapHideSpots()) do
        local origin = spot:IsA("Model") and spot.PrimaryPart or spot
        if origin and (origin.Position - root.Position).Magnitude <= 6 then
            return spot
        end
    end
    return nil
end

local function ensurePlayerHideAttrs(player)
    if player:GetAttribute("IsHidden") == nil then
        player:SetAttribute("IsHidden", false)
    end
end

local function updateHideState(player)
    local spot = getLocalSpotObject(player)
    ensurePlayerHideAttrs(player)
    if spot then
        player:SetAttribute("IsHidden", true)
        player:SetAttribute("StealthLevel", 1)
        hideRemote:FireClient(player, {isHidden = true})
    else
        player:SetAttribute("IsHidden", false)
        player:SetAttribute("StealthLevel", 0)
        hideRemote:FireClient(player, {isHidden = false})
    end
end

local function bindHideSetup(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        updateHideState(player)
    end)

    hideRemote.OnServerEvent:Connect(function(speaker, payload)
        if speaker ~= player then return end
        if type(payload) ~= "table" then return end
        local shouldHide = payload.hide == true and getLocalSpotObject(player) ~= nil
        player:SetAttribute("IsHidden", shouldHide)
        player:SetAttribute("StealthLevel", shouldHide and 1 or 0)
    end)
end

Players.PlayerAdded:Connect(function(player)
    bindHideSetup(player)
    ensurePlayerHideAttrs(player)
end)

for _,player in ipairs(Players:GetPlayers()) do
    bindHideSetup(player)
end

local hideLoop = game:GetService("RunService").Heartbeat:Connect(function()
    for _,player in ipairs(Players:GetPlayers()) do
        updateHideState(player)
    end
end)

return {
    updateHideState = updateHideState,
}
