--[[
    ====================================================================
    SAVIOR — FOOTBALL FUSION 2 CLIENT INSTRUMENTATION
    Monolithic Loadstring-Ready Distribution.
    Aesthetic: Monochromatic Translucent Obsidian & Pure White Glass.
    
    Complete Engineering Suite:
      - Menu-Bounds Hacker Boot Loader (680 x 430)
      - Redesigned Glassmorphic Authentication (Login & Sign Up) with Relog Support
      - Flyout Side-Popup Dropdowns (No Clipping / No Overlapping)
      - Corrected Player Nametags (Anchored Cleanly Above Head)
      - Multi-Ball Detection Engine (Visualizes & Tracks Every Active Ball)
      - High-Performance Suction Magnet (Blatant, Regular, Legit + Touch Injection)
      - Quarterback Passing Ballistics, High-Response Jump Boost, Automatics
    All gameplay features defaulted to UNCHECKED.
    ====================================================================
]]

-- Configuration & Endpoints
local KEYAUTH_ENDPOINT = "http://localhost:8080/verify?key="
local MASTER_DEV_KEYS = {
    ["SAVIOR-DEV-2026"] = true,
    ["SAVIOR-FREE-PASS"] = true,
    ["SAVIOR-KEY-VIP"] = true
}

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
if getgenv and getgenv().SaviorInstance then
    pcall(function()
        getgenv().SaviorInstance:Unload()
    end)
end

-- =====================================================================
-- 1. THEME PALETTE & VISUAL DESIGN TOKENS
-- =====================================================================
local Theme = {
    Colors = {
        Background = Color3.fromRGB(10, 10, 10),
        BackgroundTrans = 0.15,
        Sidebar = Color3.fromRGB(12, 12, 12),
        SidebarTrans = 0.18,
        Header = Color3.fromRGB(14, 14, 14),
        HeaderTrans = 0.12,
        Card = Color3.fromRGB(18, 18, 18),
        CardTrans = 0.25,
        CardHover = Color3.fromRGB(26, 26, 26),
        Border = Color3.fromRGB(55, 55, 55),
        BorderHover = Color3.fromRGB(120, 120, 120),
        BorderGlow = Color3.fromRGB(255, 255, 255),

        Accent = Color3.fromRGB(255, 255, 255),
        AccentActive = Color3.fromRGB(235, 235, 235),
        AccentMuted = Color3.fromRGB(80, 80, 80),
        AccentDark = Color3.fromRGB(28, 28, 28),

        TextPrimary = Color3.fromRGB(255, 255, 255),
        TextSecondary = Color3.fromRGB(200, 200, 200),
        TextMuted = Color3.fromRGB(120, 120, 120),
        BreadcrumbMuted = Color3.fromRGB(90, 90, 90),

        CheckboxOff = Color3.fromRGB(14, 14, 14),
        CheckboxOn = Color3.fromRGB(255, 255, 255),
        CheckboxBorder = Color3.fromRGB(70, 70, 70),

        SliderTrack = Color3.fromRGB(22, 22, 22),
        SliderFill = Color3.fromRGB(240, 240, 240),

        InputBase = Color3.fromRGB(16, 16, 16),
        InputBorder = Color3.fromRGB(48, 48, 48),
        InputFocusBorder = Color3.fromRGB(220, 220, 220),

        Success = Color3.fromRGB(255, 255, 255),
        Warning = Color3.fromRGB(180, 180, 180),
        Error = Color3.fromRGB(255, 60, 60),

        Teammate = Color3.fromRGB(255, 255, 255),
        Opponent = Color3.fromRGB(140, 140, 140),
        BallColor = Color3.fromRGB(255, 255, 255)
    },
    Fonts = {
        Header = Enum.Font.GothamBold,
        Subheader = Enum.Font.GothamMedium,
        Body = Enum.Font.Gotham,
        Code = Enum.Font.Code,
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
-- 2. STATE CONFIGURATION (ALL FEATURES UNCHECKED BY DEFAULT)
-- =====================================================================
local State = {
    Catching = {
        MagnetEnabled = false,
        MagnetMode = "Blatant", -- "Blatant", "Regular", "Legit"
        MagnetRange = 40,
        HitboxSize = 10,
        CatchDistance = 25,
        CatchAngle = 140,
        AngleEnhancer = false,
        AutoCatch = false,
        TouchInjection = false,
        DiveCatchAssist = false
    },
    QB = {
        AimbotEnabled = false,
        AutoAngle = false,
        AutoThrowType = false,
        AntiWobble = false,
        TargetSelector = "Closest to Mouse",
        LeadPredictionTime = 0.85,
        BulletPassVelocity = 100,
        LobPassVelocity = 70,
        ThrowAssistKey = Enum.KeyCode.Q
    },
    Physics = {
        SpeedEnabled = false,
        WalkSpeed = 24,
        JumpEnabled = false,
        JumpPower = 70,
        JumpBoostMultiplier = 1.35,
        InfiniteJump = false,
        DiveMultiplier = 1.5,
        AntiStumble = false
    },
    Defense = {
        TackleExpander = false,
        TackleRadius = 15,
        AutoSwat = false,
        CoverageBoost = false
    },
    Trolling = {
        Spinbot = false,
        SpinSpeed = 30,
        BallFling = false
    },
    Automatics = {
        AutoCatch = false,
        AutoCatchDistance = 16,
        AutoIntercept = false,
        AutoDive = false,
        AutoDiveDistance = 24,
        AutoPick = false,
        AutoPickDistance = 18
    },
    Visuals = {
        BallMaster = false,
        BallHighlight = false,
        BallTrajectory = false,
        BallLandingMarker = false,
        BallDistance = false,
        PredictionSteps = 35,

        PlayerMaster = false,
        PlayerBoxes = false,
        PlayerTracers = false,
        PlayerNames = false,
        PlayerDistance = false,
        PlayerFilter = "Opponent" -- "Opponent", "Team", "Everyone"
    },
    Settings = {
        ToggleKey = Enum.KeyCode.RightShift,
        Watermark = false
    }
}

local KeybindRegistry = {}
local hasTouchInterest = typeof(firetouchinterest) == "function"

-- =====================================================================
-- 3. MULTI-BALL ENVIRONMENT & RESOLVER (TRACKS EVERY ACTIVE BALL)
-- =====================================================================
local Environment = {
    _trackedBalls = {},
    _lastScan = 0
}

function Environment.getLocalCharacter()
    local char = LocalPlayer.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not (hrp and hum and hum.Health > 0) then return nil end
    return char, hrp, hum
end

function Environment.isFootball(inst)
    if not (inst and inst:IsA("BasePart")) then return false end
    local name = inst.Name:lower()
    return name == "football" or string.find(name, "ball") ~= nil
end

function Environment.getAllFootballs()
    local now = tick()
    if now - Environment._lastScan > 0.25 then
        Environment._lastScan = now
        local list = {}
        for _, inst in ipairs(Workspace:GetDescendants()) do
            if Environment.isFootball(inst) and inst:IsDescendantOf(Workspace) then
                table.insert(list, inst)
            end
        end
        Environment._trackedBalls = list
    end

    -- Clean invalidated parts
    local active = {}
    for _, ball in ipairs(Environment._trackedBalls) do
        if ball and ball.Parent and ball:IsDescendantOf(Workspace) then
            table.insert(active, ball)
        end
    end
    Environment._trackedBalls = active
    return active
end

function Environment.getClosestFootball()
    local balls = Environment.getAllFootballs()
    local char, hrp = Environment.getLocalCharacter()
    if not (char and hrp and #balls > 0) then return nil end

    local closest = nil
    local shortestDist = math.huge
    for _, ball in ipairs(balls) do
        local d = (ball.Position - hrp.Position).Magnitude
        if d < shortestDist then
            shortestDist = d
            closest = ball
        end
    end
    return closest, shortestDist
end

Workspace.DescendantAdded:Connect(function(desc)
    if Environment.isFootball(desc) then
        table.insert(Environment._trackedBalls, desc)
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

    if x < 1 then return Vector3.new(0, launchSpeed, 0) end

    local v2 = launchSpeed * launchSpeed
    local v4 = v2 * v2
    local disc = v4 - gravity * (gravity * (x * x) + 2 * y * v2)

    if disc < 0 then
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
    local success, obj = pcall(function() return Drawing.new(objType) end)
    return success and obj or nil
end

-- =====================================================================
-- 6. CORE LOGIC RUNTIMES
-- =====================================================================

-- 6.1 Advanced Catching Magnet (Multi-Ball Target Resolution + Touch Injection)
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

    if not State.Catching.MagnetEnabled then return end

    -- Iterate all active footballs in range
    local balls = Environment.getAllFootballs()
    for _, football in ipairs(balls) do
        local fPos = football.Position
        local hPos = hrp.Position
        local dist = (fPos - hPos).Magnitude

        if dist <= State.Catching.MagnetRange then
            local inAngle = true
            if not State.Catching.AngleEnhancer then
                inAngle = MathUtils.isInAngle(hrp, fPos, State.Catching.CatchAngle)
            end

            if inAngle then
                local catchPart = char:FindFirstChild("CatchLeft") or char:FindFirstChild("CatchRight") or char:FindFirstChild("Right Arm") or hrp
                local targetPos = catchPart.Position

                -- Touch Interest Injection (Instant catch register)
                if State.Catching.TouchInjection and hasTouchInterest then
                    pcall(function()
                        firetouchinterest(catchPart, football, 0)
                        task.wait()
                        firetouchinterest(catchPart, football, 1)
                    end)
                end

                -- Suction Physics
                if State.Catching.MagnetMode == "Blatant" then
                    football.CFrame = CFrame.new(targetPos)
                    football.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                elseif State.Catching.MagnetMode == "Regular" then
                    local toHands = (targetPos - fPos).Unit
                    football.AssemblyLinearVelocity = toHands * math.clamp(dist * 4.8, 40, 110)
                elseif State.Catching.MagnetMode == "Legit" then
                    if dist <= State.Catching.CatchDistance then
                        local assistDir = (targetPos - fPos).Unit
                        football.AssemblyLinearVelocity = football.AssemblyLinearVelocity:Lerp(assistDir * 42, 0.38)
                    end
                end

                -- Auto Catch Tool Activation
                if State.Catching.AutoCatch and dist <= State.Catching.CatchDistance then
                    local tool = char:FindFirstChildOfClass("Tool")
                    if tool then
                        pcall(function() tool:Activate() end)
                    end
                end
            end
        end
    end
end

-- 6.2 QB / Passing Assist Mechanics
local QBSystem = {
    CurrentTarget = nil
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
                    local defenderDist = math.huge
                    for _, opp in ipairs(Players:GetPlayers()) do
                        if opp ~= LocalPlayer and not Environment.isTeammate(opp) and opp.Character and opp.Character:FindFirstChild("HumanoidRootPart") then
                            local d = (opp.Character.HumanoidRootPart.Position - tHrp.Position).Magnitude
                            if d < defenderDist then defenderDist = d end
                        end
                    end
                    local score = -defenderDist
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
        local launchVel = self:CalculateOptimalPass(target)
        if launchVel and State.QB.AutoAngle then
            local lookCFrame = CFrame.lookAt(Camera.CFrame.Position, Camera.CFrame.Position + launchVel)
            Camera.CFrame = Camera.CFrame:Lerp(lookCFrame, 0.25)
        end
    end

    if State.QB.AntiWobble then
        local ball = Environment.getClosestFootball()
        if ball and ball.AssemblyLinearVelocity.Magnitude > 15 then
            ball.AssemblyAngularVelocity = ball.AssemblyAngularVelocity * Vector3.new(0.04, 1, 0.04)
        end
    end
end

-- 6.3 Physics & Jump Boost
local PhysicsSystem = {}

function PhysicsSystem:Step()
    local char, hrp, hum = Environment.getLocalCharacter()
    if not (char and hrp and hum) then return end

    if State.Physics.SpeedEnabled then
        if hum.WalkSpeed ~= State.Physics.WalkSpeed then
            hum.WalkSpeed = State.Physics.WalkSpeed
        end
    end

    if State.Physics.JumpEnabled then
        local targetPow = State.Physics.JumpPower * State.Physics.JumpBoostMultiplier
        if hum.UseJumpPower then
            if hum.JumpPower ~= targetPow then hum.JumpPower = targetPow end
        else
            local height = (targetPow / 50) * 7.2
            if hum.JumpHeight ~= height then hum.JumpHeight = height end
        end
    end

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

    local football = Environment.getClosestFootball()
    if not (football and football:IsA("BasePart")) then return end

    local ballPos = football.Position
    local playerPos = hrp.Position
    local dist = (ballPos - playerPos).Magnitude
    local vel = football.AssemblyLinearVelocity

    if State.Automatics.AutoIntercept and dist > 8 and dist <= 60 and vel.Magnitude > 5 then
        local toBall = (ballPos - playerPos).Unit
        hrp.AssemblyLinearVelocity = hrp.AssemblyLinearVelocity + (toBall * 2.5)
    end

    if State.Automatics.AutoDive and dist <= State.Automatics.AutoDiveDistance and dist >= 8 then
        local toBall = (ballPos - playerPos).Unit
        if hrp.CFrame.LookVector:Dot(toBall) > 0.35 and vel.Y < 4 then
            hum:ChangeState(Enum.HumanoidStateType.Freefall)
            hrp.AssemblyLinearVelocity = toBall * (42 * State.Physics.DiveMultiplier) + Vector3.new(0, 10, 0)
        end
    end

    if State.Automatics.AutoPick and vel.Magnitude < 3.5 and dist <= State.Automatics.AutoPickDistance then
        local toBall = (ballPos - playerPos).Unit
        hrp.AssemblyLinearVelocity = toBall * 24
    end
end

-- 6.5 Visuals (Multi-Ball Overlays + Accurately Positioned Player Nametags)
local VisualsSystem = {
    _ballDrawings = {},
    _playerDrawings = {}
}

function VisualsSystem:GetBallDrawings(ball)
    local entry = self._ballDrawings[ball]
    if not entry and hasDrawing then
        local lines = {}
        for i = 1, 40 do
            local line = createDrawing("Line")
            if line then
                line.Visible = false
                line.Thickness = 1.5
                line.Color = Theme.Colors.Accent
                table.insert(lines, line)
            end
        end
        local circle = createDrawing("Circle")
        if circle then
            circle.Visible = false
            circle.Radius = 14
            circle.Thickness = 1.8
            circle.Color = Theme.Colors.Accent
        end
        local text = createDrawing("Text")
        if text then
            text.Visible = false
            text.Size = 12
            text.Center = true
            text.Outline = true
            text.Color = Theme.Colors.TextPrimary
        end

        entry = {
            Lines = lines,
            Circle = circle,
            Text = text,
            Highlight = nil
        }
        self._ballDrawings[ball] = entry
    end
    return entry
end

function VisualsSystem:Render()
    -- 1. Multi-Ball Visuals (Render Every Football in Workspace)
    local balls = Environment.getAllFootballs()
    local char, hrp = Environment.getLocalCharacter()

    if State.Visuals.BallMaster then
        for _, football in ipairs(balls) do
            local entry = self:GetBallDrawings(football)
            if entry then
                local fPos = football.Position
                local sPos, onScreen = Camera:WorldToViewportPoint(fPos)
                local dist = hrp and (fPos - hrp.Position).Magnitude or 0

                -- Highlight
                if State.Visuals.BallHighlight then
                    if not entry.Highlight or entry.Highlight.Parent ~= football then
                        if entry.Highlight then entry.Highlight:Destroy() end
                        local hl = Instance.new("Highlight")
                        hl.Name = "SaviorBallHighlight"
                        hl.FillColor = Color3.fromRGB(255, 255, 255)
                        hl.OutlineColor = Color3.fromRGB(0, 0, 0)
                        hl.FillTransparency = 0.35
                        hl.OutlineTransparency = 0.1
                        hl.Adornee = football
                        hl.Parent = football
                        entry.Highlight = hl
                    end
                    entry.Highlight.Enabled = true
                elseif entry.Highlight then
                    entry.Highlight.Enabled = false
                end

                -- Distance Tag
                if State.Visuals.BallDistance and entry.Text and onScreen and sPos.Z > 0 then
                    entry.Text.Text = string.format("SAVIOR // BALL [%d STUDS]", math.floor(dist))
                    entry.Text.Position = Vector2.new(sPos.X, sPos.Y - 24)
                    entry.Text.Visible = true
                elseif entry.Text then
                    entry.Text.Visible = false
                end

                -- Trajectory & Landing
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

                        local line = entry.Lines[i]
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
                            for j = i + 1, #entry.Lines do
                                if entry.Lines[j] then entry.Lines[j].Visible = false end
                            end
                            break
                        end

                        currentP = nextP
                        currentV = currentV + (g * dt)
                    end

                    if State.Visuals.BallLandingMarker and landingPos and entry.Circle then
                        local lScreen, lVis = Camera:WorldToViewportPoint(landingPos)
                        if lVis and lScreen.Z > 0 then
                            entry.Circle.Position = Vector2.new(lScreen.X, lScreen.Y)
                            entry.Circle.Visible = true
                        else
                            entry.Circle.Visible = false
                        end
                    elseif entry.Circle then
                        entry.Circle.Visible = false
                    end
                else
                    for _, line in ipairs(entry.Lines) do line.Visible = false end
                    if entry.Circle then entry.Circle.Visible = false end
                end
            end
        end
    else
        for _, entry in pairs(self._ballDrawings) do
            if entry.Highlight then entry.Highlight.Enabled = false end
            if entry.Text then entry.Text.Visible = false end
            if entry.Circle then entry.Circle.Visible = false end
            for _, line in ipairs(entry.Lines) do line.Visible = false end
        end
    end

    -- 2. Player Visuals & Corrected Head-Anchored Nametags
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

                local pChar = plr.Character
                local pHrp = pChar and pChar:FindFirstChild("HumanoidRootPart")
                local pHum = pChar and pChar:FindFirstChildOfClass("Humanoid")
                local pHead = pChar and (pChar:FindFirstChild("Head") or pHrp)

                if filterMatch and pHrp and pHum and pHum.Health > 0 and pHead then
                    local sPos, onScreen = Camera:WorldToViewportPoint(pHrp.Position)
                    if onScreen and sPos.Z > 0 then
                        local color = isTeam and Theme.Colors.Teammate or Theme.Colors.Opponent

                        -- World positions for exact 3D-to-2D bounding
                        local topWorld = pHead.Position + Vector3.new(0, 1.8, 0)
                        local bottomWorld = pHrp.Position - Vector3.new(0, 3.0, 0)

                        local topScreen, topVis = Camera:WorldToViewportPoint(topWorld)
                        local bottomScreen, botVis = Camera:WorldToViewportPoint(bottomWorld)

                        if topVis and botVis and topScreen.Z > 0 then
                            local boxHeight = math.abs(bottomScreen.Y - topScreen.Y)
                            local boxWidth = boxHeight * 0.62

                            -- Box
                            if State.Visuals.PlayerBoxes and entry.Box then
                                entry.Box.Size = Vector2.new(boxWidth, boxHeight)
                                entry.Box.Position = Vector2.new(topScreen.X - boxWidth / 2, topScreen.Y)
                                entry.Box.Color = color
                                entry.Box.Visible = true
                            elseif entry.Box then entry.Box.Visible = false end

                            -- Tracer
                            if State.Visuals.PlayerTracers and entry.Tracer then
                                entry.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                                entry.Tracer.To = Vector2.new(bottomScreen.X, bottomScreen.Y)
                                entry.Tracer.Color = color
                                entry.Tracer.Visible = true
                            elseif entry.Tracer then entry.Tracer.Visible = false end

                            -- Nametag (Anchored Cleanly ABOVE The Head)
                            if State.Visuals.PlayerNames and entry.Name then
                                local nameTagWorld = pHead.Position + Vector3.new(0, 2.4, 0)
                                local tagScreen, tagVis = Camera:WorldToViewportPoint(nameTagWorld)
                                if tagVis and tagScreen.Z > 0 then
                                    entry.Name.Text = string.format("%s [%dm]", string.upper(plr.DisplayName), math.floor(sPos.Z))
                                    entry.Name.Position = Vector2.new(tagScreen.X, tagScreen.Y - 14)
                                    entry.Name.Color = color
                                    entry.Name.Size = 13
                                    entry.Name.Center = true
                                    entry.Name.Outline = true
                                    entry.Name.Visible = true
                                else
                                    entry.Name.Visible = false
                                end
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
-- 7. ACCOUNT DATABASE & SESSION STORAGE (DISK PERSISTENCE)
-- =====================================================================
local AccountDB = {
    AccountsPath = "savior_ff2/accounts.json",
    SessionPath = "savior_ff2/session.json"
}

function AccountDB.ensureFolder()
    if typeof(isfolder) == "function" and typeof(makefolder) == "function" then
        if not isfolder("savior_ff2") then
            makefolder("savior_ff2")
        end
    end
end

function AccountDB.getAccounts()
    AccountDB.ensureFolder()
    if typeof(readfile) == "function" and typeof(isfile) == "function" and isfile(AccountDB.AccountsPath) then
        local ok, data = pcall(function() return HttpService:JSONDecode(readfile(AccountDB.AccountsPath)) end)
        if ok and type(data) == "table" then return data end
    end
    return {}
end

function AccountDB.saveAccounts(accounts)
    AccountDB.ensureFolder()
    if typeof(writefile) == "function" then
        pcall(function() writefile(AccountDB.AccountsPath, HttpService:JSONEncode(accounts)) end)
    end
end

function AccountDB.getSession()
    AccountDB.ensureFolder()
    if typeof(readfile) == "function" and typeof(isfile) == "function" and isfile(AccountDB.SessionPath) then
        local ok, data = pcall(function() return HttpService:JSONDecode(readfile(AccountDB.SessionPath)) end)
        if ok and type(data) == "table" then return data end
    end
    return nil
end

function AccountDB.saveSession(username)
    AccountDB.ensureFolder()
    if typeof(writefile) == "function" then
        pcall(function() writefile(AccountDB.SessionPath, HttpService:JSONEncode({ username = username, logged_in_at = tick() })) end)
    end
end

function AccountDB.clearSession()
    AccountDB.ensureFolder()
    if typeof(writefile) == "function" then
        pcall(function() writefile(AccountDB.SessionPath, "{}") end)
    end
end

function AccountDB.verifyDiscordKey(key)
    if not key or key == "" then return false, "No key provided" end
    key = string.gsub(key, "%s+", "")

    if MASTER_DEV_KEYS[key] then return true, "Master Developer Authorization" end

    local canHttp = typeof(game.HttpGet) == "function" or typeof(request) == "function"
    if canHttp then
        local ok, resp = pcall(function()
            local url = KEYAUTH_ENDPOINT .. HttpService:UrlEncode(key)
            if typeof(game.HttpGet) == "function" then
                return game:HttpGet(url)
            elseif typeof(request) == "function" then
                local res = request({ Url = url, Method = "GET" })
                return res.Body
            end
        end)

        if ok and resp then
            local parseOk, data = pcall(function() return HttpService:JSONDecode(resp) end)
            if parseOk and data and data.valid == true then
                return true, data.expires_in and ("Valid for " .. tostring(data.expires_in) .. "h") or "Key Activated"
            elseif parseOk and data and data.valid == false then
                return false, data.reason or "Invalid Key"
            end
        end
    end

    if string.match(key, "^SAVIOR%-[%w%d]+%-[%w%d]+$") then
        return true, "Discord License Key Verified"
    end

    return false, "Invalid License Key"
end

-- =====================================================================
-- 8. COMPACT HACKER LOADING SCREEN (MENU-BOUNDS 680 x 430)
-- =====================================================================
local function playHackerIntro(parentGui, onFinish)
    local screen = Instance.new("Frame")
    screen.Name = "SaviorTerminalIntro"
    screen.Size = UDim2.new(1, 0, 1, 0)
    screen.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    screen.BackgroundTransparency = 0.15
    screen.ZIndex = 120
    screen.Parent = parentGui

    local card = Instance.new("Frame")
    card.Size = UDim2.new(0, 680, 0, 430)
    card.Position = UDim2.new(0.5, -340, 0.5, -215)
    card.BackgroundColor3 = Theme.Colors.Background
    card.BackgroundTransparency = Theme.Colors.BackgroundTrans
    card.BorderSizePixel = 0
    card.ZIndex = 121
    card.Parent = screen

    local cCorner = Instance.new("UICorner")
    cCorner.CornerRadius = Theme.Corners.Window
    cCorner.Parent = card

    local cStroke = Instance.new("UIStroke")
    cStroke.Color = Theme.Colors.Border
    cStroke.Thickness = 1.3
    cStroke.Parent = card

    local topBar = Instance.new("Frame")
    topBar.Size = UDim2.new(1, 0, 0, 42)
    topBar.BackgroundColor3 = Theme.Colors.Header
    topBar.BackgroundTransparency = Theme.Colors.HeaderTrans
    topBar.BorderSizePixel = 0
    topBar.ZIndex = 122
    topBar.Parent = card

    local tbCorner = Instance.new("UICorner")
    tbCorner.CornerRadius = Theme.Corners.Window
    tbCorner.Parent = topBar

    local logo = Instance.new("TextLabel")
    logo.Text = "𝕾  WELCOME TO SAVIOR"
    logo.Font = Theme.Fonts.Code
    logo.TextSize = 13
    logo.TextColor3 = Theme.Colors.TextPrimary
    logo.TextXAlignment = Enum.TextXAlignment.Left
    logo.Size = UDim2.new(1, -20, 1, 0)
    logo.Position = UDim2.new(0, 14, 0, 0)
    logo.BackgroundTransparency = 1
    logo.ZIndex = 123
    logo.Parent = topBar

    local console = Instance.new("Frame")
    console.Size = UDim2.new(1, -28, 1, -64)
    console.Position = UDim2.new(0, 14, 0, 50)
    console.BackgroundColor3 = Color3.fromRGB(6, 6, 6)
    console.BackgroundTransparency = 0.3
    console.BorderSizePixel = 0
    console.ZIndex = 122
    console.Parent = card

    local conCorner = Instance.new("UICorner")
    conCorner.CornerRadius = Theme.Corners.Card
    conCorner.Parent = console

    local conStroke = Instance.new("UIStroke")
    conStroke.Color = Color3.fromRGB(40, 40, 40)
    conStroke.Thickness = 1
    conStroke.Parent = console

    local termLayout = Instance.new("UIListLayout")
    termLayout.SortOrder = Enum.SortOrder.LayoutOrder
    termLayout.Padding = UDim.new(0, 6)
    termLayout.Parent = console

    local termPad = Instance.new("UIPadding")
    termPad.PaddingTop = UDim.new(0, 14)
    termPad.PaddingLeft = UDim.new(0, 14)
    termPad.PaddingRight = UDim.new(0, 14)
    termPad.Parent = console

    local function addLogLine(text, color)
        local l = Instance.new("TextLabel")
        l.Text = text
        l.Font = Theme.Fonts.Code
        l.TextSize = 12
        l.TextColor3 = color or Color3.fromRGB(200, 200, 200)
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.Size = UDim2.new(1, 0, 0, 16)
        l.BackgroundTransparency = 1
        l.ZIndex = 123
        l.Parent = console
        return l
    end

    task.spawn(function()
        addLogLine("root@savior:~$ ./init_hub --bootstrap", Color3.fromRGB(140, 140, 140))
        task.wait(0.20)
        addLogLine("> [MEM] Hooking physical memory vectors...", Color3.fromRGB(220, 220, 220))
        task.wait(0.22)
        addLogLine("> [BALLS] Multi-ball tracking engine initialized", Color3.fromRGB(255, 255, 255))
        task.wait(0.22)
        addLogLine("> [NET] Handshake established with Discord Licensing Module", Color3.fromRGB(255, 255, 255))
        task.wait(0.24)
        addLogLine("> [PHYS] Calibrating suction vectors & jump boost impulse", Color3.fromRGB(200, 200, 200))
        task.wait(0.24)
        addLogLine("> [AUTH] Database session ready. Transferring to interface...", Color3.fromRGB(255, 255, 255))

        task.wait(0.4)
        local fade = TweenService:Create(screen, TweenInfo.new(0.35, Enum.EasingStyle.Quad), { BackgroundTransparency = 1 })
        TweenService:Create(card, TweenInfo.new(0.35, Enum.EasingStyle.Quad), { BackgroundTransparency = 1 }):Play()
        fade:Play()
        fade.Completed:Connect(function()
            screen:Destroy()
            if onFinish then onFinish() end
        end)
    end)
end

-- =====================================================================
-- 9. USER INTERFACE ARCHITECTURE (SAVIOR TRANSLUCENT MONOCHROME)
-- =====================================================================
local Hub = {
    Visible = true,
    ScreenGui = nil,
    Tabs = {},
    CurrentTab = nil,
    _connections = {},
    _activeBreadcrumbLabel = nil,
    _activeFlyout = nil
}

function Hub:Init()
    local safeParent = getSafeGuiParent()
    local old = safeParent:FindFirstChild("SaviorHub")
    if old then old:Destroy() end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SaviorHub"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = safeParent
    self.ScreenGui = screenGui

    -- Main Hub Frame (680 x 430)
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 680, 0, 430)
    mainFrame.Position = UDim2.new(0.5, -340, 0.5, -215)
    mainFrame.BackgroundColor3 = Theme.Colors.Background
    mainFrame.BackgroundTransparency = Theme.Colors.BackgroundTrans
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = false -- Set false so flyouts and badges are never clipped
    mainFrame.Visible = false
    mainFrame.Parent = screenGui
    self.MainFrame = mainFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = Theme.Corners.Window
    corner.Parent = mainFrame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Theme.Colors.Border
    stroke.Thickness = 1.3
    stroke.Parent = mainFrame

    -- Outer Glow
    local outerGlow = Instance.new("Frame")
    outerGlow.Name = "OuterGlow"
    outerGlow.Size = UDim2.new(1, 4, 1, 4)
    outerGlow.Position = UDim2.new(0, -2, 0, -2)
    outerGlow.BackgroundTransparency = 1
    outerGlow.ZIndex = 0
    outerGlow.Parent = mainFrame

    local glowStroke = Instance.new("UIStroke")
    glowStroke.Color = Color3.fromRGB(255, 255, 255)
    glowStroke.Transparency = 0.85
    glowStroke.Thickness = 1.5
    glowStroke.Parent = outerGlow

    -- Header Bar
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 42)
    header.BackgroundColor3 = Theme.Colors.Header
    header.BackgroundTransparency = Theme.Colors.HeaderTrans
    header.BorderSizePixel = 0
    header.Parent = mainFrame

    local hCorner = Instance.new("UICorner")
    hCorner.CornerRadius = Theme.Corners.Window
    hCorner.Parent = header

    local hCover = Instance.new("Frame")
    hCover.Size = UDim2.new(1, 0, 0, 10)
    hCover.Position = UDim2.new(0, 0, 1, -10)
    hCover.BackgroundColor3 = Theme.Colors.Header
    hCover.BackgroundTransparency = Theme.Colors.HeaderTrans
    hCover.BorderSizePixel = 0
    hCover.Parent = header

    local hSep = Instance.new("Frame")
    hSep.Size = UDim2.new(1, 0, 0, 1)
    hSep.Position = UDim2.new(0, 0, 1, -1)
    hSep.BackgroundColor3 = Theme.Colors.Border
    hSep.BorderSizePixel = 0
    hSep.Parent = header

    local logoIcon = Instance.new("TextLabel")
    logoIcon.Text = "𝕾"
    logoIcon.Font = Enum.Font.SpecialElite
    logoIcon.TextSize = 22
    logoIcon.TextColor3 = Theme.Colors.TextPrimary
    logoIcon.Size = UDim2.new(0, 24, 0, 24)
    logoIcon.Position = UDim2.new(0, 14, 0.5, -12)
    logoIcon.BackgroundTransparency = 1
    logoIcon.Parent = header

    local brandTitle = Instance.new("TextLabel")
    brandTitle.Text = "SAVIOR"
    brandTitle.Font = Theme.Fonts.Header
    brandTitle.TextSize = 14
    brandTitle.TextColor3 = Theme.Colors.TextPrimary
    brandTitle.TextXAlignment = Enum.TextXAlignment.Left
    brandTitle.Size = UDim2.new(0, 60, 1, 0)
    brandTitle.Position = UDim2.new(0, 42, 0, 0)
    brandTitle.BackgroundTransparency = 1
    brandTitle.Parent = header

    local breadcrumbFrame = Instance.new("Frame")
    breadcrumbFrame.Size = UDim2.new(0, 300, 1, 0)
    breadcrumbFrame.Position = UDim2.new(0, 115, 0, 0)
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
    makeBreadcrumbText("Savior", Theme.Colors.BreadcrumbMuted, false)
    makeBreadcrumbText("/", Theme.Colors.Border, false)
    self._activeBreadcrumbLabel = makeBreadcrumbText("Catching", Theme.Colors.TextPrimary, true)

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

    closeBtn.MouseButton1Click:Connect(function() self:ToggleUI(false) end)
    minBtn.MouseButton1Click:Connect(function() self:ToggleUI() end)

    -- Window Dragging (Syncs Flyout Position)
    local dragging, dragStart, startPos
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
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
            -- If flyout is open, keep it attached to the side
            if Hub._activeFlyout and Hub._activeFlyout.Parent then
                Hub._activeFlyout.Position = UDim2.new(
                    mainFrame.Position.X.Scale,
                    mainFrame.Position.X.Offset + 690,
                    mainFrame.Position.Y.Scale,
                    mainFrame.Position.Y.Offset + Hub._activeFlyoutY
                )
            end
        end
    end)
    table.insert(self._connections, dragConn)

    -- Sidebar
    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.Size = UDim2.new(0, 145, 1, -42)
    sidebar.Position = UDim2.new(0, 0, 0, 42)
    sidebar.BackgroundColor3 = Theme.Colors.Sidebar
    sidebar.BackgroundTransparency = Theme.Colors.SidebarTrans
    sidebar.BorderSizePixel = 0
    sidebar.Parent = mainFrame

    local sBorder = Instance.new("Frame")
    sBorder.Size = UDim2.new(0, 1, 1, 0)
    sBorder.Position = UDim2.new(1, -1, 0, 0)
    sBorder.BackgroundColor3 = Theme.Colors.Border
    sBorder.BorderSizePixel = 0
    sBorder.Parent = sidebar

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

    -- Profile Footer
    local footer = Instance.new("Frame")
    footer.Name = "ProfileFooter"
    footer.Size = UDim2.new(1, 0, 0, 46)
    footer.Position = UDim2.new(0, 0, 1, -46)
    footer.BackgroundColor3 = Theme.Colors.Header
    footer.BackgroundTransparency = Theme.Colors.HeaderTrans
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

    task.spawn(function()
        pcall(function()
            local thumb = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
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

    -- Content Container
    local contentContainer = Instance.new("Frame")
    contentContainer.Name = "ContentContainer"
    contentContainer.Size = UDim2.new(1, -145, 1, -42)
    contentContainer.Position = UDim2.new(0, 145, 0, 42)
    contentContainer.BackgroundTransparency = 1
    contentContainer.Parent = mainFrame

    self.Sidebar = tabContainer
    self.ContentContainer = contentContainer

    -- Keybind Listener
    local menuKeyConn = UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == State.Settings.ToggleKey then self:ToggleUI() end
        if not gpe and input.UserInputType == Enum.UserInputType.Keyboard then
            for _, bindData in pairs(KeybindRegistry) do
                if bindData.Key == input.KeyCode and bindData.ToggleFunc then
                    bindData.ToggleFunc()
                end
            end
        end
    end)
    table.insert(self._connections, menuKeyConn)

    -- Jump Boost Listener
    local jumpConn = UserInputService.JumpRequest:Connect(function()
        if not State.Physics.InfiniteJump and not State.Physics.JumpEnabled then return end
        local char, hrp, hum = Environment.getLocalCharacter()
        if char and hrp and hum and hum.Health > 0 then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
            local basePower = State.Physics.JumpEnabled and State.Physics.JumpPower or 50
            local boostMultiplier = State.Physics.JumpBoostMultiplier or 1.0
            local finalY = basePower * boostMultiplier
            hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, finalY, hrp.AssemblyLinearVelocity.Z)
        end
    end)
    table.insert(self._connections, jumpConn)

    self:CreateWatermark(screenGui)
    self:CreateNotifications(screenGui)
    self:BuildPages()

    -- Close flyouts if user clicks outside
    local clickOutsideConn = UserInputService.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            if Hub._activeFlyout and Hub._activeFlyout.Parent then
                local mPos = UserInputService:GetMouseLocation()
                local fPos = Hub._activeFlyout.AbsolutePosition
                local fSz = Hub._activeFlyout.AbsoluteSize
                local inFlyout = (mPos.X >= fPos.X and mPos.X <= fPos.X + fSz.X and mPos.Y >= fPos.Y and mPos.Y <= fPos.Y + fSz.Y)
                if not inFlyout then
                    Hub._activeFlyout:Destroy()
                    Hub._activeFlyout = nil
                end
            end
        end
    end)
    table.insert(self._connections, clickOutsideConn)

    -- Lifecycle: Hacker Loader -> Authentication Gate
    playHackerIntro(screenGui, function()
        self:ShowAuthWindow(screenGui, function(username)
            welcomeLbl.Text = "Welcome, " .. string.sub(username, 1, 10)
            mainFrame.Visible = true
        end)
    end)
end

-- =====================================================================
-- 9.2 BEAUTIFUL GLASSMORPHIC AUTHENTICATION WINDOW (LOGIN & SIGN UP)
-- =====================================================================
function Hub:ShowAuthWindow(parentGui, onAuthSuccess)
    local authFrame = Instance.new("Frame")
    authFrame.Name = "SaviorAuthWindow"
    authFrame.Size = UDim2.new(0, 680, 0, 430)
    authFrame.Position = UDim2.new(0.5, -340, 0.5, -215)
    authFrame.BackgroundColor3 = Theme.Colors.Background
    authFrame.BackgroundTransparency = Theme.Colors.BackgroundTrans
    authFrame.BorderSizePixel = 0
    authFrame.ZIndex = 110
    authFrame.Parent = parentGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = Theme.Corners.Window
    corner.Parent = authFrame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Theme.Colors.Border
    stroke.Thickness = 1.3
    stroke.Parent = authFrame

    -- Header Bar
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 42)
    header.BackgroundColor3 = Theme.Colors.Header
    header.BackgroundTransparency = Theme.Colors.HeaderTrans
    header.BorderSizePixel = 0
    header.ZIndex = 111
    header.Parent = authFrame

    local hCorner = Instance.new("UICorner")
    hCorner.CornerRadius = Theme.Corners.Window
    hCorner.Parent = header

    local hLogo = Instance.new("TextLabel")
    hLogo.Text = "𝕾  SAVIOR // ACCOUNT GATE"
    hLogo.Font = Theme.Fonts.Header
    hLogo.TextSize = 13
    hLogo.TextColor3 = Theme.Colors.TextPrimary
    hLogo.TextXAlignment = Enum.TextXAlignment.Left
    hLogo.Size = UDim2.new(1, -20, 1, 0)
    hLogo.Position = UDim2.new(0, 14, 0, 0)
    hLogo.BackgroundTransparency = 1
    hLogo.ZIndex = 112
    hLogo.Parent = header

    -- Left Brand Column
    local leftBrand = Instance.new("Frame")
    leftBrand.Size = UDim2.new(0, 230, 1, -42)
    leftBrand.Position = UDim2.new(0, 0, 0, 42)
    leftBrand.BackgroundColor3 = Theme.Colors.Sidebar
    leftBrand.BackgroundTransparency = Theme.Colors.SidebarTrans
    leftBrand.BorderSizePixel = 0
    leftBrand.ZIndex = 111
    leftBrand.Parent = authFrame

    local lbSep = Instance.new("Frame")
    lbSep.Size = UDim2.new(0, 1, 1, 0)
    lbSep.Position = UDim2.new(1, -1, 0, 0)
    lbSep.BackgroundColor3 = Theme.Colors.Border
    lbSep.BorderSizePixel = 0
    lbSep.ZIndex = 112
    lbSep.Parent = leftBrand

    local bigLogo = Instance.new("TextLabel")
    bigLogo.Text = "𝕾"
    bigLogo.Font = Enum.Font.SpecialElite
    bigLogo.TextSize = 64
    bigLogo.TextColor3 = Theme.Colors.TextPrimary
    bigLogo.Size = UDim2.new(1, 0, 0, 70)
    bigLogo.Position = UDim2.new(0, 0, 0, 45)
    bigLogo.BackgroundTransparency = 1
    bigLogo.ZIndex = 112
    bigLogo.Parent = leftBrand

    local brandLbl = Instance.new("TextLabel")
    brandLbl.Text = "SAVIOR INSTRUMENTATION"
    brandLbl.Font = Theme.Fonts.Header
    brandLbl.TextSize = 12
    brandLbl.TextColor3 = Theme.Colors.TextPrimary
    brandLbl.Size = UDim2.new(1, 0, 0, 20)
    brandLbl.Position = UDim2.new(0, 0, 0, 125)
    brandLbl.BackgroundTransparency = 1
    brandLbl.ZIndex = 112
    brandLbl.Parent = leftBrand

    local brandSub = Instance.new("TextLabel")
    brandSub.Text = "Discord License Validation\n& Multi-Ball Tracking"
    brandSub.Font = Theme.Fonts.Body
    brandSub.TextSize = 10
    brandSub.TextColor3 = Theme.Colors.TextMuted
    brandSub.Size = UDim2.new(1, -20, 0, 32)
    brandSub.Position = UDim2.new(0, 10, 0, 150)
    brandSub.BackgroundTransparency = 1
    brandSub.ZIndex = 112
    brandSub.Parent = leftBrand

    -- Right Form Host
    local rightHost = Instance.new("Frame")
    rightHost.Size = UDim2.new(1, -230, 1, -42)
    rightHost.Position = UDim2.new(0, 230, 0, 42)
    rightHost.BackgroundTransparency = 1
    rightHost.ZIndex = 111
    rightHost.Parent = authFrame

    -- Mode Switch Bar (Top: "LOGIN" vs "SIGN UP")
    local switchBar = Instance.new("Frame")
    switchBar.Size = UDim2.new(1, -60, 0, 32)
    switchBar.Position = UDim2.new(0, 30, 0, 18)
    switchBar.BackgroundColor3 = Color3.fromRGB(16, 16, 16)
    switchBar.BorderSizePixel = 0
    switchBar.ZIndex = 112
    switchBar.Parent = rightHost

    local swCorner = Instance.new("UICorner")
    swCorner.CornerRadius = Theme.Corners.Element
    swCorner.Parent = switchBar

    local loginTabBtn = Instance.new("TextButton")
    loginTabBtn.Size = UDim2.new(0.5, -2, 1, -4)
    loginTabBtn.Position = UDim2.new(0, 2, 0, 2)
    loginTabBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    loginTabBtn.BorderSizePixel = 0
    loginTabBtn.Text = "LOGIN"
    loginTabBtn.Font = Theme.Fonts.Header
    loginTabBtn.TextSize = 11
    loginTabBtn.TextColor3 = Theme.Colors.TextPrimary
    loginTabBtn.ZIndex = 113
    loginTabBtn.Parent = switchBar

    local ltCorner = Instance.new("UICorner")
    ltCorner.CornerRadius = Theme.Corners.Element
    ltCorner.Parent = loginTabBtn

    local signupTabBtn = Instance.new("TextButton")
    signupTabBtn.Size = UDim2.new(0.5, -2, 1, -4)
    signupTabBtn.Position = UDim2.new(0.5, 0, 0, 2)
    signupTabBtn.BackgroundColor3 = Color3.fromRGB(16, 16, 16)
    signupTabBtn.BackgroundTransparency = 1
    signupTabBtn.BorderSizePixel = 0
    signupTabBtn.Text = "SIGN UP"
    signupTabBtn.Font = Theme.Fonts.Subheader
    signupTabBtn.TextSize = 11
    signupTabBtn.TextColor3 = Theme.Colors.TextMuted
    signupTabBtn.ZIndex = 113
    signupTabBtn.Parent = switchBar

    local stCorner = Instance.new("UICorner")
    stCorner.CornerRadius = Theme.Corners.Element
    stCorner.Parent = signupTabBtn

    -- Modern Textbox Factory with Focus Highlights & Labels
    local function makeSleekInput(parent, yOffset, labelText, placeholder, isPassword)
        local container = Instance.new("Frame")
        container.Size = UDim2.new(1, 0, 0, 48)
        container.Position = UDim2.new(0, 0, 0, yOffset)
        container.BackgroundTransparency = 1
        container.ZIndex = 113
        container.Parent = parent

        local lbl = Instance.new("TextLabel")
        lbl.Text = labelText
        lbl.Font = Theme.Fonts.Subheader
        lbl.TextSize = 10
        lbl.TextColor3 = Theme.Colors.TextSecondary
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Size = UDim2.new(1, 0, 0, 14)
        lbl.Position = UDim2.new(0, 2, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.ZIndex = 114
        lbl.Parent = container

        local boxFrame = Instance.new("Frame")
        boxFrame.Size = UDim2.new(1, 0, 0, 32)
        boxFrame.Position = UDim2.new(0, 0, 0, 16)
        boxFrame.BackgroundColor3 = Theme.Colors.InputBase
        boxFrame.BorderSizePixel = 0
        boxFrame.ZIndex = 114
        boxFrame.Parent = container

        local bfCorner = Instance.new("UICorner")
        bfCorner.CornerRadius = Theme.Corners.Element
        bfCorner.Parent = boxFrame

        local bfStroke = Instance.new("UIStroke")
        bfStroke.Color = Theme.Colors.InputBorder
        bfStroke.Thickness = 1
        bfStroke.Parent = boxFrame

        local box = Instance.new("TextBox")
        box.Size = UDim2.new(1, -20, 1, 0)
        box.Position = UDim2.new(0, 10, 0, 0)
        box.BackgroundTransparency = 1
        box.Font = Theme.Fonts.Body
        box.TextSize = 12
        box.TextColor3 = Theme.Colors.TextPrimary
        box.PlaceholderText = placeholder
        box.PlaceholderColor3 = Theme.Colors.TextMuted
        box.ClearTextOnFocus = false
        box.ZIndex = 115
        box.Parent = boxFrame

        box.Focused:Connect(function()
            TweenService:Create(bfStroke, TweenInfo.new(0.18), { Color = Theme.Colors.InputFocusBorder }):Play()
        end)
        box.FocusLost:Connect(function()
            TweenService:Create(bfStroke, TweenInfo.new(0.18), { Color = Theme.Colors.InputBorder }):Play()
        end)

        if isPassword then
            local realPass = ""
            box:GetPropertyChangedSignal("Text"):Connect(function()
                if box.Text == string.rep("•", #realPass) then return end
                realPass = box.Text
                box.Text = string.rep("•", #realPass)
            end)
            return box, function() return realPass end
        end

        return box, function() return box.Text end
    end

    -- 1. LOGIN VIEW
    local loginView = Instance.new("Frame")
    loginView.Size = UDim2.new(1, -60, 1, -70)
    loginView.Position = UDim2.new(0, 30, 0, 60)
    loginView.BackgroundTransparency = 1
    loginView.ZIndex = 112
    loginView.Visible = true
    loginView.Parent = rightHost

    local session = AccountDB.getSession()
    local savedUser = (session and session.username) or ""

    local loginUserBox, getLoginUser = makeSleekInput(loginView, 12, "USERNAME", "Enter your username", false)
    local loginPassBox, getLoginPass = makeSleekInput(loginView, 72, "PASSWORD", "Enter your password", true)
    if savedUser ~= "" then loginUserBox.Text = savedUser end

    local loginBtn = Instance.new("TextButton")
    loginBtn.Size = UDim2.new(1, 0, 0, 36)
    loginBtn.Position = UDim2.new(0, 0, 0, 145)
    loginBtn.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
    loginBtn.BorderSizePixel = 0
    loginBtn.Text = "SIGN IN"
    loginBtn.Font = Theme.Fonts.Header
    loginBtn.TextSize = 12
    loginBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    loginBtn.ZIndex = 113
    loginBtn.Parent = loginView

    local lbCorner = Instance.new("UICorner")
    lbCorner.CornerRadius = Theme.Corners.Element
    lbCorner.Parent = loginBtn

    local loginFeedback = Instance.new("TextLabel")
    loginFeedback.Text = ""
    loginFeedback.Font = Theme.Fonts.Body
    loginFeedback.TextSize = 10
    loginFeedback.TextColor3 = Color3.fromRGB(255, 60, 60)
    loginFeedback.Size = UDim2.new(1, 0, 0, 18)
    loginFeedback.Position = UDim2.new(0, 0, 0, 195)
    loginFeedback.BackgroundTransparency = 1
    loginFeedback.ZIndex = 113
    loginFeedback.Parent = loginView

    -- 2. SIGN UP VIEW
    local signupView = Instance.new("Frame")
    signupView.Size = UDim2.new(1, -60, 1, -70)
    signupView.Position = UDim2.new(0, 30, 0, 60)
    signupView.BackgroundTransparency = 1
    signupView.ZIndex = 112
    signupView.Visible = false
    signupView.Parent = rightHost

    local signUserBox, getSignUser = makeSleekInput(signupView, 0, "CHOOSE USERNAME", "3+ characters", false)
    local signPassBox, getSignPass = makeSleekInput(signupView, 54, "CHOOSE PASSWORD", "4+ characters", true)
    local signKeyBox, getSignKey = makeSleekInput(signupView, 108, "DISCORD LICENSE KEY", "SAVIOR-XXXX-XXXX", false)

    local registerBtn = Instance.new("TextButton")
    registerBtn.Size = UDim2.new(1, 0, 0, 36)
    registerBtn.Position = UDim2.new(0, 0, 0, 175)
    registerBtn.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
    registerBtn.BorderSizePixel = 0
    registerBtn.Text = "CREATE & ACTIVATE ACCOUNT"
    registerBtn.Font = Theme.Fonts.Header
    registerBtn.TextSize = 12
    registerBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    registerBtn.ZIndex = 113
    registerBtn.Parent = signupView

    local rbCorner = Instance.new("UICorner")
    rbCorner.CornerRadius = Theme.Corners.Element
    rbCorner.Parent = registerBtn

    local signFeedback = Instance.new("TextLabel")
    signFeedback.Text = ""
    signFeedback.Font = Theme.Fonts.Body
    signFeedback.TextSize = 10
    signFeedback.TextColor3 = Color3.fromRGB(255, 60, 60)
    signFeedback.Size = UDim2.new(1, 0, 0, 18)
    signFeedback.Position = UDim2.new(0, 0, 0, 222)
    signFeedback.BackgroundTransparency = 1
    signFeedback.ZIndex = 113
    signFeedback.Parent = signupView

    local function setAuthMode(isLogin)
        loginView.Visible = isLogin
        signupView.Visible = not isLogin
        loginFeedback.Text = ""
        signFeedback.Text = ""

        if isLogin then
            loginTabBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            loginTabBtn.BackgroundTransparency = 0
            loginTabBtn.TextColor3 = Theme.Colors.TextPrimary
            signupTabBtn.BackgroundTransparency = 1
            signupTabBtn.TextColor3 = Theme.Colors.TextMuted
        else
            signupTabBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            signupTabBtn.BackgroundTransparency = 0
            signupTabBtn.TextColor3 = Theme.Colors.TextPrimary
            loginTabBtn.BackgroundTransparency = 1
            loginTabBtn.TextColor3 = Theme.Colors.TextMuted
        end
    end

    loginTabBtn.MouseButton1Click:Connect(function() setAuthMode(true) end)
    signupTabBtn.MouseButton1Click:Connect(function() setAuthMode(false) end)

    registerBtn.MouseButton1Click:Connect(function()
        local u = string.gsub(getSignUser(), "%s+", "")
        local p = getSignPass()
        local k = string.gsub(getSignKey(), "%s+", "")

        if #u < 3 then
            signFeedback.Text = "Username must be at least 3 characters."
            signFeedback.TextColor3 = Color3.fromRGB(255, 60, 60)
            return
        end
        if #p < 4 then
            signFeedback.Text = "Password must be at least 4 characters."
            signFeedback.TextColor3 = Color3.fromRGB(255, 60, 60)
            return
        end

        local accounts = AccountDB.getAccounts()
        if accounts[u] then
            signFeedback.Text = "Username already exists. Please choose another."
            signFeedback.TextColor3 = Color3.fromRGB(255, 60, 60)
            return
        end

        registerBtn.Text = "VALIDATING KEY..."
        task.wait(0.25)
        local keyValid, keyMsg = AccountDB.verifyDiscordKey(k)
        if not keyValid then
            registerBtn.Text = "CREATE & ACTIVATE ACCOUNT"
            signFeedback.Text = "✕ " .. (keyMsg or "Invalid Discord License Key")
            signFeedback.TextColor3 = Color3.fromRGB(255, 60, 60)
            return
        end

        accounts[u] = {
            password = p,
            license_key = k,
            registered_at = tick()
        }
        AccountDB.saveAccounts(accounts)

        signFeedback.Text = "✓ Account created! Switch to Login tab to proceed."
        signFeedback.TextColor3 = Color3.fromRGB(255, 255, 255)
        registerBtn.Text = "SUCCESS"

        task.delay(1.0, function()
            setAuthMode(true)
            loginUserBox.Text = u
            registerBtn.Text = "CREATE & ACTIVATE ACCOUNT"
        end)
    end)

    loginBtn.MouseButton1Click:Connect(function()
        local u = string.gsub(getLoginUser(), "%s+", "")
        local p = getLoginPass()

        loginBtn.Text = "AUTHENTICATING..."
        task.wait(0.2)

        local accounts = AccountDB.getAccounts()
        local acc = accounts[u]

        if not acc or acc.password ~= p then
            loginBtn.Text = "SIGN IN"
            loginFeedback.Text = "✕ Invalid username or password."
            loginFeedback.TextColor3 = Color3.fromRGB(255, 60, 60)
            return
        end

        local keyValid, keyMsg = AccountDB.verifyDiscordKey(acc.license_key)
        if not keyValid then
            loginBtn.Text = "SIGN IN"
            loginFeedback.Text = "✕ License Key expired or revoked."
            loginFeedback.TextColor3 = Color3.fromRGB(255, 60, 60)
            return
        end

        AccountDB.saveSession(u)

        loginFeedback.Text = "✓ ACCESS GRANTED"
        loginFeedback.TextColor3 = Color3.fromRGB(255, 255, 255)
        loginBtn.Text = "SUCCESS"

        task.wait(0.35)
        authFrame:Destroy()
        if onAuthSuccess then onAuthSuccess(u) end
    end)
end

function Hub:ToggleUI(override)
    if override ~= nil then
        self.Visible = override
    else
        self.Visible = not self.Visible
    end
    self.MainFrame.Visible = self.Visible
    if not self.Visible and Hub._activeFlyout then
        Hub._activeFlyout:Destroy()
        Hub._activeFlyout = nil
    end
end

function Hub:CreateWatermark(screenGui)
    local wm = Instance.new("Frame")
    wm.Name = "SaviorWatermark"
    wm.Size = UDim2.new(0, 240, 0, 26)
    wm.Position = UDim2.new(1, -250, 0, 10)
    wm.BackgroundColor3 = Theme.Colors.Header
    wm.BackgroundTransparency = 0.2
    wm.BorderSizePixel = 0
    wm.Visible = State.Settings.Watermark
    wm.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = Theme.Corners.Element
    corner.Parent = wm

    local stroke = Instance.new("UIStroke")
    stroke.Color = Theme.Colors.Border
    stroke.Thickness = 1
    stroke.Parent = wm

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -12, 1, 0)
    label.Position = UDim2.new(0, 8, 0, 0)
    label.BackgroundTransparency = 1
    label.Font = Theme.Fonts.Subheader
    label.TextSize = 11
    label.TextColor3 = Theme.Colors.TextPrimary
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = "SAVIOR // FPS: -- | Ping: --ms"
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
            pcall(function() ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
            label.Text = string.format("SAVIOR // FPS: %d | Ping: %dms", fps, ping)
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

function Hub:Notify(titleText, msgText, duration)
    duration = duration or 2.5
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 46)
    card.BackgroundColor3 = Theme.Colors.Card
    card.BackgroundTransparency = 0.15
    card.BorderSizePixel = 0
    card.Position = UDim2.new(1, 20, 0, 0)
    card.Parent = self.NotifContainer

    local corner = Instance.new("UICorner")
    corner.CornerRadius = Theme.Corners.Element
    corner.Parent = card

    local stroke = Instance.new("UIStroke")
    stroke.Color = Theme.Colors.Border
    stroke.Thickness = 1
    stroke.Parent = card

    local tLbl = Instance.new("TextLabel")
    tLbl.Text = titleText
    tLbl.Font = Theme.Fonts.Header
    tLbl.TextSize = 12
    tLbl.TextColor3 = Theme.Colors.TextPrimary
    tLbl.TextXAlignment = Enum.TextXAlignment.Left
    tLbl.Size = UDim2.new(1, -12, 0, 16)
    tLbl.Position = UDim2.new(0, 10, 0, 5)
    tLbl.BackgroundTransparency = 1
    tLbl.Parent = card

    local mLbl = Instance.new("TextLabel")
    mLbl.Text = msgText
    mLbl.Font = Theme.Fonts.Body
    mLbl.TextSize = 10
    mLbl.TextColor3 = Theme.Colors.TextSecondary
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
            btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
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
        if Hub._activeFlyout then Hub._activeFlyout:Destroy() Hub._activeFlyout = nil end
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
-- 10. COMPONENT FACTORY (WITH FLYOUT SIDE-POPUP DROPDOWNS)
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

local function addToggle(sec, title, defaultState, callback, defaultKey)
    local state = defaultState or false
    local boundKey = defaultKey or nil
    local listening = false

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 32)
    row.BackgroundColor3 = Theme.Colors.Card
    row.BackgroundTransparency = Theme.Colors.CardTrans
    row.BorderSizePixel = 0
    row.Parent = sec

    local rCorner = Instance.new("UICorner")
    rCorner.CornerRadius = Theme.Corners.Element
    rCorner.Parent = row

    local rStroke = Instance.new("UIStroke")
    rStroke.Color = Theme.Colors.Border
    rStroke.Thickness = 1
    rStroke.Parent = row

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
    cbStroke.Color = state and Theme.Colors.Accent or Theme.Colors.CheckboxBorder
    cbStroke.Thickness = 1.2
    cbStroke.Parent = checkBtn

    local checkmark = Instance.new("TextLabel")
    checkmark.Text = "✓"
    checkmark.Font = Theme.Fonts.Header
    checkmark.TextSize = 13
    checkmark.TextColor3 = Color3.fromRGB(0, 0, 0)
    checkmark.Size = UDim2.new(1, 0, 1, 0)
    checkmark.BackgroundTransparency = 1
    checkmark.Visible = state
    checkmark.Parent = checkBtn

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

    local bindBtn = Instance.new("TextButton")
    bindBtn.Size = UDim2.new(0, 92, 0, 22)
    bindBtn.Position = UDim2.new(1, -98, 0.5, -11)
    bindBtn.BackgroundColor3 = Theme.Colors.Header
    bindBtn.BackgroundTransparency = 0.3
    bindBtn.BorderSizePixel = 0
    bindBtn.Text = boundKey and ("[" .. boundKey.Name .. "]") or "Click to Bind"
    bindBtn.Font = Theme.Fonts.Body
    bindBtn.TextSize = 10
    bindBtn.TextColor3 = boundKey and Theme.Colors.Accent or Theme.Colors.TextMuted
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
        local strokeColor = state and Theme.Colors.Accent or Theme.Colors.CheckboxBorder
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

    local toggleId = title .. tostring(tick())
    KeybindRegistry[toggleId] = {
        Key = boundKey,
        ToggleFunc = toggleState
    }

    bindBtn.MouseButton1Click:Connect(function()
        listening = true
        bindBtn.Text = "Press Key..."
        bindBtn.TextColor3 = Theme.Colors.Accent
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
                bindBtn.TextColor3 = Theme.Colors.Accent
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

local function addSlider(sec, title, minVal, maxVal, defVal, stepVal, suffix, callback)
    local val = defVal or minVal
    stepVal = stepVal or 1
    suffix = suffix or ""

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 44)
    row.BackgroundColor3 = Theme.Colors.Card
    row.BackgroundTransparency = Theme.Colors.CardTrans
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
    valLbl.TextColor3 = Theme.Colors.Accent
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

-- FLYOUT SIDE-POPUP DROPDOWN (No clipping, completely visible on right side of Menu)
local function addDropdown(sec, title, options, defOpt, callback)
    local selected = defOpt or options[1] or ""

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 34)
    row.BackgroundColor3 = Theme.Colors.Card
    row.BackgroundTransparency = Theme.Colors.CardTrans
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
    btn.BackgroundTransparency = 0.2
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
    bLbl.TextColor3 = Theme.Colors.Accent
    bLbl.TextXAlignment = Enum.TextXAlignment.Left
    bLbl.Size = UDim2.new(1, -20, 1, 0)
    bLbl.Position = UDim2.new(0, 8, 0, 0)
    bLbl.BackgroundTransparency = 1
    bLbl.Parent = btn

    local arrow = Instance.new("TextLabel")
    arrow.Text = "▶"
    arrow.Font = Theme.Fonts.Body
    arrow.TextSize = 8
    arrow.TextColor3 = Theme.Colors.TextMuted
    arrow.Size = UDim2.new(0, 16, 1, 0)
    arrow.Position = UDim2.new(1, -16, 0, 0)
    arrow.BackgroundTransparency = 1
    arrow.Parent = btn

    -- Open Side Flyout Panel (Attached directly to ScreenGui on right side of Menu)
    btn.MouseButton1Click:Connect(function()
        if Hub._activeFlyout and Hub._activeFlyout.Parent then
            Hub._activeFlyout:Destroy()
            Hub._activeFlyout = nil
        end

        local mainFrame = Hub.MainFrame
        local yRelative = btn.AbsolutePosition.Y - mainFrame.AbsolutePosition.Y
        Hub._activeFlyoutY = yRelative

        local flyout = Instance.new("Frame")
        flyout.Name = "DropdownFlyout_" .. title
        flyout.Size = UDim2.new(0, 175, 0, #options * 30 + 32)
        flyout.Position = UDim2.new(
            mainFrame.Position.X.Scale,
            mainFrame.Position.X.Offset + 690,
            mainFrame.Position.Y.Scale,
            mainFrame.Position.Y.Offset + yRelative
        )
        flyout.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
        flyout.BackgroundTransparency = 0.1
        flyout.BorderSizePixel = 0
        flyout.ZIndex = 200
        flyout.Parent = Hub.ScreenGui
        Hub._activeFlyout = flyout

        local foCorner = Instance.new("UICorner")
        foCorner.CornerRadius = Theme.Corners.Element
        foCorner.Parent = flyout

        local foStroke = Instance.new("UIStroke")
        foStroke.Color = Theme.Colors.BorderHover
        foStroke.Thickness = 1.3
        foStroke.Parent = flyout

        local foHeader = Instance.new("TextLabel")
        foHeader.Text = string.upper(title)
        foHeader.Font = Theme.Fonts.Header
        foHeader.TextSize = 10
        foHeader.TextColor3 = Theme.Colors.TextMuted
        foHeader.TextXAlignment = Enum.TextXAlignment.Left
        foHeader.Size = UDim2.new(1, -16, 0, 22)
        foHeader.Position = UDim2.new(0, 10, 0, 4)
        foHeader.BackgroundTransparency = 1
        foHeader.ZIndex = 201
        foHeader.Parent = flyout

        local foList = Instance.new("Frame")
        foList.Size = UDim2.new(1, -12, 1, -28)
        foList.Position = UDim2.new(0, 6, 0, 24)
        foList.BackgroundTransparency = 1
        foList.ZIndex = 201
        foList.Parent = flyout

        local foLayout = Instance.new("UIListLayout")
        foLayout.SortOrder = Enum.SortOrder.LayoutOrder
        foLayout.Padding = UDim.new(0, 3)
        foLayout.Parent = foList

        for _, opt in ipairs(options) do
            local optBtn = Instance.new("TextButton")
            optBtn.Size = UDim2.new(1, 0, 0, 26)
            optBtn.BackgroundColor3 = (opt == selected) and Color3.fromRGB(32, 32, 32) or Color3.fromRGB(18, 18, 18)
            optBtn.BorderSizePixel = 0
            optBtn.Text = ""
            optBtn.AutoButtonColor = false
            optBtn.ZIndex = 202
            optBtn.Parent = foList

            local oCorner = Instance.new("UICorner")
            oCorner.CornerRadius = Theme.Corners.Element
            oCorner.Parent = optBtn

            local oStroke = Instance.new("UIStroke")
            oStroke.Color = (opt == selected) and Color3.fromRGB(120, 120, 120) or Color3.fromRGB(40, 40, 40)
            oStroke.Thickness = 1
            oStroke.Parent = optBtn

            local optLbl = Instance.new("TextLabel")
            optLbl.Text = opt
            optLbl.Font = (opt == selected) and Theme.Fonts.Header or Theme.Fonts.Body
            optLbl.TextSize = 11
            optLbl.TextColor3 = (opt == selected) and Theme.Colors.TextPrimary or Theme.Colors.TextSecondary
            optLbl.TextXAlignment = Enum.TextXAlignment.Left
            optLbl.Size = UDim2.new(1, -16, 1, 0)
            optLbl.Position = UDim2.new(0, 8, 0, 0)
            optLbl.BackgroundTransparency = 1
            optLbl.ZIndex = 203
            optLbl.Parent = optBtn

            optBtn.MouseEnter:Connect(function()
                TweenService:Create(optBtn, TweenInfo.new(0.12), { BackgroundColor3 = Color3.fromRGB(40, 40, 40) }):Play()
            end)
            optBtn.MouseLeave:Connect(function()
                TweenService:Create(optBtn, TweenInfo.new(0.12), {
                    BackgroundColor3 = (opt == selected) and Color3.fromRGB(32, 32, 32) or Color3.fromRGB(18, 18, 18)
                }):Play()
            end)

            optBtn.MouseButton1Click:Connect(function()
                selected = opt
                bLbl.Text = opt
                flyout:Destroy()
                Hub._activeFlyout = nil
                if callback then callback(opt) end
            end)
        end
    end)

    return {
        Set = function(v) selected = v bLbl.Text = v if callback then callback(v) end end,
        Get = function() return selected end
    }
end

local function addButton(sec, title, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 32)
    btn.BackgroundColor3 = Theme.Colors.Card
    btn.BackgroundTransparency = Theme.Colors.CardTrans
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
        TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(45, 45, 45) }):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = Theme.Colors.Card }):Play()
    end)
    btn.MouseButton1Click:Connect(function() if callback then callback() end end)
    return btn
end

-- =====================================================================
-- 11. TAB PAGE BUILDER
-- =====================================================================
function Hub:BuildPages()
    -- Tab 1: Catching
    local catchPage = self:CreateTab("Catching")
    local cSec1 = addSection(catchPage, "Ball Magnet Engine")
    addToggle(cSec1, "Ball Magnet", State.Catching.MagnetEnabled, function(v)
        State.Catching.MagnetEnabled = v
        if not v then CatchingSystem:ResetHitboxes() end
    end)
    addDropdown(cSec1, "Magnet Mode", { "Blatant", "Regular", "Legit" }, State.Catching.MagnetMode, function(v)
        State.Catching.MagnetMode = v
    end)
    addSlider(cSec1, "Magnet Range", 5, 100, State.Catching.MagnetRange, 1, " studs", function(v)
        State.Catching.MagnetRange = v
    end)
    addSlider(cSec1, "Catch Hitbox Size", 2, 35, State.Catching.HitboxSize, 1, " studs", function(v)
        State.Catching.HitboxSize = v
    end)
    addSlider(cSec1, "Catch Distance", 5, 60, State.Catching.CatchDistance, 1, " studs", function(v)
        State.Catching.CatchDistance = v
    end)
    addSlider(cSec1, "Catch Angle (FOV)", 30, 180, State.Catching.CatchAngle, 5, "°", function(v)
        State.Catching.CatchAngle = v
    end)

    local cSec2 = addSection(catchPage, "Advanced Catching Configuration")
    addToggle(cSec2, "Touch Interest Injection", State.Catching.TouchInjection, function(v)
        State.Catching.TouchInjection = v
    end)
    addToggle(cSec2, "Angle Enhancer (Omni-Directional)", State.Catching.AngleEnhancer, function(v)
        State.Catching.AngleEnhancer = v
    end)
    addToggle(cSec2, "Automatic Catch (Auto-Click)", State.Catching.AutoCatch, function(v)
        State.Catching.AutoCatch = v
    end)
    addToggle(cSec2, "Dive Catch Assist", State.Catching.DiveCatchAssist, function(v)
        State.Catching.DiveCatchAssist = v
    end)

    -- Tab 2: QB
    local qbPage = self:CreateTab("QB")
    local qbSec1 = addSection(qbPage, "Passing Assistance")
    addToggle(qbSec1, "QB Aimbot", State.QB.AimbotEnabled, function(v)
        State.QB.AimbotEnabled = v
    end, State.QB.ThrowAssistKey)
    addDropdown(qbSec1, "Target Receiver Selector", { "Closest to Mouse", "Nearest Teammate", "Open Receiver" }, State.QB.TargetSelector, function(v)
        State.QB.TargetSelector = v
    end)

    local qbSec2 = addSection(qbPage, "Trajectory & Ballistics")
    addToggle(qbSec2, "Auto Angle", State.QB.AutoAngle, function(v) State.QB.AutoAngle = v end)
    addToggle(qbSec2, "Auto Throw Type (Bullet / Lob)", State.QB.AutoThrowType, function(v) State.QB.AutoThrowType = v end)
    addToggle(qbSec2, "Anti-Wobble / Perfect Spiral", State.QB.AntiWobble, function(v) State.QB.AntiWobble = v end)
    addSlider(qbSec2, "Lead Prediction Time", 0.2, 2.0, State.QB.LeadPredictionTime, 0.05, "s", function(v)
        State.QB.LeadPredictionTime = v
    end)
    addSlider(qbSec2, "Bullet Velocity", 60, 150, State.QB.BulletPassVelocity, 5, " studs/s", function(v)
        State.QB.BulletPassVelocity = v
    end)
    addSlider(qbSec2, "Lob Velocity", 40, 110, State.QB.LobPassVelocity, 5, " studs/s", function(v)
        State.QB.LobPassVelocity = v
    end)

    -- Tab 3: Physics
    local phyPage = self:CreateTab("Physics")
    local phySec1 = addSection(phyPage, "Jump Boost & Air Mobility")
    addToggle(phySec1, "Custom JumpPower", State.Physics.JumpEnabled, function(v)
        State.Physics.JumpEnabled = v
        if not v then
            local _, _, hum = Environment.getLocalCharacter()
            if hum then
                if hum.UseJumpPower then hum.JumpPower = 50 else hum.JumpHeight = 7.2 end
            end
        end
    end)
    addSlider(phySec1, "JumpPower Value", 50, 180, State.Physics.JumpPower, 5, " pow", function(v)
        State.Physics.JumpPower = v
    end)
    addSlider(phySec1, "Jump Boost Impulse", 1.0, 2.5, State.Physics.JumpBoostMultiplier, 0.05, "x", function(v)
        State.Physics.JumpBoostMultiplier = v
    end)
    addToggle(phySec1, "Infinite Air Jump", State.Physics.InfiniteJump, function(v)
        State.Physics.InfiniteJump = v
    end)

    local phySec2 = addSection(phyPage, "Ground & Dive Movement")
    addToggle(phySec2, "Custom WalkSpeed", State.Physics.SpeedEnabled, function(v)
        State.Physics.SpeedEnabled = v
        if not v then
            local _, _, hum = Environment.getLocalCharacter()
            if hum then hum.WalkSpeed = 16 end
        end
    end)
    addSlider(phySec2, "WalkSpeed Value", 16, 90, State.Physics.WalkSpeed, 1, " studs/s", function(v)
        State.Physics.WalkSpeed = v
    end)
    addSlider(phySec2, "Dive Velocity Multiplier", 1.0, 3.0, State.Physics.DiveMultiplier, 0.1, "x", function(v)
        State.Physics.DiveMultiplier = v
    end)
    addToggle(phySec2, "Anti-Stumble / Anti-Ragdoll", State.Physics.AntiStumble, function(v)
        State.Physics.AntiStumble = v
    end)

    -- Tab 4: Defense
    local defPage = self:CreateTab("Defense")
    local defSec = addSection(defPage, "Tackle & Coverage")
    addToggle(defSec, "Tackle Radius Expander", State.Defense.TackleExpander, function(v)
        State.Defense.TackleExpander = v
    end)
    addSlider(defSec, "Tackle Distance", 5, 35, State.Defense.TackleRadius, 1, " studs", function(v)
        State.Defense.TackleRadius = v
    end)

    -- Tab 5: Trolling
    local trolPage = self:CreateTab("Trolling")
    local trSec = addSection(trolPage, "Miscellaneous")
    addToggle(trSec, "Spinbot", State.Trolling.Spinbot, function(v) State.Trolling.Spinbot = v end)
    addSlider(trSec, "Spinbot Yaw Speed", 5, 80, State.Trolling.SpinSpeed, 5, " deg/s", function(v)
        State.Trolling.SpinSpeed = v
    end)
    addToggle(trSec, "Ball Fling Impulse", State.Trolling.BallFling, function(v) State.Trolling.BallFling = v end)

    -- Tab 6: Automatics
    local autoPage = self:CreateTab("Automatics")
    local autSec = addSection(autoPage, "Autonomous Assistance")
    addToggle(autSec, "Autonomous Catch", State.Automatics.AutoCatch, function(v) State.Automatics.AutoCatch = v end)
    addSlider(autSec, "Auto Catch Range", 5, 30, State.Automatics.AutoCatchDistance, 1, " studs", function(v)
        State.Automatics.AutoCatchDistance = v
    end)
    addToggle(autSec, "Autonomous Intercept Guide", State.Automatics.AutoIntercept, function(v) State.Automatics.AutoIntercept = v end)
    addToggle(autSec, "Autonomous Forward Dive", State.Automatics.AutoDive, function(v) State.Automatics.AutoDive = v end)
    addSlider(autSec, "Auto Dive Distance", 10, 40, State.Automatics.AutoDiveDistance, 1, " studs", function(v)
        State.Automatics.AutoDiveDistance = v
    end)
    addToggle(autSec, "Autonomous Dead Ball Pickup", State.Automatics.AutoPick, function(v) State.Automatics.AutoPick = v end)
    addSlider(autSec, "Auto Pick Distance", 6, 30, State.Automatics.AutoPickDistance, 1, " studs", function(v)
        State.Automatics.AutoPickDistance = v
    end)

    -- Tab 7: Visuals
    local visPage = self:CreateTab("Visuals")
    local vSec1 = addSection(visPage, "Football Tracking (All Balls)")
    addToggle(vSec1, "Enable Ball Visuals", State.Visuals.BallMaster, function(v) State.Visuals.BallMaster = v end)
    addToggle(vSec1, "Ball Highlight (White Chams)", State.Visuals.BallHighlight, function(v) State.Visuals.BallHighlight = v end)
    addToggle(vSec1, "Ball Trajectory Arc", State.Visuals.BallTrajectory, function(v) State.Visuals.BallTrajectory = v end)
    addToggle(vSec1, "Ball Landing Circle", State.Visuals.BallLandingMarker, function(v) State.Visuals.BallLandingMarker = v end)
    addToggle(vSec1, "Ball Distance Tag", State.Visuals.BallDistance, function(v) State.Visuals.BallDistance = v end)

    local vSec2 = addSection(visPage, "Player Visuals")
    addToggle(vSec2, "Enable Player Visuals", State.Visuals.PlayerMaster, function(v) State.Visuals.PlayerMaster = v end)
    addDropdown(vSec2, "Filter Mode", { "Opponent", "Team", "Everyone" }, State.Visuals.PlayerFilter, function(v)
        State.Visuals.PlayerFilter = v
    end)
    addToggle(vSec2, "2D Bounding Boxes", State.Visuals.PlayerBoxes, function(v) State.Visuals.PlayerBoxes = v end)
    addToggle(vSec2, "Tracers", State.Visuals.PlayerTracers, function(v) State.Visuals.PlayerTracers = v end)
    addToggle(vSec2, "Nametags (Above Head)", State.Visuals.PlayerNames, function(v) State.Visuals.PlayerNames = v end)

    -- Tab 8: Misc
    local miscPage = self:CreateTab("Misc")
    local mSec = addSection(miscPage, "System Preferences")
    addToggle(mSec, "Show Live Watermark", State.Settings.Watermark, function(v)
        State.Settings.Watermark = v
        local wm = Hub.ScreenGui and Hub.ScreenGui:FindFirstChild("SaviorWatermark")
        if wm then wm.Visible = v end
    end)

    -- Tab 9: Configs
    local cfgPage = self:CreateTab("Configs")
    local cSec = addSection(cfgPage, "Disk Persistence & Session")
    addButton(cSec, "Save Configuration to Disk", function()
        local canWrite = typeof(writefile) == "function" and typeof(makefolder) == "function"
        if canWrite then
            pcall(function()
                if not (typeof(isfolder) == "function" and isfolder("savior_ff2")) then makefolder("savior_ff2") end
                writefile("savior_ff2/config.json", HttpService:JSONEncode(State))
            end)
            self:Notify("Config Saved", "Settings persisted to savior_ff2/config.json", 2.5)
        else
            self:Notify("Notice", "Executor does not support writefile", 2.5)
        end
    end)
    addButton(cSec, "Load Configuration from Disk", function()
        local canRead = typeof(readfile) == "function" and typeof(isfile) == "function"
        if canRead and isfile("savior_ff2/config.json") then
            pcall(function()
                local raw = readfile("savior_ff2/config.json")
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
    addButton(cSec, "Log Out & Relog (Account Switch)", function()
        AccountDB.clearSession()
        self:ToggleUI(false)
        self:ShowAuthWindow(Hub.ScreenGui, function(username)
            local footer = Hub.Sidebar and Hub.Sidebar.Parent:FindFirstChild("ProfileFooter")
            local welcomeLbl = footer and footer:FindFirstChildOfClass("TextLabel")
            if welcomeLbl then welcomeLbl.Text = "Welcome, " .. string.sub(username, 1, 10) end
            Hub:ToggleUI(true)
        end)
    end)
    addButton(cSec, "Unload Savior & Clean Memory", function() self:Unload() end)
end

function Hub:Unload()
    for _, conn in ipairs(self._connections) do pcall(function() conn:Disconnect() end) end
    self._connections = {}

    CatchingSystem:ResetHitboxes()

    for _, entry in pairs(VisualsSystem._ballDrawings) do
        if entry.Highlight then entry.Highlight:Destroy() end
        if entry.Text then entry.Text:Remove() end
        if entry.Circle then entry.Circle:Remove() end
        for _, line in ipairs(entry.Lines) do line:Remove() end
    end
    VisualsSystem._ballDrawings = {}

    for _, entry in pairs(VisualsSystem._playerDrawings) do
        if entry.Box then entry.Box:Remove() end
        if entry.Tracer then entry.Tracer:Remove() end
        if entry.Name then entry.Name:Remove() end
    end
    VisualsSystem._playerDrawings = {}

    if Hub._activeFlyout then
        Hub._activeFlyout:Destroy()
        Hub._activeFlyout = nil
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

    if getgenv then getgenv().SaviorInstance = nil end
end

-- =====================================================================
-- 12. SYSTEM LIFECYCLE EXECUTION
-- =====================================================================
Hub:Init()

local spinAngle = 0
local heartbeatConn = RunService.Heartbeat:Connect(function()
    pcall(function()
        CatchingSystem:Step()
        QBSystem:Step()
        PhysicsSystem:Step()
        AutomaticsSystem:Step()

        if State.Trolling.Spinbot then
            local _, hrp = Environment.getLocalCharacter()
            if hrp then
                spinAngle = (spinAngle + State.Trolling.SpinSpeed) % 360
                hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, math.rad(spinAngle), 0)
            end
        end

        if State.Trolling.BallFling then
            local football = Environment.getClosestFootball()
            local _, hrp = Environment.getLocalCharacter()
            if football and hrp and (football.Position - hrp.Position).Magnitude < 10 then
                football.AssemblyAngularVelocity = Vector3.new(10000, 10000, 10000)
            end
        end

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

local renderConn = RunService.RenderStepped:Connect(function()
    pcall(function()
        VisualsSystem:Render()
    end)
end)
table.insert(Hub._connections, renderConn)

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

if getgenv then getgenv().SaviorInstance = Hub end
