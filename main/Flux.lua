-- Load Luna Interface
local Luna = loadstring(game:HttpGet("https://raw.githubusercontent.com/Nebula-Softworks/Luna-Interface-Suite/refs/heads/main/source.lua", true))()

-- Create Main Window
local Window = Luna:CreateWindow({
    Name = "Flux",
    Subtitle = "Flux on crack",
    LogoID = "116511775321501",
    LoadingEnabled = true,
    LoadingTitle = "Flux Hub",
    LoadingSubtitle = "by @j4y11",
    ConfigSettings = { ConfigFolder = "Flux Hub" }
})

-- Create Tab
local Tab = Window:CreateTab({ Name = "Main", Icon = "work", ImageSource = "Material", ShowTitle = true })
Tab:CreateSection("Aimbot")

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Variables
local aimbotEnabled = false
local showFOV = false
local aimSmoothness = 5
local aimbotRadius = 100
local teamCheck = false
local targetPart = "HumanoidRootPart"
local useMouseTarget = false
local predictionStrength = 0.165
local stickyLock = false
local currentTarget = nil
local aimPriority = "Closest"
local fovColor = Color3.fromRGB(255, 0, 0)

-- New Features
local triggerbotEnabled = false
local autowallEnabled = false
local recoilControlEnabled = false
local headshotOnly = false

-- Drawing
local fovCircle = Drawing.new("Circle")
fovCircle.Visible = false
fovCircle.Filled = false
fovCircle.Thickness = 1
fovCircle.Transparency = 0.5

-- Get Best Target
local function getTarget()
    if stickyLock and currentTarget and currentTarget.Character and currentTarget.Character:FindFirstChild("Humanoid") and currentTarget.Character.Humanoid.Health > 0 then
        return currentTarget
    end

    local bestTarget = nil
    local bestValue = math.huge
    local ref = useMouseTarget and UserInputService:GetMouseLocation() or Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") then
            local partName = headshotOnly and "Head" or targetPart
            local part = player.Character:FindFirstChild(partName)
            local hp = player.Character.Humanoid.Health
            if not part or hp <= 0 then continue end
            if teamCheck and player.Team == LocalPlayer.Team then continue end

            local predicted = part.Position + (part.Velocity * predictionStrength)
            local screenPos, onScreen = Camera:WorldToViewportPoint(predicted)
            if onScreen then
                local distance = (Vector2.new(screenPos.X, screenPos.Y) - ref).Magnitude
                if aimPriority == "Closest" and distance < bestValue and distance <= aimbotRadius then
                    bestTarget = player
                    bestValue = distance
                elseif aimPriority == "Lowest HP" and hp < bestValue then
                    bestTarget = player
                    bestValue = hp
                elseif aimPriority == "Random" and math.random() < 0.05 then
                    bestTarget = player
                end
            end
        end
    end

    currentTarget = bestTarget
    return bestTarget
end

-- Aimbot + Triggerbot Logic
RunService.RenderStepped:Connect(function()
    fovCircle.Position = useMouseTarget and UserInputService:GetMouseLocation() or Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    fovCircle.Visible = showFOV
    fovCircle.Radius = aimbotRadius
    fovCircle.Color = fovColor

    if aimbotEnabled then
        local target = getTarget()
        if target and target.Character then
            local partName = headshotOnly and "Head" or targetPart
            local part = target.Character:FindFirstChild(partName)
            if part then
                if autowallEnabled then
                    local ray = Ray.new(Camera.CFrame.Position, (part.Position - Camera.CFrame.Position).Unit * 1000)
                    local hit = workspace:FindPartOnRay(ray, LocalPlayer.Character)
                    if hit and not target.Character:IsAncestorOf(hit) then return end
                end

                local predicted = part.Position + (part.Velocity * predictionStrength)
                local dir = (predicted - Camera.CFrame.Position).Unit
                local newCF = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + dir)
                Camera.CFrame = recoilControlEnabled and Camera.CFrame:Lerp(newCF, aimSmoothness / 10) or newCF

                -- Triggerbot (fires automatically when target is locked)
                if triggerbotEnabled and target then
                    mouse1press()  -- Automatically press the mouse1 button
                    task.wait(0.05)  -- Small delay to simulate actual shooting time
                    mouse1release()  -- Release the mouse1 button
                end
            end
        end
    end
end)

-- UI Controls
Tab:CreateToggle({ Name = "Enable Aimbot", CurrentValue = false, Callback = function(v) aimbotEnabled = v end }, "AimbotEnabled")
Tab:CreateToggle({ Name = "Sticky Lock", CurrentValue = false, Callback = function(v) stickyLock = v end }, "StickyLockEnabled")
Tab:CreateToggle({ Name = "Team Check", CurrentValue = false, Callback = function(v) teamCheck = v end }, "TeamCheckEnabled")
Tab:CreateToggle({ Name = "Use Mouse Target", CurrentValue = false, Callback = function(v) useMouseTarget = v end }, "UseMouseTargetEnabled")
Tab:CreateToggle({ Name = "Show FOV Circle", CurrentValue = false, Callback = function(v) showFOV = v end }, "ShowFOVCircleEnabled")

-- New Feature Toggles
Tab:CreateToggle({ Name = "Triggerbot", CurrentValue = false, Callback = function(v) triggerbotEnabled = v end }, "TriggerbotEnabled")
Tab:CreateToggle({ Name = "Auto-Wall (Raycast)", CurrentValue = false, Callback = function(v) autowallEnabled = v end }, "Auto-WallEnabled")
Tab:CreateToggle({ Name = "Recoil Control System", CurrentValue = false, Callback = function(v) recoilControlEnabled = v end }, "RecoilControlSystemEnabledd")
Tab:CreateToggle({ Name = "Headshot-Only Mode", CurrentValue = false, Callback = function(v) headshotOnly = v end }, "Headshot-OnlyModeEnabled")

-- Dropdowns & Sliders
Tab:CreateDropdown({
    Name = "Aim Priority",
    Options = {"Closest", "Lowest HP", "Random"},
    CurrentOption = "Closest",
    Callback = function(opt) aimPriority = opt end
})

Tab:CreateDropdown({
    Name = "Target Bone",
    Options = {"Head", "HumanoidRootPart"},
    CurrentOption = "HumanoidRootPart",
    Callback = function(opt) targetPart = opt end
})

Tab:CreateSlider({ Name = "FOV Radius", Range = {50, 500}, Increment = 10, CurrentValue = 100, Callback = function(val) aimbotRadius = val end }, "FOVRadius")
Tab:CreateSlider({ Name = "Aimbot Smoothness", Range = {1, 10}, Increment = 1, CurrentValue = 5, Callback = function(val) aimSmoothness = val end }, " AimbotSmoothness")
Tab:CreateSlider({ Name = "Prediction Strength", Range = {0, 0.3}, Increment = 0.005, CurrentValue = 0.165, Callback = function(val) predictionStrength = val end }, "PredictionStrength")

-- Color Picker
Tab:CreateColorPicker({
    Name = "FOV Circle Color",
    Default = Color3.fromRGB(255, 0, 0),
    Flag = "FovCircleColor",
    Callback = function(newColor) fovColor = newColor end
})

-- Create Visuals Tab
local VisualsTab = Window:CreateTab({ Name = "Visuals", Icon = "visibility", ImageSource = "Material", ShowTitle = true })
VisualsTab:CreateSection("ESP")

-- ESP Variables
local espEnabled = false
local boxEnabled = true
local tracerEnabled = true
local nameTagEnabled = true
local healthBarEnabled = true
local teamCheckEsp = false
local teamColorSync = false
local espColor = Color3.fromRGB(0, 255, 0)
local maxDistance = 500
local playerDrawings = {}

-- Cleanup previous ESP drawings
local function cleanupESPDrawings()
    for _, drawings in pairs(playerDrawings) do
        for _, drawing in pairs(drawings) do
            drawing.Visible = false
        end
        table.clear(drawings)
    end
end

-- ESP Drawing Logic
local function drawESP(target)
    if not playerDrawings[target] then
        playerDrawings[target] = {}
    end

    local drawings = playerDrawings[target]
    table.clear(drawings)

    local character = target.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
    if not onScreen then return end

    local distance = (Camera.CFrame.Position - hrp.Position).Magnitude
    if distance > maxDistance then return end

    -- Draw Hitbox Box
    if boxEnabled then
        local size = hrp.Size
        local corners = {
            Vector3.new(-size.X/2, size.Y/2, 0),
            Vector3.new(size.X/2, size.Y/2, 0),
            Vector3.new(size.X/2, -size.Y/2, 0),
            Vector3.new(-size.X/2, -size.Y/2, 0),
        }

        local screenCorners = {}
        for _, offset in ipairs(corners) do
            local world = hrp.CFrame:ToWorldSpace(CFrame.new(offset)).Position
            local screen, visible = Camera:WorldToViewportPoint(world)
            if not visible then return end
            table.insert(screenCorners, screen)
        end

        for i = 1, 4 do
            local j = (i % 4) + 1
            local line = Drawing.new("Line")
            line.From = Vector2.new(screenCorners[i].X, screenCorners[i].Y)
            line.To = Vector2.new(screenCorners[j].X, screenCorners[j].Y)
            line.Color = teamColorSync and (target.TeamColor and target.TeamColor.Color) or espColor
            line.Thickness = 2
            line.Visible = true
            table.insert(drawings, line)
        end
    end

    -- Name Tag
    if nameTagEnabled then
        local nameTag = Drawing.new("Text")
        nameTag.Text = target.DisplayName
        nameTag.Position = Vector2.new(screenPos.X, screenPos.Y - 30)
        nameTag.Size = 16
        nameTag.Center = true
        nameTag.Outline = true
        nameTag.Color = teamColorSync and (target.TeamColor and target.TeamColor.Color) or espColor
        nameTag.Visible = true
        table.insert(drawings, nameTag)
    end

    -- Tracer
    if tracerEnabled then
        local tracer = Drawing.new("Line")
        tracer.Color = teamColorSync and (target.TeamColor and target.TeamColor.Color) or espColor
        tracer.Thickness = 1
        tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
        tracer.To = Vector2.new(screenPos.X, screenPos.Y)
        tracer.Visible = true
        table.insert(drawings, tracer)
    end

    -- Health Bar
    if healthBarEnabled then
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            local healthRatio = humanoid.Health / humanoid.MaxHealth
            local barHeight = 60
            local barY = screenPos.Y - barHeight / 2
            local barX = screenPos.X - 40

            local background = Drawing.new("Line")
            background.From = Vector2.new(barX - 6, barY)
            background.To = Vector2.new(barX - 6, barY + barHeight)
            background.Thickness = 4
            background.Color = Color3.fromRGB(0, 0, 0)
            background.Visible = true
            table.insert(drawings, background)

            local healthBar = Drawing.new("Line")
            healthBar.From = Vector2.new(barX - 6, barY + barHeight * (1 - healthRatio))
            healthBar.To = Vector2.new(barX - 6, barY + barHeight)
            healthBar.Thickness = 3
            healthBar.Color = Color3.fromRGB(0, 255, 0)
            healthBar.Visible = true
            table.insert(drawings, healthBar)
        end
    end
end

-- RenderStep ESP loop
RunService.RenderStepped:Connect(function()
    cleanupESPDrawings()

    if espEnabled then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                if not teamCheckEsp or player.Team ~= LocalPlayer.Team then
                    drawESP(player)
                end
            end
        end
    end
end)

-- UI Toggles
VisualsTab:CreateToggle({ Name = "Enable ESP", CurrentValue = false, Callback = function(v) espEnabled = v end }, "EnabledEsp")
VisualsTab:CreateToggle({ Name = "Draw Boxes", CurrentValue = true, Callback = function(v) boxEnabled = v end }, "DrawBoxesEnabled")
VisualsTab:CreateToggle({ Name = "Draw Tracers", CurrentValue = true, Callback = function(v) tracerEnabled = v end }, "DrawTracersEnabled")
VisualsTab:CreateToggle({ Name = "Show Name Tags", CurrentValue = true, Callback = function(v) nameTagEnabled = v end }, "ShowNameTagsEnabled")
VisualsTab:CreateToggle({ Name = "Show Health Bars", CurrentValue = true, Callback = function(v) healthBarEnabled = v end }, "ShowHealthBarsEnabled")
VisualsTab:CreateToggle({ Name = "ESP Team Check", CurrentValue = false, Callback = function(v) teamCheckEsp = v end }, "EspTeamCheckEnabled")

-- ESP Color Picker
VisualsTab:CreateColorPicker({
    Name = "ESP Color",
    Default = Color3.fromRGB(0, 255, 0),
    Flag = "EspColor",
    Callback = function(newColor)
        espColor = newColor
    end
})

-- Max Distance Slider
VisualsTab:CreateSlider({
    Name = "Max ESP Distance",
    Range = {50, 1000},
    Increment = 50,
    CurrentValue = 500,
    Flag = "MaxEspDistance",
    Callback = function(val)
        maxDistance = val
    end
})

VisualsTab:CreateToggle({
    Name = "Sync ESP with Team Color",
    CurrentValue = false,
    Flag = "SynceEspWithTeamColor",
    Callback = function(v)
        teamColorSync = v
    end
})

-- Third Person Toggle
local thirdPersonEnabled = false
local thirdPersonDistance = 10

RunService.RenderStepped:Connect(function()
    if thirdPersonEnabled then
        Camera.CameraSubject = LocalPlayer.Character.Humanoid
        Camera.CameraType = Enum.CameraType.Scriptable
        local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root then
            local behind = root.CFrame.Position - root.CFrame.LookVector * thirdPersonDistance + Vector3.new(0, 2, 0)
            Camera.CFrame = CFrame.new(behind, root.Position + Vector3.new(0, 2, 0))
        end
    end
end)

VisualsTab:CreateToggle({
    Name = "Third Person View",
    CurrentValue = false,
    FLag = "ThirdPersonView",
    Callback = function(val)
        thirdPersonEnabled = val
        Camera.CameraType = val and Enum.CameraType.Scriptable or Enum.CameraType.Custom
    end
})

-- Radar Configuration
local radarEnabled = true
local radarSize = 150
local radarPosition = Vector2.new(50, 50)
local radarMaxDistance = 500
local radarTeamCheck = false
local radarPlayerDots = {}
local radarFrame = Drawing.new("Square")
local localPlayerDot = Drawing.new("Circle")

-- Initialize Radar Frame
radarFrame.Filled = true
radarFrame.Transparency = 0.4
radarFrame.Color = Color3.fromRGB(20, 20, 20)
radarFrame.Position = radarPosition
radarFrame.Size = Vector2.new(radarSize, radarSize)
radarFrame.Visible = false

-- Initialize Local Player Dot
localPlayerDot.Radius = 3
localPlayerDot.Filled = true
localPlayerDot.Color = Color3.fromRGB(255, 255, 255)
localPlayerDot.Visible = false

-- Radar Update Logic
RunService.RenderStepped:Connect(function()
    -- Cleanup previous dots
    for _, dot in pairs(radarPlayerDots) do
        dot.Visible = false
    end

    if not radarEnabled then
        radarFrame.Visible = false
        localPlayerDot.Visible = false
        return
    end

    radarFrame.Visible = true

    local lpCharacter = LocalPlayer.Character
    if not lpCharacter or not lpCharacter:FindFirstChild("HumanoidRootPart") then return end
    local lpHRP = lpCharacter.HumanoidRootPart
    local forward = lpHRP.CFrame.LookVector

    -- Draw local player dot in center
    localPlayerDot.Position = radarFrame.Position + Vector2.new(radarSize / 2, radarSize / 2)
    localPlayerDot.Visible = true

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            if radarTeamCheck and player.Team == LocalPlayer.Team then continue end

            local hrp = player.Character.HumanoidRootPart
            local offset = hrp.Position - lpHRP.Position
            local distance = offset.Magnitude
            if distance > radarMaxDistance then continue end

            local relative = Vector3.new(offset.X, 0, offset.Z)
            local angle = math.atan2(forward.X, forward.Z)
            local rotatedX = relative.X * math.cos(-angle) - relative.Z * math.sin(-angle)
            local rotatedZ = relative.X * math.sin(-angle) + relative.Z * math.cos(-angle)

            local scaledX = math.clamp(rotatedX / radarMaxDistance * (radarSize / 2), -radarSize / 2, radarSize / 2)
            local scaledY = math.clamp(rotatedZ / radarMaxDistance * (radarSize / 2), -radarSize / 2, radarSize / 2)

            local dot = radarPlayerDots[player] or Drawing.new("Circle")
            dot.Position = radarFrame.Position + Vector2.new(radarSize / 2 + scaledX, radarSize / 2 + scaledY)
            dot.Radius = 3
            dot.Filled = true
            dot.Color = radarTeamCheck and player.TeamColor.Color or Color3.fromRGB(255, 0, 0)
            dot.Visible = true

            radarPlayerDots[player] = dot
        end
    end
end)


VisualsTab:CreateToggle({
    Name = "Enable Radar",
    CurrentValue = true,
    Flag = "EnableRadar",
    Callback = function(value)
        radarEnabled = value
    end
})

VisualsTab:CreateSlider({
    Name = "Radar Size",
    Range = {100, 300},
    Increment = 10,
    CurrentValue = 150,
    Flag = "RadarSize",
    Callback = function(value)
        radarSize = value
        radarFrame.Size = Vector2.new(value, value)
    end
})

VisualsTab:CreateSlider({
    Name = "Radar Range",
    Range = {100, 1000},
    Increment = 50,
    CurrentValue = 500,
    Flag = "RadarRange",
    Callback = function(value)
        radarMaxDistance = value
    end
})

VisualsTab:CreateToggle({
    Name = "Radar Team Check",
    CurrentValue = false,
    Flag = "RadarTeamCheck",
    Callback = function(value)
        radarTeamCheck = value
    end
})

-- Create Movement Tab
local MovementTab = Window:CreateTab({ Name = "Movement", Icon = "directions_walk", ImageSource = "Material", ShowTitle = true })
MovementTab:CreateSection("Movement Features")

-- Services and Player Setup
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- Flight Mode
local flying = false
local flySpeed = 100
local maxFlySpeed = 1000
local speedIncrement = 0.4
local originalGravity = workspace.Gravity

-- Noclip & Infinite Jump
local noclipEnabled = false
local infiniteJumpEnabled = false
local InfJumpConnection = nil

-- Update Character on Respawn
LocalPlayer.CharacterAdded:Connect(function(newCharacter)
    Character = newCharacter
    Humanoid = Character:WaitForChild("Humanoid")
    HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
end)

-- Randomized Speed Function
local function randomizeValue(value, range)
    return value + (value * (math.random(-range, range) / 100))
end

-- Flight Logic
local function fly()
    while flying do
        local MoveDirection = Vector3.new()
        local cameraCFrame = workspace.CurrentCamera.CFrame

        MoveDirection = MoveDirection + (UserInputService:IsKeyDown(Enum.KeyCode.W) and cameraCFrame.LookVector or Vector3.new())
        MoveDirection = MoveDirection - (UserInputService:IsKeyDown(Enum.KeyCode.S) and cameraCFrame.LookVector or Vector3.new())
        MoveDirection = MoveDirection - (UserInputService:IsKeyDown(Enum.KeyCode.A) and cameraCFrame.RightVector or Vector3.new())
        MoveDirection = MoveDirection + (UserInputService:IsKeyDown(Enum.KeyCode.D) and cameraCFrame.RightVector or Vector3.new())
        MoveDirection = MoveDirection + (UserInputService:IsKeyDown(Enum.KeyCode.Space) and Vector3.new(0, 1, 0) or Vector3.new())
        MoveDirection = MoveDirection - (UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) and Vector3.new(0, 1, 0) or Vector3.new())

        if MoveDirection.Magnitude > 0 then
            flySpeed = math.min(flySpeed + speedIncrement, maxFlySpeed) 
            MoveDirection = MoveDirection.Unit * math.min(randomizeValue(flySpeed, 10), maxFlySpeed)
            HumanoidRootPart.Velocity = MoveDirection * 0.5
        else
            HumanoidRootPart.Velocity = Vector3.new(0, 0, 0) 
        end

        RunService.RenderStepped:Wait() 
    end
end

-- Toggle Flight
local function toggleFlightMode()
    flying = not flying
    if flying then
        workspace.Gravity = 0
        fly()
    else
        flySpeed = 100
        HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
        workspace.Gravity = originalGravity
    end
end

-- Toggle Noclip
local function toggleNoclip()
    noclipEnabled = not noclipEnabled
end

-- Toggle Infinite Jump
local function toggleInfiniteJump()
    infiniteJumpEnabled = not infiniteJumpEnabled

    if infiniteJumpEnabled then
        InfJumpConnection = UserInputService.JumpRequest:Connect(function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    elseif InfJumpConnection then
        InfJumpConnection:Disconnect()
        InfJumpConnection = nil
    end
end

-- Noclip + Flight in RenderStepped
RunService.RenderStepped:Connect(function()
    if noclipEnabled and Character then
        for _, part in ipairs(Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
end)

-- UI Toggles
MovementTab:CreateToggle({
    Name = "Flight Mode",
    CurrentValue = false,
    Flag = "FlightMode",
    Callback = function(v)
        toggleFlightMode()
    end
})

MovementTab:CreateSlider({
    Name = "Flight Speed",
    Range = {50, 200},
    Increment = 10,
    CurrentValue = flySpeed,
    Flag = "FlightSpeed",
    Callback = function(val)
        flySpeed = val
    end
})

MovementTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Flag = "Noclip",
    Callback = function(v)
        toggleNoclip()
    end
})

MovementTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Flag = "InfiniteJump",
    Callback = function(v)
        toggleInfiniteJump()
    end
})


-- Speed Slider
local currentSpeed = 16

MovementTab:CreateSlider({
    Name = "Walk Speed",
    Range = {16, 200},
    Increment = 1,
    CurrentValue = currentSpeed,
    Flag = "WalkSpeed",
    Callback = function(value)
        currentSpeed = value
        local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = value
        end
    end
})

-- Jump Power Slider
local currentJumpPower = 50

MovementTab:CreateSlider({
    Name = "Jump Power",
    Range = {50, 200},
    Increment = 1,
    CurrentValue = currentJumpPower,
    Flag = "JumpPower",
    Callback = function(value)
        currentJumpPower = value
        local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.JumpPower = value
        end
    end
})

local SilentAimEnabled = false
local SilentAimFOV = 150
local SilentAimHitChance = 100
local SilentAimTargetPart = "Head"
local SilentAimTeamCheck = true
local SilentAimWallCheck = true

local CurrentTarget = nil
local HighlightFolder = Instance.new("Folder", game.CoreGui)
HighlightFolder.Name = "SilentAimHighlights"

local function GetClosestPlayer()
    local players = game:GetService("Players"):GetPlayers()
    local camera = workspace.CurrentCamera
    local closest = nil
    local closestDist = SilentAimFOV

    for _, player in ipairs(players) do
        if player ~= game.Players.LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            if SilentAimTeamCheck and player.Team == game.Players.LocalPlayer.Team then
                continue
            end

            local pos, onScreen = camera:WorldToViewportPoint(player.Character.HumanoidRootPart.Position)
            if onScreen then
                local mousePos = game:GetService("UserInputService"):GetMouseLocation()
                local dist = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                if dist < closestDist then
                    if SilentAimWallCheck then
                        local ray = workspace:Raycast(camera.CFrame.Position, (player.Character.HumanoidRootPart.Position - camera.CFrame.Position).Unit * 999, {game.Players.LocalPlayer.Character})
                        if ray and ray.Instance and not player.Character:IsAncestorOf(ray.Instance) then
                            continue
                        end
                    end
                    closestDist = dist
                    closest = player
                end
            end
        end
    end

    return closest
end

-- Update Highlight
local function UpdateHighlight(target)
    HighlightFolder:ClearAllChildren()
    if target and target.Character then
        local highlight = Instance.new("Highlight")
        highlight.Parent = HighlightFolder
        highlight.Adornee = target.Character
        highlight.FillColor = Color3.fromRGB(255, 0, 0)
        highlight.FillTransparency = 0.5
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.OutlineTransparency = 0
    end
end

-- Hook shot detection
local oldIndex
oldIndex = hookmetamethod(game, "__index", function(self, key)
    if SilentAimEnabled and tostring(self) == "Mouse" and (key == "Hit" or key == "Target") then
        if math.random(0,100) <= SilentAimHitChance then
            local target = GetClosestPlayer()
            if target and target.Character and target.Character:FindFirstChild(SilentAimTargetPart) then
                UpdateHighlight(target)
                CurrentTarget = target
                return target.Character[SilentAimTargetPart].CFrame
            end
        end
    end
    return oldIndex(self, key)
end)

-- Main Loop
game:GetService("RunService").RenderStepped:Connect(function()
    if SilentAimEnabled then
        local target = GetClosestPlayer()
        if target ~= CurrentTarget then
            UpdateHighlight(target)
            CurrentTarget = target
        end
    else
        HighlightFolder:ClearAllChildren()
    end
end)

Tab:CreateToggle({
    Name = "Silent Aim",
    CurrentValue = false,
    Callback = function(Value)
        SilentAimEnabled = Value
    end,
})

Tab:CreateSlider({
    Name = "Silent Aim FOV",
    Range = {0, 500},
    Increment = 1,
    CurrentValue = 150,
    Flag = "SilentAimFov",
    Callback = function(Value)
        SilentAimFOV = Value
    end,
})

Tab:CreateSlider({
    Name = "Hit Chance %",
    Range = {0, 100},
    Increment = 1,
    CurrentValue = 100,
    Flag = "HitChance%",
    Callback = function(Value)
        SilentAimHitChance = Value
    end,
})

Tab:CreateDropdown({
    Name = "Silent Aim Target Part",
    Options = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"},
    CurrentOption = "Head",
    Flag = "SilentAimTargetPart",
    Callback = function(Value)
        SilentAimTargetPart = Value
    end,
})

Tab:CreateToggle({
    Name = "Silent Aim Team Check",
    CurrentValue = true,
    Flag = "SilentAimTeamCheck",
    Callback = function(Value)
        SilentAimTeamCheck = Value
    end,
})

Tab:CreateToggle({
    Name = "Silent Aim Wall Check",
    CurrentValue = true,
    Flag = "SilentAimWallCheck",
    Callback = function(Value)
        SilentAimWallCheck = Value
    end,
})

-- =======================
-- **Main Tab Additions (Combat Section)**
-- =======================

-- Instant Hit Toggle
local instanthittoggle = Tab:CreateToggle{
    Name = "Instant Hit",
    Default = false,
    Flag = "InstantHit",
    Callback = function(Value)
        getgenv().InstantHit = Value
    end
}

-- Silent Aim FOV Slider
Tab:CreateSlider{
    Name = "Silent Aim FOV Radius",
    Min = 10,
    Max = 500,
    Default = 150,
    Flag = "SilentAimFovRadius",
    Callback = function(Value)
        getgenv().SilentAimFOV = Value
    end
}

-- Advanced Triggerbot
Tab:CreateToggle{
    Name = "Enable Advanced Triggerbot",
    Default = false,
    Flag = "EnableAdvancedTriggerbot",
    Callback = function(Value)
        getgenv().AdvancedTriggerbotEnabled = Value
    end
}

Tab:CreateSlider{
    Name = "Triggerbot Hit Chance (%)",
    Min = 1,
    Max = 100,
    Default = 80,
    Flag = "TriggerbotHitChance%",
    Callback = function(Value)
        getgenv().TriggerbotHitChance = Value
    end
}

-- =======================
-- **Visual Tab Additions (Drawing Section)**
-- =======================

-- Bullet Tracer Lines
local bullettracerlines = VisualsTab:CreateToggle({
    Name = "Bullet Tracer Lines",
    Default = false,
    Flag = "BulletTracerLines",
    Callback = function(Value)
        getgenv().BulletTracersEnabled = Value
    end
})

local bullettracercolorpicker = VisualsTab:CreateColorPicker({
    Name = "Bullet Tracer Color",
    Default = Color3.fromRGB(255, 0, 0),
    Flag = "BulletTracerColor",
    Callback = function(Value)
        getgenv().BulletTracerColor = Value
    end
})

-- Bullet Impact Markers
local bulletimpactmarkers = VisualsTab:CreateToggle({
    Name = "Bullet Impact Markers",
    Default = false,
    Flag = "BulletImpactMarkers",
    Callback = function(Value)
        getgenv().ImpactMarkersEnabled = Value
    end
})

local impactmarkercolor = VisualsTab:CreateColorPicker({
    Name = "Impact Marker Color",
    Default = Color3.fromRGB(255, 255, 0),
    Flag = "ImpactMarkerColor",
    Callback = function(Value)
        getgenv().ImpactMarkerColor = Value
    end
})

-- =======================
-- **Backend Logic**
-- =======================

-- Instant Hit Logic
game:GetService("RunService").Heartbeat:Connect(function()
    if getgenv().InstantHit then
        -- Assuming you have a function that handles shooting bullets
        -- instantly hit the target with a bullet (adjust target detection logic)
        if target then
            bullet.Position = target.Position -- instant hit
        end
    end
end)

-- Silent Aim Logic
game:GetService("RunService").Heartbeat:Connect(function()
    if getgenv().SilentAimFOV and target then
        -- Silent aim: check if target is within the FOV and lock bullet
        local targetDistance = (target.Position - workspace.CurrentCamera.CFrame.Position).Magnitude
        if targetDistance <= getgenv().SilentAimFOV then
            -- lock the bullet to the target
            -- (implement your actual bullet tracking logic here)
        end
    end
end)

-- Advanced Triggerbot Logic
game:GetService("RunService").Heartbeat:Connect(function()
    if getgenv().AdvancedTriggerbotEnabled then
        -- Example: Triggerbot shoots if hit chance is met
        local chance = math.random(1, 100)
        if chance <= getgenv().TriggerbotHitChance then
            -- shoot (triggerbot activation logic)
        end
    end
end)

-- Bullet Tracer Lines Logic
game:GetService("RunService").Heartbeat:Connect(function()
    if getgenv().BulletTracersEnabled then
        -- Assuming you have logic to track bullet position (shooting)
        local tracer = Drawing.new("Line")
        tracer.Color = getgenv().BulletTracerColor
        tracer.Thickness = 2
        tracer.From = bulletStart.Position
        tracer.To = bulletEnd.Position
        tracer.Visible = true
        task.delay(0.5, function()
            tracer:Remove()  -- remove tracer after 0.5 seconds
        end)
    end
end)

-- Variables
local player = game.Players.LocalPlayer
local camera = workspace.CurrentCamera
local mouse = player:GetMouse()
local bulletRange = 1000 -- Maximum distance for the bullet

-- Variables
local player = game.Players.LocalPlayer
local camera = workspace.CurrentCamera
local mouse = player:GetMouse()
local bulletRange = 1000 -- Maximum distance for the bullet

-- Create an impact marker (for showing where the bullet hits)
local function createImpactMarker(position)
    local impactMarker = Instance.new("Part")
    impactMarker.Shape = Enum.PartType.Ball
    impactMarker.Size = Vector3.new(0.5, 0.5, 0.5) -- Size of the impact marker
    impactMarker.Position = position
    impactMarker.Anchored = true
    impactMarker.CanCollide = false
    impactMarker.BrickColor = BrickColor.new("Bright red") -- Color of impact marker
    impactMarker.Parent = workspace
    game.Debris:AddItem(impactMarker, 2) -- Clean up after 2 seconds
end

-- Function to calculate and handle bullet impact
local function fireBullet()
    local startPosition = camera.CFrame.Position
    local direction = (mouse.Hit.p - startPosition).unit * bulletRange -- The direction in which the bullet will travel
    
    -- Raycast to detect the impact position
    local ray = Ray.new(startPosition, direction)
    local hit, position = workspace:FindPartOnRay(ray, player.Character, false, true)
    
    if hit then
        -- If the ray hits something, create an impact marker at the hit position
        createImpactMarker(position)
        
        -- Handle the logic for bullet impact (e.g., apply damage, effects, etc.)
        print("Bullet hit at position: " .. tostring(position))
    else
        print("No hit, bullet traveled to max range.")
    end
end

-- Simulate firing the bullet when the player clicks the mouse
mouse.Button1Down:Connect(function()
    fireBullet()
end)


-- Create an impact marker (for showing where the bullet hits)
local function createImpactMarker(position)
    local impactMarker = Instance.new("Part")
    impactMarker.Shape = Enum.PartType.Ball
    impactMarker.Size = Vector2.new(0.5, 0.5, 0.5) -- Size of the impact marker
    impactMarker.Position = position
    impactMarker.Anchored = true
    impactMarker.CanCollide = false
    impactMarker.BrickColor = BrickColor.new("Bright red") -- Color of impact marker
    impactMarker.Parent = workspace
    game.Debris:AddItem(impactMarker, 2) -- Clean up after 2 seconds
end

-- Bullet Impact Markers Logic
game:GetService("RunService").Heartbeat:Connect(function()
    if getgenv().ImpactMarkersEnabled then
        -- Example impact position (adjust to match your game logic)
        local marker = Drawing.new("Circle")
        marker.Color = getgenv().ImpactMarkerColor
        marker.Position = impactPosition  -- Assuming you have this value
        marker.Radius = 5
        marker.Visible = true
        task.delay(1, function()
            marker:Remove()  -- remove marker after 1 second
        end)
    end
end)

MovementTab:CreateToggle{
    Name = "Gravity Control",
    Default = false,
    Flag = "GravityControl",
    Callback = function(Value)
        getgenv().GravityControlEnabled = Value
        if Value then
            workspace.Gravity = 10 -- change this value as needed for a lower gravity
        else
            workspace.Gravity = 196.2 -- default gravity
        end
    end
}

MovementTab:CreateSlider{
    Name = "Gravity Strength",
    Min = 1,
    Max = 50,
    Default = 10,
    Flag = "GravityStregth",
    Callback = function(Value)
        if getgenv().GravityControlEnabled then
            workspace.Gravity = Value
        end
    end
}

MovementTab:CreateToggle{
    Name = "Enable Teleportation",
    Default = false,
    Flag = "EnableTeleportation",
    Callback = function(Value)
        getgenv().TeleportEnabled = Value
    end
}

MovementTab:CreateBind{
    Name = "Teleport Key",
    Default = Enum.KeyCode.LeftControl,
    Flag = "TeleportKey",
    Callback = function()
        if getgenv().TeleportEnabled then
            local mousePos = game:GetService("Players").LocalPlayer:GetMouse().Hit.Position
            game:GetService("Players").LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(mousePos)
        end
    end
}

local SettingsTab = Window:CreateTab({ Name = "Settings", Icon = "settings", ImageSource = "Material", ShowTitle = true })

SettingsTab:BuildConfigSection() -- Tab Should be the name of the tab you are adding this section to.

-- Load config
Luna:LoadAutoloadConfig()
