-- DoorServer.lua
-- Place in ServerScriptService
-- Handles door states, unlocking with a key, tweened open/close, and guard rails for server validation.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local useKeyRemote = ReplicatedStorage:FindFirstChild("UseKeyRemote")
if not useKeyRemote then
    local re = Instance.new("RemoteEvent")
    re.Name = "UseKeyRemote"
    re.Parent = ReplicatedStorage
    useKeyRemote = re
end

local function getDoorFolder()
    if workspace:FindFirstChild("Doors") then
        return workspace.Doors
    end
    return nil
end

local function findDoor(name)
    local folder = getDoorFolder()
    if not folder then return nil end
    return folder:FindFirstChild(name)
end

local function getDoorBasePart(door)
    if not door then return nil end
    if door:IsA("Model") then
        if door.PrimaryPart then
            return door.PrimaryPart
        end
        return door:FindFirstChildWhichIsA("BasePart")
    elseif door:IsA("BasePart") then
        return door
    end
    return nil
end

local function storeOriginalPivot(door)
    if not door then return end
    if not door:GetAttribute("OriginalPivot") then
        local base = getDoorBasePart(door)
        if base then
            door:SetAttribute("OriginalPivot", tostring(base.CFrame))
        end
    end
end

local function getDoorState(door)
    local locked = door:GetAttribute("Locked")
    if locked == nil then
        door:SetAttribute("Locked", true)
        return true
    end
    return locked
end

local function playerHasKey(player, doorName)
    local function scan(container)
        if not container then return false, nil end
        for _,obj in ipairs(container:GetChildren()) do
            if obj:IsA("Tool") then
                if obj.Name == "Key" then return true, obj end
                if obj.Name == "Key_" .. doorName then return true, obj end
                local keyName = obj:GetAttribute("KeyName")
                if keyName and keyName == doorName then return true, obj end
                if obj:GetAttribute("MasterKey") == true then return true, obj end
            end
        end
        return false, nil
    end

    local ok, tool = scan(player.Character)
    if ok then return true, tool end
    return scan(player.Backpack)
end

local function tweenDoorOpen(door)
    if not door then return end
    storeOriginalPivot(door)
    local base = getDoorBasePart(door)
    if not base then return end
    local openCF = base.CFrame * CFrame.Angles(0, math.rad(75), 0)
    local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    local tween = TweenService:Create(base, tweenInfo, {CFrame = openCF})
    tween:Play()
    base.CanCollide = false
    door:SetAttribute("Open", true)
    door:SetAttribute("Locked", false)
    local sound = door:FindFirstChild("Unlock")
    if sound and sound:IsA("Sound") then
        sound:Play()
    end
end

local function tweenDoorClose(door)
    if not door then return end
    local base = getDoorBasePart(door)
    if not base then return end
    local orig = door:GetAttribute("OriginalPivot")
    if orig then
        local success, cf = pcall(function() return loadstring("return " .. orig)() end)
        if success and cf then
            local tween = TweenService:Create(base, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {CFrame = cf})
            tween:Play()
            base.CanCollide = true
            door:SetAttribute("Open", false)
            door:SetAttribute("Locked", true)
        end
    end
end

useKeyRemote.OnServerEvent:Connect(function(player, doorName)
    if typeof(doorName) ~= "string" then return end
    local door = findDoor(doorName)
    if not door then return end
    if getDoorState(door) == false then
        return -- already unlocked
    end

    local hasKey, keyTool = playerHasKey(player, doorName)
    if not hasKey then return end

    if keyTool and keyTool.Parent then
        keyTool:Destroy()
    end

    tweenDoorOpen(door)
end)

return {
    findDoor = findDoor,
    tweenDoorOpen = tweenDoorOpen,
    tweenDoorClose = tweenDoorClose,
    getDoorState = getDoorState,
}
