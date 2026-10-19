-- Updated GrannyAI ModuleScript with hide/peek/ambush support
-- Place in ReplicatedStorage as GrannyAI

local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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
    HidePoints = nil,
    AmbushPoints = nil,
    PatrolSpeed = 8,
    ChaseSpeed = 16,
    DetectionRange = 28,
    SightAngle = 100,
    AttackDistance = 3,
    HearingRange = 20,
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

local function listPositionsFromFolder(folder)
    local out = {}
    if not folder then return out end
    for _,obj in ipairs(folder:GetChildren()) do
        if obj:IsA("BasePart") then
            table.insert(out, obj.Position)
        elseif obj:IsA("Model") and obj.PrimaryPart then
            table.insert(out, obj.PrimaryPart.Position)
        end
    end
    return out
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
    self._isChasing = false
    self._state = "idle"
    self._investigatePos = nil
    self.HidePoints = opts.HidePoints or (workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("HidePoints"))
    self.AmbushPoints = opts.AmbushPoints or (workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("AmbushPoints"))
    return self
end

function GrannyAI:_setState(state)
    if self._state == state then return end
    self._state = state
    pcall(function()
        stateEvent:Fire({state = state, model = self.Model})
    end)
end

function GrannyAI:NotifyNoise(pos)
    if not self._running then return end
    if self.PrimaryPart and getDistance(self.PrimaryPart.Position, pos) <= self.HearingRange then
        self._investigatePos = pos
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
                    local ray = workspace:Raycast(self.PrimaryPart.Position, hrp.Position - self.PrimaryPart.Position, rayParams)
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
    local path = PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true,
    })
    local ok = pcall(function() path:ComputeAsync(self.PrimaryPart.Position, destination) end)
    if not ok or path.Status ~= Enum.PathStatus.Success then
        return nil
    end
    return path:GetWaypoints()
end

function GrannyAI:_moveToPoint(point, speed)
    if not self.Humanoid then return end
    self.Humanoid.WalkSpeed = speed
    self.Humanoid:MoveTo(point)
    self.Humanoid.MoveToFinished:Wait()
end

function GrannyAI:_followWaypoints(waypoints, speed)
    for _,wp in ipairs(waypoints) do
        if not self._running then return end
        self:_moveToPoint(wp.Position, speed)
        if self._isChasing then return end
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

function GrannyAI:_chooseAmbushPoint()
    local points = listPositionsFromFolder(self.AmbushPoints)
    if #points == 0 then
        points = listPositionsFromFolder(self.HidePoints)
    end
    if #points == 0 then return nil end
    local chosen = points[math.random(1, #points)]
    return chosen
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
                        self:_moveToPoint(targetPos, self.ChaseSpeed)
                    end
                    self:_attackPlayer(self._currentTarget)
                    local dist = getDistance(self.PrimaryPart.Position, targetPos)
                    if dist > self.DetectionRange or not isInFOV(self.PrimaryPart.CFrame, self.PrimaryPart.Position, targetPos, self.SightAngle) then
                        self._investigatePos = targetPos
                        self:_setState("search")
                        break
                    end
                    wait(0.08)
                end

                local searchStart = tick()
                while self._running and (tick() - searchStart) < self.SearchTime do
                    local reacquire = self:_findPlayer()
                    if reacquire then
                        self._currentTarget = reacquire
                        self:_setState("chase")
                        break
                    end

                    if self._investigatePos then
                        local path = self:_computePath(self._investigatePos)
                        if path then
                            self:_followWaypoints(path, self.PatrolSpeed)
                        else
                            self:_moveToPoint(self._investigatePos, self.PatrolSpeed)
                        end
                        self._investigatePos = nil
                    end
                    wait(0.4)
                end

                self._isChasing = false
                self._currentTarget = nil
            else
                -- Smart hide/peek/ambush behavior if no target is active.
                local ambushPoint = self:_chooseAmbushPoint()
                if ambushPoint then
                    self:_setState("ambush")
                    local path = self:_computePath(ambushPoint)
                    if path then
                        self:_followWaypoints(path, self.PatrolSpeed)
                    else
                        self:_moveToPoint(ambushPoint, self.PatrolSpeed)
                    end
                    wait(0.5)
                elseif self.PatrolPoints and self.PatrolPoints:IsA("Folder") and #self.PatrolPoints:GetChildren() > 0 then
                    self:_setState("patrol")
                    local pts = self.PatrolPoints:GetChildren()
                    table.sort(pts, function(a,b) return a.Name < b.Name end)
                    local pt = pts[self._patrolIndex] or pts[1]
                    if pt then
                        local path = self:_computePath(pt.Position)
                        if path then
                            self:_followWaypoints(path, self.PatrolSpeed)
                        else
                            self:_moveToPoint(pt.Position, self.PatrolSpeed)
                        end
                        self._patrolIndex = (self._patrolIndex % #pts) + 1
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
    self._currentTarget = nil
    self._isChasing = false
    self:_setState("idle")
end

return GrannyAI
