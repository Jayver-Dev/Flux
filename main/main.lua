-- Load Luna Interface
local Luna = loadstring(game:HttpGet("https://raw.githubusercontent.com/Nebula-Softworks/Luna-Interface-Suite/refs/heads/main/source.lua", true))()

-- Create Main Window
local Window = Luna:CreateWindow({
    Name = "Laker Hub",
    Subtitle = "Kurt Cobain POV",
    LoadingEnabled = true,
    LoadingTitle = "Laker Hub",
    LoadingSubtitle = "by @j4y11",
    ConfigSettings = { ConfigFolder = "Laker Hub" }
})

-- Create Tab
local Tab = Window:CreateTab({ Name = "Main", Icon = "dashboard", ImageSource = "Material", ShowTitle = true })
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
Tab:CreateToggle({ Name = "Enable Aimbot", CurrentValue = false, Callback = function(v) aimbotEnabled = v end })
Tab:CreateToggle({ Name = "Sticky Lock", CurrentValue = false, Callback = function(v) stickyLock = v end })
Tab:CreateToggle({ Name = "Team Check", CurrentValue = false, Callback = function(v) teamCheck = v end })
Tab:CreateToggle({ Name = "Use Mouse Target", CurrentValue = false, Callback = function(v) useMouseTarget = v end })
Tab:CreateToggle({ Name = "Show FOV Circle", CurrentValue = false, Callback = function(v) showFOV = v end })

-- New Feature Toggles
Tab:CreateToggle({ Name = "Triggerbot", CurrentValue = false, Callback = function(v) triggerbotEnabled = v end })
Tab:CreateToggle({ Name = "Auto-Wall (Raycast)", CurrentValue = false, Callback = function(v) autowallEnabled = v end })
Tab:CreateToggle({ Name = "Recoil Control System", CurrentValue = false, Callback = function(v) recoilControlEnabled = v end })
Tab:CreateToggle({ Name = "Headshot-Only Mode", CurrentValue = false, Callback = function(v) headshotOnly = v end })

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

Tab:CreateSlider({ Name = "FOV Radius", Range = {50, 500}, Increment = 10, CurrentValue = 100, Callback = function(val) aimbotRadius = val end })
Tab:CreateSlider({ Name = "Aimbot Smoothness", Range = {1, 10}, Increment = 1, CurrentValue = 5, Callback = function(val) aimSmoothness = val end })
Tab:CreateSlider({ Name = "Prediction Strength", Range = {0, 0.3}, Increment = 0.005, CurrentValue = 0.165, Callback = function(val) predictionStrength = val end })

-- Color Picker
Tab:CreateColorPicker({
    Name = "FOV Circle Color",
    Default = Color3.fromRGB(255, 0, 0),
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
            healthBar.Color = Color3.fromRGB(0, 0, 255)
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
VisualsTab:CreateToggle({ Name = "Enable ESP", CurrentValue = false, Callback = function(v) espEnabled = v end })
VisualsTab:CreateToggle({ Name = "Draw Boxes", CurrentValue = true, Callback = function(v) boxEnabled = v end })
VisualsTab:CreateToggle({ Name = "Draw Tracers", CurrentValue = true, Callback = function(v) tracerEnabled = v end })
VisualsTab:CreateToggle({ Name = "Show Name Tags", CurrentValue = true, Callback = function(v) nameTagEnabled = v end })
VisualsTab:CreateToggle({ Name = "Show Health Bars", CurrentValue = true, Callback = function(v) healthBarEnabled = v end })
VisualsTab:CreateToggle({ Name = "ESP Team Check", CurrentValue = false, Callback = function(v) teamCheckEsp = v end })

-- ESP Color Picker
VisualsTab:CreateColorPicker({
    Name = "ESP Color",
    Default = Color3.fromRGB(0, 255, 0),
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
    Callback = function(val)
        maxDistance = val
    end
})

VisualsTab:CreateToggle({
    Name = "Sync ESP with Team Color",
    CurrentValue = false,
    Callback = function(v)
        teamColorSync = v
    end
})


-- Load config
Luna:LoadAutoloadConfig()
