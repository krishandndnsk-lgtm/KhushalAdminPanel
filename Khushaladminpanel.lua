--[[
    KHUSHAL ADMIN PANEL | CHILLI HUB EDITION
    Wide Clean Layout + Clear 'X' Button on Command Bar
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

if PlayerGui:FindFirstChild("KhushalChilliHubFullUI") then
    PlayerGui.KhushalChilliHubFullUI:Destroy()
end

local Yalat = {
    Commands = {},
    CmdList = {},
    SavedLocation = nil,
    UIElements = {},
    OriginalCollisionMap = {},
    State = {
        speed = nil, jump = nil, noclip = false, god = false, 
        spin = false, spinSpeed = 10, shaderActive = false, 
        waterActive = false, flyActive = false, holdingSpeedCoil = false
    }
}

local function getChar() return LocalPlayer.Character end
local function getHum()
    local c = LocalPlayer.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function getRoot()
    local c = LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function corner(inst, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = inst
end

local function stroke(inst, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or Color3.fromRGB(200, 20, 20)
    s.Thickness = thickness or 1
    s.Parent = inst
end

-- Mobile Fly Touch Controls
local mobileFlyUp = false
local mobileFlyDown = false
local flyObj = { conn = nil, lv = nil, ao = nil, attachment = nil }

local function stopFly()
    if flyObj.conn then flyObj.conn:Disconnect() flyObj.conn = nil end
    if flyObj.lv then flyObj.lv:Destroy() flyObj.lv = nil end
    if flyObj.ao then flyObj.ao:Destroy() flyObj.ao = nil end
    if flyObj.attachment then flyObj.attachment:Destroy() flyObj.attachment = nil end
    
    local hum = getHum()
    if hum then hum.PlatformStand = false end
    
    Yalat.State.flyActive = false
    if PlayerGui:FindFirstChild("MobileFlyControls") then
        PlayerGui.MobileFlyControls.Visible = false
    end
end

local function startFly(speed)
    stopFly()
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

    if PlayerGui:FindFirstChild("MobileFlyControls") then
        PlayerGui.MobileFlyControls.Visible = true
    end

    flyObj.conn = RunService.RenderStepped:Connect(function()
        local cam = Workspace.CurrentCamera
        if not (root.Parent and cam) then return stopFly() end
        local md = hum.MoveDirection
        local look = cam.CFrame.LookVector
        local flat = Vector3.new(look.X, 0, look.Z)
        local vel = md

        if flat.Magnitude > 0.01 then
            flat = flat.Unit
            local flatRight = flat:Cross(Vector3.yAxis)
            vel = look * md:Dot(flat) + cam.CFrame.RightVector * md:Dot(flatRight)
            flyObj.ao.CFrame = CFrame.new(root.Position, root.Position + flat)
        end

        if UserInputService:IsKeyDown(Enum.KeyCode.E) or UserInputService:IsKeyDown(Enum.KeyCode.Space) or mobileFlyUp then 
            vel = vel + Vector3.yAxis 
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Q) or mobileFlyDown then 
            vel = vel - Vector3.yAxis 
        end
        flyObj.lv.VectorVelocity = vel * speed
    end)
end

-- Noclip Manager
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

-- Working Tool Spawner
local function spawnItem(itemName)
    local char = getChar()
    if not char then return end

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
        tool.Activated:Connect(function()
            if isAttacking then return end
            isAttacking = true
            
            local anim = Instance.new("Animation")
            anim.AnimationId = "rbxassetid://125906970"
            local hum = getHum()
            if hum then
                local track = hum:LoadAnimation(anim)
                track:Play()
            end
            task.delay(0.5, function() isAttacking = false end)
        end)

        handle.Touched:Connect(function(hit)
            if not isAttacking then return end
            local enemyHum = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
            if enemyHum and hit.Parent ~= char then
                enemyHum:TakeDamage(25)
            end
        end)

    elseif lower == "speedcoil" then
        handle.BrickColor = BrickColor.new("Bright blue")
        tool.Equipped:Connect(function()
            Yalat.State.holdingSpeedCoil = true
            local hum = getHum()
            if hum then hum.WalkSpeed = 50 end
        end)
        tool.Unequipped:Connect(function()
            Yalat.State.holdingSpeedCoil = false
            local hum = getHum()
            if hum then hum.WalkSpeed = Yalat.State.speed or 16 end
        end)
    elseif lower == "apple" then
        handle.Shape = Enum.PartType.Ball
        handle.BrickColor = BrickColor.new("Bright red")
        tool.Activated:Connect(function()
            local hum = getHum()
            if hum then
                hum.Health = math.min(hum.MaxHealth, hum.Health + 20)
                tool:Destroy()
            end
        end)
    end

    tool.Parent = LocalPlayer:WaitForChild("Backpack")
end

-- Water Effects
local waterBackup = {}
local function enableRealisticWater()
    local terrain = Workspace:FindFirstChildOfClass("Terrain")
    if terrain then
        if not Yalat.State.waterActive then
            waterBackup.Color = terrain.WaterColor
            waterBackup.WaveSize = terrain.WaterWaveSize
            waterBackup.WaveSpeed = terrain.WaterWaveSpeed
            waterBackup.Transparency = terrain.WaterTransparency
            waterBackup.Reflectance = terrain.WaterReflectance
        end
        Yalat.State.waterActive = true
        terrain.WaterColor = Color3.fromRGB(10, 110, 170)
        terrain.WaterTransparency = 0.88
        terrain.WaterWaveSize = 0.45
        terrain.WaterWaveSpeed = 16
        terrain.WaterReflectance = 0.85
    end
end

local function disableRealisticWater()
    local terrain = Workspace:FindFirstChildOfClass("Terrain")
    if terrain and Yalat.State.waterActive then
        Yalat.State.waterActive = false
        if waterBackup.Color then
            terrain.WaterColor = waterBackup.Color
            terrain.WaterTransparency = waterBackup.Transparency
            terrain.WaterWaveSize = waterBackup.WaveSize
            terrain.WaterWaveSpeed = waterBackup.WaveSpeed
            terrain.WaterReflectance = waterBackup.Reflectance
        end
    end
end

-- Shader Effects
local lightingBackup = {}
local shaderStorage = { FX = {}, Highlight = nil }

local function applyHighlight(char)
    if not char then return end
    if shaderStorage.Highlight then shaderStorage.Highlight:Destroy() end
    local hl = Instance.new("Highlight")
    hl.Name = "RainbowGlow"
    hl.FillTransparency = 0.5
    hl.Adornee = char
    hl.Parent = char
    shaderStorage.Highlight = hl
end

local function enableShader()
    if Yalat.State.shaderActive then return end
    
    lightingBackup.Brightness = Lighting.Brightness
    lightingBackup.ClockTime = Lighting.ClockTime
    lightingBackup.GlobalShadows = Lighting.GlobalShadows

    Yalat.State.shaderActive = true
    Lighting.Brightness = 2.8
    Lighting.ClockTime = 14
    Lighting.GlobalShadows = true

    local bloom = Instance.new("BloomEffect", Lighting)
    bloom.Intensity = 0.5
    bloom.Size = 28
    bloom.Threshold = 0.75
    table.insert(shaderStorage.FX, bloom)

    local cc = Instance.new("ColorCorrectionEffect", Lighting)
    cc.Brightness = 0.05
    cc.Contrast = 0.15
    cc.Saturation = 0.25
    table.insert(shaderStorage.FX, cc)

    local sunRays = Instance.new("SunRaysEffect", Lighting)
    sunRays.Intensity = 0.3
    sunRays.Spread = 0.8
    table.insert(shaderStorage.FX, sunRays)

    applyHighlight(getChar())
end

local function disableShader()
    if not Yalat.State.shaderActive then return end
    Yalat.State.shaderActive = false

    if lightingBackup.Brightness then Lighting.Brightness = lightingBackup.Brightness end
    if lightingBackup.ClockTime then Lighting.ClockTime = lightingBackup.ClockTime end
    if lightingBackup.GlobalShadows ~= nil then Lighting.GlobalShadows = lightingBackup.GlobalShadows end

    for _, fx in ipairs(shaderStorage.FX) do
        if fx and fx.Parent then fx:Destroy() end
    end
    shaderStorage.FX = {}

    if shaderStorage.Highlight then
        shaderStorage.Highlight:Destroy()
        shaderStorage.Highlight = nil
    end
end

-- GUI Setup
local gui = Instance.new("ScreenGui")
gui.Name = "KhushalChilliHubFullUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 9999
gui.Parent = PlayerGui

-- Mobile Fly Touch Controls
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
upBtn.Text = "▲"
upBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
upBtn.Font = Enum.Font.GothamBold
upBtn.TextSize = 18
upBtn.Parent = flyUI
corner(upBtn, 22)

local downBtn = Instance.new("TextButton")
downBtn.Size = UDim2.fromOffset(45, 45)
downBtn.Position = UDim2.fromOffset(0, 55)
downBtn.BackgroundColor3 = Color3.fromRGB(180, 20, 20)
downBtn.Text = "▼"
downBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
downBtn.Font = Enum.Font.GothamBold
downBtn.TextSize = 18
downBtn.Parent = flyUI
corner(downBtn, 22)

upBtn.MouseButton1Down:Connect(function() mobileFlyUp = true end)
upBtn.MouseButton1Up:Connect(function() mobileFlyUp = false end)
downBtn.MouseButton1Down:Connect(function() mobileFlyDown = true end)
downBtn.MouseButton1Up:Connect(function() mobileFlyDown = false end)

-- Floating Open/Close Button
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.fromOffset(100, 36)
toggleBtn.Position = UDim2.new(1, -110, 0, 40)
toggleBtn.BackgroundColor3 = Color3.fromRGB(180, 10, 10)
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 13
toggleBtn.Text = "KHUSHAL"
toggleBtn.Parent = gui
corner(toggleBtn, 8)
stroke(toggleBtn, Color3.fromRGB(255, 40, 40), 1.5)

-- Main Wide Dashboard Panel
local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(780, 420)
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.Position = UDim2.fromScale(0.5, 0.45)
main.BackgroundColor3 = Color3.fromRGB(15, 10, 12)
main.Visible = true
main.Parent = gui
corner(main, 12)
stroke(main, Color3.fromRGB(220, 20, 20), 2)

toggleBtn.Activated:Connect(function() main.Visible = not main.Visible end)

-- Header Bar
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 45)
header.BackgroundTransparency = 1
header.Parent = main

local title = Instance.new("TextLabel")
title.Position = UDim2.fromOffset(15, 8)
title.Size = UDim2.new(1, -60, 1, -16)
title.BackgroundTransparency = 1
title.Text = "KHUSHAL ADMIN PANEL | CHILLI HUB EDITION"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 15
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(30, 30)
closeBtn.Position = UDim2.new(1, -38, 0, 8)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 20, 20)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.Parent = header
corner(closeBtn, 6)
closeBtn.Activated:Connect(function() main.Visible = false end)

-- Left Sidebar
local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, 130, 1, -55)
sidebar.Position = UDim2.fromOffset(10, 45)
sidebar.BackgroundColor3 = Color3.fromRGB(22, 14, 16)
sidebar.Parent = main
corner(sidebar, 8)
stroke(sidebar, Color3.fromRGB(60, 20, 20), 1)

local tabBtns = {}
local tabPages = {}

local function createTabBtn(name, iconText)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -12, 0, 36)
    btn.Position = UDim2.fromOffset(6, #tabBtns * 42 + 8)
    btn.BackgroundColor3 = (#tabBtns == 0) and Color3.fromRGB(180, 20, 20) or Color3.fromRGB(30, 18, 20)
    btn.Text = iconText .. " " .. name
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.Parent = sidebar
    corner(btn, 6)

    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(0, 440, 1, -55)
    page.Position = UDim2.fromOffset(150, 45)
    page.BackgroundTransparency = 1
    page.ScrollBarThickness = 4
    page.Visible = (#tabBtns == 0)
    page.Parent = main

    btn.Activated:Connect(function()
        for _, b in ipairs(tabBtns) do b.BackgroundColor3 = Color3.fromRGB(30, 18, 20) end
        for _, p in ipairs(tabPages) do p.Visible = false end
        btn.BackgroundColor3 = Color3.fromRGB(180, 20, 20)
        page.Visible = true
    end)

    table.insert(tabBtns, btn)
    table.insert(tabPages, page)
    return page
end

local playerPage = createTabBtn("Player", "👤")
local worldPage = createTabBtn("World", "🌐")
local toolsPage = createTabBtn("Tools", "🛠️")

-- Logo Frame
local logoFrame = Instance.new("Frame")
logoFrame.Size = UDim2.new(1, -12, 0, 90)
logoFrame.Position = UDim2.new(0, 6, 1, -98)
logoFrame.BackgroundColor3 = Color3.fromRGB(35, 10, 12)
logoFrame.Parent = sidebar
corner(logoFrame, 8)
stroke(logoFrame, Color3.fromRGB(200, 30, 30), 1)

local logoText = Instance.new("TextLabel")
logoText.Size = UDim2.new(1, 0, 1, 0)
logoText.BackgroundTransparency = 1
logoText.Text = "🌶️\nCHILLI HUB"
logoText.TextColor3 = Color3.fromRGB(255, 50, 50)
logoText.Font = Enum.Font.GothamBlack
logoText.TextSize = 14
logoText.Parent = logoFrame

local function setupGrid(page)
    local grid = Instance.new("UIGridLayout")
    grid.CellSize = UDim2.new(0.48, 0, 0, 52)
    grid.CellPadding = UDim2.new(0.03, 0, 0, 8)
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
    t1.Position = UDim2.fromOffset(8, 6)
    t1.Size = UDim2.new(0.65, 0, 0, 18)
    t1.BackgroundTransparency = 1
    t1.Text = mainTitle
    t1.TextColor3 = Color3.fromRGB(255, 255, 255)
    t1.Font = Enum.Font.GothamBold
    t1.TextSize = 12
    t1.TextXAlignment = Enum.TextXAlignment.Left
    t1.Parent = box

    local t2 = Instance.new("TextLabel")
    t2.Position = UDim2.fromOffset(8, 26)
    t2.Size = UDim2.new(0.65, 0, 0, 16)
    t2.BackgroundTransparency = 1
    t2.Text = "(" .. subTitle .. ")"
    t2.TextColor3 = Color3.fromRGB(160, 160, 160)
    t2.Font = Enum.Font.Code
    t2.TextSize = 10
    t2.TextXAlignment = Enum.TextXAlignment.Left
    t2.Parent = box

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.fromOffset(45, 24)
    btn.Position = UDim2.new(1, -52, 0.5, -12)
    btn.BackgroundColor3 = isToggle and Color3.fromRGB(80, 80, 80) or Color3.fromRGB(180, 20, 20)
    btn.Text = isToggle and "OFF" or "RUN"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    btn.Parent = box
    corner(btn, 4)

    local state = false
    local function updateUI(val)
        state = val
        if isToggle then
            btn.BackgroundColor3 = state and Color3.fromRGB(0, 180, 70) or Color3.fromRGB(80, 80, 80)
            btn.Text = state and "ON" or "OFF"
        end
    end

    btn.Activated:Connect(function()
        if isToggle then
            state = not state
            updateUI(state)
            callback(state)
        else
            callback(true)
        end
    end)

    Yalat.UIElements[nameKey] = updateUI
end

-- PLAYER TAB
createOptionBox(playerPage, "god", "God Mode", ";god", true, function(v) Yalat.State.god = v end)
createOptionBox(playerPage, "noclip", "Noclip", ";noclip", true, function(v) setNoclip(v) end)
createOptionBox(playerPage, "spin", "Spin Player", ";spin", true, function(v) Yalat.State.spin = v end)
createOptionBox(playerPage, "fly", "Fly Mode", ";fly 50", true, function(v) if v then startFly(50) else stopFly() end end)
createOptionBox(playerPage, "set", "Set Location", ";set", false, function() local r = getRoot(); if r then Yalat.SavedLocation = r.CFrame end end)
createOptionBox(playerPage, "tp", "Teleport Saved", ";tp", false, function() local r = getRoot(); if r and Yalat.SavedLocation then r.CFrame = Yalat.SavedLocation end end)
createOptionBox(playerPage, "speed", "Speed (50)", ";speed 50", true, function(v) Yalat.State.speed = v and 50 or 16 end)
createOptionBox(playerPage, "jump", "Jump (100)", ";jump 100", true, function(v) Yalat.State.jump = v and 100 or 50 end)

-- WORLD TAB
createOptionBox(worldPage, "shader", "Shader Effects", ";shader", true, function(v) if v then enableShader() else disableShader() end end)
createOptionBox(worldPage, "water", "Realistic Water", ";water", true, function(v) if v then enableRealisticWater() else disableRealisticWater() end end)

-- TOOLS TAB
createOptionBox(toolsPage, "sword", "Give Sword", ";sword", false, function() spawnItem("Sword") end)
createOptionBox(toolsPage, "bat", "Give Baseball Bat", ";bat", false, function() spawnItem("Bat") end)
createOptionBox(toolsPage, "apple", "Give Apple", ";apple", false, function() spawnItem("Apple") end)
createOptionBox(toolsPage, "speedcoil", "Give Speed Coil", ";speedcoil", false, function() spawnItem("SpeedCoil") end)

-- RIGHT PANEL: CMDS LIST
local rightList = Instance.new("Frame")
rightList.Size = UDim2.new(0, 170, 1, -55)
rightList.Position = UDim2.fromOffset(600, 45)
rightList.BackgroundColor3 = Color3.fromRGB(22, 14, 16)
rightList.Parent = main
corner(rightList, 8)
stroke(rightList, Color3.fromRGB(70, 20, 20), 1)

local cmdTitle = Instance.new("TextLabel")
cmdTitle.Position = UDim2.fromOffset(8, 8)
cmdTitle.Size = UDim2.new(1, -16, 0, 20)
cmdTitle.BackgroundTransparency = 1
cmdTitle.Text = "📋 CMDS LIST"
cmdTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
cmdTitle.Font = Enum.Font.GothamBold
cmdTitle.TextSize = 12
cmdTitle.TextXAlignment = Enum.TextXAlignment.Left
cmdTitle.Parent = rightList

local cmdScroll = Instance.new("ScrollingFrame")
cmdScroll.Size = UDim2.new(1, -10, 1, -32)
cmdScroll.Position = UDim2.fromOffset(5, 28)
cmdScroll.BackgroundTransparency = 1
cmdScroll.ScrollBarThickness = 3
cmdScroll.Parent = rightList

local cmdLayout = Instance.new("UIListLayout")
cmdLayout.Padding = UDim.new(0, 4)
cmdLayout.Parent = cmdScroll

local function addCmdListRow(cmd, desc)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 26)
    lbl.BackgroundTransparency = 1
    lbl.Text = ";" .. cmd .. "\n- " .. desc
    lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
    lbl.Font = Enum.Font.Code
    lbl.TextSize = 10
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = cmdScroll
end

addCmdListRow("cmds / ;help", "Toggle GUI")
addCmdListRow("god / ;ungod", "God Mode")
addCmdListRow("noclip / ;clip", "Wall Noclip")
addCmdListRow("spin / ;unspin", "Spin Player")
addCmdListRow("fly / ;unfly", "Fly Mode")
addCmdListRow("speed / ;ws", "Set WalkSpeed")
addCmdListRow("unspeed", "Reset Speed")
addCmdListRow("jump / ;jp", "Set JumpPower")
addCmdListRow("set", "Save Position")
addCmdListRow("tp", "Teleport Location")
addCmdListRow("shader / ;unshader", "Shader Effects")
addCmdListRow("water / ;unwater", "Realistic Water")
addCmdListRow("bat / apple", "Spawn Tools")
addCmdListRow("sword / speedcoil", "Spawn Tools")

-- BOTTOM FLOATING COMMAND BAR WITH CLEAR 'X' BUTTON
local bar = Instance.new("Frame")
bar.Size = UDim2.fromOffset(480, 40)
bar.AnchorPoint = Vector2.new(0.5, 1)
bar.Position = UDim2.new(0.5, 0, 1, -12)
bar.BackgroundColor3 = Color3.fromRGB(20, 12, 14)
bar.Parent = gui
corner(bar, 20)
stroke(bar, Color3.fromRGB(220, 20, 20), 1.5)

local box = Instance.new("TextBox")
box.Size = UDim2.new(1, -75, 1, 0)
box.Position = UDim2.fromOffset(15, 0)
box.BackgroundTransparency = 1
box.TextColor3 = Color3.fromRGB(255, 255, 255)
box.PlaceholderText = "Type command here... (e.g. ;shader, ;god)"
box.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
box.Font = Enum.Font.Code
box.TextSize = 13
box.TextXAlignment = Enum.TextXAlignment.Left
box.ClearTextOnFocus = false
box.Text = ""
box.Parent = bar

-- Clear/Close 'X' Button on Command Bar
local clearBtn = Instance.new("TextButton")
clearBtn.Size = UDim2.fromOffset(26, 26)
clearBtn.Position = UDim2.new(1, -62, 0.5, -13)
clearBtn.BackgroundColor3 = Color3.fromRGB(80, 20, 20)
clearBtn.Text = "✕"
clearBtn.TextColor3 = Color3.fromRGB(255, 180, 180)
clearBtn.Font = Enum.Font.GothamBold
clearBtn.TextSize = 13
clearBtn.Parent = bar
corner(clearBtn, 13)

clearBtn.Activated:Connect(function()
    box.Text = ""
end)

local runBtn = Instance.new("TextButton")
runBtn.Size = UDim2.fromOffset(28, 28)
runBtn.Position = UDim2.new(1, -32, 0.5, -14)
runBtn.BackgroundColor3 = Color3.fromRGB(200, 20, 20)
runBtn.Text = "➤"
runBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
runBtn.Font = Enum.Font.GothamBold
runBtn.TextSize = 13
runBtn.Parent = bar
corner(runBtn, 14)

local function updateUIElement(key, state)
    if Yalat.UIElements[key] then Yalat.UIElements[key](state) end
end

-- Command Runner
function Yalat:Run(text)
    text = text:match("^%s*(.-)%s*$"):gsub("^;", "")
    local args = {}
    for word in text:gmatch("%S+") do table.insert(args, word) end
    if #args == 0 then return end

    local cmd = args[1]:lower()
    if cmd == "cmds" or cmd == "help" then 
        main.Visible = not main.Visible
    elseif cmd == "god" then 
        Yalat.State.god = true; updateUIElement("god", true)
    elseif cmd == "ungod" then 
        Yalat.State.god = false; updateUIElement("god", false)
    elseif cmd == "noclip" then 
        setNoclip(true); updateUIElement("noclip", true)
    elseif cmd == "clip" then 
        setNoclip(false); updateUIElement("noclip", false)
    elseif cmd == "fly" then 
        startFly(tonumber(args[2]) or 50); updateUIElement("fly", true)
    elseif cmd == "unfly" then 
        stopFly(); updateUIElement("fly", false)
    elseif cmd == "spin" then 
        Yalat.State.spin = true; updateUIElement("spin", true)
    elseif cmd == "unspin" then 
        Yalat.State.spin = false; updateUIElement("spin", false)
    elseif cmd == "set" then 
        local r = getRoot(); if r then Yalat.SavedLocation = r.CFrame end
    elseif cmd == "tp" then 
        local r = getRoot(); if r and Yalat.SavedLocation then r.CFrame = Yalat.SavedLocation end
    elseif cmd == "speed" or cmd == "ws" then 
        Yalat.State.speed = tonumber(args[2]) or 50; updateUIElement("speed", true)
    elseif cmd == "unspeed" then 
        Yalat.State.speed = 16; updateUIElement("speed", false)
    elseif cmd == "jump" or cmd == "jp" then 
        Yalat.State.jump = tonumber(args[2]) or 100; updateUIElement("jump", true)
    elseif cmd == "shader" then 
        enableShader(); updateUIElement("shader", true)
    elseif cmd == "unshader" then 
        disableShader(); updateUIElement("shader", false)
    elseif cmd == "water" then 
        enableRealisticWater(); updateUIElement("water", true)
    elseif cmd == "unwater" or cmd == "resetwater" then 
        disableRealisticWater(); updateUIElement("water", false)
    elseif cmd == "sword" then spawnItem("Sword")
    elseif cmd == "bat" then spawnItem("Bat")
    elseif cmd == "apple" then spawnItem("Apple")
    elseif cmd == "speedcoil" then spawnItem("SpeedCoil")
    end
end

runBtn.Activated:Connect(function()
    if box.Text ~= "" then Yalat:Run(box.Text); box.Text = "" end
end)

box.FocusLost:Connect(function(enterPressed)
    if enterPressed and box.Text ~= "" then Yalat:Run(box.Text); box.Text = "" end
end)

-- Auto Respawn Handler
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    local hum = char:WaitForChild("Humanoid", 5)
    if hum then
        if Yalat.State.speed then hum.WalkSpeed = Yalat.State.speed end
        if Yalat.State.jump then hum.UseJumpPower = true; hum.JumpPower = Yalat.State.jump end
    end
    if Yalat.State.shaderActive then applyHighlight(char) end
    if Yalat.State.noclip then setNoclip(true) end
end)

-- Heartbeat Loop
RunService.Heartbeat:Connect(function(dt)
    local hum = getHum()
    local root = getRoot()
    if hum then
        if Yalat.State.speed and not Yalat.State.holdingSpeedCoil and hum.WalkSpeed ~= Yalat.State.speed then 
            hum.WalkSpeed = Yalat.State.speed 
        end
        if Yalat.State.jump then 
            hum.UseJumpPower = true; hum.JumpPower = Yalat.State.jump 
        end
        if Yalat.State.god and hum.Health < hum.MaxHealth then 
            hum.Health = hum.MaxHealth 
        end
    end
    if root and Yalat.State.spin then 
        root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(Yalat.State.spinSpeed * dt * 60), 0) 
    end
end)

-- Stepped Loop for Noclip
RunService.Stepped:Connect(function()
    if Yalat.State.noclip then
        local char = getChar()
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end
    end
end)

print("KHUSHAL ADMIN PANEL | CHILLI HUB EDITION LOADED")
