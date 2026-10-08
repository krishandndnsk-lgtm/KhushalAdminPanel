--[[
    Infinity Yalat - Our Happiness by Gemini
    Full In-Game Heavy Admin & Tool Spawner Suite
    
    New Additions & Bug Fixes:
      - Added 'spin [speed]' and 'unspin' commands.
      - Added 'tp set' alias support for saving position.
      - Fixed shader movement freeze.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

if PlayerGui:FindFirstChild("InfinityYalatGui") then
    PlayerGui.InfinityYalatGui:Destroy()
end

local Yalat = {
    Commands = {},
    CmdList = {},
    Conns = {},
    SavedLocation = nil,
    State = {
        speed = nil, jump = nil, hip = nil,
        noclip = false, god = false, spin = false, spinSpeed = 10,
        shaderActive = false
    }
}

local function connect(signal, fn)
    local c = signal:Connect(fn)
    table.insert(Yalat.Conns, c)
    return c
end

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

--// Flight Engine
local fly = { conn = nil, bv = nil, bg = nil }
local function stopFly()
    if fly.conn then fly.conn:Disconnect() fly.conn = nil end
    if fly.bv then fly.bv:Destroy() fly.bv = nil end
    if fly.bg then fly.bg:Destroy() fly.bg = nil end
    local hum = getHum()
    if hum then hum.PlatformStand = false end
end

local function startFly(speed)
    stopFly()
    local root, hum = getRoot(), getHum()
    if not (root and hum) then return false end

    fly.bv = Instance.new("BodyVelocity")
    fly.bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    fly.bv.Velocity = Vector3.zero
    fly.bv.Parent = root

    fly.bg = Instance.new("BodyGyro")
    fly.bg.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
    fly.bg.P = 9e4
    fly.bg.CFrame = root.CFrame
    fly.bg.Parent = root

    hum.PlatformStand = true

    fly.conn = RunService.RenderStepped:Connect(function()
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
            fly.bg.CFrame = CFrame.new(root.Position, root.Position + flat)
        end

        if UserInputService:IsKeyDown(Enum.KeyCode.E) or UserInputService:IsKeyDown(Enum.KeyCode.Space) then vel += Vector3.yAxis end
        if UserInputService:IsKeyDown(Enum.KeyCode.Q) then vel -= Vector3.yAxis end
        fly.bv.Velocity = vel * speed
    end)
    return true
end

--// Core Loops
connect(RunService.Heartbeat, function()
    local hum = getHum()
    local root = getRoot()
    if hum then
        if Yalat.State.speed and hum.WalkSpeed ~= Yalat.State.speed then hum.WalkSpeed = Yalat.State.speed end
        if Yalat.State.jump then hum.UseJumpPower = true; hum.JumpPower = Yalat.State.jump end
        if Yalat.State.god and hum.Health < hum.MaxHealth and hum.Health > 0 then hum.Health = hum.MaxHealth end
    end
    if Yalat.State.spin and root then root.CFrame *= CFrame.Angles(0, math.rad(Yalat.State.spinSpeed), 0) end
end)

connect(RunService.Stepped, function()
    if not Yalat.State.noclip then return end
    local char = getChar()
    if char then
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
        end
    end
end)

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

    Lighting.Technology = Enum.Technology.Future
    Lighting.Brightness = 2.5
    Lighting.ClockTime = 14
    Lighting.ExposureCompensation = 0.1

    local bloom = Instance.new("BloomEffect", Lighting)
    bloom.Intensity = 0.4
    bloom.Size = 24
    bloom.Threshold = 0.8
    table.insert(shaderStorage.FX, bloom)

    local sunRays = Instance.new("SunRaysEffect", Lighting)
    sunRays.Intensity = 0.25
    table.insert(shaderStorage.FX, sunRays)

    local atmosphere = Instance.new("Atmosphere", Lighting)
    atmosphere.Density = 0.3
    atmosphere.Offset = 0.25
    atmosphere.Color = Color3.fromRGB(199, 218, 255)
    atmosphere.Decay = Color3.fromRGB(106, 112, 125)
    table.insert(shaderStorage.FX, atmosphere)

    local char = getChar()
    if char then
        local hl = Instance.new("Highlight")
        hl.Name = "RainbowGlow"
        hl.FillTransparency = 0.5
        hl.OutlineTransparency = 0
        hl.Adornee = char
        hl.Parent = char
        shaderStorage.Highlight = hl

        local hum = getHum()
        if hum then hum.PlatformStand = false end
    end
end

local function disableShader()
    Yalat.State.shaderActive = false

    for _, fx in ipairs(shaderStorage.FX) do
        if fx and fx.Parent then fx:Destroy() end
    end
    shaderStorage.FX = {}

    if shaderStorage.Highlight then
        shaderStorage.Highlight:Destroy()
        shaderStorage.Highlight = nil
    end

    local hum = getHum()
    if hum then hum.PlatformStand = false end
end

local hue = 0
RunService.RenderStepped:Connect(function()
    if Yalat.State.shaderActive and shaderStorage.Highlight then
        hue = (hue + 0.005) % 1
        local rainbowColor = Color3.fromHSV(hue, 0.9, 1)
        shaderStorage.Highlight.FillColor = rainbowColor
        shaderStorage.Highlight.OutlineColor = rainbowColor
    end
end)

--// Item Spawner Engine
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
    if lower == "bat" then
        handle.Size = Vector3.new(0.5, 4, 0.5)
        handle.BrickColor = BrickColor.new("Wood")
        handle.Material = Enum.Material.Wood
    elseif lower == "apple" then
        handle.Size = Vector3.new(1, 1, 1)
        handle.Shape = Enum.PartType.Ball
        handle.BrickColor = BrickColor.new("Bright red")
    elseif lower == "sword" then
        handle.Size = Vector3.new(0.4, 4, 0.8)
        handle.BrickColor = BrickColor.new("Medium stone grey")
        handle.Material = Enum.Material.Metal
    elseif lower == "speedcoil" then
        handle.Size = Vector3.new(1.5, 1.5, 1.5)
        handle.BrickColor = BrickColor.new("Bright blue")
    end

    tool.Parent = LocalPlayer:WaitForChild("Backpack")
end

--// UI Creation
local gui = Instance.new("ScreenGui")
gui.Name = "InfinityYalatGui"
gui.ResetOnSpawn = false
gui.DisplayOrder = 999
gui.Parent = PlayerGui

local bar = Instance.new("Frame")
bar.Size = UDim2.new(0, 400, 0, 42)
bar.AnchorPoint = Vector2.new(0.5, 1)
bar.Position = UDim2.new(0.5, 0, 1, -25)
bar.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
bar.BackgroundTransparency = 0.1
bar.Visible = false
bar.Parent = gui
corner(bar, 8)

local box = Instance.new("TextBox")
box.Size = UDim2.new(1, -20, 1, 0)
box.Position = UDim2.fromOffset(10, 0)
box.BackgroundTransparency = 1
box.TextColor3 = Color3.fromRGB(255, 255, 255)
box.PlaceholderText = "Infinity Yalat | Type command ('cmds' for list)..."
box.PlaceholderColor3 = Color3.fromRGB(140, 140, 150)
box.Font = Enum.Font.Code
box.TextSize = 14
box.TextXAlignment = Enum.TextXAlignment.Left
box.ClearTextOnFocus = false
box.Text = ""
box.Parent = bar

local notifyLabel = Instance.new("TextLabel")
notifyLabel.AnchorPoint = Vector2.new(0.5, 1)
notifyLabel.Position = UDim2.new(0.5, 0, 1, -75)
notifyLabel.Size = UDim2.new(0, 400, 0, 24)
notifyLabel.BackgroundTransparency = 1
notifyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
notifyLabel.TextTransparency = 1
notifyLabel.Font = Enum.Font.GothamMedium
notifyLabel.TextSize = 14
notifyLabel.Text = ""
notifyLabel.Parent = gui

local notifyToken = 0
local function notify(msg)
    notifyToken += 1
    local t = notifyToken
    notifyLabel.Text = msg
    notifyLabel.TextTransparency = 0
    task.delay(3, function()
        if t == notifyToken and notifyLabel.Parent then
            notifyLabel.TextTransparency = 1
        end
    end)
end

local toggleBtn = Instance.new("TextButton")
toggleBtn.AnchorPoint = Vector2.new(1, 0)
toggleBtn.Position = UDim2.new(1, -15, 0, 15)
toggleBtn.Size = UDim2.fromOffset(90, 32)
toggleBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 13
toggleBtn.Text = "KHUSHAL"
toggleBtn.Parent = gui
corner(toggleBtn, 6)

local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 440, 0, 360)
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.45)
panel.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
panel.Visible = false
panel.Parent = gui
corner(panel, 10)

local panelTitle = Instance.new("TextLabel")
panelTitle.Size = UDim2.new(1, -40, 0, 36)
panelTitle.Position = UDim2.fromOffset(12, 0)
panelTitle.BackgroundTransparency = 1
panelTitle.TextXAlignment = Enum.TextXAlignment.Left
panelTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
panelTitle.Font = Enum.Font.GothamBold
panelTitle.TextSize = 14
panelTitle.Text = "Infinity Yalat - Our Happiness by Gemini"
panelTitle.Parent = panel

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(30, 30)
closeBtn.Position = UDim2.new(1, -34, 0, 3)
closeBtn.BackgroundTransparency = 1
closeBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 16
closeBtn.Text = "X"
closeBtn.Parent = panel

local scroll = Instance.new("ScrollingFrame")
scroll.Position = UDim2.fromOffset(0, 40)
scroll.Size = UDim2.new(1, 0, 1, -40)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
scroll.CanvasSize = UDim2.new()
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = panel

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 6)
layout.Parent = scroll
local pad = Instance.new("UIPadding")
pad.PaddingLeft = UDim.new(0, 12)
pad.PaddingRight = UDim.new(0, 12)
pad.Parent = scroll

function Yalat:AddCommand(names, usage, desc, fn)
    local entry = { names = names, usage = usage, desc = desc, fn = fn }
    for _, n in ipairs(names) do
        Yalat.Commands[n:lower()] = entry
    end
    table.insert(Yalat.CmdList, entry)
end

function Yalat:Run(text)
    text = text:match("^%s*(.-)%s*$"):gsub("^;", "")
    local args = {}
    for word in text:gmatch("%S+") do table.insert(args, word) end
    if #args == 0 then return end

    -- Custom multi-word check for 'tp set'
    if args[1]:lower() == "tp" and args[2] and args[2]:lower() == "set" then
        local root = getRoot()
        if root then
            Yalat.SavedLocation = root.CFrame
            return notify("Location Saved via 'tp set'!")
        end
    end

    local entry = Yalat.Commands[args[1]:lower()]
    if not entry then return notify("Unknown command: " .. args[1]) end
    local ok, err = pcall(entry.fn, args)
    if not ok then notify("Error: " .. tostring(err)) end
end

Yalat:AddCommand({ "cmds", "help" }, "", "Toggle command menu panel", function() panel.Visible = not panel.Visible end)

Yalat:AddCommand({ "set" }, "", "Save current position and facing direction", function()
    local root = getRoot()
    if root then
        Yalat.SavedLocation = root.CFrame
        notify("Location Saved!")
    end
end)

Yalat:AddCommand({ "tp" }, "", "Teleport to saved location", function()
    local root = getRoot()
    if not Yalat.SavedLocation then
        notify("No location saved! Use set first.")
    elseif root then
        root.CFrame = Yalat.SavedLocation
        notify("Teleported to saved location!")
    end
end)

Yalat:AddCommand({ "spin" }, "[speed]", "Spin your character around", function(a)
    Yalat.State.spinSpeed = tonumber(a[2]) or 10
    Yalat.State.spin = true
    notify("Spin enabled!")
end)

Yalat:AddCommand({ "unspin" }, "", "Stop spinning character", function()
    Yalat.State.spin = false
    notify("Spin disabled!")
end)

Yalat:AddCommand({ "shader" }, "", "Enable realistic lighting & rainbow glow", function() enableShader(); notify("Shader Activated!") end)
Yalat:AddCommand({ "unshader" }, "", "Disable shader effects", function() disableShader(); notify("Shader Disabled") end)

Yalat:AddCommand({ "water" }, "", "Make Terrain Water ultra realistic & crystal clear", function() enableRealisticWater(); notify("Realistic Water Activated!") end)
Yalat:AddCommand({ "unwater" }, "", "Reset Terrain Water to default", function() disableRealisticWater(); notify("Water Reset to Default") end)

Yalat:AddCommand({ "bat" }, "", "Spawn baseball bat tool", function() spawnItem("Bat"); notify("Spawned Bat") end)
Yalat:AddCommand({ "apple" }, "", "Spawn apple item tool", function() spawnItem("Apple"); notify("Spawned Apple") end)
Yalat:AddCommand({ "sword" }, "", "Spawn metal sword tool", function() spawnItem("Sword"); notify("Spawned Sword") end)
Yalat:AddCommand({ "speedcoil" }, "", "Spawn speed coil tool", function() spawnItem("SpeedCoil"); notify("Spawned SpeedCoil") end)
Yalat:AddCommand({ "give" }, "[name]", "Give custom tool item", function(a) if a[2] then spawnItem(a[2]); notify("Spawned " .. a[2]) end end)
Yalat:AddCommand({ "speed", "ws" }, "[num]", "Set WalkSpeed", function(a) Yalat.State.speed = tonumber(a[2]) or 50; notify("Speed set to " .. Yalat.State.speed) end)
Yalat:AddCommand({ "unspeed" }, "", "Reset WalkSpeed", function() Yalat.State.speed = nil; local h = getHum(); if h then h.WalkSpeed = 16 end; notify("Speed reset") end)
Yalat:AddCommand({ "jump", "jp" }, "[num]", "Set JumpPower", function(a) Yalat.State.jump = tonumber(a[2]) or 100; notify("JumpPower set to " .. Yalat.State.jump) end)
Yalat:AddCommand({ "fly" }, "[speed]", "Enable fly mode", function(a) startFly(tonumber(a[2]) or 50); notify("Flight enabled") end)
Yalat:AddCommand({ "unfly" }, "", "Disable fly mode", function() stopFly(); notify("Flight disabled") end)
Yalat:AddCommand({ "noclip" }, "", "Enable wall noclip", function() Yalat.State.noclip = true; notify("Noclip enabled") end)
Yalat:AddCommand({ "clip" }, "", "Disable wall noclip", function() Yalat.State.noclip = false; notify("Noclip disabled") end)
Yalat:AddCommand({ "god" }, "", "Enable local health lock", function() Yalat.State.god = true; notify("God mode enabled") end)
Yalat:AddCommand({ "ungod" }, "", "Disable local health lock", function() Yalat.State.god = false; notify("God mode disabled") end)

for _, entry in ipairs(Yalat.CmdList) do
    local line = entry.names[1] .. (entry.usage ~= "" and (" " .. entry.usage) or "") .. "\n   " .. entry.desc
    local row = Instance.new("TextLabel")
    row.Size = UDim2.new(1, 0, 0, 0)
    row.AutomaticSize = Enum.AutomaticSize.Y
    row.BackgroundTransparency = 1
    row.TextWrapped = true
    row.TextXAlignment = Enum.TextXAlignment.Left
    row.TextColor3 = Color3.fromRGB(220, 220, 230)
    row.Font = Enum.Font.Code
    row.TextSize = 13
    row.Text = line
    row.Parent = scroll
end

local function addHiddenCommand(names, fn)
    for _, n in ipairs(names) do
        Yalat.Commands[n:lower()] = { names = names, usage = "", desc = "", fn = fn }
    end
end

addHiddenCommand({ "exit", "close", "hide" }, function()
    panel.Visible = false
    notify("Commands panel closed")
end)

local function toggleBar()
    bar.Visible = not bar.Visible
    if bar.Visible then
        box:CaptureFocus()
        task.spawn(function() task.wait(); box.Text = "" end)
    end
end

connect(UserInputService.InputBegan, function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.Semicolon then
        toggleBar()
    end
end)

connect(box.FocusLost, function(enterPressed)
    local text = box.Text
    bar.Visible = false
    box.Text = ""
    if enterPressed and text ~= "" then Yalat:Run(text) end
end)

connect(toggleBtn.Activated, toggleBar)
connect(closeBtn.Activated, function() panel.Visible = false end)

notify("Khushal Script Loaded — Press ';' or tap KHUSHAL button")
