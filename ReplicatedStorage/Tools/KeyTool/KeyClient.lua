-- KeyTool LocalScript (client)
-- Place this LocalScript inside a Tool named "Key" stored in ReplicatedStorage.Tools.KeyTool
-- When activated, it raycasts from the player's mouse and requests the server to use the key on the targeted door.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local mouse = player:GetMouse()

local tool = script.Parent
local useKeyRemote = ReplicatedStorage:WaitForChild("UseKeyRemote")
local MAX_DISTANCE = 12

local function findDoorFromTarget(target)
    if not target then return nil end
    local model = target:FindFirstAncestorOfClass("Model")
    if not model then return nil end
    if model.Parent and model.Parent.Name == "Doors" then
        return model
    end
    return nil
end

tool.Activated:Connect(function()
    local target = mouse.Target
    local doorModel = findDoorFromTarget(target)
    if not doorModel then
        -- optional: provide feedback to player (e.g., small GUI flash)
        return
    end
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local dist = (char.HumanoidRootPart.Position - doorModel:GetModelCFrame().p).Magnitude
    if dist > MAX_DISTANCE then
        -- out of range
        return
    end
    -- Request server to use key on this door
    useKeyRemote:FireServer(doorModel.Name)
end)
