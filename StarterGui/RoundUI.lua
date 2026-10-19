-- GameServer: looped round manager + integrator for GrannyAI
-- Place in ServerScriptService/GameServer.lua
-- This script will create helper RemoteEvents/BindableEvents in ReplicatedStorage if missing.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local GrannyAI = require(ReplicatedStorage:WaitForChild("GrannyAI"))
local EscapeManager = require(script.Parent:WaitForChild("EscapeManager"))

local ROUND_TIME = 180 -- seconds per round (customize)
local INTER_ROUND_WAIT = 6 -- seconds between rounds
local INFINITE_LOOP = true -- keep looping rounds indefinitely

-- Ensure RemoteEvent for round updates exists
local roundEvent = ReplicatedStorage:FindFirstChild("RoundUpdate")
if not roundEvent then
    local re = Instance.new("RemoteEvent")
    re.Name = "RoundUpdate"
    re.Parent = ReplicatedStorage
    roundEvent = re
end

-- Ensure bindable for granny noise exists; client/server tools can call a RemoteEvent and server may forward it to this bindable
local noiseBindable = ReplicatedStorage:FindFirstChild("GrannyNoise")
if not noiseBindable then
    local be = Instance.new("BindableEvent")
    be.Name = "GrannyNoise"
    be.Parent = ReplicatedStorage
    noiseBindable = be
end

local map = workspace:WaitForChild("Map")
local grannyModel = map:WaitForChild("Granny")
local patrolFolder = map:FindFirstChild("PatrolPoints") -- optional
local itemsFolder = map:FindFirstChild("Items") -- optional
local spawn = map:FindFirstChild("PlayerSpawn") -- a SpawnLocation or Folder/Model of spawn points
local keyTemplate = ReplicatedStorage:FindFirstChild("KeyTool")
if not keyTemplate then
    local toolsFolder = ReplicatedStorage:FindFirstChild("Tools")
    if toolsFolder then
        keyTemplate = toolsFolder:FindFirstChild("KeyTool")
    end
end

local function getPlayerSnapshot()
    local total = 0
    local alive = 0
    local escaped = 0
    for _,player in ipairs(Players:GetPlayers()) do
        total = total + 1
        local char = player.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                alive = alive + 1
            end
        end
        local esc = player:FindFirstChild("Escaped")
        if esc and esc.Value then
            escaped = escaped + 1
        end
    end
    return {total = total, alive = alive, escaped = escaped}
end

local function resetPlayers()
    local spawns = {}
    if spawn then
        if spawn:IsA("Folder") then
            for _,v in ipairs(spawn:GetChildren()) do
                if v:IsA("SpawnLocation") or v:IsA("Part") then
                    table.insert(spawns, v)
                end
            end
        elseif spawn:IsA("SpawnLocation") or spawn:IsA("Part") then
            table.insert(spawns, spawn)
        end
    end

    for i,player in ipairs(Players:GetPlayers()) do
        local escaped = player:FindFirstChild("Escaped")
        if not escaped then
            escaped = Instance.new("BoolValue")
            escaped.Name = "Escaped"
            escaped.Value = false
            escaped.Parent = player
        else
            escaped.Value = false
        end
        player:SetAttribute("Escaped", false)

        if player and player.Character then
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.Health = hum.MaxHealth
            end
            if player.Backpack then
                for _,tool in ipairs(player.Backpack:GetChildren()) do
                    if tool:IsA("Tool") then
                        tool:Destroy()
                    end
                end
            end
            if #spawns > 0 then
                local s = spawns[((i-1) % #spawns) + 1]
                local spawnPos = s.Position or (s:GetModelCFrame and s:GetModelCFrame().p) or s.CFrame.p
                local char = player.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    char:SetPrimaryPartCFrame(CFrame.new(spawnPos + Vector3.new(0, 3, 0)))
                end
            else
                player:LoadCharacter()
            end
        else
            player:LoadCharacter()
        end

        -- Give the player a key tool each round for door unlocking
        if keyTemplate and keyTemplate:IsA("Tool") then
            local clone = keyTemplate:Clone()
            clone.Name = "Key"
            clone:SetAttribute("KeyName", "MainDoor")
            clone.Parent = player.Backpack
        end
    end
end

local function resetItems()
    if not itemsFolder then return end
    for _,item in ipairs(itemsFolder:GetChildren()) do
        local orig = item:GetAttribute("OriginalCFrame")
        if not orig then
            if item:IsA("Model") and item.PrimaryPart then
                item:SetAttribute("OriginalCFrame", tostring(item:GetPrimaryPartCFrame()))
            elseif item:IsA("BasePart") then
                item:SetAttribute("OriginalCFrame", tostring(item.CFrame))
            end
        end
        if item.Parent ~= workspace then
            item.Parent = workspace
        end
        local ocf = item:GetAttribute("OriginalCFrame")
        if ocf then
            local success, cf = pcall(function() return loadstring("return "..ocf)() end)
            if success and cf then
                if item:IsA("Model") and item.PrimaryPart then
                    item:SetPrimaryPartCFrame(cf)
                elseif item:IsA("BasePart") then
                    item.CFrame = cf
                end
            end
        end
        for _,desc in ipairs(item:GetDescendants()) do
            if desc:IsA("BasePart") then
                desc.CanCollide = true
                desc.Transparency = 0
            end
        end
    end
end

local function resetGranny()
    if not grannyModel then return end
    local spawnPart = map:FindFirstChild("GrannySpawn")
    if spawnPart and spawnPart:IsA("BasePart") then
        grannyModel:SetPrimaryPartCFrame(spawnPart.CFrame)
    end
    local hum = grannyModel:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.Health = hum.MaxHealth
    end
end

local function sendRoundUpdate(state, timeLeft)
    local snapshot = getPlayerSnapshot()
    if roundEvent and roundEvent:IsA("RemoteEvent") then
        roundEvent:FireAllClients({
            state = state,
            timeLeft = timeLeft,
            alive = snapshot.alive,
            escaped = snapshot.escaped,
            total = snapshot.total,
        })
    end
end

local currentAI = nil

spawn(function()
    while true do
        while #Players:GetPlayers() == 0 do
            wait(2)
        end

        resetItems()
        resetGranny()
        resetPlayers()
        EscapeManager.resetAllEscapes()

        if currentAI then
            currentAI:Stop()
            currentAI = nil
        end

        currentAI = GrannyAI.new(grannyModel, {
            PatrolPoints = patrolFolder,
            PatrolSpeed = 6,
            ChaseSpeed = 16,
            DetectionRange = 28,
            SightAngle = 110,
            AttackDistance = 2.5,
            HearingRange = 22,
            SearchTime = 8,
        })
        currentAI:Start()

        local timeLeft = ROUND_TIME
        sendRoundUpdate("started", timeLeft)
        while timeLeft > 0 do
            local snapshot = getPlayerSnapshot()
            local alive = snapshot.alive
            local escaped = snapshot.escaped
            local total = snapshot.total

            if alive <= 0 then
                break
            end
            if escaped >= total and total > 0 then
                break
            end

            sendRoundUpdate("running", timeLeft)
            wait(1)
            timeLeft = timeLeft - 1
        end

        sendRoundUpdate("ended", 0)
        if currentAI then
            currentAI:Stop()
            currentAI = nil
        end

        wait(INTER_ROUND_WAIT)
        if not INFINITE_LOOP then break end
    end
end)

-- Forward RemoteEvent noise calls to Bindable for convenience (safe server-side entrypoint)
local noiseRemote = ReplicatedStorage:FindFirstChild("GrannyNoiseRemote")
if noiseRemote and noiseRemote:IsA("RemoteEvent") then
    noiseRemote.OnServerEvent:Connect(function(player, pos)
        if pos and typeof(pos) == "Vector3" then
            noiseBindable:Fire(pos)
        end
    end)
end

noiseBindable.Event:Connect(function(pos)
    if currentAI then
        pcall(function() currentAI:NotifyNoise(pos) end)
    end
end)
