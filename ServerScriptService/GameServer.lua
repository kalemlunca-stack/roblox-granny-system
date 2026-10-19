-- EscapeManager.lua
-- Place in ServerScriptService
-- Handles the escape zone, marks players as escaped, and keeps the game loop aware of win conditions.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local roundEvent = ReplicatedStorage:WaitForChild("RoundUpdate")

local function getMapEscapeZone()
    local map = workspace:FindFirstChild("Map")
    if not map then return nil end
    return map:FindFirstChild("EscapeZone")
end

local function getOrCreateEscapedValue(player)
    local escaped = player:FindFirstChild("Escaped")
    if not escaped then
        escaped = Instance.new("BoolValue")
        escaped.Name = "Escaped"
        escaped.Value = false
        escaped.Parent = player
    end
    return escaped
end

local function countEscapedPlayers()
    local count = 0
    for _,player in ipairs(Players:GetPlayers()) do
        local escaped = getOrCreateEscapedValue(player)
        if escaped.Value then
            count = count + 1
        end
    end
    return count
end

local function broadcastEscapeState()
    local total = #Players:GetPlayers()
    local escaped = countEscapedPlayers()
    local alive = 0
    for _,player in ipairs(Players:GetPlayers()) do
        local char = player.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                alive = alive + 1
            end
        end
    end
    roundEvent:FireAllClients({
        state = "escape_update",
        timeLeft = 0,
        alive = alive,
        escaped = escaped,
        total = total,
    })
end

local function onPlayerEscaped(player)
    local escaped = getOrCreateEscapedValue(player)
    if escaped.Value then return end
    escaped.Value = true
    player:SetAttribute("Escaped", true)
    -- Keep players from being counted as alive later in the round loop
    local char = player.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = 0
            hum.JumpPower = 0
        end
    end
    broadcastEscapeState()
end

local function setupEscapeZone(zone)
    if not zone then return end
    zone.Touched:Connect(function(hit)
        local model = hit.Parent
        if not model then return end
        local player = Players:GetPlayerFromCharacter(model)
        if not player then return end
        local escaped = getOrCreateEscapedValue(player)
        if escaped.Value then return end

        local char = player.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        if (root.Position - zone.Position).Magnitude <= (zone.Size.Magnitude * 0.5) + 3 then
            onPlayerEscaped(player)
        end
    end)
end

local function resetAllEscapes()
    for _,player in ipairs(Players:GetPlayers()) do
        local escaped = getOrCreateEscapedValue(player)
        escaped.Value = false
        player:SetAttribute("Escaped", false)
        local char = player.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.WalkSpeed = 16
                hum.JumpPower = 50
            end
        end
    end
end

local escapeZone = getMapEscapeZone()
if escapeZone then
    setupEscapeZone(escapeZone)
end

Players.PlayerAdded:Connect(function(player)
    local escaped = getOrCreateEscapedValue(player)
    escaped.Value = false
    player:SetAttribute("Escaped", false)
end)

return {
    resetAllEscapes = resetAllEscapes,
    getMapEscapeZone = getMapEscapeZone,
    countEscapedPlayers = countEscapedPlayers,
    onPlayerEscaped = onPlayerEscaped,
}
