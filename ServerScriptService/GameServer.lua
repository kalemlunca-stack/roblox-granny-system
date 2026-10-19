-- RewardsManager.lua
-- Place in ServerScriptService
-- Tracks player stats, round rewards, and persistent currency/XP in leaderstats.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local roundEvent = ReplicatedStorage:FindFirstChild("RoundUpdate")

local DEFAULT_REWARD = {
    escape = 100,
    survive = 30,
    win = 50,
    death = 0,
}

local function ensureLeaderstats(player)
    if player:FindFirstChild("leaderstats") then
        return player.leaderstats
    end

    local ls = Instance.new("Folder")
    ls.Name = "leaderstats"
    ls.Parent = player

    local xp = Instance.new("IntValue")
    xp.Name = "XP"
    xp.Value = player:GetAttribute("XP") or 0
    xp.Parent = ls

    local coins = Instance.new("IntValue")
    coins.Name = "Coins"
    coins.Value = player:GetAttribute("Coins") or 0
    coins.Parent = ls

    local escapes = Instance.new("IntValue")
    escapes.Name = "Escapes"
    escapes.Value = player:GetAttribute("Escapes") or 0
    escapes.Parent = ls

    local rounds = Instance.new("IntValue")
    rounds.Name = "Rounds"
    rounds.Value = player:GetAttribute("Rounds") or 0
    rounds.Parent = ls

    return ls
end

local function getInt(player, name, default)
    local value = player:GetAttribute(name)
    if value == nil then
        value = default
        player:SetAttribute(name, value)
    end
    return value
end

local function syncLeaderstats(player)
    local ls = ensureLeaderstats(player)
    local xp = ls:FindFirstChild("XP")
    local coins = ls:FindFirstChild("Coins")
    local escapes = ls:FindFirstChild("Escapes")
    local rounds = ls:FindFirstChild("Rounds")
    if xp then xp.Value = getInt(player, "XP", 0) end
    if coins then coins.Value = getInt(player, "Coins", 0) end
    if escapes then escapes.Value = getInt(player, "Escapes", 0) end
    if rounds then rounds.Value = getInt(player, "Rounds", 0) end
end

local function awardPlayer(player, rewardType)
    local reward = DEFAULT_REWARD[rewardType] or 0
    if reward <= 0 then return end

    local xp = getInt(player, "XP", 0)
    local coins = getInt(player, "Coins", 0)
    xp = xp + reward
    coins = coins + reward
    player:SetAttribute("XP", xp)
    player:SetAttribute("Coins", coins)
    syncLeaderstats(player)
end

local function updateRoundStats(player, escaped, survivedSeconds)
    local rounds = getInt(player, "Rounds", 0)
    player:SetAttribute("Rounds", rounds + 1)
    syncLeaderstats(player)

    if escaped then
        local escapes = getInt(player, "Escapes", 0)
        player:SetAttribute("Escapes", escapes + 1)
        awardPlayer(player, "escape")
        awardPlayer(player, "win")
    else
        awardPlayer(player, "survive")
    end
end

Players.PlayerAdded:Connect(function(player)
    syncLeaderstats(player)
end)

for _,player in ipairs(Players:GetPlayers()) do
    syncLeaderstats(player)
end

roundEvent.OnServerEvent:Connect(function(player, payload)
    if not payload then return end
    updateRoundStats(player, payload.escaped == true, payload.survivedSeconds or 0)
end)

return {
    awardPlayer = awardPlayer,
    syncLeaderstats = syncLeaderstats,
    updateRoundStats = updateRoundStats,
}
