-- GeneratorManager.lua
-- Place in ServerScriptService
-- Adds a generator with activation prompt and a power state broadcast for client-side darkness effects.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local powerRemote = ReplicatedStorage:FindFirstChild("PowerState")
if not powerRemote then
    local remote = Instance.new("RemoteEvent")
    remote.Name = "PowerState"
    remote.Parent = ReplicatedStorage
    powerRemote = remote
end

local function getMapGenerator()
    local map = workspace:FindFirstChild("Map")
    if not map then return nil end
    local gen = map:FindFirstChild("Generator")
    if gen then return gen end
    local folder = map:FindFirstChild("GeneratorFolder")
    if folder and folder:FindFirstChild("Generator") then
        return folder.Generator
    end
    return nil
end

local generatorState = {
    powerOn = false,
}

local function syncGeneratorState()
    powerRemote:FireAllClients({
        powerOn = generatorState.powerOn,
    })
end

local function setGeneratorVisualState(gen)
    if not gen then return end
    local glow = gen:FindFirstChild("Glow")
    if glow and glow:IsA("PointLight") then
        glow.Enabled = generatorState.powerOn
    end
    local base = gen:FindFirstChild("Base") or gen:FindFirstChildWhichIsA("BasePart")
    if base then
        base.Color = generatorState.powerOn and Color3.fromRGB(120, 255, 120) or Color3.fromRGB(255, 80, 80)
    end
    local sound = gen:FindFirstChild("GeneratorSound")
    if sound and sound:IsA("Sound") then
        if generatorState.powerOn and not sound.IsPlaying then
            sound:Play()
        elseif not generatorState.powerOn and sound.IsPlaying then
            sound:Stop()
        end
    end
end

local function setupGeneratorPrompt(gen)
    if not gen then return end
    local prompt = gen:FindFirstChildOfClass("ProximityPrompt")
    if prompt then
        prompt.Triggered:Connect(function(player)
            if generatorState.powerOn then return end
            generatorState.powerOn = true
            setGeneratorVisualState(gen)
            syncGeneratorState()
        end)
        return
    end

    local base = gen:FindFirstChild("Base") or gen:FindFirstChildWhichIsA("BasePart") or gen:FindFirstChildOfClass("Part")
    if not base then return end

    local newPrompt = Instance.new("ProximityPrompt")
    newPrompt.ActionText = "Start Generator"
    newPrompt.ObjectText = "Power Room"
    newPrompt.HoldDuration = 1.5
    newPrompt.MaxActivationDistance = 12
    newPrompt.RequiresLineOfSight = false
    newPrompt.Parent = base
    newPrompt.Triggered:Connect(function(player)
        if generatorState.powerOn then return end
        generatorState.powerOn = true
        setGeneratorVisualState(gen)
        syncGeneratorState()
    end)
end

local function ensureGeneratorAssets(gen)
    if not gen then return end

    local base = gen:FindFirstChild("Base") or gen:FindFirstChildWhichIsA("BasePart") or gen:FindFirstChildOfClass("Part")
    if not base then
        local part = Instance.new("Part")
        part.Name = "Base"
        part.Size = Vector3.new(3, 3, 3)
        part.Position = gen.Position or Vector3.new(0, 5, 0)
        part.Anchored = true
        part.Material = Enum.Material.Metal
        part.Parent = gen
        base = part
    end

    if not gen:FindFirstChild("Glow") then
        local glow = Instance.new("PointLight")
        glow.Name = "Glow"
        glow.Color = Color3.fromRGB(120, 255, 120)
        glow.Brightness = 2.5
        glow.Range = 12
        glow.Enabled = false
        glow.Parent = base
    end

    if not gen:FindFirstChild("GeneratorSound") then
        local sound = Instance.new("Sound")
        sound.Name = "GeneratorSound"
        sound.SoundId = "rbxassetid://184845761"
        sound.Volume = 0.4
        sound.Looped = true
        sound.Parent = gen
    end
end

local function resetGeneratorState()
    generatorState.powerOn = false
    local gen = getMapGenerator()
    if not gen then return end
    ensureGeneratorAssets(gen)
    setGeneratorVisualState(gen)
    syncGeneratorState()
end

local gen = getMapGenerator()
if gen then
    ensureGeneratorAssets(gen)
    setupGeneratorPrompt(gen)
    resetGeneratorState()
end

return {
    getMapGenerator = getMapGenerator,
    resetGeneratorState = resetGeneratorState,
    isPowerOn = function() return generatorState.powerOn end,
}

