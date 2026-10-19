-- LocalScript for a simple Round UI
-- Place this in StarterGui as a LocalScript (e.g., StarterGui/RoundUI.lua)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local roundEvent = ReplicatedStorage:WaitForChild("RoundUpdate")

-- Create a simple ScreenGui with a label
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RoundUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local label = Instance.new("TextLabel")
label.Size = UDim2.new(0, 220, 0, 60)
label.Position = UDim2.new(0.5, -110, 0, 20)
label.BackgroundTransparency = 0.4
label.BackgroundColor3 = Color3.fromRGB(0,0,0)
label.TextColor3 = Color3.fromRGB(255,255,255)
label.TextScaled = true
label.Font = Enum.Font.SourceSansBold
label.Text = "Waiting for round..."
label.Parent = screenGui

local function updateUI(data)
    if not data then return end
    local state = data.state or "idle"
    local timeLeft = data.timeLeft or 0
    if state == "started" or state == "running" then
        label.Text = string.format("Round: %s  |  Time: %d", state, timeLeft)
    elseif state == "ended" then
        label.Text = "Round ended"
        wait(2)
        label.Text = "Waiting for round..."
    else
        label.Text = "Waiting for round..."
    end
end

roundEvent.OnClientEvent:Connect(updateUI)
