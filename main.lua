--[[
    ====================================================================
    VORTEX HUB (WIIHUB EDITION) — FOOTBALL FUSION 2 CLIENT INSTRUMENTATION
    Monolithic Loadstring-Ready Distribution.
    Engineered for ultra-smooth FPS, responsive UI keybinds,
    comprehensive QB assistance, physics modifiers, and visual tracking.
    ====================================================================
]]

-- Service Declarations
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Stats = game:GetService("Stats")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Global Cleanup Sentinel
if getgenv and getgenv().VortexInstance then
    pcall(function()
        getgenv().VortexInstance:Unload()
    end)
end

-- =====================================================================
-- 1. THEME PALETTE & VISUAL DESIGN TOKENS
-- =====================================================================
local Theme = {
    Colors = {
        Background = Color3.fromRGB(12, 10, 18),
        Sidebar = Color3.fromRGB(14, 11, 20),
        Header = Color3.fromRGB(16, 13, 24),
        Card = Color3.fromRGB(20, 16, 30),
        CardHover = Color3.fromRGB(26, 21, 40),
        Border = Color3.fromRGB(36, 28, 54),
        BorderHover = Color3.fromRGB(70, 52, 105),

        -- WiiHub Neon Violet & Purple Accent Suite
        Accent = Color3.fromRGB(124, 58, 237),
        AccentActive = Color3.fromRGB(109, 40, 217),
        AccentGlow = Color3.fromRGB(168, 85, 247),
        AccentLight = Color3.fromRGB(192, 132, 252),
        AccentMuted = Color3.fromRGB(55, 38, 88),

        TextPrimary = Color3.fromRGB(243, 244, 246),
        TextSecondary = Color3.fromRGB(196, 181, 253),
        TextMuted = Color3.fromRGB(140, 130, 165),
        BreadcrumbMuted = Color3.fromRGB(105, 95, 130),

        CheckboxOff = Color3.fromRGB(22, 17, 34),
        CheckboxOn = Color3.fromRGB(124, 58, 237),
        CheckboxBorder = Color3.fromRGB(65, 50, 95),

        SliderTrack = Color3.fromRGB(24, 19, 36),
        SliderFill = Color3.fromRGB(147, 51, 234),

        Success = Color3.fromRGB(34, 197, 94),
        Warning = Color3.fromRGB(234, 179, 8),
        Error = Color3.fromRGB(239, 68, 68),

        Teammate = Color3.fromRGB(168, 85, 247),
        Opponent = Color3.fromRGB(244, 63, 94),
        BallGold = Color3.fromRGB(250, 204, 21)
    },
    Fonts = {
        Header = Enum.Font.GothamBold,
        Subheader = Enum.Font.GothamMedium,
        Body = Enum.Font.Gotham,
        Badge = Enum.Font.GothamBlack
    },
    Corners = {
        Window = UDim.new(0, 10),
        Card = UDim.new(0, 7),
        Element = UDim.new(0, 5),
        Pill = UDim.new(1, 0)
    }
}

-- Safe GUI container resolution
local function getSafeGuiParent()
    local success, parent = pcall(function()
        if typeof(gethui) == "function" then
            return gethui()
        end
        return CoreGui
    end)
    if success and parent then
        return parent
    end
    return LocalPlayer:WaitForChild("PlayerGui")
end

-- =====================================================================
-- 2. STATE CONFIGURATION
-- =====================================================================
local State = {
    Catching = {
        MagnetEnabled = false,
        MagnetMode = "Regular", -- "Regular", "Strong", "Legit"
        MagnetRange = 35,
        HitboxSize = 8,
        CatchDistance = 22,
        CatchAngle = 120,
        AngleEnhancer = false,
        AutoCatch = false,
        DiveCatchAssist = true
    },
    QB = {
        AimbotEnabled = false,
        AutoAngle = true,
        AutoThrowType = true,
        AntiWobble = true,
        TargetSelector = "Closest to Mouse", -- "Closest to Mouse", "Nearest Teammate", "Open Receiver"
        LeadPredictionTime = 0.85,
        BulletPassVelocity = 95,
        LobPassVelocity = 65,
        ThrowAssistKey = Enum.KeyCode.Q
    },
    Physics = {
        SpeedEnabled = false,
        WalkSpeed = 23,
        JumpEnabled = false,
        JumpPower = 65,
        InfiniteJump = false,
        DiveMultiplier = 1.35,
        AntiStumble = true
    },
    Defense = {
        TackleExpander = false,
        TackleRadius = 14,
        AutoSwat = false,
        CoverageBoost = false
    },
    Trolling = {
        Spinbot = false,
        SpinSpeed = 25,
        BallFling = false,
        NoClip = false
    },
    Automatics = {
        AutoCatch = false,
        AutoCatchDistance = 14,
        AutoIntercept = false,
        AutoDive = false,
        AutoDiveDistance = 22,
        AutoPick = false,
        AutoPickDistance = 16
    },
    Visuals = {
        BallMaster = true,
        BallHighlight = true,
        BallTrajectory = true,
        BallLandingMarker = true,
        BallDistance = true,
        PredictionSteps = 30,

        PlayerMaster = false,
        PlayerBoxes = true,
        PlayerTracers = false,
        PlayerNames = true,
        PlayerDistance = true,
        PlayerFilter = "Opponent" -- "Opponent", "Team", "Everyone"
    },
    Settings = {
        ToggleKey = Enum.KeyCode.RightShift,
        Watermark = true
    }
}

-- Per-toggle keybind registry
local KeybindRegistry = {}

-- =====================================================================
-- 3. ENVIRONMENT & BALL RESOLVER (CACHED & OPTIMIZED)
-- =====================================================================
local Environment = {
    _cachedFootball = nil,
    _lastFootballSearch = 0
}

function Environment.getLocalCharacter()
    local char = LocalPlayer.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not (hrp and hum and hum.Health > 0) then return nil end
    return char, hrp, hum
end

function Environment.getFootball()
    local now = tick()
    local cached = Environment._cachedFootball
    if cached and cached.Parent and cached:IsDescendantOf(Workspace) then
        return cached
    end

    if now - Environment._lastFootballSearch < 0.2 then
        return nil
    end
    Environment._lastFootballSearch = now

    local found = Workspace:FindFirstChild("Football", true)
    if found and found:IsA("BasePart") then
        Environment._cachedFootball = found
        return found
    end

    for _, inst in ipairs(Workspace:GetChildren()) do
        if inst:IsA("BasePart") and (string.find(inst.Name:lower(), "ball") or inst.Name == "Football") then
            Environment._cachedFootball = inst
            return inst
        end
    end
    return nil
end

Workspace.DescendantAdded:Connect(function(desc)
    if desc:IsA("BasePart") and (desc.Name == "Football" or string.find(desc.Name:lower(), "football")) then
        Environment._cachedFootball = desc
    end
end)

Workspace.DescendantRemoving:Connect(function(desc)
    if desc == Environment._cachedFootball then
        Environment._cachedFootball = nil
    end
end)

function Environment.isTeammate(player)
    if player == LocalPlayer then return true end
    if LocalPlayer.Team and player.Team then
        return LocalPlayer.Team == player.Team
    end
    return false
end

function Environment.getTeammates()
    local list = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and Environment.isTeammate(plr) and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            table.insert(list, plr)
        end
    end
    return list
end

-- =====================================================================
-- 4. MATHEMATICS & BALLISTICS UTILITY
-- =====================================================================
local MathUtils = {}

function MathUtils.solveBallisticLaunch(startPos, targetPos, launchSpeed, gravity)
    gravity = gravity or Workspace.Gravity
    local delta = targetPos - startPos
    local deltaXZ = Vector3.new(delta.X, 0, delta.Z)
    local x = deltaXZ.Magnitude
    local y = delta.Y

    if x < 1 then
        return Vector3.new(0, launchSpeed, 0)
    end

    local v2 = launchSpeed * launchSpeed
    local v4 = v2 * v2
    local disc = v4 - gravity * (gravity * (x * x) + 2 * y * v2)

    if disc < 0 then
        -- Target out of theoretical range at this speed, launch at optimal 45 degrees
        local dir = deltaXZ.Unit
        return (dir * math.cos(math.rad(45)) + Vector3.new(0, math.sin(math.rad(45)), 0)) * launchSpeed
    end

    local root = math.sqrt(disc)
    local angle = math.atan((v2 - root) / (gravity * x))
    local dirXZ = deltaXZ.Unit
    local launchDir = (dirXZ * math.cos(angle) + Vector3.new(0, math.sin(angle), 0)).Unit
    return launchDir * launchSpeed
end

function MathUtils.isInAngle(charHrp, targetPos, maxAngleDeg)
    if not (charHrp and targetPos) then return false end
    local forward = charHrp.CFrame.LookVector
    local toTarget = (targetPos - charHrp.Position).Unit
    local dot = forward:Dot(toTarget)
    local threshold = math.cos(math.rad(maxAngleDeg / 2))
    return dot >= threshold
end

-- =====================================================================
-- 5. DRAWING RUNTIME ABSTRACTION
-- =====================================================================
local hasDrawing = typeof(Drawing) == "table" and typeof(Drawing.new) == "function"

local function createDrawing(objType)
    if not hasDrawing then return nil end
    local success, obj = pcall(function()
        return Drawing.new(objType)
    end)
    return success and obj or nil
end

-- =====================================================================
-- 6. CORE LOGIC RUNTIMES
-- =====================================================================

-- 6.1 Catching & Magnet Mechanics
local CatchingSystem = {
    _originalSizes = {},
    _affectedParts = {}
}

function CatchingSystem:ResetHitboxes()
    for part, origSize in pairs(self._originalSizes) do
        if part and part.Parent then
            pcall(function() part.Size = origSize end)
        end
    end
    self._originalSizes = {}
    self._affectedParts = {}
end

function CatchingSystem:Step()
    local char, hrp, hum = Environment.getLocalCharacter()
    if not (char and hrp and hum) then return end

    local football = Environment.getFootball()
    if not (football and football:IsA("BasePart")) then return end

    local fPos = football.Position
    local hPos = hrp.Position
    local dist = (fPos - hPos).Magnitude

    -- Magnet Logic
    if State.Catching.MagnetEnabled and dist <= State.Catching.MagnetRange then
        local inAngle = true
        if not State.Catching.AngleEnhancer then
            inAngle = MathUtils.isInAngle(hrp, fPos, State.Catching.CatchAngle)
        end

        if inAngle then
            local catchPart = char:FindFirstChild("CatchLeft") or char:FindFirstChild("CatchRight") or char:FindFirstChild("Right Arm") or hrp
            local targetPos = catchPart.Position

            if State.Catching.MagnetMode == "Regular" then
                local toHands = (targetPos - fPos).Unit
                football.AssemblyLinearVelocity = toHands * math.clamp(dist * 3.5, 25, 75)
            elseif State.Catching.MagnetMode == "Strong" then
                football.CFrame = CFrame.new(targetPos)
                football.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            elseif State.Catching.MagnetMode == "Legit" then
                if dist <= State.Catching.CatchDistance then
                    local assistDir = (targetPos - fPos).Unit
                    football.AssemblyLinearVelocity = football.AssemblyLinearVelocity:Lerp(assistDir * 35, 0.28)
                end
            end
        end
    end

    -- Hitbox Expansion
    if State.Catching.MagnetEnabled and State.Catching.HitboxSize > 2 then
        local targetParts = {
            char:FindFirstChild("CatchLeft"),
            char:FindFirstChild("CatchRight"),
            char:FindFirstChild("Left Arm"),
            char:FindFirstChild("Right Arm"),
            char:FindFirstChild("LeftHand"),
            char:FindFirstChild("RightHand")
        }
        for _, part in ipairs(targetParts) do
            if part and part:IsA("BasePart") then
                if not self._originalSizes[part] then
                    self._originalSizes[part] = part.Size
                end
                local sz = State.Catching.HitboxSize
                part.Size = Vector3.new(sz, sz, sz)
                part.CanCollide = false
            end
        end
    end

    -- Auto Catch Simulation
    if State.Catching.AutoCatch and dist <= State.Catching.CatchDistance then
        local tool = char:FindFirstChildOfClass("Tool")
        if tool then
            pcall(function() tool:Activate() end)
        end
    end
end

-- 6.2 QB / Passing Assist Mechanics
local QBSystem = {
    CurrentTarget = nil,
    _lockedVelocity = nil
}

function QBSystem:GetTargetReceiver()
    local teammates = Environment.getTeammates()
    if #teammates == 0 then return nil end

    local char, hrp = Environment.getLocalCharacter()
    if not (char and hrp) then return nil end

    local mousePos = UserInputService:GetMouseLocation()
    local bestReceiver = nil
    local bestScore = math.huge

    for _, teammate in ipairs(teammates) do
        local tChar = teammate.Character
        local tHrp = tChar and tChar:FindFirstChild("HumanoidRootPart")
        if tHrp then
            local sPos, onScreen = Camera:WorldToViewportPoint(tHrp.Position)
            if onScreen and sPos.Z > 0 then
                if State.QB.TargetSelector == "Closest to Mouse" then
                    local screenDist = (Vector2.new(sPos.X, sPos.Y) - mousePos).Magnitude
                    if screenDist < bestScore then
                        bestScore = screenDist
                        bestReceiver = teammate
                    end
                elseif State.QB.TargetSelector == "Nearest Teammate" then
                    local worldDist = (tHrp.Position - hrp.Position).Magnitude
                    if worldDist < bestScore then
                        bestScore = worldDist
                        bestReceiver = teammate
                    end
                elseif State.QB.TargetSelector == "Open Receiver" then
                    -- Score based on absence of nearby defenders
                    local defenderDist = math.huge
                    for _, opp in ipairs(Players:GetPlayers()) do
                        if opp ~= LocalPlayer and not Environment.isTeammate(opp) and opp.Character and opp.Character:FindFirstChild("HumanoidRootPart") then
                            local d = (opp.Character.HumanoidRootPart.Position - tHrp.Position).Magnitude
                            if d < defenderDist then defenderDist = d end
                        end
                    end
                    local score = -defenderDist -- higher defender distance is better
                    if score < bestScore then
                        bestScore = score
                        bestReceiver = teammate
                    end
                end
            end
        end
    end

    return bestReceiver
end

function QBSystem:CalculateOptimalPass(receiverPlr)
    local char, hrp = Environment.getLocalCharacter()
    if not (char and hrp and receiverPlr and receiverPlr.Character) then return nil end

    local rHrp = receiverPlr.Character:FindFirstChild("HumanoidRootPart")
    if not rHrp then return nil end

    local leadTime = State.QB.LeadPredictionTime
    local predictedPos = rHrp.Position + (rHrp.AssemblyLinearVelocity * leadTime)

    local dist = (predictedPos - hrp.Position).Magnitude
    local isBullet = true
    if State.QB.AutoThrowType then
        isBullet = dist < 45
    end

    local throwSpeed = isBullet and State.QB.BulletPassVelocity or State.QB.LobPassVelocity
    local launchVel = MathUtils.solveBallisticLaunch(hrp.Position + Vector3.new(0, 3, 0), predictedPos, throwSpeed)

    return launchVel, predictedPos
end

function QBSystem:Step()
    if not State.QB.AimbotEnabled then
        self.CurrentTarget = nil
        return
    end

    local char, hrp = Environment.getLocalCharacter()
    if not (char and hrp) then return end

    local target = self:GetTargetReceiver()
    self.CurrentTarget = target

    if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
        local launchVel, predictedPos = self:CalculateOptimalPass(target)
        if launchVel and State.QB.AutoAngle then
            -- Steer camera smoothly towards launch vector
            local lookCFrame = CFrame.lookAt(Camera.CFrame.Position, Camera.CFrame.Position + launchVel)
            Camera.CFrame = Camera.CFrame:Lerp(lookCFrame, 0.22)
        end
    end

    -- Anti-Wobble routine for thrown balls
    if State.QB.AntiWobble then
        local football = Environment.getFootball()
        if football and football:IsA("BasePart") and football.AssemblyLinearVelocity.Magnitude > 15 then
            football.AssemblyAngularVelocity = football.AssemblyAngularVelocity * Vector3.new(0.05, 1, 0.05)
        end
    end
end

-- 6.3 Physics & Movement Runtime
local PhysicsSystem = {}

function PhysicsSystem:Step()
    local char, hrp, hum = Environment.getLocalCharacter()
    if not (char and hrp and hum) then return end

    -- Custom WalkSpeed with protection
    if State.Physics.SpeedEnabled then
        if hum.WalkSpeed ~= State.Physics.WalkSpeed then
            hum.WalkSpeed = State.Physics.WalkSpeed
        end
    end

    -- Custom JumpPower
    if State.Physics.JumpEnabled then
        if hum.UseJumpPower then
            if hum.JumpPower ~= State.Physics.JumpPower then hum.JumpPower = State.Physics.JumpPower end
        else
            local height = (State.Physics.JumpPower / 50) * 7.2
            if hum.JumpHeight ~= height then hum.JumpHeight = height end
        end
    end

    -- Anti-Stumble / No Ragdoll
    if State.Physics.AntiStumble then
        if hum.PlatformStand then hum.PlatformStand = false end
        if hum.Sit then hum.Sit = false end
    end
end

-- 6.4 Automatics System
local AutomaticsSystem = {}

function AutomaticsSystem:Step()
    local char, hrp, hum = Environment.getLocalCharacter()
    if not (char and hrp and hum) then return end

    local football = Environment.getFootball()
    if not (football and football:IsA("BasePart")) then return end

    local ballPos = football.Position
    local playerPos = hrp.Position
    local dist = (ballPos - playerPos).Magnitude
    local vel = football.AssemblyLinearVelocity

    -- Autonomous Intercept
    if State.Automatics.AutoIntercept and dist > 8 and dist <= 55 and vel.Magnitude > 5 then
        local toBall = (ballPos - playerPos).Unit
        hrp.AssemblyLinearVelocity = hrp.AssemblyLinearVelocity + (toBall * 2.2)
    end

    -- Autonomous Dive
    if State.Automatics.AutoDive and dist <= State.Automatics.AutoDiveDistance and dist >= 8 then
        local toBall = (ballPos - playerPos).Unit
        if hrp.CFrame.LookVector:Dot(toBall) > 0.4 and vel.Y < 4 then
            hum:ChangeState(Enum.HumanoidStateType.Freefall)
            hrp.AssemblyLinearVelocity = toBall * (38 * State.Physics.DiveMultiplier) + Vector3.new(0, 8, 0)
        end
    end

    -- Autonomous Dead Ball Pickup
    if State.Automatics.AutoPick and vel.Magnitude < 3.5 and dist <= State.Automatics.AutoPickDistance then
        local toBall = (ballPos - playerPos).Unit
        hrp.AssemblyLinearVelocity = toBall * 22
    end
end

-- 6.5 Visuals (Ball & Player Overlays)
local VisualsSystem = {
    _ballHighlight = nil,
    _ballLines = {},
    _ballCircle = nil,
    _ballText = nil,
    _playerDrawings = {}
}

function VisualsSystem:Init()
    if not hasDrawing then return end

    -- Ball trajectory lines
    for i = 1, 40 do
        local line = createDrawing("Line")
        if line then
            line.Visible = false
            line.Thickness = 1.5
            line.Color = Theme.Colors.AccentGlow
            table.insert(self._ballLines, line)
        end
    end

    -- Ball landing circle
    self._ballCircle = createDrawing("Circle")
    if self._ballCircle then
        self._ballCircle.Visible = false
        self._ballCircle.Radius = 14
        self._ballCircle.Thickness = 1.8
        self._ballCircle.Color = Theme.Colors.BallGold
    end

    -- Ball distance tag
    self._ballText = createDrawing("Text")
    if self._ballText then
        self._ballText.Visible = false
        self._ballText.Size = 12
        self._ballText.Center = true
        self._ballText.Outline = true
        self._ballText.Color = Theme.Colors.TextPrimary
    end
end

function VisualsSystem:Render()
    -- Render Ball
    local football = Environment.getFootball()
    if State.Visuals.BallMaster and football and football:IsA("BasePart") then
        local fPos = football.Position
        local sPos, onScreen = Camera:WorldToViewportPoint(fPos)
        local char, hrp = Environment.getLocalCharacter()
        local dist = hrp and (fPos - hrp.Position).Magnitude or 0

        -- Highlight
        if State.Visuals.BallHighlight then
            if not self._ballHighlight or self._ballHighlight.Parent ~= football then
                if self._ballHighlight then self._ballHighlight:Destroy() end
                local hl = Instance.new("Highlight")
                hl.Name = "VortexBallHighlight"
                hl.FillColor = Theme.Colors.AccentLight
                hl.OutlineColor = Theme.Colors.Accent
                hl.FillTransparency = 0.4
                hl.OutlineTransparency = 0.1
                hl.Adornee = football
                hl.Parent = football
                self._ballHighlight = hl
            end
            self._ballHighlight.Enabled = true
        elseif self._ballHighlight then
            self._ballHighlight.Enabled = false
        end

        -- Distance Tag
        if State.Visuals.BallDistance and self._ballText and onScreen and sPos.Z > 0 then
            self._ballText.Text = string.format("FOOTBALL [%d studs]", math.floor(dist))
            self._ballText.Position = Vector2.new(sPos.X, sPos.Y - 22)
            self._ballText.Visible = true
        elseif self._ballText then
            self._ballText.Visible = false
        end

        -- Trajectory Arc & Landing Marker
        local vel = football.AssemblyLinearVelocity
        if State.Visuals.BallTrajectory and vel.Magnitude > 4 then
            local currentP = fPos
            local currentV = vel
            local dt = 0.05
            local g = Vector3.new(0, -Workspace.Gravity, 0)
            local landingPos = nil

            local maxSteps = math.clamp(State.Visuals.PredictionSteps, 10, 40)
            for i = 1, maxSteps do
                local nextP = currentP + (currentV * dt) + (0.5 * g * dt * dt)
                local ray = Workspace:Raycast(currentP, nextP - currentP)

                local p1, v1 = Camera:WorldToViewportPoint(currentP)
                local p2, v2 = Camera:WorldToViewportPoint(ray and ray.Position or nextP)

                local line = self._ballLines[i]
                if line then
                    if v1 and v2 and p1.Z > 0 and p2.Z > 0 then
                        line.From = Vector2.new(p1.X, p1.Y)
                        line.To = Vector2.new(p2.X, p2.Y)
                        line.Visible = true
                    else
                        line.Visible = false
                    end
                end

                if ray then
                    landingPos = ray.Position
                    for j = i + 1, #self._ballLines do
                        if self._ballLines[j] then self._ballLines[j].Visible = false end
                    end
                    break
                end

                currentP = nextP
                currentV = currentV + (g * dt)
            end

            if State.Visuals.BallLandingMarker and landingPos and self._ballCircle then
                local lScreen, lVis = Camera:WorldToViewportPoint(landingPos)
                if lVis and lScreen.Z > 0 then
                    self._ballCircle.Position = Vector2.new(lScreen.X, lScreen.Y)
                    self._ballCircle.Visible = true
                else
                    self._ballCircle.Visible = false
                end
            elseif self._ballCircle then
                self._ballCircle.Visible = false
            end
        else
            for _, line in ipairs(self._ballLines) do line.Visible = false end
            if self._ballCircle then self._ballCircle.Visible = false end
        end
    else
        if self._ballHighlight then self._ballHighlight.Enabled = false end
        if self._ballText then self._ballText.Visible = false end
        if self._ballCircle then self._ballCircle.Visible = false end
        for _, line in ipairs(self._ballLines) do line.Visible = false end
    end

    -- Render Players
    if State.Visuals.PlayerMaster and hasDrawing then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                local isTeam = Environment.isTeammate(plr)
                local filterMatch = false
                if State.Visuals.PlayerFilter == "Everyone" then filterMatch = true
                elseif State.Visuals.PlayerFilter == "Team" and isTeam then filterMatch = true
                elseif State.Visuals.PlayerFilter == "Opponent" and not isTeam then filterMatch = true end

                local entry = self._playerDrawings[plr]
                if not entry then
                    entry = {
                        Box = createDrawing("Square"),
                        Tracer = createDrawing("Line"),
                        Name = createDrawing("Text")
                    }
                    self._playerDrawings[plr] = entry
                end

                local char = plr.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local hum = char and char:FindFirstChildOfClass("Humanoid")

                if filterMatch and hrp and hum and hum.Health > 0 then
                    local sPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                    if onScreen and sPos.Z > 0 then
                        local color = isTeam and Theme.Colors.Teammate or Theme.Colors.Opponent
                        local head = char:FindFirstChild("Head")
                        local headPos = head and Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0)) or Vector2.new(sPos.X, sPos.Y - 20)
                        local boxHeight = math.abs(sPos.Y - headPos.Y) * 2.2
                        local boxWidth = boxHeight * 0.65

                        -- Box
                        if State.Visuals.PlayerBoxes and entry.Box then
                            entry.Box.Size = Vector2.new(boxWidth, boxHeight)
                            entry.Box.Position = Vector2.new(sPos.X - boxWidth / 2, sPos.Y - boxHeight / 2)
                            entry.Box.Color = color
                            entry.Box.Visible = true
                        elseif entry.Box then entry.Box.Visible = false end

                        -- Tracer
                        if State.Visuals.PlayerTracers and entry.Tracer then
                            entry.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                            entry.Tracer.To = Vector2.new(sPos.X, sPos.Y)
                            entry.Tracer.Color = color
                            entry.Tracer.Visible = true
                        elseif entry.Tracer then entry.Tracer.Visible = false end

                        -- Name Tag
                        if State.Visuals.PlayerNames and entry.Name then
                            entry.Name.Text = string.format("%s [%d]", plr.DisplayName, math.floor(sPos.Z))
                            entry.Name.Position = Vector2.new(sPos.X, sPos.Y - (boxHeight / 2) - 15)
                            entry.Name.Color = color
                            entry.Name.Visible = true
                        elseif entry.Name then entry.Name.Visible = false end
                    else
                        if entry.Box then entry.Box.Visible = false end
                        if entry.Tracer then entry.Tracer.Visible = false end
                        if entry.Name then entry.Name.Visible = false end
                    end
                else
                    if entry.Box then entry.Box.Visible = false end
                    if entry.Tracer then entry.Tracer.Visible = false end
                    if entry.Name then entry.Name.Visible = false end
                end
            end
        end
    else
        for _, entry in pairs(self._playerDrawings) do
            if entry.Box then entry.Box.Visible = false end
            if entry.Tracer then entry.Tracer.Visible = false end
            if entry.Name then entry.Name.Visible = false end
        end
    end
end

-- =====================================================================
-- 7. USER INTERFACE ARCHITECTURE (WIIHUB DESIGN PATTERN)
-- =====================================================================
local Hub = {
    Visible = true,
    ScreenGui = nil,
    Tabs = {},
    CurrentTab = nil,
    _connections = {},
    _activeBreadcrumbLabel = nil
}

function Hub:Init()
    local safeParent = getSafeGuiParent()
    local old = safeParent:FindFirstChild("WiiHub_Vortex")
    if old then old:Destroy() end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "WiiHub_Vortex"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = safeParent
    self.ScreenGui = screenGui

    -- Main Hub Frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 680, 0, 430)
    mainFrame.Position = UDim2.new(0.5, -340, 0.5, -215)
    mainFrame.BackgroundColor3 = Theme.Colors.Background
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = screenGui
    self.MainFrame = mainFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = Theme.Corners.Window
    corner.Parent = mainFrame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Theme.Colors.Border
    stroke.Thickness = 1.4
    stroke.Parent = mainFrame

    -- Outer Neon Glow
    local outerGlow = Instance.new("Frame")
    outerGlow.Name = "OuterGlow"
    outerGlow.Size = UDim2.new(1, 4, 1, 4)
    outerGlow.Position = UDim2.new(0, -2, 0, -2)
    outerGlow.BackgroundTransparency = 1
    outerGlow.ZIndex = 0
    outerGlow.Parent = mainFrame

    local glowStroke = Instance.new("UIStroke")
    glowStroke.Color = Theme.Colors.Accent
    glowStroke.Transparency = 0.65
    glowStroke.Thickness = 2
    glowStroke.Parent = outerGlow

    -- 7.1 Header Bar with Breadcrumbs
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 42)
    header.BackgroundColor3 = Theme.Colors.Header
    header.BorderSizePixel = 0
    header.Parent = mainFrame

    local hCorner = Instance.new("UICorner")
    hCorner.CornerRadius = Theme.Corners.Window
    hCorner.Parent = header

    local hCover = Instance.new("Frame")
    hCover.Size = UDim2.new(1, 0, 0, 10)
    hCover.Position = UDim2.new(0, 0, 1, -10)
    hCover.BackgroundColor3 = Theme.Colors.Header
    hCover.BorderSizePixel = 0
    hCover.Parent = header

    local hSep = Instance.new("Frame")
    hSep.Size = UDim2.new(1, 0, 0, 1)
    hSep.Position = UDim2.new(0, 0, 1, -1)
    hSep.BackgroundColor3 = Theme.Colors.Border
    hSep.BorderSizePixel = 0
    hSep.Parent = header

    -- Left Icon (Cube Emblem)
    local logoIcon = Instance.new("ImageLabel")
    logoIcon.Size = UDim2.new(0, 20, 0, 20)
    logoIcon.Position = UDim2.new(0, 14, 0.5, -10)
    logoIcon.BackgroundTransparency = 1
    logoIcon.Image = "rbxassetid://7733960981"
    logoIcon.ImageColor3 = Theme.Colors.AccentLight
    logoIcon.Parent = header

    -- Hub Brand Name
    local brandTitle = Instance.new("TextLabel")
    brandTitle.Text = "WiiHub"
    brandTitle.Font = Theme.Fonts.Header
    brandTitle.TextSize = 14
    brandTitle.TextColor3 = Theme.Colors.TextPrimary
    brandTitle.TextXAlignment = Enum.TextXAlignment.Left
    brandTitle.Size = UDim2.new(0, 60, 1, 0)
    brandTitle.Position = UDim2.new(0, 42, 0, 0)
    brandTitle.BackgroundTransparency = 1
    brandTitle.Parent = header

    -- Breadcrumb Navigation Path: "Projects / WiiHub / <Tab>"
    local breadcrumbFrame = Instance.new("Frame")
    breadcrumbFrame.Size = UDim2.new(0, 300, 1, 0)
    breadcrumbFrame.Position = UDim2.new(0, 120, 0, 0)
    breadcrumbFrame.BackgroundTransparency = 1
    breadcrumbFrame.Parent = header

    local bcLayout = Instance.new("UIListLayout")
    bcLayout.FillDirection = Enum.FillDirection.Horizontal
    bcLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    bcLayout.SortOrder = Enum.SortOrder.LayoutOrder
    bcLayout.Padding = UDim.new(0, 6)
    bcLayout.Parent = breadcrumbFrame

    local function makeBreadcrumbText(text, color, isBold)
        local lbl = Instance.new("TextLabel")
        lbl.Text = text
        lbl.Font = isBold and Theme.Fonts.Header or Theme.Fonts.Body
        lbl.TextSize = 12
        lbl.TextColor3 = color
        lbl.AutomaticSize = Enum.AutomaticSize.X
        lbl.Size = UDim2.new(0, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Parent = breadcrumbFrame
        return lbl
    end

    makeBreadcrumbText("Projects", Theme.Colors.BreadcrumbMuted, false)
    makeBreadcrumbText("/", Theme.Colors.Border, false)
    makeBreadcrumbText("WiiHub", Theme.Colors.BreadcrumbMuted, false)
    makeBreadcrumbText("/", Theme.Colors.Border, false)
    self._activeBreadcrumbLabel = makeBreadcrumbText("Catching", Theme.Colors.AccentLight, true)

    -- Header Controls: Close and Minimize
    local closeBtn = Instance.new("TextButton")
    closeBtn.Text = "✕"
    closeBtn.Font = Theme.Fonts.Header
    closeBtn.TextSize = 13
    closeBtn.TextColor3 = Theme.Colors.TextMuted
    closeBtn.Size = UDim2.new(0, 32, 0, 32)
    closeBtn.Position = UDim2.new(1, -38, 0.5, -16)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Parent = header

    local minBtn = Instance.new("TextButton")
    minBtn.Text = "—"
    minBtn.Font = Theme.Fonts.Header
    minBtn.TextSize = 14
    minBtn.TextColor3 = Theme.Colors.TextMuted
    minBtn.Size = UDim2.new(0, 32, 0, 32)
    minBtn.Position = UDim2.new(1, -72, 0.5, -16)
    minBtn.BackgroundTransparency = 1
    minBtn.Parent = header

    closeBtn.MouseButton1Click:Connect(function()
        self:ToggleUI(false)
    end)
    minBtn.MouseButton1Click:Connect(function()
        self:ToggleUI()
    end)

    -- Header Window Dragging (Smooth Input Tracking)
    local dragging, dragStart, startPos
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    local dragConn = UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
    table.insert(self._connections, dragConn)

    -- 7.2 Left Sidebar Frame
    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.Size = UDim2.new(0, 145, 1, -42)
    sidebar.Position = UDim2.new(0, 0, 0, 42)
    sidebar.BackgroundColor3 = Theme.Colors.Sidebar
    sidebar.BorderSizePixel = 0
    sidebar.Parent = mainFrame

    local sBorder = Instance.new("Frame")
    sBorder.Size = UDim2.new(0, 1, 1, 0)
    sBorder.Position = UDim2.new(1, -1, 0, 0)
    sBorder.BackgroundColor3 = Theme.Colors.Border
    sBorder.BorderSizePixel = 0
    sBorder.Parent = sidebar

    -- Sidebar Tab Scroll / List
    local tabContainer = Instance.new("ScrollingFrame")
    tabContainer.Size = UDim2.new(1, 0, 1, -48)
    tabContainer.Position = UDim2.new(0, 0, 0, 0)
    tabContainer.BackgroundTransparency = 1
    tabContainer.BorderSizePixel = 0
    tabContainer.ScrollBarThickness = 0
    tabContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    tabContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
    tabContainer.Parent = sidebar

    local sLayout = Instance.new("UIListLayout")
    sLayout.SortOrder = Enum.SortOrder.LayoutOrder
    sLayout.Padding = UDim.new(0, 3)
    sLayout.Parent = tabContainer

    local sPad = Instance.new("UIPadding")
    sPad.PaddingTop = UDim.new(0, 8)
    sPad.PaddingBottom = UDim.new(0, 8)
    sPad.PaddingLeft = UDim.new(0, 8)
    sPad.PaddingRight = UDim.new(0, 8)
    sPad.Parent = tabContainer

    -- 7.3 Sidebar Bottom Profile Footer ("Welcome, <user>")
    local footer = Instance.new("Frame")
    footer.Name = "ProfileFooter"
    footer.Size = UDim2.new(1, 0, 0, 46)
    footer.Position = UDim2.new(0, 0, 1, -46)
    footer.BackgroundColor3 = Theme.Colors.Header
    footer.BorderSizePixel = 0
    footer.Parent = sidebar

    local fSep = Instance.new("Frame")
    fSep.Size = UDim2.new(1, 0, 0, 1)
    fSep.Position = UDim2.new(0, 0, 0, 0)
    fSep.BackgroundColor3 = Theme.Colors.Border
    fSep.BorderSizePixel = 0
    fSep.Parent = footer

    local avatarImg = Instance.new("ImageLabel")
    avatarImg.Size = UDim2.new(0, 26, 0, 26)
    avatarImg.Position = UDim2.new(0, 10, 0.5, -13)
    avatarImg.BackgroundColor3 = Theme.Colors.Card
    avatarImg.BorderSizePixel = 0
    avatarImg.Parent = footer

    local aCorner = Instance.new("UICorner")
    aCorner.CornerRadius = UDim.new(1, 0)
    aCorner.Parent = avatarImg

    local aStroke = Instance.new("UIStroke")
    aStroke.Color = Theme.Colors.Accent
    aStroke.Thickness = 1
    aStroke.Parent = avatarImg

    -- Load User Headshot
    task.spawn(function()
        pcall(function()
            local thumb = Players:GetUserThumbnailAsync(
                LocalPlayer.UserId,
                Enum.ThumbnailType.HeadShot,
                Enum.ThumbnailSize.Size48x48
            )
            avatarImg.Image = thumb
        end)
    end)

    local welcomeLbl = Instance.new("TextLabel")
    welcomeLbl.Text = "Welcome, " .. string.sub(LocalPlayer.DisplayName or LocalPlayer.Name, 1, 10)
    welcomeLbl.Font = Theme.Fonts.Subheader
    welcomeLbl.TextSize = 11
    welcomeLbl.TextColor3 = Theme.Colors.TextSecondary
    welcomeLbl.TextXAlignment = Enum.TextXAlignment.Left
    welcomeLbl.Size = UDim2.new(1, -44, 1, 0)
    welcomeLbl.Position = UDim2.new(0, 42, 0, 0)
    welcomeLbl.BackgroundTransparency = 1
    welcomeLbl.Parent = footer

    -- 7.4 Main Content Area
    local contentContainer = Instance.new("Frame")
    contentContainer.Name = "ContentContainer"
    contentContainer.Size = UDim2.new(1, -145, 1, -42)
    contentContainer.Position = UDim2.new(0, 145, 0, 42)
    contentContainer.BackgroundTransparency = 1
    contentContainer.Parent = mainFrame

    self.Sidebar = tabContainer
    self.ContentContainer = contentContainer

    -- Keybind Listener for Toggle Key
    local menuKeyConn = UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == State.Settings.ToggleKey then
            self:ToggleUI()
        end

        -- Check per-toggle keybinds
        if not gpe and input.UserInputType == Enum.UserInputType.Keyboard then
            for toggleId, bindData in pairs(KeybindRegistry) do
                if bindData.Key == input.KeyCode and bindData.ToggleFunc then
                    bindData.ToggleFunc()
                end
            end
        end
    end)
    table.insert(self._connections, menuKeyConn)

    -- Infinite Jump Listener
    local jumpConn = UserInputService.JumpRequest:Connect(function()
        if not State.Physics.InfiniteJump then return end
        local char, hrp, hum = Environment.getLocalCharacter()
        if char and hrp and hum and hum.Health > 0 then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
            local pwr = State.Physics.JumpEnabled and (State.Physics.JumpPower * 0.85) or 50
            hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, pwr, hrp.AssemblyLinearVelocity.Z)
        end
    end)
    table.insert(self._connections, jumpConn)

    -- Watermark & Notifications
    self:CreateWatermark(screenGui)
    self:CreateNotifications(screenGui)

    -- Construct All Tabs
    self:BuildPages()
end

function Hub:ToggleUI(override)
    if override ~= nil then
        self.Visible = override
    else
        self.Visible = not self.Visible
    end
    self.MainFrame.Visible = self.Visible
end

function Hub:CreateWatermark(screenGui)
    local wm = Instance.new("Frame")
    wm.Name = "WiiHubWatermark"
    wm.Size = UDim2.new(0, 240, 0, 26)
    wm.Position = UDim2.new(1, -250, 0, 10)
    wm.BackgroundColor3 = Theme.Colors.Header
    wm.BorderSizePixel = 0
    wm.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = Theme.Corners.Element
    corner.Parent = wm

    local stroke = Instance.new("UIStroke")
    stroke.Color = Theme.Colors.Accent
    stroke.Thickness = 1
    stroke.Transparency = 0.5
    stroke.Parent = wm

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -12, 1, 0)
    label.Position = UDim2.new(0, 8, 0, 0)
    label.BackgroundTransparency = 1
    label.Font = Theme.Fonts.Subheader
    label.TextSize = 11
    label.TextColor3 = Theme.Colors.TextPrimary
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = "WiiHub | FPS: -- | Ping: --ms"
    label.Parent = wm

    local frames = 0
    local lastTick = tick()
    local conn = RunService.RenderStepped:Connect(function()
        frames = frames + 1
        local now = tick()
        if now - lastTick >= 0.5 then
            local fps = math.floor(frames / (now - lastTick))
            frames = 0
            lastTick = now
            local ping = 0
            pcall(function()
                ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
            end)
            label.Text = string.format("WiiHub | FPS: %d | Ping: %dms", fps, ping)
        end
    end)
    table.insert(self._connections, conn)
end

function Hub:CreateNotifications(screenGui)
    local notifContainer = Instance.new("Frame")
    notifContainer.Name = "Notifications"
    notifContainer.Size = UDim2.new(0, 240, 1, -40)
    notifContainer.Position = UDim2.new(1, -250, 0, 20)
    notifContainer.BackgroundTransparency = 1
    notifContainer.Parent = screenGui

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    layout.Padding = UDim.new(0, 6)
    layout.Parent = notifContainer

    self.NotifContainer = notifContainer
end

function Hub:Notify(titleText, msgText, duration, statusType)
    duration = duration or 2.5
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 46)
    card.BackgroundColor3 = Theme.Colors.Card
    card.BorderSizePixel = 0
    card.Position = UDim2.new(1, 20, 0, 0)
    card.Parent = self.NotifContainer

    local corner = Instance.new("UICorner")
    corner.CornerRadius = Theme.Corners.Element
    corner.Parent = card

    local stroke = Instance.new("UIStroke")
    stroke.Color = Theme.Colors.Accent
    stroke.Thickness = 1
    stroke.Parent = card

    local tLbl = Instance.new("TextLabel")
    tLbl.Text = titleText
    tLbl.Font = Theme.Fonts.Header
    tLbl.TextSize = 12
    tLbl.TextColor3 = Theme.Colors.AccentLight
    tLbl.TextXAlignment = Enum.TextXAlignment.Left
    tLbl.Size = UDim2.new(1, -12, 0, 16)
    tLbl.Position = UDim2.new(0, 10, 0, 5)
    tLbl.BackgroundTransparency = 1
    tLbl.Parent = card

    local mLbl = Instance.new("TextLabel")
    mLbl.Text = msgText
    mLbl.Font = Theme.Fonts.Body
    mLbl.TextSize = 10
    mLbl.TextColor3 = Theme.Colors.TextPrimary
    mLbl.TextXAlignment = Enum.TextXAlignment.Left
    mLbl.Size = UDim2.new(1, -12, 0, 16)
    mLbl.Position = UDim2.new(0, 10, 0, 22)
    mLbl.BackgroundTransparency = 1
    mLbl.Parent = card

    TweenService:Create(card, TweenInfo.new(0.2, Enum.EasingStyle.Quart), { Position = UDim2.new(0, 0, 0, 0) }):Play()
    task.delay(duration, function()
        if card and card.Parent then
            local tw = TweenService:Create(card, TweenInfo.new(0.2, Enum.EasingStyle.Quart), { Position = UDim2.new(1, 20, 0, 0) })
            tw:Play()
            tw.Completed:Connect(function() card:Destroy() end)
        end
    end)
end

-- Tab Creator with WiiHub Styling
function Hub:CreateTab(name)
    local btn = Instance.new("TextButton")
    btn.Name = name .. "TabBtn"
    btn.Size = UDim2.new(1, 0, 0, 32)
    btn.BackgroundTransparency = 1
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Text = ""
    btn.Parent = self.Sidebar

    local bCorner = Instance.new("UICorner")
    bCorner.CornerRadius = Theme.Corners.Card
    bCorner.Parent = btn

    local lbl = Instance.new("TextLabel")
    lbl.Text = name
    lbl.Font = Theme.Fonts.Subheader
    lbl.TextSize = 12
    lbl.TextColor3 = Theme.Colors.TextMuted
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Size = UDim2.new(1, -16, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Parent = btn

    -- Content Page for this Tab
    local page = Instance.new("ScrollingFrame")
    page.Name = name .. "Page"
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = Theme.Colors.Accent
    page.Visible = false
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Parent = self.ContentContainer

    local pLayout = Instance.new("UIListLayout")
    pLayout.SortOrder = Enum.SortOrder.LayoutOrder
    pLayout.Padding = UDim.new(0, 12)
    pLayout.Parent = page

    local pPad = Instance.new("UIPadding")
    pPad.PaddingTop = UDim.new(0, 12)
    pPad.PaddingBottom = UDim.new(0, 16)
    pPad.PaddingLeft = UDim.new(0, 14)
    pPad.PaddingRight = UDim.new(0, 14)
    pPad.Parent = page

    local tabObj = {
        Button = btn,
        Page = page,
        Label = lbl,
        Name = name
    }

    local function setActive(active)
        page.Visible = active
        if active then
            btn.BackgroundTransparency = 0
            btn.BackgroundColor3 = Theme.Colors.AccentActive
            lbl.TextColor3 = Theme.Colors.TextPrimary
            lbl.Font = Theme.Fonts.Header
            if self._activeBreadcrumbLabel then
                self._activeBreadcrumbLabel.Text = name
            end
        else
            btn.BackgroundTransparency = 1
            lbl.TextColor3 = Theme.Colors.TextMuted
            lbl.Font = Theme.Fonts.Subheader
        end
    end

    btn.MouseButton1Click:Connect(function()
        if self.CurrentTab == tabObj then return end
        for _, t in ipairs(self.Tabs) do t.SetActive(false) end
        setActive(true)
        self.CurrentTab = tabObj
    end)

    tabObj.SetActive = setActive
    table.insert(self.Tabs, tabObj)

    if #self.Tabs == 1 then
        setActive(true)
        self.CurrentTab = tabObj
    end

    return page
end

-- =====================================================================
-- 8. WIIHUB COMPONENT FACTORY (CHECKBOX WITH KEYBIND, SLIDERS, DROPDOWNS)
-- =====================================================================

local function addSection(page, titleText)
    local sec = Instance.new("Frame")
    sec.Size = UDim2.new(1, 0, 0, 0)
    sec.AutomaticSize = Enum.AutomaticSize.Y
    sec.BackgroundTransparency = 1
    sec.Parent = page

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 6)
    layout.Parent = sec

    local header = Instance.new("TextLabel")
    header.Text = titleText
    header.Font = Theme.Fonts.Header
    header.TextSize = 12
    header.TextColor3 = Theme.Colors.TextSecondary
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.Size = UDim2.new(1, 0, 0, 18)
    header.BackgroundTransparency = 1
    header.Parent = sec

    return sec
end

-- WiiHub Checkbox Row with Integrated Keybind ("Click to Bind")
local function addToggle(sec, title, defaultState, callback, defaultKey)
    local state = defaultState or false
    local boundKey = defaultKey or nil
    local listening = false

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 32)
    row.BackgroundColor3 = Theme.Colors.Card
    row.BorderSizePixel = 0
    row.Parent = sec

    local rCorner = Instance.new("UICorner")
    rCorner.CornerRadius = Theme.Corners.Element
    rCorner.Parent = row

    local rStroke = Instance.new("UIStroke")
    rStroke.Color = Theme.Colors.Border
    rStroke.Thickness = 1
    rStroke.Parent = row

    -- Checkbox Button (Left)
    local checkBtn = Instance.new("TextButton")
    checkBtn.Size = UDim2.new(0, 18, 0, 18)
    checkBtn.Position = UDim2.new(0, 8, 0.5, -9)
    checkBtn.BackgroundColor3 = state and Theme.Colors.CheckboxOn or Theme.Colors.CheckboxOff
    checkBtn.BorderSizePixel = 0
    checkBtn.Text = ""
    checkBtn.AutoButtonColor = false
    checkBtn.Parent = row

    local cbCorner = Instance.new("UICorner")
    cbCorner.CornerRadius = UDim.new(0, 4)
    cbCorner.Parent = checkBtn

    local cbStroke = Instance.new("UIStroke")
    cbStroke.Color = state and Theme.Colors.AccentGlow or Theme.Colors.CheckboxBorder
    cbStroke.Thickness = 1.2
    cbStroke.Parent = checkBtn

    local checkmark = Instance.new("TextLabel")
    checkmark.Text = "✓"
    checkmark.Font = Theme.Fonts.Header
    checkmark.TextSize = 13
    checkmark.TextColor3 = Color3.fromRGB(255, 255, 255)
    checkmark.Size = UDim2.new(1, 0, 1, 0)
    checkmark.BackgroundTransparency = 1
    checkmark.Visible = state
    checkmark.Parent = checkBtn

    -- Title Label
    local titleLbl = Instance.new("TextLabel")
    titleLbl.Text = title
    titleLbl.Font = Theme.Fonts.Body
    titleLbl.TextSize = 12
    titleLbl.TextColor3 = Theme.Colors.TextPrimary
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Size = UDim2.new(1, -135, 1, 0)
    titleLbl.Position = UDim2.new(0, 34, 0, 0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Parent = row

    -- Keybind Button (Right: "Click to Bind" or "[Key]")
    local bindBtn = Instance.new("TextButton")
    bindBtn.Size = UDim2.new(0, 92, 0, 22)
    bindBtn.Position = UDim2.new(1, -98, 0.5, -11)
    bindBtn.BackgroundColor3 = Theme.Colors.Header
    bindBtn.BorderSizePixel = 0
    bindBtn.Text = boundKey and ("[" .. boundKey.Name .. "]") or "Click to Bind"
    bindBtn.Font = Theme.Fonts.Body
    bindBtn.TextSize = 10
    bindBtn.TextColor3 = boundKey and Theme.Colors.AccentLight or Theme.Colors.TextMuted
    bindBtn.Parent = row

    local bCorner = Instance.new("UICorner")
    bCorner.CornerRadius = Theme.Corners.Element
    bCorner.Parent = bindBtn

    local bStroke = Instance.new("UIStroke")
    bStroke.Color = Theme.Colors.Border
    bStroke.Thickness = 1
    bStroke.Parent = bindBtn

    local function updateVisuals(anim)
        local targetColor = state and Theme.Colors.CheckboxOn or Theme.Colors.CheckboxOff
        local strokeColor = state and Theme.Colors.AccentGlow or Theme.Colors.CheckboxBorder
        checkmark.Visible = state
        if anim then
            TweenService:Create(checkBtn, TweenInfo.new(0.15), { BackgroundColor3 = targetColor }):Play()
            TweenService:Create(cbStroke, TweenInfo.new(0.15), { Color = strokeColor }):Play()
        else
            checkBtn.BackgroundColor3 = targetColor
            cbStroke.Color = strokeColor
        end
    end

    local function toggleState()
        state = not state
        updateVisuals(true)
        if callback then callback(state) end
    end

    checkBtn.MouseButton1Click:Connect(toggleState)

    -- Register with Keybind listener
    local toggleId = title .. tostring(tick())
    KeybindRegistry[toggleId] = {
        Key = boundKey,
        ToggleFunc = toggleState
    }

    bindBtn.MouseButton1Click:Connect(function()
        listening = true
        bindBtn.Text = "Press Key..."
        bindBtn.TextColor3 = Theme.Colors.AccentLight
    end)

    UserInputService.InputBegan:Connect(function(inp, gpe)
        if listening and inp.UserInputType == Enum.UserInputType.Keyboard then
            if inp.KeyCode == Enum.KeyCode.Backspace or inp.KeyCode == Enum.KeyCode.Escape then
                boundKey = nil
                bindBtn.Text = "Click to Bind"
                bindBtn.TextColor3 = Theme.Colors.TextMuted
            else
                boundKey = inp.KeyCode
                bindBtn.Text = "[" .. boundKey.Name .. "]"
                bindBtn.TextColor3 = Theme.Colors.AccentLight
            end
            KeybindRegistry[toggleId].Key = boundKey
            listening = false
        end
    end)

    return {
        Set = function(v)
            state = v
            updateVisuals(false)
            if callback then callback(v) end
        end,
        Get = function() return state end
    }
end

-- Slider Component
local function addSlider(sec, title, minVal, maxVal, defVal, stepVal, suffix, callback)
    local val = defVal or minVal
    stepVal = stepVal or 1
    suffix = suffix or ""

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 44)
    row.BackgroundColor3 = Theme.Colors.Card
    row.BorderSizePixel = 0
    row.Parent = sec

    local rCorner = Instance.new("UICorner")
    rCorner.CornerRadius = Theme.Corners.Element
    rCorner.Parent = row

    local rStroke = Instance.new("UIStroke")
    rStroke.Color = Theme.Colors.Border
    rStroke.Thickness = 1
    rStroke.Parent = row

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Text = title
    titleLbl.Font = Theme.Fonts.Body
    titleLbl.TextSize = 12
    titleLbl.TextColor3 = Theme.Colors.TextPrimary
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Size = UDim2.new(0.65, 0, 0, 18)
    titleLbl.Position = UDim2.new(0, 10, 0, 5)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Parent = row

    local valLbl = Instance.new("TextLabel")
    valLbl.Text = tostring(val) .. suffix
    valLbl.Font = Theme.Fonts.Header
    valLbl.TextSize = 11
    valLbl.TextColor3 = Theme.Colors.AccentLight
    valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.Size = UDim2.new(0.3, 0, 0, 18)
    valLbl.Position = UDim2.new(0.67, 0, 0, 5)
    valLbl.BackgroundTransparency = 1
    valLbl.Parent = row

    local track = Instance.new("TextButton")
    track.Size = UDim2.new(1, -20, 0, 6)
    track.Position = UDim2.new(0, 10, 0, 28)
    track.BackgroundColor3 = Theme.Colors.SliderTrack
    track.BorderSizePixel = 0
    track.Text = ""
    track.AutoButtonColor = false
    track.Parent = row

    local tCorner = Instance.new("UICorner")
    tCorner.CornerRadius = UDim.new(1, 0)
    tCorner.Parent = track

    local pct = math.clamp((val - minVal) / (maxVal - minVal), 0, 1)
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(pct, 0, 1, 0)
    fill.BackgroundColor3 = Theme.Colors.SliderFill
    fill.BorderSizePixel = 0
    fill.Parent = track

    local fCorner = Instance.new("UICorner")
    fCorner.CornerRadius = UDim.new(1, 0)
    fCorner.Parent = fill

    local dragging = false
    local function apply(inputPos)
        local absPos = track.AbsolutePosition.X
        local absSz = track.AbsoluteSize.X
        local rel = math.clamp(inputPos.X - absPos, 0, absSz)
        local raw = minVal + (maxVal - minVal) * (rel / absSz)
        val = math.floor((raw / stepVal) + 0.5) * stepVal
        val = math.clamp(val, minVal, maxVal)

        local newPct = (val - minVal) / (maxVal - minVal)
        fill.Size = UDim2.new(newPct, 0, 1, 0)
        valLbl.Text = tostring(val) .. suffix
        if callback then callback(val) end
    end

    track.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            apply(inp.Position)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            apply(inp.Position)
        end
    end)

    return {
        Set = function(newVal)
            val = math.clamp(newVal, minVal, maxVal)
            local newPct = (val - minVal) / (maxVal - minVal)
            fill.Size = UDim2.new(newPct, 0, 1, 0)
            valLbl.Text = tostring(val) .. suffix
            if callback then callback(val) end
        end,
        Get = function() return val end
    }
end

-- Dropdown Component
local function addDropdown(sec, title, options, defOpt, callback)
    local selected = defOpt or options[1] or ""
    local open = false

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 34)
    row.BackgroundColor3 = Theme.Colors.Card
    row.BorderSizePixel = 0
    row.Parent = sec

    local rCorner = Instance.new("UICorner")
    rCorner.CornerRadius = Theme.Corners.Element
    rCorner.Parent = row

    local rStroke = Instance.new("UIStroke")
    rStroke.Color = Theme.Colors.Border
    rStroke.Thickness = 1
    rStroke.Parent = row

    local lbl = Instance.new("TextLabel")
    lbl.Text = title
    lbl.Font = Theme.Fonts.Body
    lbl.TextSize = 12
    lbl.TextColor3 = Theme.Colors.TextPrimary
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Size = UDim2.new(0.5, 0, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Parent = row

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.46, 0, 0, 24)
    btn.Position = UDim2.new(0.52, 0, 0.5, -12)
    btn.BackgroundColor3 = Theme.Colors.Header
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = row

    local bCorner = Instance.new("UICorner")
    bCorner.CornerRadius = Theme.Corners.Element
    bCorner.Parent = btn

    local bStroke = Instance.new("UIStroke")
    bStroke.Color = Theme.Colors.Border
    bStroke.Thickness = 1
    bStroke.Parent = btn

    local bLbl = Instance.new("TextLabel")
    bLbl.Text = selected
    bLbl.Font = Theme.Fonts.Subheader
    bLbl.TextSize = 11
    bLbl.TextColor3 = Theme.Colors.AccentLight
    bLbl.TextXAlignment = Enum.TextXAlignment.Left
    bLbl.Size = UDim2.new(1, -20, 1, 0)
    bLbl.Position = UDim2.new(0, 8, 0, 0)
    bLbl.BackgroundTransparency = 1
    bLbl.Parent = btn

    local arrow = Instance.new("TextLabel")
    arrow.Text = "▼"
    arrow.Font = Theme.Fonts.Body
    arrow.TextSize = 8
    arrow.TextColor3 = Theme.Colors.TextMuted
    arrow.Size = UDim2.new(0, 16, 1, 0)
    arrow.Position = UDim2.new(1, -16, 0, 0)
    arrow.BackgroundTransparency = 1
    arrow.Parent = btn

    local list = Instance.new("Frame")
    list.Size = UDim2.new(1, 0, 0, #options * 24 + 6)
    list.Position = UDim2.new(0, 0, 1, 4)
    list.BackgroundColor3 = Theme.Colors.Header
    list.BorderSizePixel = 0
    list.Visible = false
    list.ZIndex = 50
    list.Parent = btn

    local lCorner = Instance.new("UICorner")
    lCorner.CornerRadius = Theme.Corners.Element
    lCorner.Parent = list

    local lStroke = Instance.new("UIStroke")
    lStroke.Color = Theme.Colors.Accent
    lStroke.Thickness = 1
    lStroke.Parent = list

    local lLayout = Instance.new("UIListLayout")
    lLayout.SortOrder = Enum.SortOrder.LayoutOrder
    lLayout.Padding = UDim.new(0, 2)
    lLayout.Parent = list

    local lPad = Instance.new("UIPadding")
    lPad.PaddingTop = UDim.new(0, 3)
    lPad.PaddingBottom = UDim.new(0, 3)
    lPad.PaddingLeft = UDim.new(0, 4)
    lPad.PaddingRight = UDim.new(0, 4)
    lPad.Parent = list

    local function toggleMenu()
        open = not open
        list.Visible = open
        arrow.Text = open and "▲" or "▼"
    end
    btn.MouseButton1Click:Connect(toggleMenu)

    for _, opt in ipairs(options) do
        local optBtn = Instance.new("TextButton")
        optBtn.Size = UDim2.new(1, 0, 0, 22)
        optBtn.BackgroundTransparency = 1
        optBtn.BorderSizePixel = 0
        optBtn.Text = opt
        optBtn.Font = Theme.Fonts.Body
        optBtn.TextSize = 11
        optBtn.TextColor3 = (opt == selected) and Theme.Colors.AccentLight or Theme.Colors.TextSecondary
        optBtn.ZIndex = 51
        optBtn.Parent = list

        optBtn.MouseButton1Click:Connect(function()
            selected = opt
            bLbl.Text = opt
            toggleMenu()
            if callback then callback(opt) end
        end)
    end

    return {
        Set = function(v) selected = v bLbl.Text = v if callback then callback(v) end end,
        Get = function() return selected end
    }
end

local function addButton(sec, title, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 32)
    btn.BackgroundColor3 = Theme.Colors.Card
    btn.BorderSizePixel = 0
    btn.Text = title
    btn.Font = Theme.Fonts.Subheader
    btn.TextSize = 12
    btn.TextColor3 = Theme.Colors.TextPrimary
    btn.Parent = sec

    local corner = Instance.new("UICorner")
    corner.CornerRadius = Theme.Corners.Element
    corner.Parent = btn

    local stroke = Instance.new("UIStroke")
    stroke.Color = Theme.Colors.Border
    stroke.Thickness = 1
    stroke.Parent = btn

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = Theme.Colors.AccentActive }):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = Theme.Colors.Card }):Play()
    end)
    btn.MouseButton1Click:Connect(function()
        if callback then callback() end
    end)
    return btn
end

-- =====================================================================
-- 9. TAB PAGE REGISTRATION (ALL MODULES)
-- =====================================================================
function Hub:BuildPages()
    -- Tab 1: Catching
    local catchPage = self:CreateTab("Catching")
    local cSec1 = addSection(catchPage, "Ball Magnet")
    addToggle(cSec1, "Ball Magnet", State.Catching.MagnetEnabled, function(v)
        State.Catching.MagnetEnabled = v
        if not v then CatchingSystem:ResetHitboxes() end
    end)
    addDropdown(cSec1, "Magnet Mode", { "Regular", "Strong", "Legit" }, State.Catching.MagnetMode, function(v)
        State.Catching.MagnetMode = v
    end)
    addSlider(cSec1, "Magnet Range", 5, 80, State.Catching.MagnetRange, 1, " studs", function(v)
        State.Catching.MagnetRange = v
    end)
    addSlider(cSec1, "Catch Hitbox Size", 2, 30, State.Catching.HitboxSize, 1, " studs", function(v)
        State.Catching.HitboxSize = v
    end)
    addSlider(cSec1, "Catch Distance", 5, 50, State.Catching.CatchDistance, 1, " studs", function(v)
        State.Catching.CatchDistance = v
    end)
    addSlider(cSec1, "Catch Angle (FOV)", 30, 180, State.Catching.CatchAngle, 5, "°", function(v)
        State.Catching.CatchAngle = v
    end)

    local cSec2 = addSection(catchPage, "Configuration")
    addToggle(cSec2, "Angle Enhancer (Omni-Catch)", State.Catching.AngleEnhancer, function(v)
        State.Catching.AngleEnhancer = v
    end)
    addToggle(cSec2, "Automatic Catch", State.Catching.AutoCatch, function(v)
        State.Catching.AutoCatch = v
    end)
    addToggle(cSec2, "Dive Catch Assist", State.Catching.DiveCatchAssist, function(v)
        State.Catching.DiveCatchAssist = v
    end)

    -- Tab 2: QB (Quarterback / Passing)
    local qbPage = self:CreateTab("QB")
    local qbSec1 = addSection(qbPage, "Aimbot")
    addToggle(qbSec1, "QB Aimbot", State.QB.AimbotEnabled, function(v)
        State.QB.AimbotEnabled = v
    end, State.QB.ThrowAssistKey)
    addDropdown(qbSec1, "Target Selector", { "Closest to Mouse", "Nearest Teammate", "Open Receiver" }, State.QB.TargetSelector, function(v)
        State.QB.TargetSelector = v
    end)

    local qbSec2 = addSection(qbPage, "Configuration")
    addToggle(qbSec2, "Auto Angle", State.QB.AutoAngle, function(v)
        State.QB.AutoAngle = v
    end)
    addToggle(qbSec2, "Auto Throw Type", State.QB.AutoThrowType, function(v)
        State.QB.AutoThrowType = v
    end)
    addToggle(qbSec2, "Anti-Wobble / Perfect Spiral", State.QB.AntiWobble, function(v)
        State.QB.AntiWobble = v
    end)
    addSlider(qbSec2, "Lead Prediction Depth", 0.2, 2.0, State.QB.LeadPredictionTime, 0.05, "s", function(v)
        State.QB.LeadPredictionTime = v
    end)
    addSlider(qbSec2, "Bullet Velocity", 60, 140, State.QB.BulletPassVelocity, 5, " studs/s", function(v)
        State.QB.BulletPassVelocity = v
    end)
    addSlider(qbSec2, "Lob Velocity", 40, 95, State.QB.LobPassVelocity, 5, " studs/s", function(v)
        State.QB.LobPassVelocity = v
    end)

    -- Tab 3: Physics
    local phyPage = self:CreateTab("Physics")
    local phySec1 = addSection(phyPage, "Movement Modifiers")
    addToggle(phySec1, "Enable Custom WalkSpeed", State.Physics.SpeedEnabled, function(v)
        State.Physics.SpeedEnabled = v
        if not v then
            local _, _, hum = Environment.getLocalCharacter()
            if hum then hum.WalkSpeed = 16 end
        end
    end)
    addSlider(phySec1, "WalkSpeed Value", 16, 85, State.Physics.WalkSpeed, 1, " studs/s", function(v)
        State.Physics.WalkSpeed = v
    end)
    addToggle(phySec1, "Enable Custom JumpPower", State.Physics.JumpEnabled, function(v)
        State.Physics.JumpEnabled = v
        if not v then
            local _, _, hum = Environment.getLocalCharacter()
            if hum then
                if hum.UseJumpPower then hum.JumpPower = 50 else hum.JumpHeight = 7.2 end
            end
        end
    end)
    addSlider(phySec1, "JumpPower Value", 50, 160, State.Physics.JumpPower, 5, " pow", function(v)
        State.Physics.JumpPower = v
    end)
    addToggle(phySec1, "Infinite Jump", State.Physics.InfiniteJump, function(v)
        State.Physics.InfiniteJump = v
    end)
    addSlider(phySec1, "Dive Velocity Multiplier", 1.0, 2.5, State.Physics.DiveMultiplier, 0.1, "x", function(v)
        State.Physics.DiveMultiplier = v
    end)
    addToggle(phySec1, "Anti-Stumble / No Ragdoll", State.Physics.AntiStumble, function(v)
        State.Physics.AntiStumble = v
    end)

    -- Tab 4: Defense
    local defPage = self:CreateTab("Defense")
    local defSec = addSection(defPage, "Tackle & Pass Coverage")
    addToggle(defSec, "Tackle Radius Expander", State.Defense.TackleExpander, function(v)
        State.Defense.TackleExpander = v
    end)
    addSlider(defSec, "Tackle Distance", 5, 30, State.Defense.TackleRadius, 1, " studs", function(v)
        State.Defense.TackleRadius = v
    end)
    addToggle(defSec, "Auto Swat / Deflect Pass", State.Defense.AutoSwat, function(v)
        State.Defense.AutoSwat = v
    end)
    addToggle(defSec, "Coverage Acceleration Assist", State.Defense.CoverageBoost, function(v)
        State.Defense.CoverageBoost = v
    end)

    -- Tab 5: Trolling
    local trolPage = self:CreateTab("Trolling")
    local trSec = addSection(trolPage, "Miscellaneous & Fun")
    addToggle(trSec, "Spinbot", State.Trolling.Spinbot, function(v)
        State.Trolling.Spinbot = v
    end)
    addSlider(trSec, "Spinbot Yaw Speed", 5, 60, State.Trolling.SpinSpeed, 5, " deg/s", function(v)
        State.Trolling.SpinSpeed = v
    end)
    addToggle(trSec, "Ball Fling Impulse", State.Trolling.BallFling, function(v)
        State.Trolling.BallFling = v
    end)

    -- Tab 6: Automatics
    local autoPage = self:CreateTab("Automatics")
    local autSec = addSection(autoPage, "Autonomous Routines")
    addToggle(autSec, "Autonomous Catch", State.Automatics.AutoCatch, function(v)
        State.Automatics.AutoCatch = v
    end)
    addSlider(autSec, "Auto Catch Range", 5, 25, State.Automatics.AutoCatchDistance, 1, " studs", function(v)
        State.Automatics.AutoCatchDistance = v
    end)
    addToggle(autSec, "Autonomous Intercept Guide", State.Automatics.AutoIntercept, function(v)
        State.Automatics.AutoIntercept = v
    end)
    addToggle(autSec, "Autonomous Dive", State.Automatics.AutoDive, function(v)
        State.Automatics.AutoDive = v
    end)
    addSlider(autSec, "Auto Dive Distance", 10, 35, State.Automatics.AutoDiveDistance, 1, " studs", function(v)
        State.Automatics.AutoDiveDistance = v
    end)
    addToggle(autSec, "Autonomous Dead Ball Pickup", State.Automatics.AutoPick, function(v)
        State.Automatics.AutoPick = v
    end)
    addSlider(autSec, "Auto Pick Distance", 6, 25, State.Automatics.AutoPickDistance, 1, " studs", function(v)
        State.Automatics.AutoPickDistance = v
    end)

    -- Tab 7: Visuals
    local visPage = self:CreateTab("Visuals")
    local vSec1 = addSection(visPage, "Football Tracking & Trajectory")
    addToggle(vSec1, "Enable Ball Visuals", State.Visuals.BallMaster, function(v)
        State.Visuals.BallMaster = v
    end)
    addToggle(vSec1, "Ball Highlight (Chams)", State.Visuals.BallHighlight, function(v)
        State.Visuals.BallHighlight = v
    end)
    addToggle(vSec1, "Ball Trajectory Arc", State.Visuals.BallTrajectory, function(v)
        State.Visuals.BallTrajectory = v
    end)
    addToggle(vSec1, "Ball Landing Circle", State.Visuals.BallLandingMarker, function(v)
        State.Visuals.BallLandingMarker = v
    end)
    addToggle(vSec1, "Ball Distance Tag", State.Visuals.BallDistance, function(v)
        State.Visuals.BallDistance = v
    end)

    local vSec2 = addSection(visPage, "Player Visuals")
    addToggle(vSec2, "Enable Player Visuals", State.Visuals.PlayerMaster, function(v)
        State.Visuals.PlayerMaster = v
    end)
    addDropdown(vSec2, "Filter Mode", { "Opponent", "Team", "Everyone" }, State.Visuals.PlayerFilter, function(v)
        State.Visuals.PlayerFilter = v
    end)
    addToggle(vSec2, "Player 2D Boxes", State.Visuals.PlayerBoxes, function(v)
        State.Visuals.PlayerBoxes = v
    end)
    addToggle(vSec2, "Player Tracers", State.Visuals.PlayerTracers, function(v)
        State.Visuals.PlayerTracers = v
    end)
    addToggle(vSec2, "Player Nametags", State.Visuals.PlayerNames, function(v)
        State.Visuals.PlayerNames = v
    end)

    -- Tab 8: Misc
    local miscPage = self:CreateTab("Misc")
    local mSec = addSection(miscPage, "Interface & Preferences")
    addToggle(mSec, "Show Live Watermark", State.Settings.Watermark, function(v)
        State.Settings.Watermark = v
        local wm = Hub.ScreenGui and Hub.ScreenGui:FindFirstChild("WiiHubWatermark")
        if wm then wm.Visible = v end
    end)

    -- Tab 9: Configs
    local cfgPage = self:CreateTab("Configs")
    local cSec = addSection(cfgPage, "Storage & Lifecycle")
    addButton(cSec, "Save Configuration to Disk", function()
        local canWrite = typeof(writefile) == "function" and typeof(makefolder) == "function"
        if canWrite then
            pcall(function()
                if not (typeof(isfolder) == "function" and isfolder("wiihub_ff2")) then
                    makefolder("wiihub_ff2")
                end
                writefile("wiihub_ff2/config.json", HttpService:JSONEncode(State))
            end)
            self:Notify("Config Saved", "Preferences saved to wiihub_ff2/config.json", 2.5)
        else
            self:Notify("Notice", "Executor does not support writefile", 2.5)
        end
    end)
    addButton(cSec, "Load Configuration from Disk", function()
        local canRead = typeof(readfile) == "function" and typeof(isfile) == "function"
        if canRead and isfile("wiihub_ff2/config.json") then
            pcall(function()
                local raw = readfile("wiihub_ff2/config.json")
                local decoded = HttpService:JSONDecode(raw)
                for cat, vals in pairs(decoded) do
                    if State[cat] and type(vals) == "table" then
                        for k, v in pairs(vals) do State[cat][k] = v end
                    end
                end
            end)
            self:Notify("Config Loaded", "Preferences applied successfully", 2.5)
        else
            self:Notify("Notice", "No existing configuration file found", 2.5)
        end
    end)
    addButton(cSec, "Unload Hub & Clean Memory", function()
        self:Unload()
    end)
end

function Hub:Unload()
    for _, conn in ipairs(self._connections) do
        pcall(function() conn:Disconnect() end)
    end
    self._connections = {}

    CatchingSystem:ResetHitboxes()

    if VisualsSystem._ballHighlight then VisualsSystem._ballHighlight:Destroy() end
    if VisualsSystem._ballText then VisualsSystem._ballText:Remove() end
    if VisualsSystem._ballCircle then VisualsSystem._ballCircle:Remove() end
    for _, line in ipairs(VisualsSystem._ballLines) do line:Remove() end
    for _, entry in pairs(VisualsSystem._playerDrawings) do
        if entry.Box then entry.Box:Remove() end
        if entry.Tracer then entry.Tracer:Remove() end
        if entry.Name then entry.Name:Remove() end
    end

    pcall(function()
        local _, _, hum = Environment.getLocalCharacter()
        if hum then
            hum.WalkSpeed = 16
            if hum.UseJumpPower then hum.JumpPower = 50 else hum.JumpHeight = 7.2 end
        end
    end)

    if self.ScreenGui then
        self.ScreenGui:Destroy()
        self.ScreenGui = nil
    end

    if getgenv then
        getgenv().VortexInstance = nil
    end
end

-- =====================================================================
-- 10. SYSTEM LIFECYCLE EXECUTION
-- =====================================================================
VisualsSystem:Init()
Hub:Init()

-- Fast Heartbeat Loop (Magnet, QB, Physics, Automatics, Defense, Trolling)
local spinAngle = 0
local heartbeatConn = RunService.Heartbeat:Connect(function()
    pcall(function()
        CatchingSystem:Step()
        QBSystem:Step()
        PhysicsSystem:Step()
        AutomaticsSystem:Step()

        -- Spinbot logic
        if State.Trolling.Spinbot then
            local _, hrp = Environment.getLocalCharacter()
            if hrp then
                spinAngle = (spinAngle + State.Trolling.SpinSpeed) % 360
                hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, math.rad(spinAngle), 0)
            end
        end

        -- Ball Fling logic
        if State.Trolling.BallFling then
            local football = Environment.getFootball()
            local _, hrp = Environment.getLocalCharacter()
            if football and hrp and (football.Position - hrp.Position).Magnitude < 10 then
                football.AssemblyAngularVelocity = Vector3.new(10000, 10000, 10000)
            end
        end

        -- Defense Tackle Expander
        if State.Defense.TackleExpander then
            local char, hrp = Environment.getLocalCharacter()
            if char and hrp then
                for _, opp in ipairs(Players:GetPlayers()) do
                    if opp ~= LocalPlayer and not Environment.isTeammate(opp) and opp.Character and opp.Character:FindFirstChild("HumanoidRootPart") then
                        local oppHrp = opp.Character.HumanoidRootPart
                        local dist = (oppHrp.Position - hrp.Position).Magnitude
                        if dist <= State.Defense.TackleRadius then
                            hrp.CFrame = oppHrp.CFrame
                            break
                        end
                    end
                end
            end
        end
    end)
end)
table.insert(Hub._connections, heartbeatConn)

-- Render Loop (Visuals)
local renderConn = RunService.RenderStepped:Connect(function()
    pcall(function()
        VisualsSystem:Render()
    end)
end)
table.insert(Hub._connections, renderConn)

-- Player Removal Cleanup
local plrLeaveConn = Players.PlayerRemoving:Connect(function(plr)
    local entry = VisualsSystem._playerDrawings[plr]
    if entry then
        if entry.Box then entry.Box:Remove() end
        if entry.Tracer then entry.Tracer:Remove() end
        if entry.Name then entry.Name:Remove() end
        VisualsSystem._playerDrawings[plr] = nil
    end
end)
table.insert(Hub._connections, plrLeaveConn)

-- Save global instance reference
if getgenv then
    getgenv().VortexInstance = Hub
end

Hub:Notify("WiiHub Loaded", "Press " .. State.Settings.ToggleKey.Name .. " to toggle interface.", 4)
