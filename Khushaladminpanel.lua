--[[
    KHUSHAL ADMIN PANEL | CHILLI HUB EDITION
    Full Features: Player, World, Tools, Shader, Water, Spawners & Short Commands
    All Syntax Errors Fixed
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
    State = {
        speed = nil, jump = nil, noclip = false, god = false, 
        spin = false, spinSpeed = 10, shaderActive = false
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

--// Flight Engine
local flyObj = { conn = nil, bv = nil, bg = nil }
local function stopFly()
    if flyObj.conn then flyObj.conn:Disconnect() flyObj.conn = nil end
    if flyObj.bv then flyObj.bv:Destroy() flyObj.bv = nil end
    if flyObj.bg then flyObj.bg:Destroy() flyObj.bg = nil end
    local hum = getHum()
    if hum then hum.PlatformStand = false end
end

local function startFly(speed)
    stopFly()
    local root, hum = getRoot(), getHum()
    if not (root and hum) then return end

    flyObj.bv = Instance.new("BodyVelocity")
    flyObj.bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    flyObj.bv.Velocity = Vector3.zero
    flyObj.bv.Parent = root

    flyObj.bg = Instance.new("BodyGyro")
    flyObj.bg.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
    flyObj.bg.P = 9e4
    flyObj.bg.CFrame = root.CFrame
    flyObj.bg.Parent = root

    hum.PlatformStand = true

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
            flyObj.bg.CFrame = CFrame.new(root.Position, root.Position + flat)
        end

        if UserInputService:IsKeyDown(Enum.KeyCode.E) or UserInputService:IsKeyDown(Enum.KeyCode.Space) then vel += Vector3.yAxis end
        if UserInputService:IsKeyDown(Enum.KeyCode.Q) then vel -= Vector3.yAxis end
        flyObj.bv.Velocity = vel * speed
    end)
end

--// Spawner Engine
local function spawnItem(itemName)
    local char = getChar()
    if not char then return end
    local tool = Instance.new("Tool")
    tool.Name = itemName
    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(1, 1, 1)
    handle.Parent = tool
    tool.Parent = LocalPlayer:WaitForChild("Backpack")
end

--// Realistic Water System
local waterDefaults = {}
local terrain = Workspace:FindFirstChildOfClass("Terrain")

if terrain then
    waterDefaults.Color = terrain.WaterColor
    waterDefaults.WaveSize = terrain.WaterWaveSize
    waterDefaults.WaveSpeed = terrain.WaterWaveSpeed
    waterDefaults.Transparency = terrain.WaterTransparency
    waterDefaults.Reflectance = terrain.WaterReflectance
end

local function enableRealisticWater()
    terrain = Workspace:FindFirstChildOfClass("Terrain")
    if terrain then
        terrain.WaterColor = Color3.fromRGB(15, 120, 185)
        terrain.WaterTransparency = 0.85
        terrain.WaterWaveSize = 0.35
        terrain.WaterWaveSpeed = 12
        terrain.WaterReflectance = 0.75
    end
end

local function disableRealisticWater()
    terrain = Workspace:FindFirstChildOfClass("Terrain")
    if terrain and waterDefaults.Color then
        terrain.WaterColor = waterDefaults.Color
        terrain.WaterTransparency = waterDefaults.Transparency
        terrain.WaterWaveSize = waterDefaults.WaveSize
        terrain.WaterWaveSpeed = waterDefaults.WaveSpeed
        terrain.WaterReflectance = waterDefaults.Reflectance
    end
end

--// Shader Engine
local shaderStorage = { FX = {}, Highlight = nil }

local function enableShader()
    if Yalat.State.shaderActive then return end
    Yalat.State.shaderActive = true

    Lighting.Brightness = 2.5
    Lighting.ClockTime = 14

    local bloom = Instance.new("BloomEffect", Lighting)
    bloom.Intensity = 0.4
    bloom.Size = 24
    bloom.Threshold = 0.8
    table.insert(shaderStorage.FX, bloom)

    local char = getChar()
    if char then
        local hl = Instance.new("Highlight")
        hl.Name = "RainbowGlow"
        hl.FillTransparency = 0.5
        hl.Adornee = char
        hl.Parent = char
        shaderStorage.Highlight = hl
    end
end

local function disableShader()
    Yalat.State.shaderActive = false
    Lighting.Brightness = 1

    for _, fx in ipairs(shaderStorage.FX) do
        if fx and fx.Parent then fx:Destroy() end
    end
    shaderStorage.FX = {}

    if shaderStorage.Highlight then
        shaderStorage.Highlight:Destroy()
        shaderStorage.Highlight = nil
    end
end

--// Main GUI Setup
local gui = Instance.new("ScreenGui")
gui.Name = "KhushalChilliHubFullUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 9999
gui.Parent = PlayerGui

-- Open/Close Floating Button
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.fromOffset(100, 36)
toggleBtn.Position = UDim2.new(1, -110, 0, 50)
toggleBtn.BackgroundColor3 = Color3.fromRGB(180, 10, 10)
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 13
toggleBtn.Text = "KHUSHAL"
toggleBtn.Parent = gui
corner(toggleBtn, 8)
stroke(toggleBtn, Color3.fromRGB(255, 40, 40), 1.5)

-- Main Dashboard Frame
local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(820, 460)
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.Position = UDim2.fromScale(0.5, 0.45)
main.BackgroundColor3 = Color3.fromRGB(15, 10, 12)
main.Visible = true
main.Parent = gui
corner(main, 12)
stroke(main, Color3.fromRGB(220, 20, 20), 2)

toggleBtn.Activated:Connect(function()
    main.Visible = not main.Visible
end)

-- Header Bar
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 50)
header.BackgroundTransparency = 1
header.Parent = main

local title = Instance.new("TextLabel")
title.Position = UDim2.fromOffset(20, 10)
title.Size = UDim2.fromOffset(400, 30)
title.BackgroundTransparency = 1
title.Text = "KHUSHAL ADMIN PANEL  |  CHILLI HUB EDITION"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(32, 32)
closeBtn.Position = UDim2.new(1, -42, 0, 9)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 20, 20)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 16
closeBtn.Parent = header
corner(closeBtn, 6)
closeBtn.Activated:Connect(function() main.Visible = false end)

-- Left Sidebar Tabs
local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, 130, 1, -60)
sidebar.Position = UDim2.fromOffset(12, 52)
sidebar.BackgroundColor3 = Color3.fromRGB(22, 14, 16)
sidebar.Parent = main
corner(sidebar, 8)
stroke(sidebar, Color3.fromRGB(60, 20, 20), 1)

local tabBtns = {}
local tabPages = {}

local function createTabBtn(name, iconText)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -16, 0, 36)
    btn.Position = UDim2.fromOffset(8, #tabBtns * 42 + 10)
    btn.BackgroundColor3 = (#tabBtns == 0) and Color3.fromRGB(180, 20, 20) or Color3.fromRGB(30, 18, 20)
    btn.Text = iconText .. "  " .. name
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.Parent = sidebar
    corner(btn, 6)

    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(0, 470, 1, -60)
    page.Position = UDim2.fromOffset(150, 52)
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

-- Chilli Hub Logo Graphic
local logoFrame = Instance.new("Frame")
logoFrame.Size = UDim2.new(1, -16, 0, 110)
logoFrame.Position = UDim2.new(0, 8, 1, -118)
logoFrame.BackgroundColor3 = Color3.fromRGB(35, 10, 12)
logoFrame.Parent = sidebar
corner(logoFrame, 8)
stroke(logoFrame, Color3.fromRGB(200, 30, 30), 1)

local logoText = Instance.new("TextLabel")
logoText.Size = UDim2.new(1, 0, 1, 0)
logoText.BackgroundTransparency = 1
logoText.Text = "🌶️\nCHILLI\nHUB"
logoText.TextColor3 = Color3.fromRGB(255, 50, 50)
logoText.Font = Enum.Font.GothamBlack
logoText.TextSize = 15
logoText.Parent = logoFrame

local function setupGrid(page)
    local grid = Instance.new("UIGridLayout")
    grid.CellSize = UDim2.new(0.48, 0, 0, 48)
    grid.CellPadding = UDim2.new(0.03, 0, 0, 8)
    grid.Parent = page
end

setupGrid(playerPage)
setupGrid(worldPage)
setupGrid(toolsPage)

local function createOptionBox(parent, mainTitle, subTitle, isToggle, callback)
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
    t2.Position = UDim2.fromOffset(8, 24)
    t2.Size = UDim2.new(0.65, 0, 0, 16)
    t2.BackgroundTransparency = 1
    t2.Text = "(" .. subTitle .. ")"
    t2.TextColor3 = Color3.fromRGB(160, 160, 160)
    t2.Font = Enum.Font.Code
    t2.TextSize = 10
    t2.TextXAlignment = Enum.TextXAlignment.Left
    t2.Parent = box

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.fromOffset(42, 22)
    btn.Position = UDim2.new(1, -48, 0.5, -11)
    btn.BackgroundColor3 = isToggle and Color3.fromRGB(80, 80, 80) or Color3.fromRGB(180, 20, 20)
    btn.Text = isToggle and "OFF" or "RUN"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    btn.Parent = box
    corner(btn, 4)

    local state = false
    btn.Activated:Connect(function()
        if isToggle then
            state = not state
            btn.BackgroundColor3 = state and Color3.fromRGB(0, 180, 70) or Color3.fromRGB(80, 80, 80)
            btn.Text = state and "ON" or "OFF"
            callback(state)
        else
            callback(true)
        end
    end)
end

-- PLAYER TAB
createOptionBox(playerPage, "God Mode", ";god", true, function(v) Yalat.State.god = v end)
createOptionBox(playerPage, "Noclip", ";noclip", true, function(v) Yalat.State.noclip = v end)
createOptionBox(playerPage, "Spin Player", ";spin", true, function(v) Yalat.State.spin = v end)
createOptionBox(playerPage, "Fly Mode", ";fly 50", true, function(v) if v then startFly(50) else stopFly() end end)
createOptionBox(playerPage, "Set Location", ";set", false, function() local r = getRoot(); if r then Yalat.SavedLocation = r.CFrame end end)
createOptionBox(playerPage, "Teleport Saved", ";tp", false, function() local r = getRoot(); if r and Yalat.SavedLocation then r.CFrame = Yalat.SavedLocation end end)
createOptionBox(playerPage, "Speed (50)", ";speed 50", true, function(v) Yalat.State.speed = v and 50 or 16 end)
createOptionBox(playerPage, "Jump (100)", ";jump 100", true, function(v) Yalat.State.jump = v and 100 or 50 end)

-- WORLD TAB
createOptionBox(worldPage, "Shader Effects", ";shader", true, function(v) if v then enableShader() else disableShader() end end)
createOptionBox(worldPage, "Realistic Water", ";water", true, function(v) if v then enableRealisticWater() else disableRealisticWater() end end)

-- TOOLS TAB
createOptionBox(toolsPage, "Give Sword", ";sword", false, function() spawnItem("Sword") end)
createOptionBox(toolsPage, "Give Baseball Bat", ";bat", false, function() spawnItem("Bat") end)
createOptionBox(toolsPage, "Give Apple", ";apple", false, function() spawnItem("Apple") end)
createOptionBox(toolsPage, "Give Speed Coil", ";speedcoil", false, function() spawnItem("SpeedCoil") end)

-- RIGHT PANEL: CMDS LIST
local rightList = Instance.new("Frame")
rightList.Size = UDim2.new(0, 175, 1, -60)
rightList.Position = UDim2.fromOffset(630, 52)
rightList.BackgroundColor3 = Color3.fromRGB(22, 14, 16)
rightList.Parent = main
corner(rightList, 8)
stroke(rightList, Color3.fromRGB(70, 20, 20), 1)

local cmdTitle = Instance.new("TextLabel")
cmdTitle.Position = UDim2.fromOffset(10, 8)
cmdTitle.Size = UDim2.new(1, -20, 0, 20)
cmdTitle.BackgroundTransparency = 1
cmdTitle.Text = "📋 CMDS LIST"
cmdTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
cmdTitle.Font = Enum.Font.GothamBold
cmdTitle.TextSize = 13
cmdTitle.TextXAlignment = Enum.TextXAlignment.Left
cmdTitle.Parent = rightList

local cmdScroll = Instance.new("ScrollingFrame")
cmdScroll.Size = UDim2.new(1, -10, 1, -35)
cmdScroll.Position = UDim2.fromOffset(5, 30)
cmdScroll.BackgroundTransparency = 1
cmdScroll.ScrollBarThickness = 3
cmdScroll.Parent = rightList

local cmdLayout = Instance.new("UIListLayout")
cmdLayout.Padding = UDim.new(0, 4)
cmdLayout.Parent = cmdScroll

local function addCmdListRow(cmd, desc)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 28)
    lbl.BackgroundTransparency = 1
    lbl.Text = ";" .. cmd .. "\n- " .. desc
    lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
    lbl.Font = Enum.Font.Code
    lbl.TextSize = 11
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
addCmdListRow("set / ;tp set", "Save Position")
addCmdListRow("tp", "Teleport Location")
addCmdListRow("shader / ;unshader", "Shader Effects")
addCmdListRow("water / ;unwater", "Realistic Water")
addCmdListRow("bat / apple", "Spawn Tools")
addCmdListRow("sword / speedcoil", "Spawn Tools")

-- BOTTOM FLOATING COMMAND BAR
local bar = Instance.new("Frame")
bar.Size = UDim2.new(0, 480, 0, 42)
bar.AnchorPoint = Vector2.new(0.5, 1)
bar.Position = UDim2.new(0.5, 0, 1, -15)
bar.BackgroundColor3 = Color3.fromRGB(20, 12, 14)
bar.Parent = gui
corner(bar, 20)
stroke(bar, Color3.fromRGB(220, 20, 20), 1.5)

local box = Instance.new("TextBox")
box.Size = UDim2.new(1, -60, 1, 0)
box.Position = UDim2.fromOffset(15, 0)
box.BackgroundTransparency = 1
box.TextColor3 = Color3.fromRGB(255, 255, 255)
box.PlaceholderText = "Type command here... (e.g. ;shader, ;water)"
box.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
box.Font = Enum.Font.Code
box.TextSize = 13
box.TextXAlignment = Enum.TextXAlignment.Left
box.ClearTextOnFocus = false
box.Text = ""
box.Parent = bar

local runBtn = Instance.new("TextButton")
runBtn.Size = UDim2.fromOffset(32, 32)
runBtn.Position = UDim2.new(1, -38, 0.5, -16)
runBtn.BackgroundColor3 = Color3.fromRGB(200, 20, 20)
runBtn.Text = "➤"
runBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
runBtn.Font = Enum.Font.GothamBold
runBtn.TextSize = 14
runBtn.Parent = bar
corner(runBtn, 16)

-- Command Runner System
function Yalat:Run(text)
    text = text:match("^%s*(.-)%s*$"):gsub("^;", "")
    local args = {}
    for word in text:gmatch("%S+") do table.insert(args, word) end
    if #args == 0 then return end

    local cmd = args[1]:lower()
    if cmd == "cmds" or cmd == "help" then main.Visible = not main.Visible
    elseif cmd == "god" then Yalat.State.god = true
    elseif cmd == "ungod" then Yalat.State.god = false
    elseif cmd == "noclip" then Yalat.State.noclip = true
    elseif cmd == "clip" then Yalat.State.noclip = false
    elseif cmd == "fly" then startFly(tonumber(args[2]) or 50)
    elseif cmd == "unfly" then stopFly()
    elseif cmd == "spin" then Yalat.State.spin = true
    elseif cmd == "unspin" then Yalat.State.spin = false
    elseif cmd == "set" then local r = getRoot(); if r then Yalat.SavedLocation = r.CFrame end
    elseif cmd == "tp" then local r = getRoot(); if r and Yalat.SavedLocation then r.CFrame = Yalat.SavedLocation end
    elseif cmd == "speed" or cmd == "ws" then Yalat.State.speed = tonumber(args[2]) or 50
    elseif cmd == "unspeed" then Yalat.State.speed = 16
    elseif cmd == "jump" or cmd == "jp" then Yalat.State.jump = tonumber(args[2]) or 100
    elseif cmd == "shader" then enableShader()
    elseif cmd == "unshader" then disableShader()
    elseif cmd == "water" then enableRealisticWater()
    elseif cmd == "unwater" or cmd == "resetwater" then disableRealisticWater()
    elseif cmd == "sword" then spawnItem("Sword")
    elseif cmd == "bat" then spawnItem("Bat")
    elseif cmd == "apple" then spawnItem("Apple")
    elseif cmd == "speedcoil" then spawnItem("SpeedCoil")
    end
end

runBtn.Activated:Connect(function()
    if box.Text ~= "" then
        Yalat:Run(box.Text)
        box.Text = ""
    end
end)

box.FocusLost:Connect(function(enterPressed)
    if enterPressed and box.Text ~= "" then
        Yalat:Run(box.Text)
        box.Text = ""
    end
end)

-- Core Heartbeat
RunService.Heartbeat:Connect(function()
    local hum = getHum()
    local root = getRoot()
    if hum then
        if Yalat.State.speed then hum.WalkSpeed = Yalat.State.speed end
        if Yalat.State.jump then hum.UseJumpPower = true; hum.JumpPower = Yalat.State.jump end
        if Yalat.State.god and hum.Health < hum.MaxHealth then hum.Health = hum.MaxHealth end
    end
    if root and Yalat.State.spin then root.CFrame *= CFrame.Angles(0, math.rad(Yalat.State.spinSpeed), 0) end
end)

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
