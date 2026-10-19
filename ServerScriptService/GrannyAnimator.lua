-- GrannyAnimator: listens for GrannyState events and plays animations & sounds
-- Place this in ServerScriptService/GrannyAnimator.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local stateEvent = ReplicatedStorage:FindFirstChild("GrannyState")
if not stateEvent then
    local be = Instance.new("BindableEvent")
    be.Name = "GrannyState"
    be.Parent = ReplicatedStorage
    stateEvent = be
end

-- Animation names/ids: create Animation objects named Idle/Patrol/Chase/Attack under ReplicatedStorage.GrannyAnimations or under the Granny model's folder named "Animations".

local function getAnimationsForModel(model)
    -- prefer animations stored under the model
    if model:FindFirstChild("Animations") then
        return model.Animations
    end
    if ReplicatedStorage:FindFirstChild("GrannyAnimations") then
        return ReplicatedStorage.GrannyAnimations
    end
    return nil
end

local activeTracks = {}

local function stopAllTracks(humanoid)
    for _,track in pairs(activeTracks) do
        if track and track.IsPlaying then
            pcall(function() track:Stop() end)
        end
    end
    activeTracks = {}
end

stateEvent.Event:Connect(function(payload)
    if not payload or not payload.model then return end
    local model = payload.model
    local state = payload.state
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    local animFolder = getAnimationsForModel(model)
    -- Play sounds attached to the model
    local function playSound(name, loop)
        local s = model:FindFirstChild(name)
        if s and s:IsA("Sound") then
            s.Looped = loop or false
            s:Play()
        end
    end

    if state == "idle" then
        stopAllTracks(humanoid)
        playSound("Footstep", false)
        if animFolder and animFolder:FindFirstChild("Idle") then
            local anim = animFolder.Idle
            local track = humanoid:LoadAnimation(anim)
            track:Play()
            activeTracks.Idle = track
        end
    elseif state == "patrol" then
        stopAllTracks(humanoid)
        playSound("Footstep", true)
        if animFolder and animFolder:FindFirstChild("Patrol") then
            local anim = animFolder.Patrol
            local track = humanoid:LoadAnimation(anim)
            track:Play()
            activeTracks.Patrol = track
        end
    elseif state == "chase" then
        stopAllTracks(humanoid)
        playSound("Footstep", true)
        playSound("Scream", false)
        if animFolder and animFolder:FindFirstChild("Chase") then
            local anim = animFolder.Chase
            local track = humanoid:LoadAnimation(anim)
            track:Play()
            activeTracks.Chase = track
        end
    elseif state == "attack" then
        stopAllTracks(humanoid)
        playSound("Attack", false)
        if animFolder and animFolder:FindFirstChild("Attack") then
            local anim = animFolder.Attack
            local track = humanoid:LoadAnimation(anim)
            track:Play()
            activeTracks.Attack = track
        end
    elseif state == "investigate" then
        stopAllTracks(humanoid)
        playSound("Footstep", true)
        if animFolder and animFolder:FindFirstChild("Investigate") then
            local anim = animFolder.Investigate
            local track = humanoid:LoadAnimation(anim)
            track:Play()
            activeTracks.Investigate = track
        end
    elseif state == "search" then
        stopAllTracks(humanoid)
        playSound("Footstep", true)
        if animFolder and animFolder:FindFirstChild("Search") then
            local anim = animFolder.Search
            local track = humanoid:LoadAnimation(anim)
            track:Play()
            activeTracks.Search = track
        end
    end
end)
