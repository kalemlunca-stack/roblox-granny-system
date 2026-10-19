-- FlashlightClient.lua
-- Place in StarterPlayerScripts or StarterGui as a LocalScript
-- Toggles the flashlight, drains battery, and displays panic/battery UI.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local localPlayerGui = player:WaitForChild("PlayerGui")

local toggleRemote = ReplicatedStorage:WaitForChild("FlashlightState")
local syncRemote = ReplicatedStorage:WaitForChild("FlashlightSync")

local flashlight = nil
local flashlightEnabled = false
local batteryValue = 100
local panicValue = 0

local function ensureFlashlightLight()
    if flashlight then return flashlight end
    local char = player.Character or player.CharacterAdded:Wait()
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    flashlight = Instance.new("PointLight")
    flashlight.Name = "Flashlight"
    flashlight.Color = Color3.fromRGB(255, 240, 180)
    flashlight.Brightness = 2.5
    flashlight.Range = 25
    flashlight.Shadows = true
    flashlight.Enabled = false
    flashlight.Parent = root
    return flashlight
end

local function createHud()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FlashlightHUD"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = localPlayerGui

    local batteryFrame = Instance.new("Frame")
    batteryFrame.Name = "BatteryFrame"
    batteryFrame.Size = UDim2.new(0, 200, 0, 22)
    batteryFrame.Position = UDim2.new(0.5, -100, 1, -60)
    batteryFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    batteryFrame.BorderSizePixel = 0
    batteryFrame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = batteryFrame

    local batteryBar = Instance.new("Frame")
    batteryBar.Name = "BatteryBar"
    batteryBar.Size = UDim2.new(0.9, 0, 1, 0)
    batteryBar.Position = UDim2.new(0.05, 0, 0, 0)
    batteryBar.BackgroundColor3 = Color3.fromRGB(255, 195, 70)
    batteryBar.BorderSizePixel = 0
    batteryBar.Parent = batteryFrame

    local batteryLabel = Instance.new("TextLabel")
    batteryLabel.Name = "BatteryLabel"
    batteryLabel.Size = UDim2.new(1, 0, 1, 0)
    batteryLabel.BackgroundTransparency = 1
    batteryLabel.Font = Enum.Font.GothamBold
    batteryLabel.TextColor3 = Color3.fromRGB(255,255,255)
    batteryLabel.TextScaled = true
    batteryLabel.Text = "BATTERY 100%"
    batteryLabel.Parent = batteryFrame

    local panicOverlay = Instance.new("Frame")
    panicOverlay.Name = "PanicOverlay"
    panicOverlay.Size = UDim2.new(1, 0, 1, 0)
    panicOverlay.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    panicOverlay.BackgroundTransparency = 0.75
    panicOverlay.Visible = false
    panicOverlay.Parent = screenGui

    return {screenGui = screenGui, batteryFrame = batteryFrame, batteryBar = batteryBar, batteryLabel = batteryLabel, panicOverlay = panicOverlay}
end

local ui = createHud()

local function setFlashlightState(enabled)
    flashlightEnabled = enabled
    local light = ensureFlashlightLight()
    if light then
        light.Enabled = enabled
        light.Brightness = enabled and 2.5 or 0
    end
    toggleRemote:FireServer({enabled = enabled})
end

local function updateHud()
    local ratio = math.max(0, math.min(1, batteryValue / 100))
    ui.batteryBar.Size = UDim2.new(ratio, 0, 1, 0)
    ui.batteryBar.Position = UDim2.new(0.05, 0, 0, 0)
    ui.batteryLabel.Text = "BATTERY " .. math.floor(batteryValue) .. "%"
    if batteryValue < 25 then
        ui.batteryBar.BackgroundColor3 = Color3.fromRGB(255, 90, 90)
    elseif batteryValue < 60 then
        ui.batteryBar.BackgroundColor3 = Color3.fromRGB(255, 188, 70)
    else
        ui.batteryBar.BackgroundColor3 = Color3.fromRGB(120, 255, 120)
    end

    local alpha = panicValue / 100
    ui.panicOverlay.Visible = panicValue > 40
    ui.panicOverlay.BackgroundTransparency = 0.75 + (alpha * 0.15)
end

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.F then
        setFlashlightState(not flashlightEnabled)
    end
end)

syncRemote.OnClientEvent:Connect(function(data)
    if type(data) ~= "table" then return end
    batteryValue = data.battery or batteryValue
    panicValue = data.panic or panicValue
    flashlightEnabled = data.on == true
    local light = ensureFlashlightLight()
    if light then
        light.Enabled = flashlightEnabled
        light.Brightness = flashlightEnabled and 2.5 or 0
    end
    updateHud()
end)

updateHud()
