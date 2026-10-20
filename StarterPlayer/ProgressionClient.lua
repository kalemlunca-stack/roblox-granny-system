-- ProgressionManager.lua
-- Place in ServerScriptService
-- Adds map progression, unlockables, and persistent progression data.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local progressionStore = DataStoreService:GetDataStore("RobloxHorrorProgression")

local function getProfile(player)
    local profile = player:GetAttribute("Profile")
    if profile then return profile end
    profile = {
        unlockedMaps = {"Default"},
        bestScore = 0,
        totalEscapes = 0,
        totalRounds = 0,
    }
    player:SetAttribute("Profile", profile)
    return profile
end

local function saveProfile(player)
    local profile = getProfile(player)
    local success, err = pcall(function()
        progressionStore:SetAsync("player_" .. player.UserId, profile)
    end)
    if not success then
        warn("Failed to save profile:", err)
    end
end

local function loadProfile(player)
    local success, data = pcall(function()
        return progressionStore:GetAsync("player_" .. player.UserId)
    end)
    if success and data then
        player:SetAttribute("Profile", data)
        return data
    end
    local empty = {
        unlockedMaps = {"Default"},
        bestScore = 0,
        totalEscapes = 0,
        totalRounds = 0,
    }
    player:SetAttribute("Profile", empty)
    return empty
end

local function awardProgress(player, score)
    local profile = getProfile(player)
    if score > (profile.bestScore or 0) then
        profile.bestScore = score
    end
    profile.totalRounds = (profile.totalRounds or 0) + 1
    if score > 0 then
        profile.totalEscapes = (profile.totalEscapes or 0) + 1
    end
    if #profile.unlockedMaps < 2 then
        table.insert(profile.unlockedMaps, "House_01")
    end
    player:SetAttribute("Profile", profile)
    saveProfile(player)
end

local function unlockMap(player, mapName)
    local profile = getProfile(player)
    for _,name in ipairs(profile.unlockedMaps) do
        if name == mapName then return end
    end
    table.insert(profile.unlockedMaps, mapName)
    player:SetAttribute("Profile", profile)
    saveProfile(player)
end

Players.PlayerAdded:Connect(function(player)
    local profile = loadProfile(player)
    player:SetAttribute("Profile", profile)
end)

for _,player in ipairs(Players:GetPlayers()) do
    local profile = loadProfile(player)
    player:SetAttribute("Profile", profile)
end

return {
    loadProfile = loadProfile,
    saveProfile = saveProfile,
    awardProgress = awardProgress,
    unlockMap = unlockMap,
}
