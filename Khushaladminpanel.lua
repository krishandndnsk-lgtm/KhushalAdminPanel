--[[
    ============================================================================
    KHUSHAL ADMIN PANEL | CHILLI HUB EDITION (REFINED EXECUTOR ENGINE)
    ============================================================================
]]

-- 1. PROTECTED PREVIOUS INSTANCE TEARDOWN
if _G.KhushalAdminCleanup and type(_G.KhushalAdminCleanup) == "function" then
    pcall(_G.KhushalAdminCleanup)
end

local connections = {}
local function trackConn(conn)
    table.insert(connections, conn)
    return conn
end

-- 2. SERVICES & CORE VARIABLES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Yalat = {
    Commands = {},
    CmdList = {},
    SavedLocation = nil,
    UIElements = {},
    OriginalCollisionMap = {},
    SpawnedTools = {},
    Baseline = {
        walkSpeed = 16,
        jumpPower = 50,
        useJumpPower = true
    },
    State = {
        speed = nil,
        jump = nil,
        noclip = false,
        god = false, 
        spin = false,
        spinSpeed = 10,
        shaderActive = false, 
        waterActive = false,
        flyActive = false,
        flySpeed = 50,
        holdingSpeedCoil = false
    }
}

local function getChar() 
    return LocalPlayer.Character 
end

local function getHum()
    local c = LocalPlayer.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function getRoot()
    local c = LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function findHumanoidFromHit(hitPart)
    if not hitPart then return nil end
    local current = hitPart
    while current and current ~= Workspace do
        local hum = current:FindFirstChildOfClass("Humanoid")
        if hum then return hum end
        current = current.Parent
    end
    return nil
end

-- 3. UI STYLING & NOTIFICATION SYSTEM
local function corner(inst, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = inst
    return c
end

local function stroke(inst, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or Color3.fromRGB(200, 20, 20)
    s.Thickness = thickness or 1
    s.Parent = inst
    return s
end

local function showNotification(message, isError)
    local sg = PlayerGui:FindFirstChild("KhushalChilliHubFullUI")
    if not sg then return end

    local notifFrame = sg:FindFirstChild("NotifContainer")
    if not notifFrame then
        notifFrame = Instance.new("Frame")
        notifFrame.Name = "NotifContainer"
        notifFrame.Size = UDim2.new(0.3, 0, 0.2, 0)
        notifFrame.Position = UDim2.new(0.02, 0, 0.75, 0)
        notifFrame.BackgroundTransparency = 1
        notifFrame.Parent = sg
        
        local layout = Instance.new("UIListLayout")
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Padding = UDim.new(0, 5)
        layout.Parent = notifFrame
    end

    local toast = Instance.new("Frame")
    toast.Size = UDim2.new(1, 0, 0, 32)
    toast.BackgroundColor3 = isError and Color3.fromRGB(50, 10, 10) or Color3.fromRGB(20, 40, 20)
    toast.BackgroundTransparency = 0.1
    corner(toast, 6)
    stroke(toast, isError and Color3.fromRGB(220, 30, 30) or Color3.fromRGB(30, 220, 80), 1)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -10, 1, 0)
    lbl.Position = UDim2.fromOffset(5, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = message
    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = toast

    toast.Parent = notifFrame
    task.delay(3, function()
        if toast and toast.Parent then
            local tween = TweenService:Create(toast, TweenInfo.new(0.4), {BackgroundTransparency = 1})
            tween:Play()
            trackConn(tween.Completed:Connect(function() toast:Destroy() end))
        end
    end)
end

-- 4. FLY ENGINE & MOBILE CONTROLS
local mobileFlyUp = false
local mobileFlyDown = false
local flyObj = { conn = nil, lv = nil, ao = nil, attachment = nil, diedConn = nil }

local function stopFly(keepState)
    if flyObj.conn then flyObj.conn:Disconnect() flyObj.conn = nil end
    if flyObj.diedConn then flyObj.diedConn:Disconnect() flyObj.diedConn = nil end
    if flyObj.lv then flyObj.lv:Destroy() flyObj.lv = nil end
    if flyObj.ao then flyObj.ao:Destroy() flyObj.ao = nil end
    if flyObj.attachment then flyObj.attachment:Destroy() flyObj.attachment = nil end
    
    mobileFlyUp = false
    mobileFlyDown = false

    if not keepState then
        Yalat.State.flyActive = false
    end

    local hum = getHum()
    if hum then hum.PlatformStand = false end
    
    local sg = PlayerGui:FindFirstChild("KhushalChilliHubFullUI")
    if sg and sg:FindFirstChild("MobileFlyControls") then
        sg.MobileFlyControls.Visible = false
    end
end

local function startFly(speed)
    stopFly(true)
    speed = math.clamp(speed or 50, 1, 1000)
    Yalat.State.flySpeed = speed

    local root, hum = getRoot(), getHum()
    if not (root and hum) then return end

    flyObj.attachment = Instance.new("Attachment", root)

    flyObj.lv = Instance.new("LinearVelocity")
    flyObj.lv.MaxForce = 1e9
    flyObj.lv.VectorVelocity = Vector3.zero
    flyObj.lv.Attachment0 = flyObj.attachment
    flyObj.lv.RelativeTo = Enum.ActuatorRelativeTo.World
    flyObj.lv.Parent = root

    flyObj.ao = Instance.new("AlignOrientation")
    flyObj.ao.MaxTorque = 1e9
    flyObj.ao.Responsiveness = 200
    flyObj.ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
    flyObj.ao.Attachment0 = flyObj.attachment
    flyObj.ao.CFrame = root.CFrame
    flyObj.ao.Parent = root

    hum.PlatformStand = true
    Yalat.State.flyActive = true

    local sg = PlayerGui:FindFirstChild("KhushalChilliHubFullUI")
    if sg and sg:FindFirstChild("MobileFlyControls") then
        sg.MobileFlyControls.Visible = true
    end

    flyObj.diedConn = hum.Died:Connect(function()
        stopFly(true)
    end)

    flyObj.conn = RunService.RenderStepped:Connect(function()
        local cam = Workspace.CurrentCamera
        local currentRoot, currentHum = getRoot(), getHum()
        if not (currentRoot and currentRoot.Parent and currentHum and cam) then 
            return stopFly(true) 
        end

        local md = currentHum.MoveDirection
        local look = cam.CFrame.LookVector
        local flat = Vector3.new(look.X, 0, look.Z)
        local vel = md

        if flat.Magnitude > 0.01 then
            flat = flat.Unit
            local flatRight = flat:Cross(Vector3.yAxis)
            vel = look * md:Dot(flat) + cam.CFrame.RightVector * md:Dot(flatRight)
            flyObj.ao.CFrame = CFrame.new(currentRoot.Position, currentRoot.Position + flat)
        else
            flyObj.ao.CFrame = cam.CFrame
        end

        if UserInputService:IsKeyDown(Enum.KeyCode.E) or UserInputService:IsKeyDown(Enum.KeyCode.Space) or mobileFlyUp then 
            vel = vel + Vector3.yAxis 
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Q) or mobileFlyDown then 
            vel = vel - Vector3.yAxis 
        end

        flyObj.lv.VectorVelocity = vel * Yalat.State.flySpeed
    end)
end

-- 5. NOCLIP ENGINE
local function setNoclip(enable)
    Yalat.State.noclip = enable
    local char = getChar()
    if not char then return end

    if enable then
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then
                if Yalat.OriginalCollisionMap[p] == nil then
                    Yalat.OriginalCollisionMap[p] = p.CanCollide
                end
                p.CanCollide = false
            end
        end
    else
        for p, originalVal in pairs(Yalat.OriginalCollisionMap) do
            if p and p.Parent then
                p.CanCollide = originalVal
            end
        end
        Yalat.OriginalCollisionMap = {}
    end
end

-- 6. SHADER, SKYBOX & WATER BACKUP SYSTEMS
local lightingBackup = nil
local shaderStorage = { FX = {}, Highlight = nil, CustomSky = nil, SavedSky = nil }

local function applyHighlight(char)
    if not char then return end
    if shaderStorage.Highlight then 
        shaderStorage.Highlight:Destroy() 
        shaderStorage.Highlight = nil
    end
    local hl = Instance.new("Highlight")
    hl.Name = "RainbowGlow"
    hl.FillTransparency = 0.6
    hl.OutlineTransparency = 0.1
    hl.OutlineColor = Color3.fromRGB(255, 50, 50)
    hl.Adornee = char
    hl.Parent = char
    shaderStorage.Highlight = hl
end

local function enableShader()
    if Yalat.State.shaderActive then return end
    
    if not lightingBackup then
        lightingBackup = {
            Brightness = Lighting.Brightness,
            ClockTime = Lighting.ClockTime,
            GlobalShadows = Lighting.GlobalShadows,
            ExposureCompensation = Lighting.ExposureCompensation,
            Ambient = Lighting.Ambient,
            OutdoorAmbient = Lighting.OutdoorAmbient
        }
    end

    Yalat.State.shaderActive = true
    Lighting.Brightness = 3.2
    Lighting.ClockTime = 14.2
    Lighting.GlobalShadows = true
    Lighting.ExposureCompensation = 0.25
    Lighting.Ambient = Color3.fromRGB(80, 80, 90)
    Lighting.OutdoorAmbient = Color3.fromRGB(120, 120, 130)

    local existingSky = Lighting:FindFirstChildOfClass("Sky")
    if existingSky then
        shaderStorage.SavedSky = existingSky
        existingSky.Parent = nil
    end

    local sky = Instance.new("Sky")
    sky.Name = "ChilliShaderSky"
    sky.SkyboxBk = "rbxassetid://600830446"
    sky.SkyboxDn = "rbxassetid://600831635"
    sky.SkyboxFt = "rbxassetid://600832720"
    sky.SkyboxLf = "rbxassetid://600833862"
    sky.SkyboxRt = "rbxassetid://600834938"
    sky.SkyboxUp = "rbxassetid://600835863"
    sky.StarCount = 3000
    sky.Parent = Lighting
    shaderStorage.CustomSky = sky

    local bloom = Instance.new("BloomEffect", Lighting)
    bloom.Intensity = 0.65; bloom.Size = 32; bloom.Threshold = 0.7
    table.insert(shaderStorage.FX, bloom)

    local cc = Instance.new("ColorCorrectionEffect", Lighting)
    cc.Brightness = 0.08; cc.Contrast = 0.25; cc.Saturation = 0.35
    cc.TintColor = Color3.fromRGB(255, 248, 240)
    table.insert(shaderStorage.FX, cc)

    local sunRays = Instance.new("SunRaysEffect", Lighting)
    sunRays.Intensity = 0.45; sunRays.Spread = 0.85
    table.insert(shaderStorage.FX, sunRays)

    local dof = Instance.new("DepthOfFieldEffect", Lighting)
    dof.FarIntensity = 0.15; dof.FocusDistance = 25
    dof.InFocusRadius = 40; dof.NearIntensity = 0.1
    table.insert(shaderStorage.FX, dof)

    local atmos = Instance.new("Atmosphere", Lighting)
    atmos.Density = 0.35; atmos.Offset = 0.25
    atmos.Color = Color3.fromRGB(180, 200, 220)
    atmos.Decay = Color3.fromRGB(100, 110, 120)
    atmos.Glare = 0.5; atmos.Haze = 0.8
    table.insert(shaderStorage.FX, atmos)

    applyHighlight(getChar())
end

local function disableShader()
    if not Yalat.State.shaderActive then return end
    Yalat.State.shaderActive = false

    if lightingBackup then
        Lighting.Brightness = lightingBackup.Brightness
        Lighting.ClockTime = lightingBackup.ClockTime
        Lighting.GlobalShadows = lightingBackup.GlobalShadows
        Lighting.ExposureCompensation = lightingBackup.ExposureCompensation
        Lighting.Ambient = lightingBackup.Ambient
        Lighting.OutdoorAmbient = lightingBackup.OutdoorAmbient
        lightingBackup = nil
    end

    for _, fx in ipairs(shaderStorage.FX) do
        if fx and fx.Parent then fx:Destroy() end
    end
    shaderStorage.FX = {}

    if shaderStorage.CustomSky then
        shaderStorage.CustomSky:Destroy()
        shaderStorage.CustomSky = nil
    end

    if shaderStorage.SavedSky then
        shaderStorage.SavedSky.Parent = Lighting
        shaderStorage.SavedSky = nil
    end

    if shaderStorage.Highlight then
        shaderStorage.Highlight:Destroy()
        shaderStorage.Highlight = nil
    end
end

local waterBackup = nil
local function enableRealisticWater()
    local terrain = Workspace:FindFirstChildOfClass("Terrain")
    if terrain then
        if not Yalat.State.waterActive then
            waterBackup = {
                Color = terrain.WaterColor,
                WaveSize = terrain.WaterWaveSize,
                WaveSpeed = terrain.WaterWaveSpeed,
                Transparency = terrain.WaterTransparency,
                Reflectance = terrain.WaterReflectance
            }
        end
        Yalat.State.waterActive = true
        terrain.WaterColor = Color3.fromRGB(0, 140, 190)
        terrain.WaterTransparency = 0.92
        terrain.WaterWaveSize = 0.5
        terrain.WaterWaveSpeed = 22
        terrain.WaterReflectance = 0.95
    end
end

local function disableRealisticWater()
    local terrain = Workspace:FindFirstChildOfClass("Terrain")
    if terrain and Yalat.State.waterActive then
        Yalat.State.waterActive = false
        if waterBackup then
            terrain.WaterColor = waterBackup.Color
            terrain.WaterTransparency = waterBackup.Transparency
            terrain.WaterWaveSize = waterBackup.WaveSize
            terrain.WaterWaveSpeed = waterBackup.WaveSpeed
            terrain.WaterReflectance = waterBackup.Reflectance
            waterBackup = nil
        end
    end
end

-- 7. TOOL SPAWNER ENGINE (WITH CACHED ANIMATION & FULL CLEANUP TRACKING)
local weaponAnimation = Instance.new("Animation")
weaponAnimation.AnimationId = "rbxassetid://125906970"
local cachedAnimTrack = nil

local function spawnItem(itemName)
    local char = getChar()
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    if not (char and backpack) then return end

    if backpack:FindFirstChild(itemName) or char:FindFirstChild(itemName) then
        showNotification(itemName .. " is already in your inventory!", true)
        return
    end

    local tool = Instance.new("Tool")
    tool.Name = itemName

    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(1, 1, 1)
    handle.Parent = tool

    local lower = itemName:lower()
    if lower == "sword" or lower == "bat" then
        handle.Size = Vector3.new(0.5, 4, 0.5)
        handle.Material = Enum.Material.Metal

        local isAttacking = false
        local hitDebounceMap = {}

        trackConn(tool.Activated:Connect(function()
            if isAttacking then return end
            isAttacking = true
            hitDebounceMap = {}

            local hum = getHum()
            local animator = hum and hum:FindFirstChildOfClass("Animator")
            if animator then
                if not cachedAnimTrack or cachedAnimTrack.Animator ~= animator then
                    cachedAnimTrack = animator:LoadAnimation(weaponAnimation)
                end
                cachedAnimTrack:Play()
            end
            task.delay(0.5, function() isAttacking = false end)
        end))

        trackConn(handle.Touched:Connect(function(hit)
            if not isAttacking then return end
            local enemyHum = findHumanoidFromHit(hit)
            if enemyHum and enemyHum.Parent ~= char and not hitDebounceMap[enemyHum] then
                hitDebounceMap[enemyHum] = true
                enemyHum:TakeDamage(25)
            end
        end))

    elseif lower == "speedcoil" then
        handle.BrickColor = BrickColor.new("Bright blue")
        trackConn(tool.Equipped:Connect(function()
            Yalat.State.holdingSpeedCoil = true
            local hum = getHum()
            if hum then hum.WalkSpeed = 50 end
        end))
        trackConn(tool.Unequipped:Connect(function()
            Yalat.State.holdingSpeedCoil = false
            local hum = getHum()
            if hum then 
                hum.WalkSpeed = Yalat.State.speed or Yalat.Baseline.walkSpeed 
            end
        end))
    elseif lower == "apple" then
        handle.Shape = Enum.PartType.Ball
        handle.BrickColor = BrickColor.new("Bright red")
        trackConn(tool.Activated:Connect(function()
            local hum = getHum()
            if hum then
                hum.Health = math.min(hum.MaxHealth, hum.Health + 20)
                tool:Destroy()
            end
        end))
    end

    tool.Parent = backpack
    table.insert(Yalat.SpawnedTools, tool)
    showNotification("Received " .. itemName .. "!", false)
end

-- 8. GUI CONSTRUCTION & ADAPTIVE RESPONSIVENESS
local gui = Instance.new("ScreenGui")
gui.Name = "KhushalChilliHubFullUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 9999
gui.Parent = PlayerGui

local flyUI = Instance.new("Frame")
flyUI.Name = "MobileFlyControls"
flyUI.Size = UDim2.fromOffset(50, 110)
flyUI.Position = UDim2.new(1, -60, 0.5, -55)
flyUI.BackgroundTransparency = 1
flyUI.Visible = false
flyUI.Parent = gui

local upBtn = Instance.new("TextButton")
upBtn.Size = UDim2.fromOffset(45, 45)
upBtn.BackgroundColor3 = Color3.fromRGB(180, 20, 20)
upBtn.Text = "▲"; upBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
upBtn.Font = Enum.Font.GothamBold; upBtn.TextSize = 18
upBtn.Parent = flyUI
corner(upBtn, 22)

local downBtn = Instance.new("TextButton")
downBtn.Size = UDim2.fromOffset(45, 45)
downBtn.Position = UDim2.fromOffset(0, 55)
downBtn.BackgroundColor3 = Color3.fromRGB(180, 20, 20)
downBtn.Text = "▼"; downBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
downBtn.Font = Enum.Font.GothamBold; downBtn.TextSize = 18
downBtn.Parent = flyUI
corner(downBtn, 22)

trackConn(upBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        mobileFlyUp = true
    end
end))
trackConn(upBtn.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        mobileFlyUp = false
    end
end))

trackConn(downBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        mobileFlyDown = true
    end
end))
trackConn(downBtn.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        mobileFlyDown = false
    end
end))

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.fromOffset(100, 36)
toggleBtn.Position = UDim2.new(1, -110, 0, 40)
toggleBtn.BackgroundColor3 = Color3.fromRGB(180, 10, 10)
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.Font = Enum.Font.GothamBold; toggleBtn.TextSize = 13
toggleBtn.Text = "KHUSHAL"
toggleBtn.Parent = gui
corner(toggleBtn, 8)
stroke(toggleBtn, Color3.fromRGB(255, 40, 40), 1.5)

local cmdOpenBtn = Instance.new("TextButton")
cmdOpenBtn.Size = UDim2.fromOffset(90, 32)
cmdOpenBtn.Position = UDim2.new(1, -100, 0, 82)
cmdOpenBtn.BackgroundColor3 = Color3.fromRGB(40, 20, 22)
cmdOpenBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
cmdOpenBtn.Font = Enum.Font.GothamBold; cmdOpenBtn.TextSize = 11
cmdOpenBtn.Text = "CMD BAR"
cmdOpenBtn.Parent = gui
corner(cmdOpenBtn, 6)
stroke(cmdOpenBtn, Color3.fromRGB(180, 20, 20), 1)

local main = Instance.new("Frame")
main.Size = UDim2.fromScale(0.85, 0.75)
main.SizeConstraint = Enum.SizeConstraint.RelativeYY
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.Position = UDim2.fromScale(0.5, 0.45)
main.BackgroundColor3 = Color3.fromRGB(15, 10, 12)
main.Visible = true
main.Parent = gui
corner(main, 12)
stroke(main, Color3.fromRGB(220, 20, 20), 2)

local aspect = Instance.new("UIAspectRatioConstraint")
aspect.AspectRatio = 1.75
aspect.Parent = main

trackConn(toggleBtn.Activated:Connect(function() 
    main.Visible = not main.Visible 
end))

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 42)
header.BackgroundTransparency = 1
header.Parent = main

local title = Instance.new("TextLabel")
title.Position = UDim2.fromOffset(15, 6)
title.Size = UDim2.new(1, -60, 1, -12)
title.BackgroundTransparency = 1
title.Text = "KHUSHAL ADMIN PANEL | CHILLI HUB EDITION"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold; title.TextSize = 13
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(28, 28)
closeBtn.Position = UDim2.new(1, -34, 0, 6)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 20, 20)
closeBtn.Text = "X"; closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold; closeBtn.TextSize = 13
closeBtn.Parent = header
corner(closeBtn, 6)
trackConn(closeBtn.Activated:Connect(function() main.Visible = false end))

local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0.2, 0, 1, -50)
sidebar.Position = UDim2.fromOffset(8, 42)
sidebar.BackgroundColor3 = Color3.fromRGB(22, 14, 16)
sidebar.Parent = main
corner(sidebar, 8)
stroke(sidebar, Color3.fromRGB(60, 20, 20), 1)

local tabBtns = {}
local tabPages = {}

local function createTabBtn(name, iconText)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 34)
    btn.Position = UDim2.fromOffset(5, #tabBtns * 38 + 6)
    btn.BackgroundColor3 = (#tabBtns == 0) and Color3.fromRGB(180, 20, 20) or Color3.fromRGB(30, 18, 20)
    btn.Text = iconText .. " " .. name
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold; btn.TextSize = 11
    btn.Parent = sidebar
    corner(btn, 6)

    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(0.55, 0, 1, -50)
    page.Position = UDim2.new(0.22, 0, 0, 42)
    page.BackgroundTransparency = 1
    page.ScrollBarThickness = 3
    page.Visible = (#tabBtns == 0)
    page.Parent = main

    trackConn(btn.Activated:Connect(function()
        for _, b in ipairs(tabBtns) do b.BackgroundColor3 = Color3.fromRGB(30, 18, 20) end
        for _, p in ipairs(tabPages) do p.Visible = false end
        btn.BackgroundColor3 = Color3.fromRGB(180, 20, 20)
        page.Visible = true
    end))

    table.insert(tabBtns, btn)
    table.insert(tabPages, page)
    return page
end

local playerPage = createTabBtn("Player", "👤")
local worldPage = createTabBtn("World", "🌐")
local toolsPage = createTabBtn("Tools", "🛠️")

local logoFrame = Instance.new("Frame")
logoFrame.Size = UDim2.new(1, -10, 0, 75)
logoFrame.Position = UDim2.new(0, 5, 1, -80)
logoFrame.BackgroundColor3 = Color3.fromRGB(35, 10, 12)
logoFrame.Parent = sidebar
corner(logoFrame, 8)
stroke(logoFrame, Color3.fromRGB(200, 30, 30), 1)

local logoText = Instance.new("TextLabel")
logoText.Size = UDim2.new(1, 0, 1, 0)
logoText.BackgroundTransparency = 1
logoText.Text = "🌶️\nCHILLI HUB"
logoText.TextColor3 = Color3.fromRGB(255, 50, 50)
logoText.Font = Enum.Font.GothamBlack; logoText.TextSize = 12
logoText.Parent = logoFrame

local function setupGrid(page)
    local grid = Instance.new("UIGridLayout")
    grid.CellSize = UDim2.new(0.48, 0, 0, 48)
    grid.CellPadding = UDim2.new(0.03, 0, 0, 6)
    grid.Parent = page
end

setupGrid(playerPage)
setupGrid(worldPage)
setupGrid(toolsPage)

local function createOptionBox(parent, nameKey, mainTitle, subTitle, isToggle, callback)
    local box = Instance.new("Frame")
    box.BackgroundColor3 = Color3.fromRGB(30, 20, 22)
    box.Parent = parent
    corner(box, 6)
    stroke(box, Color3.fromRGB(90, 25, 25), 1)

    local t1 = Instance.new("TextLabel")
    t1.Name = "MainTitle"
    t1.Position = UDim2.fromOffset(6, 4)
    t1.Size = UDim2.new(0.65, 0, 0, 16)
    t1.BackgroundTransparency = 1
    t1.Text = mainTitle
    t1.TextColor3 = Color3.fromRGB(255, 255, 255)
    t1.Font = Enum.Font.GothamBold; t1.TextSize = 11
    t1.TextXAlignment = Enum.TextXAlignment.Left
    t1.Parent = box

    local t2 = Instance.new("TextLabel")
    t2.Name = "SubTitle"
    t2.Position = UDim2.fromOffset(6, 22)
    t2.Size = UDim2.new(0.65, 0, 0, 14)
    t2.BackgroundTransparency = 1
    t2.Text = "(" .. subTitle .. ")"
    t2.TextColor3 = Color3.fromRGB(160, 160, 160)
    t2.Font = Enum.Font.Code; t2.TextSize = 9
    t2.TextXAlignment = Enum.TextXAlignment.Left
    t2.Parent = box

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.fromOffset(40, 22)
    btn.Position = UDim2.new(1, -45, 0.5, -11)
    btn.BackgroundColor3 = isToggle and Color3.fromRGB(80, 80, 80) or Color3.fromRGB(180, 20, 20)
    btn.Text = isToggle and "OFF" or "RUN"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold; btn.TextSize = 9
    btn.Parent = box
    corner(btn, 4)

    local state = false
    local function updateUI(val, customSub)
        if customSub then t2.Text = "(" .. customSub .. ")" end
        if isToggle then
            state = (val == true)
            btn.BackgroundColor3 = state and Color3.fromRGB(0, 180, 70) or Color3.fromRGB(80, 80, 80)
            btn.Text = state and "ON" or "OFF"
        end
    end

    trackConn(btn.Activated:Connect(function()
        if isToggle then
            state = not state
            updateUI(state)
            callback(state)
        else
            callback(true)
        end
    end))

    Yalat.UIElements[nameKey] = updateUI
end

createOptionBox(playerPage, "god", "God Mode", ";god", true, function(v) Yalat.State.god = v end)
createOptionBox(playerPage, "noclip", "Noclip", ";noclip", true, function(v) setNoclip(v) end)
createOptionBox(playerPage, "spin", "Spin Player", ";spin", true, function(v) Yalat.State.spin = v end)
createOptionBox(playerPage, "fly", "Fly Mode", ";fly 50", true, function(v) if v then startFly(Yalat.State.flySpeed or 50) else stopFly(false) end end)
createOptionBox(playerPage, "set", "Set Location", ";set", false, function() 
    local r = getRoot()
    if r then 
        Yalat.SavedLocation = r.CFrame 
        showNotification("Location set!", false)
    end 
end)
createOptionBox(playerPage, "tp", "Teleport Saved", ";tp", false, function() 
    local r = getRoot()
    if r and Yalat.SavedLocation then 
        r.CFrame = Yalat.SavedLocation 
        showNotification("Teleported to saved location!", false)
    else
        showNotification("No location saved!", true)
    end 
end)
createOptionBox(playerPage, "speed", "Speed (50)", ";speed 50", true, function(v) 
    Yalat.State.speed = v and (Yalat.State.speed or 50) or nil
    local hum = getHum()
    if hum then hum.WalkSpeed = Yalat.State.speed or Yalat.Baseline.walkSpeed end
end)
createOptionBox(playerPage, "jump", "Jump (100)", ";jump 100", true, function(v) 
    Yalat.State.jump = v and (Yalat.State.jump or 100) or nil
    local hum = getHum()
    if hum then 
        hum.UseJumpPower = true
        hum.JumpPower = Yalat.State.jump or Yalat.Baseline.jumpPower
    end
end)

createOptionBox(worldPage, "shader", "Ultra Shader", ";shader", true, function(v) if v then enableShader() else disableShader() end end)
createOptionBox(worldPage, "water", "Realistic Water", ";water", true, function(v) if v then enableRealisticWater() else disableRealisticWater() end end)

createOptionBox(toolsPage, "sword", "Give Sword", ";sword", false, function() spawnItem("Sword") end)
createOptionBox(toolsPage, "bat", "Give Baseball Bat", ";bat", false, function() spawnItem("Bat") end)
createOptionBox(toolsPage, "apple", "Give Apple", ";apple", false, function() spawnItem("Apple") end)
createOptionBox(toolsPage, "speedcoil", "Give Speed Coil", ";speedcoil", false, function() spawnItem("SpeedCoil") end)

local rightList = Instance.new("Frame")
rightList.Size = UDim2.new(0.21, 0, 1, -50)
rightList.Position = UDim2.new(0.78, 0, 0, 42)
rightList.BackgroundColor3 = Color3.fromRGB(22, 14, 16)
rightList.Parent = main
corner(rightList, 8)
stroke(rightList, Color3.fromRGB(70, 20, 20), 1)

local cmdTitle = Instance.new("TextLabel")
cmdTitle.Position = UDim2.fromOffset(6, 6)
cmdTitle.Size = UDim2.new(1, -12, 0, 18)
cmdTitle.BackgroundTransparency = 1
cmdTitle.Text = "📋 CMDS LIST"
cmdTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
cmdTitle.Font = Enum.Font.GothamBold; cmdTitle.TextSize = 11
cmdTitle.TextXAlignment = Enum.TextXAlignment.Left
cmdTitle.Parent = rightList

local cmdScroll = Instance.new("ScrollingFrame")
cmdScroll.Size = UDim2.new(1, -8, 1, -28)
cmdScroll.Position = UDim2.fromOffset(4, 24)
cmdScroll.BackgroundTransparency = 1
cmdScroll.ScrollBarThickness = 2
cmdScroll.Parent = rightList

local cmdLayout = Instance.new("UIListLayout")
cmdLayout.Padding = UDim.new(0, 3)
cmdLayout.Parent = cmdScroll

local function addCmdListRow(cmd, desc)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 24)
    lbl.BackgroundTransparency = 1
    lbl.Text = cmd .. "\n- " .. desc
    lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
    lbl.Font = Enum.Font.Code; lbl.TextSize = 9
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = cmdScroll
end

addCmdListRow(";cmds / ;help", "Toggle GUI")
addCmdListRow(";god / ;ungod", "God Mode")
addCmdListRow(";noclip / ;clip", "Wall Noclip")
addCmdListRow(";spin / ;unspin", "Spin Player")
addCmdListRow(";fly / ;unfly", "Fly Mode")
addCmdListRow(";speed / ;ws", "Set WalkSpeed")
addCmdListRow(";unspeed", "Reset Speed")
addCmdListRow(";jump / ;jp", "Set JumpPower")
addCmdListRow(";set", "Save Position")
addCmdListRow(";tp", "Teleport Location")
addCmdListRow(";shader / ;unshader", "Ultra Shader")
addCmdListRow(";water / ;unwater", "Realistic Water")
addCmdListRow(";bat / ;apple", "Spawn Tools")
addCmdListRow(";sword / ;speedcoil", "Spawn Tools")

local bar = Instance.new("Frame")
bar.Name = "CommandBarFrame"
bar.Size = UDim2.new(0.85, 0, 0, 38)
bar.SizeConstraint = Enum.SizeConstraint.RelativeX
bar.AnchorPoint = Vector2.new(0.5, 1)
bar.Position = UDim2.new(0.5, 0, 1, -10)
bar.BackgroundColor3 = Color3.fromRGB(20, 12, 14)
bar.Visible = true
bar.Parent = gui
corner(bar, 19)
stroke(bar, Color3.fromRGB(220, 20, 20), 1.5)

local barConstraint = Instance.new("UISizeConstraint")
barConstraint.MaxSize = Vector2.new(500, 38)
barConstraint.MinSize = Vector2.new(260, 38)
barConstraint.Parent = bar

local box = Instance.new("TextBox")
box.Size = UDim2.new(1, -70, 1, 0)
box.Position = UDim2.fromOffset(12, 0)
box.BackgroundTransparency = 1
box.TextColor3 = Color3.fromRGB(255, 255, 255)
box.PlaceholderText = "Type command here... (e.g. ;shader, ;god)"
box.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
box.Font = Enum.Font.Code; box.TextSize = 12
box.TextXAlignment = Enum.TextXAlignment.Left
box.ClearTextOnFocus = false
box.Text = ""
box.Parent = bar

local clearBtn = Instance.new("TextButton")
clearBtn.Size = UDim2.fromOffset(24, 24)
clearBtn.Position = UDim2.new(1, -56, 0.5, -12)
clearBtn.BackgroundColor3 = Color3.fromRGB(80, 20, 20)
clearBtn.Text = "✕"; clearBtn.TextColor3 = Color3.fromRGB(255, 180, 180)
clearBtn.Font = Enum.Font.GothamBold; clearBtn.TextSize = 12
clearBtn.Parent = bar
corner(clearBtn, 12)

trackConn(clearBtn.Activated:Connect(function()
    box.Text = ""
    bar.Visible = false
end))

trackConn(cmdOpenBtn.Activated:Connect(function()
    bar.Visible = true
    box:CaptureFocus()
end))

local runBtn = Instance.new("TextButton")
runBtn.Size = UDim2.fromOffset(26, 26)
runBtn.Position = UDim2.new(1, -28, 0.5, -13)
runBtn.BackgroundColor3 = Color3.fromRGB(200, 20, 20)
runBtn.Text = "➤"; runBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
runBtn.Font = Enum.Font.GothamBold; runBtn.TextSize = 12
runBtn.Parent = bar
corner(runBtn, 13)

trackConn(UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.Semicolon then
        bar.Visible = not bar.Visible
        if bar.Visible then box:CaptureFocus() end
    end
end))

local function updateUIElement(key, state, subText)
    if Yalat.UIElements[key] then Yalat.UIElements[key](state, subText) end
end

-- 9. COMMAND PARSER ENGINE
function Yalat:Run(text)
    if not text or text == "" then return end
    
    text = text:gsub("^%s*;", ""):gsub("%s+$", "")
    local args = {}
    for word in text:gmatch("%S+") do table.insert(args, word) end
    if #args == 0 then return end

    local cmd = args[1]:lower()

    if cmd == "cmds" or cmd == "help" then 
        main.Visible = not main.Visible

    elseif cmd == "god" then 
        Yalat.State.god = true
        updateUIElement("god", true)
        showNotification("God Mode Enabled", false)

    elseif cmd == "ungod" then 
        Yalat.State.god = false
        updateUIElement("god", false)
        showNotification("God Mode Disabled", false)

    elseif cmd == "noclip" then 
        setNoclip(true)
        updateUIElement("noclip", true)
        showNotification("Noclip Enabled", false)

    elseif cmd == "clip" then 
        setNoclip(false)
        updateUIElement("noclip", false)
        showNotification("Noclip Disabled", false)

    elseif cmd == "fly" then 
        local val = tonumber(args[2]) or 50
        if val <= 0 or val > 1000 then
            showNotification("Fly speed must be 1-1000!", true)
            return
        end
        startFly(val)
        updateUIElement("fly", true, ";fly " .. tostring(val))
        showNotification("Fly Enabled (" .. val .. ")", false)

    elseif cmd == "unfly" then 
        stopFly(false)
        updateUIElement("fly", false)
        showNotification("Fly Disabled", false)

    elseif cmd == "spin" then 
        Yalat.State.spin = true
        updateUIElement("spin", true)
        showNotification("Spin Enabled", false)

    elseif cmd == "unspin" then 
        Yalat.State.spin = false
        updateUIElement("spin", false)
        showNotification("Spin Disabled", false)

    elseif cmd == "set" then 
        local r = getRoot()
        if r then 
            Yalat.SavedLocation = r.CFrame 
            showNotification("Position saved!", false)
        end

    elseif cmd == "tp" then 
        local r = getRoot()
        if r and Yalat.SavedLocation then 
            r.CFrame = Yalat.SavedLocation
            showNotification("Teleported to saved location!", false)
        else
            showNotification("No location saved!", true)
        end

    elseif cmd == "speed" or cmd == "ws" then 
        if not args[2] then
            showNotification("Specify speed value! (e.g. ;speed 50)", true)
            return
        end
        local val = tonumber(args[2])
        if not val or val < 0 or val > 1000 then
            showNotification("Invalid speed value (0-1000)!", true)
            return
        end
        Yalat.State.speed = val
        local hum = getHum()
        if hum then hum.WalkSpeed = val end
        updateUIElement("speed", true, ";speed " .. tostring(val))
        showNotification("WalkSpeed set to " .. val, false)

    elseif cmd == "unspeed" then 
        Yalat.State.speed = nil
        local hum = getHum()
        if hum then hum.WalkSpeed = Yalat.Baseline.walkSpeed end
        updateUIElement("speed", false)
        showNotification("Speed reset to default", false)

    elseif cmd == "jump" or cmd == "jp" then 
        if not args[2] then
            showNotification("Specify jump value! (e.g. ;jump 100)", true)
            return
        end
        local val = tonumber(args[2])
        if not val or val < 0 or val > 1000 then
            showNotification("Invalid jump value (0-1000)!", true)
            return
        end
        Yalat.State.jump = val
        local hum = getHum()
        if hum then 
            hum.UseJumpPower = true
            hum.JumpPower = val 
        end
        updateUIElement("jump", true, ";jump " .. tostring(val))
        showNotification("JumpPower set to " .. val, false)

    elseif cmd == "shader" then 
        enableShader()
        updateUIElement("shader", true)
        showNotification("Ultra Shader Enabled", false)

    elseif cmd == "unshader" then 
        disableShader()
        updateUIElement("shader", false)
        showNotification("Shader Disabled", false)

    elseif cmd == "water" then 
        enableRealisticWater()
        updateUIElement("water", true)
        showNotification("Realistic Water Enabled", false)

    elseif cmd == "unwater" or cmd == "resetwater" then 
        disableRealisticWater()
        updateUIElement("water", false)
        showNotification("Water Reset", false)

    elseif cmd == "sword" then spawnItem("Sword")
    elseif cmd == "bat" then spawnItem("Bat")
    elseif cmd == "apple" then spawnItem("Apple")
    elseif cmd == "speedcoil" then spawnItem("SpeedCoil")
    else
        showNotification("Unknown Command: ;" .. cmd, true)
    end
end

trackConn(runBtn.Activated:Connect(function()
    if box.Text ~= "" then 
        Yalat:Run(box.Text)
        box.Text = "" 
    end
end))

trackConn(box.FocusLost:Connect(function(enterPressed)
    if enterPressed and box.Text ~= "" then 
        Yalat:Run(box.Text)
        box.Text = "" 
    end
end))

-- 10. CHARACTER RESPAWN & RUNTIME CYCLES
local function onCharacterAdded(char)
    Yalat.OriginalCollisionMap = {}
    local hum = char:WaitForChild("Humanoid", 5)
    if hum then
        Yalat.Baseline.walkSpeed = hum.WalkSpeed
        Yalat.Baseline.jumpPower = hum.JumpPower
        Yalat.Baseline.useJumpPower = hum.UseJumpPower

        if Yalat.State.speed then hum.WalkSpeed = Yalat.State.speed end
        if Yalat.State.jump then 
            hum.UseJumpPower = true
            hum.JumpPower = Yalat.State.jump 
        end
    end

    if Yalat.State.shaderActive then applyHighlight(char) end
    if Yalat.State.noclip then setNoclip(true) end
    if Yalat.State.flyActive then startFly(Yalat.State.flySpeed) end
end

if LocalPlayer.Character then
    onCharacterAdded(LocalPlayer.Character)
end

trackConn(LocalPlayer.CharacterAdded:Connect(onCharacterAdded))

trackConn(RunService.Heartbeat:Connect(function(dt)
    local hum = getHum()
    local root = getRoot()
    
    if hum and hum.Health > 0 and Yalat.State.god then
        if hum.Health < hum.MaxHealth then
            hum.Health = hum.MaxHealth
        end
    end

    if root and Yalat.State.spin then
        root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(Yalat.State.spinSpeed * dt * 60), 0)
    end
end))

trackConn(RunService.Stepped:Connect(function()
    if Yalat.State.noclip then
        local char = getChar()
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end
    end
end))

-- 11. CENTRAL CLEANUP IMPLEMENTATION
_G.KhushalAdminCleanup = function()
    stopFly(false)
    disableShader()
    disableRealisticWater()
    setNoclip(false)

    -- Remove spawned tools
    for _, tool in ipairs(Yalat.SpawnedTools) do
        if tool and tool.Parent then
            tool:Destroy()
        end
    end
    Yalat.SpawnedTools = {}

    for _, conn in ipairs(connections) do
        if conn and conn.Connected then
            conn:Disconnect()
        end
    end
    connections = {}

    if gui and gui.Parent then
        gui:Destroy()
    end

    _G.KhushalAdminCleanup = nil
    print("KHUSHAL ADMIN PANEL: Cleaned up previous script instance.")
end

print("KHUSHAL ADMIN PANEL | CHILLI HUB EDITION EXECUTOR ENGINE LOADED")
