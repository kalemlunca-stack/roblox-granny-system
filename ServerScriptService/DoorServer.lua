-- DoorServer: handles secure unlocking of door Models in workspace.Doors
-- Place in ServerScriptService/DoorServer.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- RemoteEvent clients will call to request unlocking a door
local useKeyRemote = ReplicatedStorage:FindFirstChild("UseKeyRemote")
if not useKeyRemote then
    local re = Instance.new("RemoteEvent")
    re.Name = "UseKeyRemote"
    re.Parent = ReplicatedStorage
    useKeyRemote = re
end

-- Helper: find a door model by name under workspace.Doors
local function findDoorByName(name)
    if not workspace:FindFirstChild("Doors") then return nil end
    local doorsFolder = workspace.Doors
    local door = doorsFolder:FindFirstChild(name)
    if door and door:IsA("Model") then return door end
    return nil
end

-- Helper: check if player owns a key for this door
local function playerHasKeyForDoor(player, doorName)
    -- Check character tools first
    local function checkContainer(container)
        if not container then return false, nil end
        for _,obj in ipairs(container:GetChildren()) do
            if obj:IsA("Tool") then
                -- Either Name matches pattern Key_<DoorName> OR Tool has attribute KeyName equal to doorName OR generic Key
                if obj.Name == ("Key_" .. doorName) then
                    return true, obj
                end
                local kname = obj:GetAttribute("KeyName")
                if kname and kname == doorName then
                    return true, obj
                end
                if obj.Name == "Key" or obj:GetAttribute("MasterKey") == true then
                    return true, obj
                end
            end
        end
        return false, nil
    end
    local ok, tool = checkContainer(player.Character)
    if ok then return true, tool end
    return checkContainer(player.Backpack)
end

-- Unlock door server-side
local function unlockDoor(door)
    if not door or not door:IsA("Model") then return end
    -- store attribute
    door:SetAttribute("Locked", false)
    door:SetAttribute("Opened", true)
    -- simple open behavior: turn off collisions and optionally tween parts or rotate hinge
    for _,part in ipairs(door:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
            part.Transparency = math.clamp(part.Transparency, 0.5, 1)
        end
    end
    -- Play unlock sound if present
    local s = door:FindFirstChild("Unlock")
    if s and s:IsA("Sound") then
        s:Play()
    end
end

-- Server validation and handler
useKeyRemote.OnServerEvent:Connect(function(player, doorName)
    if typeof(doorName) ~= "string" then return end
    local door = findDoorByName(doorName)
    if not door then
        warn("UseKey: door not found: ", doorName)
        return
    end
    -- Check if door is locked (attribute default true)
    local locked = door:GetAttribute("Locked")
    if locked == nil then locked = true end
    if not locked then
        -- already unlocked
        return
    end
    -- Validate player has key
    local hasKey, keyTool = playerHasKeyForDoor(player, doorName)
    if not hasKey then
        -- optional: notify player of failure via RemoteEvent (not implemented)
        return
    end
    -- Consume key (destroy tool) — server-owned tool could be in character or backpack
    if keyTool and keyTool.Parent then
        keyTool:Destroy()
    end
    -- Unlock the door
    unlockDoor(door)
end)
