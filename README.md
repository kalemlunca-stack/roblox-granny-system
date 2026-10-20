-- RoundSummary.lua
-- Place in StarterPlayerScripts or StarterGui as a LocalScript
-- Displays the end-of-round summary for wins/losses and round progression.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "RoundSummaryGui"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 420, 0, 220)
panel.Position = UDim2.new(0.5, -210, 0.5, -110)
panel.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
panel.BackgroundTransparency = 0.2
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 16)
corner.Parent = panel

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -30, 0, 36)
title.Position = UDim2.new(0, 15, 0, 10)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextColor3 = Color3.fromRGB(255,255,255)
title.Text = "ROUND SUMMARY"
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

local result = Instance.new("TextLabel")
result.Size = UDim2.new(1, -30, 0, 38)
result.Position = UDim2.new(0, 15, 0, 56)
result.BackgroundTransparency = 1
result.Font = Enum.Font.GothamBold
result.TextColor3 = Color3.fromRGB(255, 210, 80)
result.Text = "YOU ESCAPED"
result.TextXAlignment = Enum.TextXAlignment.Left
result.Parent = panel

local reward = Instance.new("TextLabel")
reward.Size = UDim2.new(1, -30, 0, 28)
reward.Position = UDim2.new(0, 15, 0, 100)
reward.BackgroundTransparency = 1
reward.Font = Enum.Font.Gotham
reward.TextColor3 = Color3.fromRGB(220, 220, 220)
reward.Text = "Reward: +100 XP +100 Coins"
reward.TextXAlignment = Enum.TextXAlignment.Left
reward.Parent = panel

local nextMap = Instance.new("TextLabel")
nextMap.Size = UDim2.new(1, -30, 0, 28)
nextMap.Position = UDim2.new(0, 15, 0, 132)
nextMap.BackgroundTransparency = 1
nextMap.Font = Enum.Font.Gotham
nextMap.TextColor3 = Color3.fromRGB(180, 200, 255)
nextMap.Text = "Next map: House_01"
nextMap.TextXAlignment = Enum.TextXAlignment.Left
nextMap.Parent = panel

local function showSummary(success)
    panel.Visible = true
    result.Text = success and "YOU ESCAPED" or "YOU DIED"
    reward.Text = success and "Reward: +100 XP +100 Coins" or "Reward: +30 XP +30 Coins"
    nextMap.Text = "Next map: House_01"
    task.delay(3, function()
        panel.Visible = false
    end)
end

local roundEvent = ReplicatedStorage:FindFirstChild("RoundUpdate")
if roundEvent then
    roundEvent.OnClientEvent:Connect(function(data)
        if not data then return end
        if data.state == "ended" then
            showSummary((data.escaped or 0) > 0)
        end
    end)
end
