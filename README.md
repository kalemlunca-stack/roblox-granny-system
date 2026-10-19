-- Scoreboard.lua
-- Place in StarterGui as a LocalScript
-- Displays persistent player stats (XP, Coins, Escapes, Rounds).

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "ScoreboardGui"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.new(0, 210, 0, 150)
panel.Position = UDim2.new(0.02, 0, 0.15, 0)
panel.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
panel.BackgroundTransparency = 0.2
panel.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = panel

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 30)
title.Position = UDim2.new(0, 10, 0, 8)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextColor3 = Color3.fromRGB(255,255,255)
title.Text = "STATS"
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

local xp = Instance.new("TextLabel")
xp.Size = UDim2.new(1, -30, 0, 18)
xp.Position = UDim2.new(0, 15, 0, 42)
xp.BackgroundTransparency = 1
xp.Font = Enum.Font.Gotham
xp.TextColor3 = Color3.fromRGB(255,255,255)
xp.Text = "XP: 0"
xp.TextXAlignment = Enum.TextXAlignment.Left
xp.Parent = panel

local coins = Instance.new("TextLabel")
coins.Size = UDim2.new(1, -30, 0, 18)
coins.Position = UDim2.new(0, 15, 0, 62)
coins.BackgroundTransparency = 1
coins.Font = Enum.Font.Gotham
coins.TextColor3 = Color3.fromRGB(255,255,255)
coins.Text = "Coins: 0"
coins.TextXAlignment = Enum.TextXAlignment.Left
coins.Parent = panel

local escapes = Instance.new("TextLabel")
escapes.Size = UDim2.new(1, -30, 0, 18)
escapes.Position = UDim2.new(0, 15, 0, 82)
escapes.BackgroundTransparency = 1
escapes.Font = Enum.Font.Gotham
escapes.TextColor3 = Color3.fromRGB(255,255,255)
escapes.Text = "Escapes: 0"
escapes.TextXAlignment = Enum.TextXAlignment.Left
escapes.Parent = panel

local rounds = Instance.new("TextLabel")
rounds.Size = UDim2.new(1, -30, 0, 18)
rounds.Position = UDim2.new(0, 15, 0, 102)
rounds.BackgroundTransparency = 1
rounds.Font = Enum.Font.Gotham
rounds.TextColor3 = Color3.fromRGB(255,255,255)
rounds.Text = "Rounds: 0"
rounds.TextXAlignment = Enum.TextXAlignment.Left
rounds.Parent = panel

local function syncStats()
    local ls = player:FindFirstChild("leaderstats")
    if not ls then return end
    xp.Text = "XP: " .. tostring(ls:FindFirstChild("XP") and ls.XP.Value or 0)
    coins.Text = "Coins: " .. tostring(ls:FindFirstChild("Coins") and ls.Coins.Value or 0)
    escapes.Text = "Escapes: " .. tostring(ls:FindFirstChild("Escapes") and ls.Escapes.Value or 0)
    rounds.Text = "Rounds: " .. tostring(ls:FindFirstChild("Rounds") and ls.Rounds.Value or 0)
end

player.CharacterAdded:Connect(syncStats)
player:GetPropertyChangedSignal("leaderstats"):Connect(syncStats)

syncStats()
