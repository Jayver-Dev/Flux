
local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'

local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

local Window = Library:CreateWindow({
    Title = 'Flux Shooter',
    Center = true,
    AutoShow = true,
})

local Tabs = {
    Main = Window:AddTab('Main'),
    Visuals = Window:AddTab('Visuals'),
    Movement = Window:AddTab('Movement'),
    Misc = Window:AddTab('Misc'),
    Settings = Window:AddTab('Settings'),
}

-- Create Tab


-- Services
local Players = game:GetService 'Players'
local RunService = game:GetService 'RunService'
local TweenService = game:GetService 'TweenService'
local TweenService = game:GetService 'TweenService'
local UserInputService = game:GetService 'UserInputService'
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Variables
local aimbotEnabled = false
local showFOV = false
local aimSmoothness = 5
local aimbotRadius = 100
local teamCheck = false
local targetPart = 'HumanoidRootPart'
local useMouseTarget = false
local predictionStrength = 0.165
local stickyLock = false
local currentTarget = nil
local aimPriority = 'Closest'
local fovColor = Color3.fromRGB(255, 0, 0)

-- New Features
local triggerbotEnabled = false
local autowallEnabled = false
local recoilControlEnabled = false
local headshotOnly = false

-- Drawing
local fovCircle = Drawing.new 'Circle'
fovCircle.Visible = false
fovCircle.Filled = false
fovCircle.Thickness = 1
fovCircle.Transparency = 0.5

-- Get Best Target
local function getTarget()
  local numericAimbotRadius = tonumber(aimbotRadius) or 1000
  local numericPredictionStrength = tonumber(predictionStrength) or 0

  if
    stickyLock
    and currentTarget
    and currentTarget.Character
    and currentTarget.Character:FindFirstChild 'Humanoid'
    and currentTarget.Character.Humanoid.Health > 0
  then
    return currentTarget
  end

  local bestTarget = nil
  local bestValue = math.huge
  local ref = useMouseTarget and UserInputService:GetMouseLocation()
    or Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

  for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild 'Humanoid' then
      local partText = headshotOnly and 'Head' or targetPart
      local part = player.Character:FindFirstChild(partName)
      local hp = player.Character.Humanoid.Health
      if not part or hp <= 0 then
        continue
      end
      if teamCheck and player.Team == LocalPlayer.Team then
        continue
      end

      local predicted = part.Position + (part.Velocity * numericPredictionStrength)
      local screenPos, onScreen = Camera:WorldToViewportPoint(predicted)
      if onScreen then
        local distance = (Vector2.new(screenPos.X, screenPos.Y) - ref).Magnitude
        if aimPriority == 'Closest' and distance < bestValue and distance <= numericAimbotRadius then
          bestTarget = player
          bestValue = distance
        elseif aimPriority == 'Lowest HP' and hp < bestValue then
          bestTarget = player
          bestValue = hp
        elseif aimPriority == 'Random' and math.random() < 0.05 then
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
  fovCircle.Position = useMouseTarget and UserInputService:GetMouseLocation()
    or Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
  fovCircle.Visible = showFOV
  fovCircle.Radius = aimbotRadius
  fovCircle.Color = fovColor

  if aimbotEnabled then
    local target = getTarget()
    if target and target.Character then
      local partText = headshotOnly and 'Head' or targetPart
      local part = target.Character:FindFirstChild(partName)
      if part then
        if autowallEnabled then
          local ray = Ray.new(Camera.CFrame.Position, (part.Position - Camera.CFrame.Position).Unit * 1000)
          local hit = workspace:FindPartOnRay(ray, LocalPlayer.Character)
          if hit and not target.Character:IsAncestorOf(hit) then
            return
          end
        end

        local predicted = part.Position + (part.Velocity * predictionStrength)
        local dir = (predicted - Camera.CFrame.Position).Unit
        local newCF = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + dir)
        Camera.CFrame = recoilControlEnabled and Camera.CFrame:Lerp(newCF, aimSmoothness / 10) or newCF

        -- Triggerbot (fires automatically when target is locked)
        if triggerbotEnabled and target then
          mouse1press() -- Automatically press the mouse1 button
          task.wait(0.05) -- Small delay to simulate actual shooting time
          mouse1release() -- Release the mouse1 button
        end
      end
    end
  end
end)

local AimbotBox = Tabs.Main:AddLeftGroupbox('Aimbot')


-- UI Controls
AimbotBox:AddToggle( "Enable Aimbot", {
  Text = 'Enable Aimbot',
  Default = false,
  Callback = function(v)
    aimbotEnabled = v
  end,
}, 'AimbotEnabled')
AimbotBox:AddToggle( "Stick Lock", {
  Text = 'Sticky Lock',
  Default = false,
  Callback = function(v)
    stickyLock = v
  end,
}, 'StickyLockEnabled')
AimbotBox:AddToggle( "Team Check", {
  Text = 'Team Check',
  Default = false,
  Callback = function(v)
    teamCheck = v
  end,
}, 'TeamCheckEnabled')
AimbotBox:AddToggle( "Use Mouse Target", {
  Text = 'Use Mouse Target',
  Default = false,
  Callback = function(v)
    useMouseTarget = v
  end,
}, 'UseMouseTargetEnabled')
AimbotBox:AddToggle( "Show FOV Circle", {
  Text = 'Show FOV Circle',
  Default = false,
  Callback = function(v)
    showFOV = v
  end,
}, 'ShowFOVCircleEnabled')

-- New Feature Toggles
AimbotBox:AddToggle( "Triggerbot", {
  Text = 'Triggerbot',
  Default = false,
  Callback = function(v)
    triggerbotEnabled = v
  end,
}, 'TriggerbotEnabled')
AimbotBox:AddToggle( "WallCheck", {
  Text = 'WallCheck (Raycast)',
  Default = false,
  Callback = function(v)
    autowallEnabled = v
  end,
}, 'WallCheckEnabled')
AimbotBox:AddToggle( "Recoil Control System", {
  Text = 'Recoil Control System',
  Default = false,
  Callback = function(v)
    recoilControlEnabled = v
  end,
}, 'RecoilControlSystemEnabledd')
AimbotBox:AddToggle( "Headshot-Only Mode", {
  Text = 'Headshot-Only Mode',
  Default = false,
  Callback = function(v)
    headshotOnly = v
  end,
}, 'Headshot-OnlyModeEnabled')

-- Dropdowns & Sliders
Main:AddDropdown ( "Aim Priority", {
  Text = 'Aim Priority',
  Options = { 'Closest', 'Lowest HP', 'Random' },
  Default = 1,
  Callback = function(opt)
    aimPriority = opt
  end,
})

Main:AddDropdown ( "Target Part", {
  Text = 'Target Bone',
  Options = { 'Head', 'HumanoidRootPart' },
  Default = 1,
  Callback = function(opt)
    targetPart = opt
  end,
})

Main:AddSlider( "FOV Radius",{
  Text = 'FOV Radius',
  Range = { 50, 500 },
  Increment = 10,
  Default = 100,
  Callback = function(val)
    aimbotRadius = val
  end,
}, 'FOVRadius')
Main:AddSlider( "FOV Circle Thickness",{0
  Text = 'Aimbot Smoothness',
  Range = { 1, 10 },
  Increment = 1,
  Default = 5,
  Callback = function(val)
    aimSmoothness = val
  end,
}, ' AimbotSmoothness')
Main:AddSlider( "Prediction Strength",{
  Text = 'Prediction Strength',
  Range = { 0, 0.3 },
  Increment = 0.005,
  Default = 0.165,
  Callback = function(val)
    predictionStrength = val
  end,
}, 'PredictionStrength')

-- Color Picker
Main:AddColorPicker ( "FOV Circle Color",{
  Text = 'FOV Circle Color',
  Default = Color3.fromRGB(255, 0, 0),
  Flag = 'FovCircleColor',
  Callback = function(newColor)
    fovColor = newColor
  end,
})

-- Create Visuals Tab
local EspBox = Tabs.Visuals:AddLeftGroupbox('Esp')


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
  if not character then
    return
  end
  local hrp = character:FindFirstChild 'HumanoidRootPart'
  if not hrp then
    return
  end

  local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
  if not onScreen then
    return
  end

  local distance = (Camera.CFrame.Position - hrp.Position).Magnitude
  if distance > maxDistance then
    return
  end

  -- Draw Hitbox Box
  if boxEnabled then
    local size = hrp.Size
    local corners = {
      Vector3.new(-size.X / 2, size.Y / 2, 0),
      Vector3.new(size.X / 2, size.Y / 2, 0),
      Vector3.new(size.X / 2, -size.Y / 2, 0),
      Vector3.new(-size.X / 2, -size.Y / 2, 0),
    }

    local screenCorners = {}
    for _, offset in ipairs(corners) do
      local world = hrp.CFrame:ToWorldSpace(CFrame.new(offset)).Position
      local screen, visible = Camera:WorldToViewportPoint(world)
      if not visible then
        return
      end
      table.insert(screenCorners, screen)
    end

    for i = 1, 4 do
      local j = (i % 4) + 1
      local line = Drawing.new 'Line'
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
    local nameTag = Drawing.new 'Text'
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
    local tracer = Drawing.new 'Line'
    tracer.Color = teamColorSync and (target.TeamColor and target.TeamColor.Color) or espColor
    tracer.Thickness = 1
    tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
    tracer.To = Vector2.new(screenPos.X, screenPos.Y)
    tracer.Visible = true
    table.insert(drawings, tracer)
  end

  -- Health Bar
  if healthBarEnabled then
    local humanoid = character:FindFirstChild 'Humanoid'
    if humanoid then
      local healthRatio = humanoid.Health / humanoid.MaxHealth
      local barHeight = 60
      local barY = screenPos.Y - barHeight / 2
      local barX = screenPos.X - 40

      local background = Drawing.new 'Line'
      background.From = Vector2.new(barX - 6, barY)
      background.To = Vector2.new(barX - 6, barY + barHeight)
      background.Thickness = 4
      background.Color = Color3.fromRGB(0, 0, 0)
      background.Visible = true
      table.insert(drawings, background)

      local healthBar = Drawing.new 'Line'
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
EspBox:AddToggle( ""Enable ESP", {
  Text = 'Enable ESP',
  Default = false,
  Callback = function(v)
    espEnabled = v
  end,
}, 'EnabledEsp')
EspBox:AddToggle( "Draw Boxes", {
  Text = 'Draw Boxes',
  Default = true,
  Callback = function(v)
    boxEnabled = v
  end,
}, 'DrawBoxesEnabled')
EspBox:AddToggle( "Draw Tracers", {
  Text = 'Draw Tracers',
  Default = true,
  Callback = function(v)
    tracerEnabled = v
  end,
}, 'DrawTracersEnabled')
EspBox:AddToggle( "Show Name Tags", {
  Text = 'Show Name Tags',
  Default = true,
  Callback = function(v)
    nameTagEnabled = v
  end,
}, 'ShowNameTagsEnabled')
EspBox:AddToggle( "Show Health Bars", {
  Text = 'Show Health Bars',
  Default = true,
  Callback = function(v)
    healthBarEnabled = v
  end,
}, 'ShowHealthBarsEnabled')
EspBox:AddToggle( "Team Check", {
  Text = 'ESP Team Check',
  Default = false,
  Callback = function(v)
    teamCheckEsp = v
  end,
}, 'EspTeamCheckEnabled')

-- ESP Color Picker
EspBox:AddColorPicker( "ESP Color", {
  Text = 'ESP Color',
  Default = Color3.fromRGB(0, 255, 0),
  Flag = 'EspColor',
  Callback = function(newColor)
    espColor = newColor
  end,
})

-- Max Distance Slider
EspBox:AddSlider( "Max ESP Distance", {
  Text = 'Max ESP Distance',
  Range = { 50, 1000 },
  Increment = 50,
  Default = 500,
  Flag = 'MaxEspDistance',
  Callback = function(val)
    maxDistance = val
  end,
})

EspBox:AddToggle( "Sync ESP with Team Color", {
  Text = 'Sync ESP with Team Color',
  Default = false,
  Flag = 'SynceEspWithTeamColor',
  Callback = function(v)
    teamColorSync = v
  end,
})

-- Third Person Toggle
local thirdPersonEnabled = false
local thirdPersonDistance = 10

RunService.RenderStepped:Connect(function()
  if thirdPersonEnabled then
    Camera.CameraSubject = LocalPlayer.Character.Humanoid
    Camera.CameraType = Enum.CameraType.Scriptable
    local root = LocalPlayer.Character:FindFirstChild 'HumanoidRootPart'
    if root then
      local behind = root.CFrame.Position - root.CFrame.LookVector * thirdPersonDistance + Vector3.new(0, 2, 0)
      Camera.CFrame = CFrame.new(behind, root.Position + Vector3.new(0, 2, 0))
    end
  end
end)

EspBox:AddToggle( "Third Person View", {
  Text = 'Third Person View',
  Default = false,
  FLag = 'ThirdPersonView',
  Callback = function(val)
    thirdPersonEnabled = val
    Camera.CameraType = val and Enum.CameraType.Scriptable or Enum.CameraType.Custom
  end,
}

-- Radar Configuration
local radarEnabled = true
local radarSize = 150
local radarPosition = Vector2.new(50, 50)
local radarMaxDistance = 500
local radarTeamCheck = false
local radarPlayerDots = {}
local radarFrame = Drawing.new 'Square'
local localPlayerDot = Drawing.new 'Circle'

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
  if not lpCharacter or not lpCharacter:FindFirstChild 'HumanoidRootPart' then
    return
  end
  local lpHRP = lpCharacter.HumanoidRootPart
  local forward = lpHRP.CFrame.LookVector

  -- Draw local player dot in center
  localPlayerDot.Position = radarFrame.Position + Vector2.new(radarSize / 2, radarSize / 2)
  localPlayerDot.Visible = true

  for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild 'HumanoidRootPart' then
      if radarTeamCheck and player.Team == LocalPlayer.Team then
        continue
      end

      local hrp = player.Character.HumanoidRootPart
      local offset = hrp.Position - lpHRP.Position
      local distance = offset.Magnitude
      if distance > radarMaxDistance then
        continue
      end

      local relative = Vector3.new(offset.X, 0, offset.Z)
      local angle = math.atan2(forward.X, forward.Z)
      local rotatedX = relative.X * math.cos(-angle) - relative.Z * math.sin(-angle)
      local rotatedZ = relative.X * math.sin(-angle) + relative.Z * math.cos(-angle)

      local scaledX = math.clamp(rotatedX / radarMaxDistance * (radarSize / 2), -radarSize / 2, radarSize / 2)
      local scaledY = math.clamp(rotatedZ / radarMaxDistance * (radarSize / 2), -radarSize / 2, radarSize / 2)

      local dot = radarPlayerDots[player] or Drawing.new 'Circle'
      dot.Position = radarFrame.Position + Vector2.new(radarSize / 2 + scaledX, radarSize / 2 + scaledY)
      dot.Radius = 3
      dot.Filled = true
      dot.Color = radarTeamCheck and player.TeamColor.Color or Color3.fromRGB(255, 0, 0)
      dot.Visible = true

      radarPlayerDots[player] = dot
    end
  end
end)

EspBox:AddToggle( "Enable Radar", {
  Text = 'Enable Radar',
  Default = false,
  Flag = 'EnableRadar',
  Callback = function(value)
    radarEnabled = value
  end,
})

EspBox:AddSlider( "Radar Size", {
  Text = 'Radar Size',
  Range = { 100, 300 },
  Increment = 10,
  Default = 150,
  Flag = 'RadarSize',
  Callback = function(value)
    radarSize = value
    radarFrame.Size = Vector2.new(value, value)
  end,
})

EspBox:AddSlider( "Radar Range", {
  Text = 'Radar Range',
  Range = { 100, 1000 },
  Increment = 50,
  Default = 500,
  Flag = 'RadarRange',
  Callback = function(value)
    radarMaxDistance = value
  end,
})

EspBox:AddToggle( "Radar Team Check", {
  Text = 'Radar Team Check',
  Default = false,
  Flag = 'RadarTeamCheck',
  Callback = function(value)
    radarTeamCheck = value
  end,
})


-- Services and Player Setup
local Players = game:GetService 'Players'
local RunService = game:GetService 'RunService'
local UserInputService = game:GetService 'UserInputService'

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild 'Humanoid'
local HumanoidRootPart = Character:WaitForChild 'HumanoidRootPart'

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
  Humanoid = Character:WaitForChild 'Humanoid'
  HumanoidRootPart = Character:WaitForChild 'HumanoidRootPart'
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

    MoveDirection = MoveDirection
      + (UserInputService:IsKeyDown(Enum.KeyCode.W) and cameraCFrame.LookVector or Vector3.new())
    MoveDirection = MoveDirection
      - (UserInputService:IsKeyDown(Enum.KeyCode.S) and cameraCFrame.LookVector or Vector3.new())
    MoveDirection = MoveDirection
      - (UserInputService:IsKeyDown(Enum.KeyCode.A) and cameraCFrame.RightVector or Vector3.new())
    MoveDirection = MoveDirection
      + (UserInputService:IsKeyDown(Enum.KeyCode.D) and cameraCFrame.RightVector or Vector3.new())
    MoveDirection = MoveDirection
      + (UserInputService:IsKeyDown(Enum.KeyCode.Space) and Vector3.new(0, 1, 0) or Vector3.new())
    MoveDirection = MoveDirection
      - (UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) and Vector3.new(0, 1, 0) or Vector3.new())

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
      if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild 'Humanoid' then
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
      if part:IsA 'BasePart' and part.CanCollide then
        part.CanCollide = false
      end
    end
  end
end)

local MovementBox = Tabs.Movement:AddLeftGroupbox('Movement')

-- UI Toggles
MovementBox:AddToggle( "Enable Flight", {
  Text = 'Flight Mode',
  Default = false,
  Flag = 'FlightMode',
  Callback = function(v)
    toggleFlightMode()
  end,
})

MovementBox:AddSlider( "Flight Speed", {
  Text = 'Flight Speed',
  Range = { 50, 200 },
  Increment = 10,
  Default = flySpeed,
  Flag = 'FlightSpeed',
  Callback = function(val)
    flySpeed = val
  end,
})

MovementBox:AddToggle( "Noclip", {
  Text = 'Noclip',
  Default = false,
  Flag = 'Noclip',
  Callback = function(v)
    toggleNoclip()
  end,
})

MovementBox:AddToggle( "Infinite Jump", {
  Text = 'Infinite Jump',
  Default = false,
  Flag = 'InfiniteJump',
  Callback = function(v)
    toggleInfiniteJump()
  end,
})

-- Speed Slider
local currentSpeed = 16

MovementBox:AddSlider( "Walk Speed", {
  Text = 'Walk Speed',
  Range = { 16, 200 },
  Increment = 1,
  Default = currentSpeed,
  Flag = 'WalkSpeed',
  Callback = function(value)
    currentSpeed = value
    local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass 'Humanoid'
    if humanoid then
      humanoid.WalkSpeed = value
    end
  end,
})

-- Jump Power Slider
local currentJumpPower = 50

MovementBox:AddSlider( "Jump Power", {
  Text = 'Jump Power',
  Range = { 50, 200 },
  Increment = 1,
  Default = currentJumpPower,
  Flag = 'JumpPower',
  Callback = function(value)
    currentJumpPower = value
    local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass 'Humanoid'
    if humanoid then
      humanoid.JumpPower = value
    end
  end,
})

local SilentAimEnabled = false
local SilentAimFOV = 150
local SilentAimHitChance = 100
local SilentAimTargetPart = 'Head'
local SilentAimTeamCheck = true
local SilentAimWallCheck = true

local CurrentTarget = nil
local HighlightFolder = Instance.new('Folder', game.CoreGui)
HighlightFolder.Text = 'SilentAimHighlights'

local function GetClosestPlayer()
  local players = game:GetService('Players'):GetPlayers()
  local camera = workspace.CurrentCamera
  local closest = nil
  local closestDist = SilentAimFOV

  for _, player in ipairs(players) do
    if
      player ~= game.Players.LocalPlayer
      and player.Character
      and player.Character:FindFirstChild 'HumanoidRootPart'
    then
      if SilentAimTeamCheck and player.Team == game.Players.LocalPlayer.Team then
        continue
      end

      local pos, onScreen = camera:WorldToViewportPoint(player.Character.HumanoidRootPart.Position)
      if onScreen then
        local mousePos = game:GetService('UserInputService'):GetMouseLocation()
        local dist = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
        if dist < closestDist then
          if SilentAimWallCheck then
            local ray = workspace:Raycast(
              camera.CFrame.Position,
              (player.Character.HumanoidRootPart.Position - camera.CFrame.Position).Unit * 999,
              { game.Players.LocalPlayer.Character }
            )
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
    local highlight = Instance.new 'Highlight'
    highlight.Parent = HighlightFolder
    highlight.Adornee = target.Character
    highlight.FillColor = Color3.fromRGB(255, 0, 0)
    highlight.FillTransparency = 0.5
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.OutlineTransparency = 01
  end
end

-- Hook shot detection
local oldIndex
oldIndex = hookmetamethod(game, '__index', function(self, key)
  if SilentAimEnabled and tostring(self) == 'Mouse' and (key == 'Hit' or key == 'Target') then
    if math.random(0, 100) <= SilentAimHitChance then
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
game:GetService('RunService').RenderStepped:Connect(function()
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

local AimbotBox2 = Tabs.Main:AddRightGroupbox('SilentAim')


AimbotBox2:AddToggle( "Enable Silent Aim", {
  Text = 'Silent Aim',
  Default = false,
  Callback = function(Value)
    SilentAimEnabled = Value
  end,
})

AimbotBox2:AddSlider( "Silent Aim FOV", {
  Text = 'Silent Aim FOV',
  Range = { 0, 500 },
  Increment = 1,
  Default = 150,
  Flag = 'SilentAimFov',
  Callback = function(Value)
    SilentAimFOV = Value
  end,
})

AimbotBox2:AddSlider( "Hit Chance", {
  Text = 'Hit Chance %',
  Range = { 0, 100 },
  Increment = 1,
  Default = 100,
  Flag = 'HitChance%',
  Callback = function(Value)
    SilentAimHitChance = Value
  end,
})

AimbotBox2:AddDropdown( "Aim Target", {
  Text = 'Silent Aim Target Part',
  Options = { 'Head', 'HumanoidRootPart', 'UpperTorso', 'LowerTorso' },
  Default = 1,
  Flag = 'SilentAimTargetPart',
  Callback = function(Value)
    SilentAimTargetPart = Value
  end,
})

AimbotBox2:AddToggle( "Silent Aim team Check", {
  Text = 'Silent Aim Team Check',
  Default = true,
  Flag = 'SilentAimTeamCheck',
  Callback = function(Value)
    SilentAimTeamCheck = Value
  end,
})

AimbotBox2:AddToggle( "Silent Aim Wall Check", {
  Text = 'Silent Aim Wall Check',
  Default = true,
  Flag = 'SilentAimWallCheck',
  Callback = function(Value)
    SilentAimWallCheck = Value
  end,
})

-- =======================
-- **Main Tab Additions (Combat Section)**
-- =======================

-- Instant Hit Toggle
local instanthittoggle = AimbotBox2:AddToggle( "Instant Hit", {
  Text = 'Instant Hit',
  Default = false,
  Flag = 'InstantHit',
  Callback = function(Value)
    getgenv().InstantHit = Value
  end,
})

-- Silent Aim FOV Slider
AimbotBox2:AddSlider( "Silent Aim FOV Radius", {
  Text = 'Silent Aim FOV Radius',
  Min = 10,
  Max = 500,
  Default = 150,
  Flag = 'SilentAimFovRadius',
  Callback = function(Value)
    getgenv().SilentAimFOV = Value
  end,
})

-- Advanced Triggerbot
AimbotBox2:AddToggle( "Enable Advanced Triggerbot", {
  Text = 'Enable Advanced Triggerbot',
  Default = false,
  Flag = 'EnableAdvancedTriggerbot',
  Callback = function(Value)
    getgenv().AdvancedTriggerbotEnabled = Value
  end,
})

AimbotBox2:AddSlider( "Triggerbot Hit Chance", {
  Text = 'Triggerbot Hit Chance (%)',
  Min = 1,
  Max = 100,
  Default = 80,
  Flag = 'TriggerbotHitChance%',
  Callback = function(Value)
    getgenv().TriggerbotHitChance = Value
  end,
})

-- =======================
-- **Backend Logic**
-- =======================

-- Instant Hit Logic
game:GetService('RunService').Heartbeat:Connect(function()
  if getgenv().InstantHit then
    -- Assuming you have a function that handles shooting bullets
    -- instantly hit the target with a bullet (adjust target detection logic)
    if target then
      bullet.Position = target.Position -- instant hit
    end
  end
end)

-- Silent Aim Logic
game:GetService('RunService').Heartbeat:Connect(function()
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
game:GetService('RunService').Heartbeat:Connect(function()
  if getgenv().AdvancedTriggerbotEnabled then
    -- Example: Triggerbot shoots if hit chance is met
    local chance = math.random(1, 100)
    if chance <= getgenv().TriggerbotHitChance then
      triggerbotEnabled = true -- shoot (triggerbot activation logic)
    end
  end
end)

local Movementbox2 = Tabs.Movement:AddRightGroupbox('Bypass Movement')

--// Services
local RunService = game:GetService 'RunService'
local UserInputService = game:GetService 'UserInputService'
local Players = game:GetService 'Players'
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--// Variables
local flyEnabled = false
local hoverEnabled = false
local flySpeed = 4
local hoverIntensity = 1
local flyKey = Enum.KeyCode.H

local movementKeys = {
  [Enum.KeyCode.W] = false,
  [Enum.KeyCode.A] = false,
  [Enum.KeyCode.S] = false,
  [Enum.KeyCode.D] = false,
  [Enum.KeyCode.Space] = false,
  [Enum.KeyCode.LeftControl] = false,
}

local lastTween -- Store last tween to cancel it if needed

--// Helper
local function getHRP()
  return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild 'HumanoidRootPart'
end

--// Flight + Hover Update
RunService.Heartbeat:Connect(function(deltaTime)
  if not flyEnabled then
    return
  end
  local hrp = getHRP()
  if not hrp then
    return
  end

  local moveDir = Vector3.zero

  if movementKeys[Enum.KeyCode.W] then
    moveDir += Camera.CFrame.LookVector
  end
  if movementKeys[Enum.KeyCode.S] then
    moveDir -= Camera.CFrame.LookVector
  end
  if movementKeys[Enum.KeyCode.A] then
    moveDir -= Camera.CFrame.RightVector
  end
  if movementKeys[Enum.KeyCode.D] then
    moveDir += Camera.CFrame.RightVector
  end
  if movementKeys[Enum.KeyCode.Space] then
    moveDir += Vector3.new(0, 1, 0)
  end
  if movementKeys[Enum.KeyCode.LeftControl] then
    moveDir -= Vector3.new(0, 1, 0)
  end

  -- Normalize to prevent speed boost diagonally
  if moveDir.Magnitude > 0 then
    moveDir = moveDir.Unit
  end

  local targetPos
  if moveDir.Magnitude > 0 then
    -- Move with input
    targetPos = hrp.Position + moveDir * flySpeed
  elseif hoverEnabled then
    -- Hover with sinusoidal up/down
    local hoverOffset = math.sin(tick() * 2) * hoverIntensity
    targetPos = hrp.Position + Vector3.new(0, hoverOffset, 0)
  else
    targetPos = hrp.Position
  end

  -- Cancel last tween if exists
  if lastTween then
    lastTween:Cancel()
  end

  -- Tween move
  local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
  local goal = { CFrame = CFrame.new(targetPos) }
  local tween = TweenService:Create(hrp, tweenInfo, goal)
  tween:Play()
  lastTween = tween

  -- Anti-Detection
  hrp.Velocity = Vector3.zero
  hrp.RotVelocity = Vector3.zero
end)

--// Inputs
UserInputService.InputBegan:Connect(function(input, processed)
  if processed then
    return
  end
  if movementKeys[input.KeyCode] ~= nil then
    movementKeys[input.KeyCode] = true
  elseif input.KeyCode == flyKey then
    flyEnabled = not flyEnabled
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild 'Humanoid' then
      LocalPlayer.Character.Humanoid.PlatformStand = flyEnabled
    end
  end
end)

UserInputService.InputEnded:Connect(function(input, processed)
  if processed then
    return
  end
  if movementKeys[input.KeyCode] ~= nil then
    movementKeys[input.KeyCode] = false
  end
end)

--// Luna UI Setup
MovementBox2:AddToggle( "Enable Fly", {
  Text = 'Enable Fly',
  Default = false,
  Callback = function(Value)
    flyEnabled = Value
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild 'Humanoid' then
      LocalPlayer.Character.Humanoid.PlatformStand = Value
    end
  end,
})

MovementBox2:AddToggle( "Enable Hover", {
  Text = 'Enable Hover Mode',
  Default = false,
  Callback = function(Value)
    hoverEnabled = Value
  end,
})

MovementBox2:AddSlider( "Fly Speed", {
  Text = 'Fly Speed',
  Range = { 1, 20 },
  Increment = 1,
  Default = flySpeed,
  Suffix = ' Studs/s',
  Callback = function(Value)
    flySpeed = Value
  end,
})

MovementBox2:AddSlider( "Hover Intensity", {
  Text = 'Hover Intensity',
  Range = { 0, 5 },
  Increment = 0.1,
  Default = hoverIntensity,
  Suffix = '',
  Callback = function(Value)
    hoverIntensity = Value
  end,
})


local Players = game:GetService 'Players'
local RunService = game:GetService 'RunService'
local LocalPlayer = Players.LocalPlayer

local DetectedPlayers = {}
local DetectionCooldown = 10 -- seconds before rechecking same player

-- Settings
local speedThreshold = 200 -- studs/second
local flyHeightThreshold = 300 -- Y-studs above ground

local function sendNotification(player, reason, severity, details)
  if DetectedPlayers[player] and tick() - DetectedPlayers[player] < DetectionCooldown then
    return
  end

  DetectedPlayers[player] = tick()

  Luna:Notification {
    Title = 'Exploiter Spotted [' .. severity .. ']',
    Icon = 'notifications_active',
    ImageSource = 'Material',
    Content = player.Name .. ' flagged for ' .. reason .. '. Details: ' .. details,
  }
end

RunService.Heartbeat:Connect(function(deltaTime)
  for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild 'HumanoidRootPart' then
      local hrp = player.Character.HumanoidRootPart
      local humanoid = player.Character:FindFirstChildOfClass 'Humanoid'

      -- Fly Detection
      if humanoid and humanoid.FloorMaterial == Enum.Material.Air and hrp.Position.Y > flyHeightThreshold then
        local heightAboveGround = math.floor(hrp.Position.Y)
        sendNotification(player, 'Flying Detected', 'HIGH', 'Height: ' .. heightAboveGround .. ' studs')
      end

      -- Speed Detection
      if not hrp:FindFirstChild 'LastPosition' then
        local lastPos = Instance.new 'Vector3Value'
        lastPos.Text = 'LastPosition'
        lastPos.Value = hrp.Position
        lastPos.Parent = hrp
      else
        local lastPos = hrp:FindFirstChild 'LastPosition'
        local distanceMoved = (hrp.Position - lastPos.Value).Magnitude
        local speed = distanceMoved / deltaTime

        if speed > speedThreshold then
          sendNotification(player, 'Speed Hacking', 'MEDIUM', 'Speed: ' .. math.floor(speed) .. ' studs/sec')
        end

        lastPos.Value = hrp.Position
      end
    end
  end
end)

local SettingsTab = Tabs.Settings:AddRightGroupbox('Settings')

local Players = game:GetService 'Players'
local LocalPlayer = Players.LocalPlayer

local antiRagdollEnabled = false

local function warnRagdollAttempt(partName)
  Luna:Notification {
    Title = 'Anti-Ragdoll System',
    Icon = 'warning',
    ImageSource = 'Material',
    Content = 'Blocked ragdoll component: ' .. tostring(partName),
  }
end

local function removeRagdoll()
  if not antiRagdollEnabled then
    return
  end
  if not LocalPlayer.Character then
    return
  end
  for _, object in ipairs(LocalPlayer.Character:GetDescendants()) do
    if object:IsA 'BallSocketConstraint' or object:IsA 'HingeConstraint' then
      warnRagdollAttempt(object.Name)
      object:Destroy()
    elseif object:IsA 'Attachment' and object.Name:lower():find 'ragdoll' then
      warnRagdollAttempt(object.Name)
      object:Destroy()
    end
  end
end

local function setupAntiRagdoll(character)
  character:WaitForChild 'Humanoid'
  removeRagdoll()
  character.DescendantAdded:Connect(function(descendant)
    if antiRagdollEnabled then
      if descendant:IsA 'BallSocketConstraint' or descendant:IsA 'HingeConstraint' then
        warnRagdollAttempt(descendant.Name)
        descendant:Destroy()
      elseif descendant:IsA 'Attachment' and descendant.Name:lower():find 'ragdoll' then
        warnRagdollAttempt(descendant.Name)
        descendant:Destroy()
      end
    end
  end)
end

LocalPlayer.CharacterAdded:Connect(function(character)
  setupAntiRagdoll(character)
end)

if LocalPlayer.Character then
  setupAntiRagdoll(LocalPlayer.Character)
end

-- Luna UI Toggle
SettingsTab:AddToggle( "Enable Anti-Ragdoll", {
  Text = 'Anti-Ragdoll',
  Default = antiRagdollEnabled,
  Callback = function(state)
    antiRagdollEnabled = state
    if antiRagdollEnabled then
      removeRagdoll()
    end
  end,
}

local hitboxEnabled = false
local hitboxSize = 20
local hitboxTeamCheck = true

AimbotBox:AddToggle("Hitbox Expander", {
  Text = 'Hitbox Expander',
  Default = false,
  Callback = function(value)
    hitboxEnabled = value
  end,
})

AimbotBox:AddToggle("Hitbox Team Check", {
  Text = 'Hitbox Team Check',
  Default = true,
  Callback = function(value)
    hitboxTeamCheck = value
  end,
})

AimbotBox:AddSlider("Hitbox Size", {
  Text = 'Hitbox Size',
  Min = 5,
  Max = 50,
  Default = 20,
  Increment = 1,
  Callback = function(value)
    hitboxSize = value
  end,
})

local originalSizes = {}

RunService.RenderStepped:Connect(function()
  if hitboxEnabled then
    for _, player in pairs(Players:GetPlayers()) do
      if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild 'Head' then
        if hitboxTeamCheck and player.Team == LocalPlayer.Team then
          continue
        end

        local hrp = player.Character.HumanoidRootPart
        pcall(function()
          -- Save original size once
          if not originalSizes[player] then
            originalSizes[player] = hrp.Size
          end

          hrp.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
          hrp.Transparency = 0.7
          hrp.Material = Enum.Material.Neon
          hrp.BrickColor = BrickColor.new 'Really red'
          hrp.CanCollide = false
        end)
      end
    end
  else
    -- Reset hitboxes
    for _, player in pairs(Players:GetPlayers()) do
      local hrp = player.Character and player.Character:FindFirstChild 'Head'
      if hrp and originalSizes[player] then
        pcall(function()
          hrp.Size = originalSizes[player]
          hrp.Transparency = 0
          hrp.Material = Enum.Material.Plastic
          hrp.BrickColor = BrickColor.new 'Medium stone grey'
          hrp.CanCollide = true
        end)
        originalSizes[player] = nil
      end
    end
  end
end)

local crosshairEnabled = false
local crosshairId = "rbxassetid://9943168537"

local presetCrosshairs = {
    ["Red Dot"] = "rbxassetid://17797747635",
    ["Green Dot"] = "rbxassetid://11329293521",
    ["Angle"] = "rbxassetid://18932934463",
    ["Heart"] = "rbxassetid://13318885193",
    ["Circle"] = "rbxassetid://17459159263"
}

local function updateCrosshair()
    LocalPlayer:GetMouse().Icon = crosshairEnabled and crosshairId or ""
end

local EspBox2 = Tabs.Visuals:AddRightGroupbox('CrossHair')

EspBox2:AddToggle( "Enable Custom Crosshair", {
    Text = "Enable Custom Crosshair",
    Default = false,
    Flag = "CustomCrosshairEnabled",
    Callback = function(state)
        crosshairEnabled = state
        updateCrosshair()
    end
})

EspBox2:AddInput( "CustomCrosshairID",{
    Text = "Custom Crosshair ID",
    Description = "use TEXTURE ID not ASSET ID",
    PlaceholderText = "Enter Texture ID",
    RemoveTextAfterFocusLost = false,
    FLag = "CustomCrosshairID",
    Callback = function(input)
        if input and tonumber(input) then
            local assetId = "rbxassetid://" .. input
            UserInputService.MouseIcon = assetId
        else
            warn("Invalid input: must be a numeric ID")
        end
    end
})

EspBox2:AddDropdown( "Preset Crosshairs", {
    Text = "Preset Crosshairs",
    Options = { "Red Dot", "Green Dot", "Angle", "Heart", "Circle" },
    Default = 1,
    Callback = function(option)
        crosshairId = presetCrosshairs[option]
        updateCrosshair()
    end
})


ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)
