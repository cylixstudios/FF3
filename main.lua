--[[
    ====================================================================
    VORTEX FREE — FOOTBALL FUSION 2 SCRIPT HUB
    Loadstring-ready single-file distribution.
    Features: Advanced Ball Mechanics, Magnet, Trajectory Prediction,
              Visual Overlays, Automatics Engine, Physics Modifiers.
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
if getgenv and getgenv().VortexFreeInstance then
    pcall(function()
        getgenv().VortexFreeInstance:Unload()
    end)
end

-- =====================================================================
-- 1. THEME & STYLING TOKENS
-- =====================================================================
local Theme = {
    Colors = {
        Background = Color3.fromRGB(11, 14, 23),
        Panel = Color3.fromRGB(17, 22, 37),
        PanelHover = Color3.fromRGB(24, 31, 51),
        PanelBorder = Color3.fromRGB(30, 41, 59),
        Header = Color3.fromRGB(14, 18, 30),
        Sidebar = Color3.fromRGB(13, 17, 28),

        Accent = Color3.fromRGB(0, 180, 216),
        AccentDark = Color3.fromRGB(0, 119, 182),
        AccentNeon = Color3.fromRGB(0, 240, 255),

        TextPrimary = Color3.fromRGB(226, 232, 240),
        TextSecondary = Color3.fromRGB(148, 163, 184),
        TextMuted = Color3.fromRGB(100, 116, 139),

        ToggleOff = Color3.fromRGB(30, 41, 59),
        ToggleOn = Color3.fromRGB(0, 180, 216),
        SliderTrack = Color3.fromRGB(25, 33, 52),
        SliderThumb = Color3.fromRGB(0, 240, 255),

        Success = Color3.fromRGB(34, 197, 94),
        Warning = Color3.fromRGB(234, 179, 8),
        Error = Color3.fromRGB(239, 68, 68),

        Teammate = Color3.fromRGB(0, 240, 255),
        Opponent = Color3.fromRGB(255, 75, 75)
    },
    Fonts = {
        Header = Enum.Font.GothamBold,
        Subheader = Enum.Font.GothamMedium,
        Body = Enum.Font.Gotham,
        Badge = Enum.Font.GothamBlack
    },
    Corners = {
        Window = UDim.new(0, 10),
        Card = UDim.new(0, 8),
        Element = UDim.new(0, 6),
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
-- 2. ENVIRONMENT & BALL RESOLUTION
-- =====================================================================
local Environment = {}

function Environment.getLocalCharacter()
    local char = LocalPlayer.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not (hrp and hum and hum.Health > 0) then return nil end
    return char, hrp, hum
end

function Environment.getCatchParts(char)
    if not char then return {} end
    local parts = {}
    local limbNames = {
        "CatchHitbox", "CatchPart",
        "Right Arm", "Left Arm",
        "RightHand", "LeftHand",
        "RightLowerArm", "LeftLowerArm",
        "HumanoidRootPart"
    }
    for _, name in ipairs(limbNames) do
        local part = char:FindFirstChild(name)
        if part and part:IsA("BasePart") then
            table.insert(parts, part)
        end
    end
    return parts
end

function Environment.getFootball()
    local direct = Workspace:FindFirstChild("Football")
    if direct and direct:IsA("BasePart") then
        return direct
    end
    for _, child in ipairs(Workspace:GetChildren()) do
        if child.Name == "Football" then
            if child:IsA("BasePart") then
                return child
            elseif child:IsA("Model") then
                local p = child:FindFirstChild("Handle") or child.PrimaryPart or child:FindFirstChildOfClass("BasePart")
                if p then return p end
            end
        end
    end
    for _, child in ipairs(Workspace:GetDescendants()) do
        if (child.Name == "Football" or child.Name == "Ball") and child:IsA("BasePart") then
            if child.Parent == Workspace or not child:IsDescendantOf(LocalPlayer.Character or Workspace) then
                return child
            end
        end
    end
    return nil
end

function Environment.isBallLive(football)
    if not (football and football:IsA("BasePart")) then return false end
    if football.Parent and football.Parent:FindFirstChildOfClass("Humanoid") then
        return false
    end
    for _, child in ipairs(football:GetChildren()) do
        if child:IsA("Weld") or child:IsA("Motor6D") or child:IsA("WeldConstraint") then
            local p0, p1 = child.Part0, child.Part1
            if (p0 and p0.Parent:FindFirstChildOfClass("Humanoid")) or (p1 and p1.Parent:FindFirstChildOfClass("Humanoid")) then
                return false
            end
        end
    end
    return football.AssemblyLinearVelocity.Magnitude > 3.0
end

function Environment.isOpponent(player)
    if not player or player == LocalPlayer then return false end
    if LocalPlayer.Team and player.Team then
        return LocalPlayer.Team ~= player.Team
    end
    if LocalPlayer.TeamColor and player.TeamColor then
        return LocalPlayer.TeamColor ~= player.TeamColor
    end
    return true
end

-- =====================================================================
-- 3. DRAWING PRIMITIVE WRAPPER
-- =====================================================================
local hasDrawing = typeof(Drawing) == "table" and typeof(Drawing.new) == "function"

local function createDrawingContainer()
    local container = { objects = {} }

    function container:AddLine(props)
        if not hasDrawing then return nil end
        local line = Drawing.new("Line")
        line.Visible = false
        line.Thickness = 1.5
        line.Color = Theme.Colors.AccentNeon
        line.Transparency = 1
        line.From = Vector2.new(0, 0)
        line.To = Vector2.new(0, 0)
        if props then for k, v in pairs(props) do line[k] = v end end
        table.insert(self.objects, line)
        return line
    end

    function container:AddText(props)
        if not hasDrawing then return nil end
        local text = Drawing.new("Text")
        text.Visible = false
        text.Size = 13
        text.Center = true
        text.Outline = true
        text.OutlineColor = Color3.fromRGB(0, 0, 0)
        text.Color = Color3.fromRGB(255, 255, 255)
        if props then for k, v in pairs(props) do text[k] = v end end
        table.insert(self.objects, text)
        return text
    end

    function container:AddSquare(props)
        if not hasDrawing then return nil end
        local sq = Drawing.new("Square")
        sq.Visible = false
        sq.Thickness = 1.5
        sq.Filled = false
        sq.Color = Theme.Colors.Accent
        if props then for k, v in pairs(props) do sq[k] = v end end
        table.insert(self.objects, sq)
        return sq
    end

    function container:AddCircle(props)
        if not hasDrawing then return nil end
        local circle = Drawing.new("Circle")
        circle.Visible = false
        circle.Thickness = 1.5
        circle.Filled = false
        circle.NumSides = 24
        circle.Radius = 12
        circle.Color = Theme.Colors.AccentNeon
        if props then for k, v in pairs(props) do circle[k] = v end end
        table.insert(self.objects, circle)
        return circle
    end

    function container:Clear()
        for _, obj in ipairs(self.objects) do
            pcall(function()
                obj.Visible = false
                obj:Remove()
            end)
        end
        self.objects = {}
    end

    return container
end

-- =====================================================================
-- 4. STATE & CONFIGURATION STORE
-- =====================================================================
local State = {
    Magnet = {
        Enabled = false,
        Range = 25,
        HitboxSize = 8,
        Mode = "Regular", -- "Legit", "Regular", "Strong"
        CatchDistance = 20,
        CatchAngle = 80,
        AngleEnhancer = false,
        AutoCatch = true,
        DiveCatchAssist = true
    },
    BallVisuals = {
        Enabled = true,
        Highlight = true,
        Tracer = true,
        Distance = true,
        Prediction = true,
        PredictionSteps = 35
    },
    PlayerVisuals = {
        Enabled = true,
        Filter = "Opponent", -- "Everyone", "Opponent", "Team"
        Boxes = true,
        Names = true,
        Distances = true,
        Tracers = false
    },
    Player = {
        SpeedEnabled = false,
        WalkSpeed = 24,
        JumpEnabled = false,
        JumpPower = 65,
        InfiniteJump = false
    },
    Physics = {
        DiveVelocityMultiplier = 1.4,
        DiveDistanceBoost = 15,
        CatchRadiusModifier = 1.0
    },
    Automatics = {
        AutoCatch = true,
        AutoIntercept = false,
        AutoDive = false,
        AutoPick = true,
        AutoCatchDistance = 14,
        AutoDiveDistance = 22,
        AutoPickDistance = 18
    },
    Settings = {
        ToggleKey = Enum.KeyCode.RightShift,
        Watermark = true
    }
}

-- Safe touch interest caller
local function triggerTouchInterest(p1, p2)
    if not (p1 and p2 and p1:IsA("BasePart") and p2:IsA("BasePart")) then return end
    if typeof(firetouchinterest) == "function" then
        pcall(function()
            firetouchinterest(p1, p2, 0)
            task.wait()
            firetouchinterest(p1, p2, 1)
        end)
    else
        pcall(function()
            local c = p1.CFrame
            p1.CFrame = p2.CFrame
            task.wait()
            p1.CFrame = c
        end)
    end
end

-- =====================================================================
-- 5. RUNTIME SYSTEM IMPLEMENTATIONS
-- =====================================================================

-- 5.1 Ball Magnet Runtime
local MagnetSystem = {
    _activeOriginalSizes = {},
    _heartbeatConn = nil
}

function MagnetSystem:ApplyHitboxes(char)
    local parts = Environment.getCatchParts(char)
    local sz = Vector3.new(State.Magnet.HitboxSize, State.Magnet.HitboxSize, State.Magnet.HitboxSize)
    for _, part in ipairs(parts) do
        if part.Name == "CatchHitbox" or part.Name:find("Arm") or part.Name:find("Hand") then
            if not self._activeOriginalSizes[part] then
                self._activeOriginalSizes[part] = part.Size
            end
            part.Size = sz
            part.CanCollide = false
        end
    end
end

function MagnetSystem:ResetHitboxes()
    for part, size in pairs(self._activeOriginalSizes) do
        if part and part.Parent then
            pcall(function() part.Size = size end)
        end
    end
    self._activeOriginalSizes = {}
end

function MagnetSystem:Step()
    if not State.Magnet.Enabled then return end

    local char, hrp, hum = Environment.getLocalCharacter()
    if not (char and hrp) then return end

    local football = Environment.getFootball()
    if not (football and football:IsA("BasePart")) then return end
    if not Environment.isBallLive(football) then return end

    local ballPos = football.Position
    local playerPos = hrp.Position
    local dist = (ballPos - playerPos).Magnitude

    if dist > State.Magnet.Range then return end

    -- Angle check
    if not State.Magnet.AngleEnhancer then
        local dir = (ballPos - playerPos).Unit
        local look = hrp.CFrame.LookVector
        local dot = math.clamp(look:Dot(dir), -1, 1)
        local angleDeg = math.deg(math.acos(dot))
        if angleDeg > State.Magnet.CatchAngle then
            return
        end
    end

    self:ApplyHitboxes(char)
    local catchParts = Environment.getCatchParts(char)

    if State.Magnet.Mode == "Legit" then
        if dist <= State.Magnet.CatchDistance then
            local targetHand = char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm") or hrp
            local pullDir = (targetHand.Position - ballPos).Unit
            football.AssemblyLinearVelocity = football.AssemblyLinearVelocity + (pullDir * 6.0)

            if State.Magnet.AutoCatch and dist <= 7.0 then
                triggerTouchInterest(targetHand, football)
            end
        end

    elseif State.Magnet.Mode == "Regular" then
        if dist <= State.Magnet.CatchDistance then
            local targetPart = char:FindFirstChild("CatchHitbox") or char:FindFirstChild("RightHand") or hrp
            local pullDir = (targetPart.Position - ballPos).Unit
            local pullSpeed = math.clamp(32.0 / math.max(dist, 1), 10, 45)
            football.AssemblyLinearVelocity = pullDir * pullSpeed

            if State.Magnet.AutoCatch and dist <= 12.0 then
                for _, cp in ipairs(catchParts) do
                    triggerTouchInterest(cp, football)
                end
            end
        end

    elseif State.Magnet.Mode == "Strong" then
        if dist <= State.Magnet.CatchDistance then
            for _, cp in ipairs(catchParts) do
                triggerTouchInterest(cp, football)
            end
            football.AssemblyLinearVelocity = (hrp.Position - ballPos).Unit * 55.0
        end
    end

    -- Dive catch assist
    if State.Magnet.DiveCatchAssist and hum:GetState() == Enum.HumanoidStateType.Freefall then
        local vel = hrp.AssemblyLinearVelocity
        if vel.Magnitude > 22 and vel.Y < 5 then
            local toBall = (ballPos - playerPos).Unit
            hrp.AssemblyLinearVelocity = hrp.AssemblyLinearVelocity + (toBall * (State.Physics.DiveVelocityMultiplier * 4.5))
        end
    end
end

-- 5.2 Ball Visual Overlay Runtime
local BallOverlaySystem = {
    _container = createDrawingContainer(),
    _highlight = nil,
    _tracer = nil,
    _distText = nil,
    _landingCircle = nil,
    _trajectoryLines = {}
}

function BallOverlaySystem:Init()
    self._tracer = self._container:AddLine({
        Thickness = 1.5,
        Color = Theme.Colors.AccentNeon,
        Visible = false
    })
    self._distText = self._container:AddText({
        Size = 13,
        Center = true,
        Outline = true,
        Color = Color3.fromRGB(255, 255, 255),
        Visible = false
    })
    self._landingCircle = self._container:AddCircle({
        Thickness = 2,
        Radius = 16,
        NumSides = 28,
        Color = Theme.Colors.AccentNeon,
        Visible = false
    })
    for i = 1, 50 do
        local l = self._container:AddLine({
            Thickness = 1.8,
            Color = Theme.Colors.AccentNeon,
            Visible = false
        })
        table.insert(self._trajectoryLines, l)
    end
end

function BallOverlaySystem:UpdateHighlight(football)
    if not (State.BallVisuals.Enabled and State.BallVisuals.Highlight) then
        if self._highlight then self._highlight.Enabled = false end
        return
    end
    if not self._highlight or self._highlight.Parent ~= football then
        if self._highlight then self._highlight:Destroy() end
        local hl = Instance.new("Highlight")
        hl.Name = "VortexBallHighlight"
        hl.FillColor = Theme.Colors.AccentNeon
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        hl.FillTransparency = 0.25
        hl.OutlineTransparency = 0.1
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Adornee = football
        hl.Parent = football
        self._highlight = hl
    end
    self._highlight.Enabled = true
end

function BallOverlaySystem:Render()
    if not State.BallVisuals.Enabled then
        if self._tracer then self._tracer.Visible = false end
        if self._distText then self._distText.Visible = false end
        if self._landingCircle then self._landingCircle.Visible = false end
        for _, l in ipairs(self._trajectoryLines) do l.Visible = false end
        if self._highlight then self._highlight.Enabled = false end
        return
    end

    local football = Environment.getFootball()
    if not (football and football:IsA("BasePart")) then
        if self._tracer then self._tracer.Visible = false end
        if self._distText then self._distText.Visible = false end
        if self._landingCircle then self._landingCircle.Visible = false end
        for _, l in ipairs(self._trajectoryLines) do l.Visible = false end
        return
    end

    self:UpdateHighlight(football)

    local screenPos, onScreen = Camera:WorldToViewportPoint(football.Position)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local dist = hrp and (football.Position - hrp.Position).Magnitude or 0

    -- Tracer
    if State.BallVisuals.Tracer and onScreen and self._tracer then
        self._tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
        self._tracer.To = Vector2.new(screenPos.X, screenPos.Y)
        self._tracer.Visible = true
    elseif self._tracer then
        self._tracer.Visible = false
    end

    -- Distance Tag
    if State.BallVisuals.Distance and onScreen and self._distText then
        self._distText.Text = string.format("BALL [%d studs]", math.floor(dist))
        self._distText.Position = Vector2.new(screenPos.X, screenPos.Y - 20)
        self._distText.Visible = true
    elseif self._distText then
        self._distText.Visible = false
    end

    -- Trajectory and Landing
    local vel = football.AssemblyLinearVelocity
    if State.BallVisuals.Prediction and vel.Magnitude > 3.5 then
        local p0 = football.Position
        local v0 = vel
        local gravity = Vector3.new(0, -Workspace.Gravity, 0)
        local stepTime = 0.05
        local currentP = p0
        local currentV = v0

        local landingPoint = nil
        local rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        rayParams.FilterDescendantsInstances = { football, LocalPlayer.Character }

        local maxSteps = math.clamp(State.BallVisuals.PredictionSteps, 10, 50)
        for i = 1, maxSteps do
            local nextP = currentP + (currentV * stepTime) + (0.5 * gravity * (stepTime * stepTime))
            local rayResult = Workspace:Raycast(currentP, nextP - currentP, rayParams)

            local segStart = Camera:WorldToViewportPoint(currentP)
            local segEnd = Camera:WorldToViewportPoint(rayResult and rayResult.Position or nextP)

            local line = self._trajectoryLines[i]
            if line then
                if segStart.Z > 0 and segEnd.Z > 0 then
                    line.From = Vector2.new(segStart.X, segStart.Y)
                    line.To = Vector2.new(segEnd.X, segEnd.Y)
                    line.Visible = true
                else
                    line.Visible = false
                end
            end

            if rayResult then
                landingPoint = rayResult.Position
                for j = i + 1, #self._trajectoryLines do
                    if self._trajectoryLines[j] then self._trajectoryLines[j].Visible = false end
                end
                break
            end

            currentP = nextP
            currentV = currentV + (gravity * stepTime)
        end

        if landingPoint and self._landingCircle then
            local landScreen, landVis = Camera:WorldToViewportPoint(landingPoint)
            if landVis and landScreen.Z > 0 then
                self._landingCircle.Position = Vector2.new(landScreen.X, landScreen.Y)
                self._landingCircle.Visible = true
            else
                self._landingCircle.Visible = false
            end
        elseif self._landingCircle then
            self._landingCircle.Visible = false
        end
    else
        for _, l in ipairs(self._trajectoryLines) do l.Visible = false end
        if self._landingCircle then self._landingCircle.Visible = false end
    end
end

-- 5.3 Player Visual Overlay Runtime
local PlayerOverlaySystem = {
    _entries = {}
}

function PlayerOverlaySystem:CreateEntry(player)
    if self._entries[player] then return end
    local box = hasDrawing and Drawing.new("Square")
    if box then
        box.Visible = false
        box.Thickness = 1.5
        box.Filled = false
    end
    local tracer = hasDrawing and Drawing.new("Line")
    if tracer then
        tracer.Visible = false
        tracer.Thickness = 1.2
    end
    local nameText = hasDrawing and Drawing.new("Text")
    if nameText then
        nameText.Visible = false
        nameText.Size = 13
        nameText.Center = true
        nameText.Outline = true
    end
    local distText = hasDrawing and Drawing.new("Text")
    if distText then
        distText.Visible = false
        distText.Size = 11
        distText.Center = true
        distText.Outline = true
    end

    self._entries[player] = {
        Box = box,
        Tracer = tracer,
        Name = nameText,
        Distance = distText
    }
end

function PlayerOverlaySystem:RemoveEntry(player)
    local entry = self._entries[player]
    if entry then
        pcall(function()
            if entry.Box then entry.Box.Visible = false entry.Box:Remove() end
            if entry.Tracer then entry.Tracer.Visible = false entry.Tracer:Remove() end
            if entry.Name then entry.Name.Visible = false entry.Name:Remove() end
            if entry.Distance then entry.Distance.Visible = false entry.Distance:Remove() end
        end)
        self._entries[player] = nil
    end
end

function PlayerOverlaySystem:Render()
    if not State.PlayerVisuals.Enabled then
        for _, entry in pairs(self._entries) do
            if entry.Box then entry.Box.Visible = false end
            if entry.Tracer then entry.Tracer.Visible = false end
            if entry.Name then entry.Name.Visible = false end
            if entry.Distance then entry.Distance.Visible = false end
        end
        return
    end

    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if not self._entries[player] then
                self:CreateEntry(player)
            end

            local entry = self._entries[player]
            if not entry then continue end

            local opp = Environment.isOpponent(player)
            local filter = State.PlayerVisuals.Filter
            local allowed = (filter == "Everyone") or (filter == "Opponent" and opp) or (filter == "Team" and not opp)

            local char = player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")

            if allowed and root and hum and hum.Health > 0 then
                local rootPos, onScreen = Camera:WorldToViewportPoint(root.Position)
                local dist = myRoot and (root.Position - myRoot.Position).Magnitude or 0
                local targetColor = opp and Theme.Colors.Opponent or Theme.Colors.Teammate

                if onScreen and rootPos.Z > 0 then
                    local head = char:FindFirstChild("Head")
                    local headPos = head and Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.8, 0)) or Vector3.new(rootPos.X, rootPos.Y - 30, rootPos.Z)
                    local legPos = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3.2, 0))

                    local height = math.abs(headPos.Y - legPos.Y)
                    local width = height * 0.65
                    local boxTopLeft = Vector2.new(rootPos.X - (width / 2), headPos.Y)

                    if State.PlayerVisuals.Boxes and entry.Box then
                        entry.Box.Size = Vector2.new(width, height)
                        entry.Box.Position = boxTopLeft
                        entry.Box.Color = targetColor
                        entry.Box.Visible = true
                    elseif entry.Box then
                        entry.Box.Visible = false
                    end

                    if State.PlayerVisuals.Tracers and entry.Tracer then
                        entry.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                        entry.Tracer.To = Vector2.new(rootPos.X, legPos.Y)
                        entry.Tracer.Color = targetColor
                        entry.Tracer.Visible = true
                    elseif entry.Tracer then
                        entry.Tracer.Visible = false
                    end

                    if State.PlayerVisuals.Names and entry.Name then
                        entry.Name.Text = player.DisplayName or player.Name
                        entry.Name.Position = Vector2.new(rootPos.X, headPos.Y - 16)
                        entry.Name.Color = Color3.fromRGB(255, 255, 255)
                        entry.Name.Visible = true
                    elseif entry.Name then
                        entry.Name.Visible = false
                    end

                    if State.PlayerVisuals.Distances and entry.Distance then
                        entry.Distance.Text = string.format("%d studs", math.floor(dist))
                        entry.Distance.Position = Vector2.new(rootPos.X, legPos.Y + 4)
                        entry.Distance.Color = targetColor
                        entry.Distance.Visible = true
                    elseif entry.Distance then
                        entry.Distance.Visible = false
                    end
                else
                    if entry.Box then entry.Box.Visible = false end
                    if entry.Tracer then entry.Tracer.Visible = false end
                    if entry.Name then entry.Name.Visible = false end
                    if entry.Distance then entry.Distance.Visible = false end
                end
            else
                if entry.Box then entry.Box.Visible = false end
                if entry.Tracer then entry.Tracer.Visible = false end
                if entry.Name then entry.Name.Visible = false end
                if entry.Distance then entry.Distance.Visible = false end
            end
        end
    end
end

-- 5.4 Automatics & Physics Runtime
local AutomaticsSystem = {}

function AutomaticsSystem:Step()
    -- Movement Physics
    local char, hrp, hum = Environment.getLocalCharacter()
    if char and hum and hrp then
        if State.Player.SpeedEnabled then
            hum.WalkSpeed = State.Player.WalkSpeed
        end
        if State.Player.JumpEnabled then
            if hum.UseJumpPower then
                hum.JumpPower = State.Player.JumpPower
            else
                hum.JumpHeight = State.Player.JumpPower * 0.15
            end
        end
    end

    -- Automatics
    if not (char and hrp and hum and hum.Health > 0) then return end
    local football = Environment.getFootball()
    if not (football and football:IsA("BasePart")) then return end

    local ballPos = football.Position
    local playerPos = hrp.Position
    local dist = (ballPos - playerPos).Magnitude
    local vel = football.AssemblyLinearVelocity
    local isLive = vel.Magnitude > 3.0

    -- Auto Pick (Grounded dead ball)
    if State.Automatics.AutoPick and not isLive and dist <= State.Automatics.AutoPickDistance then
        if football.Parent == Workspace and not football:IsDescendantOf(char) then
            local catchPart = char:FindFirstChild("CatchHitbox") or char:FindFirstChild("RightHand") or hrp
            triggerTouchInterest(catchPart, football)
        end
    end

    -- In-Flight Automatics
    if isLive then
        -- Auto Catch
        if State.Automatics.AutoCatch and dist <= State.Automatics.AutoCatchDistance then
            local catchPart = char:FindFirstChild("CatchHitbox") or char:FindFirstChild("RightHand") or hrp
            triggerTouchInterest(catchPart, football)
        end

        -- Auto Dive
        if State.Automatics.AutoDive and dist > State.Automatics.AutoCatchDistance and dist <= State.Automatics.AutoDiveDistance then
            local toBall = (ballPos - playerPos).Unit
            local look = hrp.CFrame.LookVector
            if look:Dot(toBall) > 0.35 and vel.Y < 3 then
                hum:ChangeState(Enum.HumanoidStateType.Freefall)
                hrp.AssemblyLinearVelocity = toBall * (40 * State.Physics.DiveVelocityMultiplier) + Vector3.new(0, 10, 0)
            end
        end

        -- Auto Intercept Guide
        if State.Automatics.AutoIntercept and dist > 10 and dist <= 55 then
            local toBall = (ballPos - playerPos).Unit
            hrp.AssemblyLinearVelocity = hrp.AssemblyLinearVelocity + (toBall * 2.8)
        end
    end
end

-- =====================================================================
-- 6. USER INTERFACE CONSTRUCTION
-- =====================================================================
local Hub = {
    Visible = true,
    ScreenGui = nil,
    Tabs = {},
    CurrentTab = nil,
    _connections = {}
}

function Hub:Init()
    local safeParent = getSafeGuiParent()
    local old = safeParent:FindFirstChild("VortexFreeHub")
    if old then old:Destroy() end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "VortexFreeHub"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = safeParent
    self.ScreenGui = screenGui

    -- Main Frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 680, 0, 440)
    mainFrame.Position = UDim2.new(0.5, -340, 0.5, -220)
    mainFrame.BackgroundColor3 = Theme.Colors.Background
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = screenGui
    self.MainFrame = mainFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = Theme.Corners.Window
    corner.Parent = mainFrame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Theme.Colors.PanelBorder
    stroke.Thickness = 1.2
    stroke.Parent = mainFrame

    -- Header Bar
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 44)
    header.BackgroundColor3 = Theme.Colors.Header
    header.BorderSizePixel = 0
    header.Parent = mainFrame

    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = Theme.Corners.Window
    headerCorner.Parent = header

    local bottomCover = Instance.new("Frame")
    bottomCover.Size = UDim2.new(1, 0, 0, 10)
    bottomCover.Position = UDim2.new(0, 0, 1, -10)
    bottomCover.BackgroundColor3 = Theme.Colors.Header
    bottomCover.BorderSizePixel = 0
    bottomCover.Parent = header

    local sep = Instance.new("Frame")
    sep.Size = UDim2.new(1, 0, 0, 1)
    sep.Position = UDim2.new(0, 0, 1, -1)
    sep.BackgroundColor3 = Theme.Colors.PanelBorder
    sep.BorderSizePixel = 0
    sep.Parent = header

    local title = Instance.new("TextLabel")
    title.Text = "VORTEX"
    title.Font = Theme.Fonts.Header
    title.TextSize = 16
    title.TextColor3 = Theme.Colors.TextPrimary
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Size = UDim2.new(0, 85, 1, 0)
    title.Position = UDim2.new(0, 18, 0, 0)
    title.BackgroundTransparency = 1
    title.Parent = header

    local badge = Instance.new("TextLabel")
    badge.Text = "FREE"
    badge.Font = Theme.Fonts.Badge
    badge.TextSize = 11
    badge.TextColor3 = Theme.Colors.AccentNeon
    badge.BackgroundColor3 = Theme.Colors.AccentDark
    badge.BackgroundTransparency = 0.75
    badge.Size = UDim2.new(0, 46, 0, 18)
    badge.Position = UDim2.new(0, 92, 0.5, -9)
    badge.Parent = header

    local bCorner = Instance.new("UICorner")
    bCorner.CornerRadius = Theme.Corners.Pill
    bCorner.Parent = badge

    local bStroke = Instance.new("UIStroke")
    bStroke.Color = Theme.Colors.AccentNeon
    bStroke.Thickness = 1
    bStroke.Transparency = 0.5
    bStroke.Parent = badge

    -- Header Controls
    local minBtn = Instance.new("TextButton")
    minBtn.Text = "—"
    minBtn.Font = Theme.Fonts.Header
    minBtn.TextSize = 14
    minBtn.TextColor3 = Theme.Colors.TextMuted
    minBtn.Size = UDim2.new(0, 32, 0, 32)
    minBtn.Position = UDim2.new(1, -72, 0.5, -16)
    minBtn.BackgroundTransparency = 1
    minBtn.Parent = header

    local closeBtn = Instance.new("TextButton")
    closeBtn.Text = "✕"
    closeBtn.Font = Theme.Fonts.Header
    closeBtn.TextSize = 13
    closeBtn.TextColor3 = Theme.Colors.TextMuted
    closeBtn.Size = UDim2.new(0, 32, 0, 32)
    closeBtn.Position = UDim2.new(1, -38, 0.5, -16)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Parent = header

    minBtn.MouseButton1Click:Connect(function()
        self:ToggleUI()
    end)
    closeBtn.MouseButton1Click:Connect(function()
        self:ToggleUI(false)
    end)

    -- Window Dragging
    local dragging, dragInput, dragStart, startPos
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

    header.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)

    local dragConn = UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
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

    -- Sidebar
    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.Size = UDim2.new(0, 160, 1, -44)
    sidebar.Position = UDim2.new(0, 0, 0, 44)
    sidebar.BackgroundColor3 = Theme.Colors.Sidebar
    sidebar.BorderSizePixel = 0
    sidebar.Parent = mainFrame

    local sSep = Instance.new("Frame")
    sSep.Size = UDim2.new(0, 1, 1, 0)
    sSep.Position = UDim2.new(1, -1, 0, 0)
    sSep.BackgroundColor3 = Theme.Colors.PanelBorder
    sSep.BorderSizePixel = 0
    sSep.Parent = sidebar

    local sLayout = Instance.new("UIListLayout")
    sLayout.SortOrder = Enum.SortOrder.LayoutOrder
    sLayout.Padding = UDim.new(0, 4)
    sLayout.Parent = sidebar

    local sPad = Instance.new("UIPadding")
    sPad.PaddingTop = UDim.new(0, 12)
    sPad.PaddingLeft = UDim.new(0, 10)
    sPad.PaddingRight = UDim.new(0, 10)
    sPad.Parent = sidebar

    -- Content Container
    local container = Instance.new("Frame")
    container.Name = "ContentContainer"
    container.Size = UDim2.new(1, -160, 1, -44)
    container.Position = UDim2.new(0, 160, 0, 44)
    container.BackgroundTransparency = 1
    container.Parent = mainFrame

    self.Sidebar = sidebar
    self.ContentContainer = container

    -- Notifications
    self:CreateNotifications(screenGui)

    -- Watermark
    self:CreateWatermark(screenGui)

    -- Build All Tabs and Controls
    self:BuildPages()

    -- Keybind toggle listener
    local keyConn = UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == State.Settings.ToggleKey then
            self:ToggleUI()
        end
    end)
    table.insert(self._connections, keyConn)

    -- Infinite jump listener
    local jumpConn = UserInputService.JumpRequest:Connect(function()
        if not State.Player.InfiniteJump then return end
        local char, hrp, hum = Environment.getLocalCharacter()
        if char and hrp and hum and hum.Health > 0 then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
            hrp.AssemblyLinearVelocity = Vector3.new(
                hrp.AssemblyLinearVelocity.X,
                State.Player.JumpEnabled and (State.Player.JumpPower * 0.85) or 50,
                hrp.AssemblyLinearVelocity.Z
            )
        end
    end)
    table.insert(self._connections, jumpConn)
end

function Hub:ToggleUI(override)
    if override ~= nil then
        self.Visible = override
    else
        self.Visible = not self.Visible
    end
    self.MainFrame.Visible = self.Visible
end

function Hub:CreateNotifications(screenGui)
    local notifContainer = Instance.new("Frame")
    notifContainer.Name = "NotificationContainer"
    notifContainer.Size = UDim2.new(0, 260, 1, -30)
    notifContainer.Position = UDim2.new(1, -270, 0, 15)
    notifContainer.BackgroundTransparency = 1
    notifContainer.Parent = screenGui

    local nLayout = Instance.new("UIListLayout")
    nLayout.SortOrder = Enum.SortOrder.LayoutOrder
    nLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    nLayout.Padding = UDim.new(0, 8)
    nLayout.Parent = notifContainer

    self.NotifContainer = notifContainer
end

function Hub:Notify(titleText, messageText, duration, statusType)
    duration = duration or 3.0
    local color = Theme.Colors.AccentNeon
    if statusType == "Success" then color = Theme.Colors.Success
    elseif statusType == "Warning" then color = Theme.Colors.Warning
    elseif statusType == "Error" then color = Theme.Colors.Error end

    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 52)
    card.BackgroundColor3 = Theme.Colors.Panel
    card.BorderSizePixel = 0
    card.Position = UDim2.new(1, 20, 0, 0)
    card.Parent = self.NotifContainer

    local cCorner = Instance.new("UICorner")
    cCorner.CornerRadius = Theme.Corners.Element
    cCorner.Parent = card

    local cStroke = Instance.new("UIStroke")
    cStroke.Color = Theme.Colors.PanelBorder
    cStroke.Thickness = 1
    cStroke.Parent = card

    local ind = Instance.new("Frame")
    ind.Size = UDim2.new(0, 3, 1, 0)
    ind.BackgroundColor3 = color
    ind.BorderSizePixel = 0
    ind.Parent = card

    local iCorner = Instance.new("UICorner")
    iCorner.CornerRadius = UDim.new(0, 3)
    iCorner.Parent = ind

    local tLbl = Instance.new("TextLabel")
    tLbl.Text = titleText
    tLbl.Font = Theme.Fonts.Subheader
    tLbl.TextSize = 13
    tLbl.TextColor3 = Theme.Colors.TextPrimary
    tLbl.TextXAlignment = Enum.TextXAlignment.Left
    tLbl.Size = UDim2.new(1, -16, 0, 18)
    tLbl.Position = UDim2.new(0, 12, 0, 6)
    tLbl.BackgroundTransparency = 1
    tLbl.Parent = card

    local mLbl = Instance.new("TextLabel")
    mLbl.Text = messageText
    mLbl.Font = Theme.Fonts.Body
    mLbl.TextSize = 11
    mLbl.TextColor3 = Theme.Colors.TextSecondary
    mLbl.TextXAlignment = Enum.TextXAlignment.Left
    mLbl.Size = UDim2.new(1, -16, 0, 16)
    mLbl.Position = UDim2.new(0, 12, 0, 26)
    mLbl.BackgroundTransparency = 1
    mLbl.Parent = card

    TweenService:Create(card, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 0, 0, 0)
    }):Play()

    task.delay(duration, function()
        if card and card.Parent then
            local tw = TweenService:Create(card, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                Position = UDim2.new(1, 20, 0, 0)
            })
            tw:Play()
            tw.Completed:Connect(function() card:Destroy() end)
        end
    end)
end

function Hub:CreateWatermark(screenGui)
    local wm = Instance.new("Frame")
    wm.Name = "Watermark"
    wm.Size = UDim2.new(0, 240, 0, 28)
    wm.Position = UDim2.new(1, -250, 0, 12)
    wm.BackgroundColor3 = Theme.Colors.Panel
    wm.BorderSizePixel = 0
    wm.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = Theme.Corners.Element
    corner.Parent = wm

    local stroke = Instance.new("UIStroke")
    stroke.Color = Theme.Colors.PanelBorder
    stroke.Thickness = 1
    stroke.Parent = wm

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 3, 1, 0)
    bar.BackgroundColor3 = Theme.Colors.AccentNeon
    bar.BorderSizePixel = 0
    bar.Parent = wm

    local bCorner = Instance.new("UICorner")
    bCorner.CornerRadius = UDim.new(0, 3)
    bCorner.Parent = bar

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -12, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Font = Theme.Fonts.Body
    label.TextSize = 12
    label.TextColor3 = Theme.Colors.TextPrimary
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = "VORTEX FREE | FPS: -- | PING: --ms"
    label.Parent = wm

    -- Dragging
    local wmDrag, wmStart, wmPos
    wm.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            wmDrag = true
            wmStart = inp.Position
            wmPos = wm.Position
            inp.Changed:Connect(function()
                if inp.UserInputState == Enum.UserInputState.End then wmDrag = false end
            end)
        end
    end)
    local wmConn = UserInputService.InputChanged:Connect(function(inp)
        if wmDrag and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = inp.Position - wmStart
            wm.Position = UDim2.new(wmPos.X.Scale, wmPos.X.Offset + delta.X, wmPos.Y.Scale, wmPos.Y.Offset + delta.Y)
        end
    end)
    table.insert(self._connections, wmConn)

    -- Update loop
    local frames = 0
    local lastTick = tick()
    local renderConn = RunService.RenderStepped:Connect(function()
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
            label.Text = string.format("VORTEX FREE | FPS: %d | PING: %dms", fps, ping)
        end
    end)
    table.insert(self._connections, renderConn)
end

function Hub:CreateTab(name)
    local btn = Instance.new("TextButton")
    btn.Name = name .. "TabBtn"
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.BackgroundTransparency = 1
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Text = ""
    btn.Parent = self.Sidebar

    local bCorner = Instance.new("UICorner")
    bCorner.CornerRadius = Theme.Corners.Element
    bCorner.Parent = btn

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 3, 0, 18)
    bar.Position = UDim2.new(0, 0, 0.5, -9)
    bar.BackgroundColor3 = Theme.Colors.AccentNeon
    bar.BorderSizePixel = 0
    bar.Visible = false
    bar.Parent = btn

    local bCor = Instance.new("UICorner")
    bCor.CornerRadius = UDim.new(0, 2)
    bCor.Parent = bar

    local lbl = Instance.new("TextLabel")
    lbl.Text = name
    lbl.Font = Theme.Fonts.Subheader
    lbl.TextSize = 13
    lbl.TextColor3 = Theme.Colors.TextMuted
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Size = UDim2.new(1, -20, 1, 0)
    lbl.Position = UDim2.new(0, 14, 0, 0)
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
    pLayout.Padding = UDim.new(0, 10)
    pLayout.Parent = page

    local pPad = Instance.new("UIPadding")
    pPad.PaddingTop = UDim.new(0, 14)
    pPad.PaddingBottom = UDim.new(0, 14)
    pPad.PaddingLeft = UDim.new(0, 14)
    pPad.PaddingRight = UDim.new(0, 14)
    pPad.Parent = page

    local tabObj = {
        Button = btn,
        Page = page,
        Bar = bar,
        Label = lbl
    }

    local function setActive(active)
        bar.Visible = active
        page.Visible = active
        if active then
            btn.BackgroundTransparency = 0
            btn.BackgroundColor3 = Theme.Colors.Panel
            lbl.TextColor3 = Theme.Colors.TextPrimary
        else
            btn.BackgroundTransparency = 1
            lbl.TextColor3 = Theme.Colors.TextMuted
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
-- 7. PAGE & COMPONENT FACTORY
-- =====================================================================

local function addSection(page, titleText)
    local s = Instance.new("Frame")
    s.Size = UDim2.new(1, 0, 0, 32)
    s.BackgroundColor3 = Theme.Colors.Panel
    s.BorderSizePixel = 0
    s.AutomaticSize = Enum.AutomaticSize.Y
    s.Parent = page

    local c = Instance.new("UICorner")
    c.CornerRadius = Theme.Corners.Card
    c.Parent = s

    local strk = Instance.new("UIStroke")
    strk.Color = Theme.Colors.PanelBorder
    strk.Thickness = 1
    strk.Parent = s

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 8)
    layout.Parent = s

    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 10)
    pad.PaddingBottom = UDim.new(0, 12)
    pad.PaddingLeft = UDim.new(0, 12)
    pad.PaddingRight = UDim.new(0, 12)
    pad.Parent = s

    local header = Instance.new("TextLabel")
    header.Text = string.upper(titleText)
    header.Font = Theme.Fonts.Header
    header.TextSize = 11
    header.TextColor3 = Theme.Colors.AccentNeon
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.Size = UDim2.new(1, 0, 0, 16)
    header.BackgroundTransparency = 1
    header.Parent = s

    return s
end

local function addToggle(sec, title, default, callback)
    local state = default or false

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 30)
    row.BackgroundTransparency = 1
    row.Parent = sec

    local lbl = Instance.new("TextLabel")
    lbl.Text = title
    lbl.Font = Theme.Fonts.Body
    lbl.TextSize = 13
    lbl.TextColor3 = Theme.Colors.TextPrimary
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Size = UDim2.new(1, -55, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Parent = row

    local sw = Instance.new("TextButton")
    sw.Size = UDim2.new(0, 42, 0, 22)
    sw.Position = UDim2.new(1, -42, 0.5, -11)
    sw.BackgroundColor3 = state and Theme.Colors.ToggleOn or Theme.Colors.ToggleOff
    sw.BorderSizePixel = 0
    sw.Text = ""
    sw.AutoButtonColor = false
    sw.Parent = row

    local sCorner = Instance.new("UICorner")
    sCorner.CornerRadius = Theme.Corners.Pill
    sCorner.Parent = sw

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = sw

    local kCorner = Instance.new("UICorner")
    kCorner.CornerRadius = Theme.Corners.Pill
    kCorner.Parent = knob

    local function update(anim)
        local targetColor = state and Theme.Colors.ToggleOn or Theme.Colors.ToggleOff
        local targetPos = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
        if anim then
            TweenService:Create(sw, TweenInfo.new(0.18, Enum.EasingStyle.Quart), { BackgroundColor3 = targetColor }):Play()
            TweenService:Create(knob, TweenInfo.new(0.18, Enum.EasingStyle.Quart), { Position = targetPos }):Play()
        else
            sw.BackgroundColor3 = targetColor
            knob.Position = targetPos
        end
    end

    sw.MouseButton1Click:Connect(function()
        state = not state
        update(true)
        if callback then callback(state) end
    end)

    return {
        Set = function(v) state = v update(false) if callback then callback(v) end end,
        Get = function() return state end
    }
end

local function addSlider(sec, title, minVal, maxVal, defVal, stepVal, suffix, callback)
    local val = defVal or minVal
    stepVal = stepVal or 1
    suffix = suffix or ""

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 42)
    row.BackgroundTransparency = 1
    row.Parent = sec

    local top = Instance.new("Frame")
    top.Size = UDim2.new(1, 0, 0, 18)
    top.BackgroundTransparency = 1
    top.Parent = row

    local lbl = Instance.new("TextLabel")
    lbl.Text = title
    lbl.Font = Theme.Fonts.Body
    lbl.TextSize = 13
    lbl.TextColor3 = Theme.Colors.TextPrimary
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Size = UDim2.new(0.7, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Parent = top

    local valLbl = Instance.new("TextLabel")
    valLbl.Text = tostring(val) .. suffix
    valLbl.Font = Theme.Fonts.Subheader
    valLbl.TextSize = 12
    valLbl.TextColor3 = Theme.Colors.AccentNeon
    valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.Size = UDim2.new(0.3, 0, 1, 0)
    valLbl.Position = UDim2.new(0.7, 0, 0, 0)
    valLbl.BackgroundTransparency = 1
    valLbl.Parent = top

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, 0, 0, 8)
    track.Position = UDim2.new(0, 0, 0, 24)
    track.BackgroundColor3 = Theme.Colors.SliderTrack
    track.BorderSizePixel = 0
    track.Parent = row

    local tCorner = Instance.new("UICorner")
    tCorner.CornerRadius = Theme.Corners.Pill
    tCorner.Parent = track

    local fill = Instance.new("Frame")
    local pct = math.clamp((val - minVal) / (maxVal - minVal), 0, 1)
    fill.Size = UDim2.new(pct, 0, 1, 0)
    fill.BackgroundColor3 = Theme.Colors.Accent
    fill.BorderSizePixel = 0
    fill.Parent = track

    local fCorner = Instance.new("UICorner")
    fCorner.CornerRadius = Theme.Corners.Pill
    fCorner.Parent = fill

    local dragging = false
    local function applyInput(inpPos)
        local absPos = track.AbsolutePosition.X
        local absSz = track.AbsoluteSize.X
        local rel = math.clamp(inpPos.X - absPos, 0, absSz)
        local rawVal = minVal + (maxVal - minVal) * (rel / absSz)
        local stepped = math.floor((rawVal / stepVal) + 0.5) * stepVal
        val = math.clamp(stepped, minVal, maxVal)

        local newPct = (val - minVal) / (maxVal - minVal)
        fill.Size = UDim2.new(newPct, 0, 1, 0)
        valLbl.Text = tostring(val) .. suffix
        if callback then callback(val) end
    end

    track.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            applyInput(inp.Position)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            applyInput(inp.Position)
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

local function addDropdown(sec, title, options, defOpt, callback)
    local selected = defOpt or options[1] or ""
    local open = false

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 32)
    row.BackgroundTransparency = 1
    row.Parent = sec

    local lbl = Instance.new("TextLabel")
    lbl.Text = title
    lbl.Font = Theme.Fonts.Body
    lbl.TextSize = 13
    lbl.TextColor3 = Theme.Colors.TextPrimary
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Size = UDim2.new(0.5, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Parent = row

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.48, 0, 0, 26)
    btn.Position = UDim2.new(0.52, 0, 0.5, -13)
    btn.BackgroundColor3 = Theme.Colors.SliderTrack
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = row

    local bCorner = Instance.new("UICorner")
    bCorner.CornerRadius = Theme.Corners.Element
    bCorner.Parent = btn

    local bStroke = Instance.new("UIStroke")
    bStroke.Color = Theme.Colors.PanelBorder
    bStroke.Thickness = 1
    bStroke.Parent = btn

    local bLbl = Instance.new("TextLabel")
    bLbl.Text = selected
    bLbl.Font = Theme.Fonts.Subheader
    bLbl.TextSize = 12
    bLbl.TextColor3 = Theme.Colors.AccentNeon
    bLbl.TextXAlignment = Enum.TextXAlignment.Left
    bLbl.Size = UDim2.new(1, -22, 1, 0)
    bLbl.Position = UDim2.new(0, 8, 0, 0)
    bLbl.BackgroundTransparency = 1
    bLbl.Parent = btn

    local arrow = Instance.new("TextLabel")
    arrow.Text = "▼"
    arrow.Font = Theme.Fonts.Body
    arrow.TextSize = 9
    arrow.TextColor3 = Theme.Colors.TextMuted
    arrow.Size = UDim2.new(0, 16, 1, 0)
    arrow.Position = UDim2.new(1, -18, 0, 0)
    arrow.BackgroundTransparency = 1
    arrow.Parent = btn

    local list = Instance.new("Frame")
    list.Size = UDim2.new(1, 0, 0, #options * 24 + 6)
    list.Position = UDim2.new(0, 0, 1, 4)
    list.BackgroundColor3 = Theme.Colors.Panel
    list.BorderSizePixel = 0
    list.Visible = false
    list.ZIndex = 40
    list.Parent = btn

    local lCorner = Instance.new("UICorner")
    lCorner.CornerRadius = Theme.Corners.Element
    lCorner.Parent = list

    local lStroke = Instance.new("UIStroke")
    lStroke.Color = Theme.Colors.PanelBorder
    lStroke.Thickness = 1
    lStroke.Parent = list

    local lLayout = Instance.new("UIListLayout")
    lLayout.SortOrder = Enum.SortOrder.LayoutOrder
    lLayout.Padding = UDim.new(0, 2)
    lLayout.Parent = list

    local lPad = Instance.new("UIPadding")
    lPad.PaddingTop = UDim.new(0, 3)
    lPad.PaddingBottom = UDim.new(0, 3)
    lPad.PaddingLeft = UDim.new(0, 3)
    lPad.PaddingRight = UDim.new(0, 3)
    lPad.Parent = list

    local function toggle()
        open = not open
        list.Visible = open
        arrow.Text = open and "▲" or "▼"
    end
    btn.MouseButton1Click:Connect(toggle)

    for _, opt in ipairs(options) do
        local optBtn = Instance.new("TextButton")
        optBtn.Size = UDim2.new(1, 0, 0, 22)
        optBtn.BackgroundColor3 = Theme.Colors.SliderTrack
        optBtn.BackgroundTransparency = 1
        optBtn.BorderSizePixel = 0
        optBtn.Text = opt
        optBtn.Font = Theme.Fonts.Body
        optBtn.TextSize = 11
        optBtn.TextColor3 = (opt == selected) and Theme.Colors.AccentNeon or Theme.Colors.TextSecondary
        optBtn.ZIndex = 41
        optBtn.Parent = list

        local oCorner = Instance.new("UICorner")
        oCorner.CornerRadius = Theme.Corners.Element
        oCorner.Parent = optBtn

        optBtn.MouseButton1Click:Connect(function()
            selected = opt
            bLbl.Text = opt
            toggle()
            if callback then callback(opt) end
        end)
    end

    return {
        Set = function(v) selected = v bLbl.Text = v if callback then callback(v) end end,
        Get = function() return selected end
    }
end

local function addKeybind(sec, title, defKey, callback)
    local curKey = defKey or Enum.KeyCode.RightShift
    local listening = false

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 30)
    row.BackgroundTransparency = 1
    row.Parent = sec

    local lbl = Instance.new("TextLabel")
    lbl.Text = title
    lbl.Font = Theme.Fonts.Body
    lbl.TextSize = 13
    lbl.TextColor3 = Theme.Colors.TextPrimary
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Size = UDim2.new(0.6, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Parent = row

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.38, 0, 0, 24)
    btn.Position = UDim2.new(0.62, 0, 0.5, -12)
    btn.BackgroundColor3 = Theme.Colors.SliderTrack
    btn.BorderSizePixel = 0
    btn.Text = curKey.Name
    btn.Font = Theme.Fonts.Subheader
    btn.TextSize = 11
    btn.TextColor3 = Theme.Colors.AccentNeon
    btn.Parent = row

    local bCorner = Instance.new("UICorner")
    bCorner.CornerRadius = Theme.Corners.Element
    bCorner.Parent = btn

    local bStroke = Instance.new("UIStroke")
    bStroke.Color = Theme.Colors.PanelBorder
    bStroke.Thickness = 1
    bStroke.Parent = btn

    btn.MouseButton1Click:Connect(function()
        listening = true
        btn.Text = "..."
        btn.TextColor3 = Theme.Colors.TextMuted
    end)

    UserInputService.InputBegan:Connect(function(input, gpe)
        if listening and input.UserInputType == Enum.UserInputType.Keyboard then
            curKey = input.KeyCode
            btn.Text = curKey.Name
            btn.TextColor3 = Theme.Colors.AccentNeon
            listening = false
            if callback then callback(curKey) end
        end
    end)

    return {
        Set = function(k) curKey = k btn.Text = k.Name if callback then callback(k) end end,
        Get = function() return curKey end
    }
end

local function addButton(sec, title, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 30)
    btn.BackgroundColor3 = Theme.Colors.SliderTrack
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
    stroke.Color = Theme.Colors.PanelBorder
    stroke.Thickness = 1
    stroke.Parent = btn

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {
            BackgroundColor3 = Theme.Colors.AccentDark,
            TextColor3 = Color3.fromRGB(255, 255, 255)
        }):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {
            BackgroundColor3 = Theme.Colors.SliderTrack,
            TextColor3 = Theme.Colors.TextPrimary
        }):Play()
    end)

    btn.MouseButton1Click:Connect(function()
        if callback then callback() end
    end)

    return btn
end

-- =====================================================================
-- 8. BUILD ALL TAB SECTIONS
-- =====================================================================
function Hub:BuildPages()
    -- Tab 1: Catching
    local catchPage = self:CreateTab("Catching")
    local magSec = addSection(catchPage, "Ball Magnet & Catching Mechanics")
    addToggle(magSec, "Ball Magnet", State.Magnet.Enabled, function(v)
        State.Magnet.Enabled = v
        if not v then MagnetSystem:ResetHitboxes() end
        self:Notify("Magnet", v and "Attraction system active" or "Attraction disabled", 2)
    end)
    addDropdown(magSec, "Magnet Mode", { "Regular", "Strong", "Legit" }, State.Magnet.Mode, function(v)
        State.Magnet.Mode = v
    end)
    addSlider(magSec, "Magnet Range", 5, 80, State.Magnet.Range, 1, " studs", function(v)
        State.Magnet.Range = v
    end)
    addSlider(magSec, "Catch Hitbox Size", 2, 25, State.Magnet.HitboxSize, 1, " studs", function(v)
        State.Magnet.HitboxSize = v
    end)
    addSlider(magSec, "Catch Distance", 5, 50, State.Magnet.CatchDistance, 1, " studs", function(v)
        State.Magnet.CatchDistance = v
    end)
    addSlider(magSec, "Catch Angle (FOV)", 30, 180, State.Magnet.CatchAngle, 5, "°", function(v)
        State.Magnet.CatchAngle = v
    end)
    addToggle(magSec, "Angle Enhancer (Omni-Catch)", State.Magnet.AngleEnhancer, function(v)
        State.Magnet.AngleEnhancer = v
    end)
    addToggle(magSec, "Automatic Catch", State.Magnet.AutoCatch, function(v)
        State.Magnet.AutoCatch = v
    end)
    addToggle(magSec, "Dive Catch Assist", State.Magnet.DiveCatchAssist, function(v)
        State.Magnet.DiveCatchAssist = v
    end)

    -- Tab 2: Visuals
    local visPage = self:CreateTab("Visuals")
    local bSec = addSection(visPage, "Football Visuals & Prediction")
    addToggle(bSec, "Ball Visuals Master", State.BallVisuals.Enabled, function(v)
        State.BallVisuals.Enabled = v
    end)
    addToggle(bSec, "Ball Highlight (Through Walls)", State.BallVisuals.Highlight, function(v)
        State.BallVisuals.Highlight = v
    end)
    addToggle(bSec, "Ball Screen Tracer", State.BallVisuals.Tracer, function(v)
        State.BallVisuals.Tracer = v
    end)
    addToggle(bSec, "Ball Distance Tag", State.BallVisuals.Distance, function(v)
        State.BallVisuals.Distance = v
    end)
    addToggle(bSec, "Ball Trajectory Prediction", State.BallVisuals.Prediction, function(v)
        State.BallVisuals.Prediction = v
    end)
    addSlider(bSec, "Prediction Step Depth", 10, 50, State.BallVisuals.PredictionSteps, 5, " ticks", function(v)
        State.BallVisuals.PredictionSteps = v
    end)

    local pSec = addSection(visPage, "Player Visuals & Bounding Boxes")
    addToggle(pSec, "Player Visuals Master", State.PlayerVisuals.Enabled, function(v)
        State.PlayerVisuals.Enabled = v
    end)
    addDropdown(pSec, "Filter Target", { "Opponent", "Team", "Everyone" }, State.PlayerVisuals.Filter, function(v)
        State.PlayerVisuals.Filter = v
    end)
    addToggle(pSec, "2D Bounding Boxes", State.PlayerVisuals.Boxes, function(v)
        State.PlayerVisuals.Boxes = v
    end)
    addToggle(pSec, "Directional Tracers", State.PlayerVisuals.Tracers, function(v)
        State.PlayerVisuals.Tracers = v
    end)
    addToggle(pSec, "Player Names", State.PlayerVisuals.Names, function(v)
        State.PlayerVisuals.Names = v
    end)
    addToggle(pSec, "Distance Indicators", State.PlayerVisuals.Distances, function(v)
        State.PlayerVisuals.Distances = v
    end)

    -- Tab 3: Player
    local plrPage = self:CreateTab("Player")
    local movSec = addSection(plrPage, "Movement Modifiers")
    addToggle(movSec, "Enable Custom WalkSpeed", State.Player.SpeedEnabled, function(v)
        State.Player.SpeedEnabled = v
        if not v then
            local _, _, hum = Environment.getLocalCharacter()
            if hum then hum.WalkSpeed = 16 end
        end
    end)
    addSlider(movSec, "WalkSpeed Value", 16, 100, State.Player.WalkSpeed, 1, " studs/s", function(v)
        State.Player.WalkSpeed = v
    end)
    addToggle(movSec, "Enable Custom JumpPower", State.Player.JumpEnabled, function(v)
        State.Player.JumpEnabled = v
        if not v then
            local _, _, hum = Environment.getLocalCharacter()
            if hum then
                if hum.UseJumpPower then hum.JumpPower = 50 else hum.JumpHeight = 7.2 end
            end
        end
    end)
    addSlider(movSec, "JumpPower Value", 50, 200, State.Player.JumpPower, 5, " pow", function(v)
        State.Player.JumpPower = v
    end)
    addToggle(movSec, "Infinite Jump", State.Player.InfiniteJump, function(v)
        State.Player.InfiniteJump = v
    end)

    -- Tab 4: Physics
    local phyPage = self:CreateTab("Physics")
    local phySec = addSection(phyPage, "Game Physics Modifiers")
    addSlider(phySec, "Dive Velocity Multiplier", 1.0, 2.5, State.Physics.DiveVelocityMultiplier, 0.1, "x", function(v)
        State.Physics.DiveVelocityMultiplier = v
    end)
    addSlider(phySec, "Dive Distance Boost", 5, 35, State.Physics.DiveDistanceBoost, 1, " studs", function(v)
        State.Physics.DiveDistanceBoost = v
    end)
    addSlider(phySec, "Catch Radius Scaling", 0.5, 3.0, State.Physics.CatchRadiusModifier, 0.1, "x", function(v)
        State.Physics.CatchRadiusModifier = v
    end)

    -- Tab 5: Automatics
    local autoPage = self:CreateTab("Automatics")
    local autSec = addSection(autoPage, "Autonomous Assistance Routines")
    addToggle(autSec, "Autonomous Catch", State.Automatics.AutoCatch, function(v)
        State.Automatics.AutoCatch = v
    end)
    addSlider(autSec, "Auto Catch Distance", 5, 25, State.Automatics.AutoCatchDistance, 1, " studs", function(v)
        State.Automatics.AutoCatchDistance = v
    end)
    addToggle(autSec, "Autonomous Intercept Guide", State.Automatics.AutoIntercept, function(v)
        State.Automatics.AutoIntercept = v
    end)
    addToggle(autSec, "Autonomous Dive", State.Automatics.AutoDive, function(v)
        State.Automatics.AutoDive = v
    end)
    addSlider(autSec, "Auto Dive Distance", 12, 35, State.Automatics.AutoDiveDistance, 1, " studs", function(v)
        State.Automatics.AutoDiveDistance = v
    end)
    addToggle(autSec, "Autonomous Pick (Dead Ball)", State.Automatics.AutoPick, function(v)
        State.Automatics.AutoPick = v
    end)
    addSlider(autSec, "Auto Pick Distance", 8, 30, State.Automatics.AutoPickDistance, 1, " studs", function(v)
        State.Automatics.AutoPickDistance = v
    end)

    -- Tab 6: Settings
    local setPage = self:CreateTab("Settings")
    local cfgSec = addSection(setPage, "Hub Configuration & Keybinds")
    addKeybind(cfgSec, "Toggle Menu Keybind", State.Settings.ToggleKey, function(key)
        State.Settings.ToggleKey = key
        self:Notify("Keybind Updated", "Toggle menu set to " .. key.Name, 2.5)
    end)
    addButton(cfgSec, "Save Current Settings to File", function()
        local canWrite = typeof(writefile) == "function" and typeof(makefolder) == "function"
        if canWrite then
            pcall(function()
                if not (typeof(isfolder) == "function" and isfolder("vortex_ff2")) then
                    makefolder("vortex_ff2")
                end
                local saveTable = {
                    Magnet = State.Magnet,
                    BallVisuals = State.BallVisuals,
                    PlayerVisuals = State.PlayerVisuals,
                    Player = State.Player,
                    Physics = State.Physics,
                    Automatics = State.Automatics
                }
                writefile("vortex_ff2/config.json", HttpService:JSONEncode(saveTable))
            end)
            self:Notify("Config Saved", "Preferences stored to vortex_ff2/config.json", 3, "Success")
        else
            self:Notify("Notice", "Executor missing writefile capability", 3, "Warning")
        end
    end)
    addButton(cfgSec, "Load Saved Settings from File", function()
        local canRead = typeof(readfile) == "function" and typeof(isfile) == "function"
        if canRead and isfile("vortex_ff2/config.json") then
            pcall(function()
                local raw = readfile("vortex_ff2/config.json")
                local decoded = HttpService:JSONDecode(raw)
                for cat, vals in pairs(decoded) do
                    if State[cat] and type(vals) == "table" then
                        for k, v in pairs(vals) do State[cat][k] = v end
                    end
                end
            end)
            self:Notify("Config Loaded", "Preferences applied successfully", 3, "Success")
        else
            self:Notify("Notice", "No existing config file found", 3, "Warning")
        end
    end)
    addButton(cfgSec, "Unload Hub & Clean Memory", function()
        self:Unload()
    end)
end

function Hub:Unload()
    -- Disconnect all events
    for _, conn in ipairs(self._connections) do
        pcall(function() conn:Disconnect() end)
    end
    self._connections = {}

    -- Stop runtimes
    MagnetSystem:ResetHitboxes()
    BallOverlaySystem._container:Clear()
    if BallOverlaySystem._highlight then
        BallOverlaySystem._highlight:Destroy()
    end
    for plr, _ in pairs(PlayerOverlaySystem._entries) do
        PlayerOverlaySystem:RemoveEntry(plr)
    end

    -- Restore humanoid movement
    pcall(function()
        local _, _, hum = Environment.getLocalCharacter()
        if hum then
            hum.WalkSpeed = 16
            if hum.UseJumpPower then hum.JumpPower = 50 else hum.JumpHeight = 7.2 end
        end
    end)

    -- Destroy UI
    if self.ScreenGui then
        self.ScreenGui:Destroy()
        self.ScreenGui = nil
    end

    if getgenv then
        getgenv().VortexFreeInstance = nil
    end
end

-- =====================================================================
-- 9. LIFECYCLE INITIALIZATION
-- =====================================================================
BallOverlaySystem:Init()
Hub:Init()

-- Main Heartbeat Loop
local heartbeatConn = RunService.Heartbeat:Connect(function()
    pcall(function()
        MagnetSystem:Step()
        AutomaticsSystem:Step()
    end)
end)
table.insert(Hub._connections, heartbeatConn)

-- Main Render Loop
local renderConn = RunService.RenderStepped:Connect(function()
    pcall(function()
        BallOverlaySystem:Render()
        PlayerOverlaySystem:Render()
    end)
end)
table.insert(Hub._connections, renderConn)

-- Player Cleanup
local plrLeaveConn = Players.PlayerRemoving:Connect(function(plr)
    PlayerOverlaySystem:RemoveEntry(plr)
end)
table.insert(Hub._connections, plrLeaveConn)

-- Save global reference
if getgenv then
    getgenv().VortexFreeInstance = Hub
end

Hub:Notify("Vortex Free", "Hub initialized. Press " .. State.Settings.ToggleKey.Name .. " to toggle.", 4, "Success")
