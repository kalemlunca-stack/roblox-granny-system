-- Updated GrannyAI ModuleScript with state events
-- Place this file in ReplicatedStorage as GrannyAI (overwrites previous)

local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Ensure a BindableEvent exists for Granny state changes
local stateEvent = ReplicatedStorage:FindFirstChild("GrannyState")
if not stateEvent then
    local be = Instance.new("BindableEvent")
    be.Name = "GrannyState"
    be.Parent = ReplicatedStorage
    stateEvent = be
end

local GrannyAI = {}
GrannyAI.__index = GrannyAI

local DEFAULTS = {
    PatrolPoints = nil,
    PatrolSpeed = 8,
    ChaseSpeed = 16,
    DetectionRange = 28,
    SightAngle = 100,
    AttackDistance = 3,
    HearingRange = 20,
    RepathInterval = 1.0,
    SearchTime = 8,
}

local function getDistance(a, b)
    return (a - b).Magnitude
end

local function isInFOV(sourceCFrame, sourcePos, targetPos, angle)
    local forward = sourceCFrame.LookVector
    local dir = (targetPos - sourcePos).Unit
    local dot = forward:Dot(dir)
    local deg = math.deg(math.acos(math.clamp(dot, -1, 1)))
    return deg <= (angle/2)
end

function GrannyAI.new(model, opts)
    assert(model and model.PrimaryPart, "Granny model must have PrimaryPart set")
    local self = setmetatable({}, GrannyAI)
    opts = opts or {}
    for k,v in pairs(DEFAULTS) do
        self[k] = opts[k] ~= nil and opts[k] or v
    end
    for k,v in pairs(opts) do self[k] = v end
    self.Model = model
    self.Humanoid = model:FindFirstChildOfClass("Humanoid")
    self.PrimaryPart = model.PrimaryPart
    self._running = false
    self._currentTarget = nil
    self._patrolIndex = 1
    self._lastPath = nil
    self._isChasing = false
    self._lastSeenTime = 0
    self._state = "idle"
    return self
end

function GrannyAI:_setState(state)
    if self._state == state then return end
    self._state = state
    -- Fire global BindableEvent so other scripts (animator/sounds) can respond
    local ok, err = pcall(function()
        stateEvent:Fire({state = state, model = self.Model})
    end)
    if not ok then
        warn("Failed to fire GrannyState: ", err)
    end
end

function GrannyAI:NotifyNoise(pos)
    if not self._running then return end
    if getDistance(self.PrimaryPart.Position, pos) <= self.HearingRange then
        self._investigatePos = pos
        self._isChasing = false
        self:_setState("investigate")
    end
end

function GrannyAI:_findPlayer()
    local players = game:GetService("Players"):GetPlayers()
    local bestPlayer = nil
    local bestDist = math.huge
    for _,p in ipairs(players) do
        if p.Character and p.Character:FindFirstChild("Humanoid") and p.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = p.Character.HumanoidRootPart
            local dist = getDistance(self.PrimaryPart.Position, hrp.Position)
            if dist <= self.DetectionRange and dist < bestDist then
                if isInFOV(self.PrimaryPart.CFrame, self.PrimaryPart.Position, hrp.Position, self.SightAngle) then
                    local rayParams = RaycastParams.new()
                    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
                    rayParams.FilterDescendantsInstances = {self.Model}
                    local ray = workspace:Raycast(self.PrimaryPart.Position, (hrp.Position - self.PrimaryPart.Position), rayParams)
                    if not ray or (ray and ray.Instance and ray.Instance:IsDescendantOf(p.Character)) then
                        bestPlayer = p
                        bestDist = dist
                    end
                end
            end
        end
    end
    return bestPlayer
end

function GrannyAI:_computePath(destination)
    local start = self.PrimaryPart.Position
    local path = PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true,
    })
    local ok = pcall(function() path:ComputeAsync(start, destination) end)
    if not ok or path.Status ~= Enum.PathStatus.Success then
        return nil
    end
    local points = path:GetWaypoints()
    return points
end

function GrannyAI:_followWaypoints(waypoints, moveSpeed, stopWhenClose)
    for _,wp in ipairs(waypoints) do
        if not self._running then return end
        local targetPos = wp.Position
        if self.Humanoid then
            self.Humanoid.WalkSpeed = moveSpeed
            self.Humanoid:MoveTo(targetPos)
            local reached = self.Humanoid.MoveToFinished:Wait()
            if not reached then
                -- continue
            end
            if stopWhenClose and getDistance(self.PrimaryPart.Position, targetPos) <= (stopWhenClose) then
                return
            end
            if self._isChasing then return end
        else
            wait(0.1)
        end
    end
end

function GrannyAI:_attackPlayer(player)
    if not player or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
    local hrp = player.Character.HumanoidRootPart
    if getDistance(self.PrimaryPart.Position, hrp.Position) <= self.AttackDistance then
        local charHum = player.Character:FindFirstChildOfClass("Humanoid")
        if charHum and charHum.Health > 0 then
            charHum.Health = 0
            self:_setState("attack")
        end
    end
end

function GrannyAI:Start()
    if self._running then return end
    self._running = true
    spawn(function()
        while self._running do
            local detected = self:_findPlayer()
            if detected then
                self._isChasing = true
                self._currentTarget = detected
                self:_setState("chase")
                while self._running and self._currentTarget and self._currentTarget.Character and self._currentTarget.Character:FindFirstChild("HumanoidRootPart") do
                    local targetPos = self._currentTarget.Character.HumanoidRootPart.Position
                    local waypoints = self:_computePath(targetPos)
                    if waypoints then
                        self:_followWaypoints(waypoints, self.ChaseSpeed)
                    else
                        if self.Humanoid then
                            self.Humanoid:MoveTo(targetPos)
                            self.Humanoid.MoveToFinished:Wait()
                        end
                    end
                    self:_attackPlayer(self._currentTarget)
                    local dist = getDistance(self.PrimaryPart.Position, targetPos)
                    if dist > self.DetectionRange or not isInFOV(self.PrimaryPart.CFrame, self.PrimaryPart.Position, targetPos, self.SightAngle) then
                        self._lastSeenTime = tick()
                        break
                    end
                    wait(0.1)
                end
                local startSearch = tick()
                self:_setState("search")
                while self._running and (tick() - startSearch) < self.SearchTime do
                    local reacquire = self:_findPlayer()
                    if reacquire then
                        detected = reacquire
                        break
                    end
                    if self._investigatePos then
                        local wp = self:_computePath(self._investigatePos)
                        if wp then
                            self:_followWaypoints(wp, self.PatrolSpeed)
                        else
                            if self.Humanoid then
                                self.Humanoid:MoveTo(self._investigatePos)
                                self.Humanoid.MoveToFinished:Wait()
                            end
                        end
                        self._investigatePos = nil
                    end
                    wait(0.5)
                end
                self._isChasing = false
                self._currentTarget = nil
            else
                if self.PatrolPoints and self.PatrolPoints:IsA("Folder") and #self.PatrolPoints:GetChildren() > 0 then
                    self:_setState("patrol")
                    local pts = self.PatrolPoints:GetChildren()
                    table.sort(pts, function(a,b) return a.Name < b.Name end)
                    local pt = pts[self._patrolIndex]
                    if pt then
                        local waypoints = self:_computePath(pt.Position)
                        if waypoints then
                            self:_followWaypoints(waypoints, self.PatrolSpeed)
                        else
                            if self.Humanoid then
                                self.Humanoid:MoveTo(pt.Position)
                                self.Humanoid.MoveToFinished:Wait()
                            end
                        end
                        self._patrolIndex = (self._patrolIndex % #pts) + 1
                    else
                        wait(1)
                    end
                else
                    self:_setState("idle")
                    if self.Humanoid then
                        self.Humanoid.WalkSpeed = 0
                    end
                    wait(1)
                end
            end
            wait(0.1)
        end
    end)
end

function GrannyAI:Stop()
    self._running = false
    if self.Humanoid then
        self.Humanoid:MoveTo(self.PrimaryPart.Position)
    end
    self:_setState("idle")
end

return GrannyAI
