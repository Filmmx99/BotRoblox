repeat task.wait() until game:IsLoaded()

--====== SERVICES ======--

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer or Players.PlayerAdded:Wait()
local playerGui = player:WaitForChild("PlayerGui")

--====== CLEAR OLD GUI ======--

do
    local old = playerGui:FindFirstChild("FoodGui")
    if old then
        old:Destroy()
    end
end

--====== CONFIG SYSTEM ======--

local CONFIG_FILE = "BotRoblox_Config.json"

local settings = {
    foods = {},              -- [foodName] = true/false
    autoJump = false,        -- Auto Jump เปิด/ปิด
    autoCoin = false,        -- Auto Claim Coin เปิด/ปิด
    autoCoinMinutes = 5,     -- 1-10 นาทีต่อรอบ
    activeTab = "Food",      -- "Food" หรือ "Player"
}

local function hasFileFuncs()
    return (typeof(isfile) == "function")
        and (typeof(readfile) == "function")
        and (typeof(writefile) == "function")
end

local function loadConfig()
    if not hasFileFuncs() or not isfile(CONFIG_FILE) then return end

    local ok, data = pcall(readfile, CONFIG_FILE)
    if not ok or type(data) ~= "string" then return end

    local ok2, decoded = pcall(function()
        return HttpService:JSONDecode(data)
    end)
    if not ok2 or typeof(decoded) ~= "table" then return end

    for k, v in pairs(decoded) do
        if k == "foods" and typeof(v) == "table" then
            settings.foods = {}
            for name, val in pairs(v) do
                settings.foods[name] = val and true or false
            end

        elseif k == "autoJump" then
            settings.autoJump = v and true or false

        elseif k == "autoCoin" then
            settings.autoCoin = v and true or false

        elseif k == "autoCoinMinutes" and typeof(v) == "number" then
            settings.autoCoinMinutes = math.clamp(v, 1, 10)

        elseif k == "activeTab" and (v == "Food" or v == "Player") then
            settings.activeTab = v
        end
    end
end

local function saveConfig()
    if not hasFileFuncs() then return end

    local ok, encoded = pcall(function()
        return HttpService:JSONEncode(settings)
    end)
    if not ok then return end

    pcall(writefile, CONFIG_FILE, encoded)
end

loadConfig()

--====== REMOTE ======--

local foodRemoteFolder = ReplicatedStorage:FindFirstChild("Remote")
local foodRemote = foodRemoteFolder and foodRemoteFolder:FindFirstChild("FoodStoreRE")

--====== CONSTANTS ======--

local OFF_COLOR = Color3.fromRGB(70, 70, 95)
local ON_COLOR  = Color3.fromRGB(90, 170, 120)

--====== MAIN GUI ======--

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FoodGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ToggleFoodWindow"
toggleButton.Size = UDim2.new(0, 140, 0, 32)
toggleButton.Position = UDim2.new(0, 15, 1, -50)
toggleButton.AnchorPoint = Vector2.new(0, 1)
toggleButton.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
toggleButton.BorderSizePixel = 0
toggleButton.Text = "Menu"
toggleButton.Font = Enum.Font.GothamBold
toggleButton.TextSize = 16
toggleButton.TextColor3 = Color3.fromRGB(235, 235, 255)
toggleButton.Visible = false
toggleButton.Parent = screenGui

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 10)
toggleCorner.Parent = toggleButton

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainWindow"
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.Size = UDim2.new(0, 300, 0, 350)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 32)
mainFrame.BorderSizePixel = 0
mainFrame.Visible = true
mainFrame.Parent = screenGui

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 12)
frameCorner.Parent = mainFrame

local frameStroke = Instance.new("UIStroke")
frameStroke.Thickness = 2
frameStroke.Color = Color3.fromRGB(120, 120, 190)
frameStroke.Transparency = 0.25
frameStroke.Parent = mainFrame

local shadow = Instance.new("ImageLabel")
shadow.Name = "Shadow"
shadow.AnchorPoint = Vector2.new(0.5, 0.5)
shadow.Position = UDim2.new(0.5, 0, 0.5, 6)
shadow.Size = UDim2.new(1, 20, 1, 20)
shadow.BackgroundTransparency = 1
shadow.Image = "rbxassetid://5028857084"
shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
shadow.ImageTransparency = 0.45
shadow.ScaleType = Enum.ScaleType.Slice
shadow.SliceCenter = Rect.new(24, 24, 276, 276)
shadow.ZIndex = 0
shadow.Parent = mainFrame

--====== TITLE BAR ======--

local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 42)
titleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 60)
titleBar.BorderSizePixel = 0
titleBar.ZIndex = 2
titleBar.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.BackgroundTransparency = 1
titleLabel.Size = UDim2.new(1, -70, 1, 0)
titleLabel.Position = UDim2.new(0, 14, 0, 0)
titleLabel.Text = "Auto Menu"
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 18
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.TextColor3 = Color3.fromRGB(230, 230, 255)
titleLabel.ZIndex = 3
titleLabel.Parent = titleBar

local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.AnchorPoint = Vector2.new(1, 0.5)
closeButton.Position = UDim2.new(1, -10, 0.5, 0)
closeButton.Size = UDim2.new(0, 26, 0, 26)
closeButton.BackgroundColor3 = Color3.fromRGB(60, 40, 70)
closeButton.Text = "X"
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 16
closeButton.TextColor3 = Color3.fromRGB(250, 230, 255)
closeButton.BorderSizePixel = 0
closeButton.ZIndex = 3
closeButton.Parent = titleBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(1, 0)
closeCorner.Parent = closeButton

--====== DRAGGABLE UI ======--

local function makeDraggable(dragHandle, targetFrame)
    local dragging = false
    local dragInput, dragStart, startPos

    local function update(input)
        local delta = input.Position - dragStart
        targetFrame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end

    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = targetFrame.Position

            ContextActionService:BindAction(
                "BlockCameraWhileDrag",
                function()
                    return Enum.ContextActionResult.Sink
                end,
                false,
                Enum.UserInputType.MouseMovement,
                Enum.UserInputType.Touch
            )

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    ContextActionService:UnbindAction("BlockCameraWhileDrag")
                end
            end)
        end
    end)

    dragHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input == dragInput then
            update(input)
        end
    end)
end

makeDraggable(titleBar, mainFrame)
makeDraggable(toggleButton, toggleButton)

toggleButton.MouseButton1Click:Connect(function()
    mainFrame.Visible = true
    toggleButton.Visible = false
end)

closeButton.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
    toggleButton.Visible = true
end)

--====== TABS ======--

local tabBar = Instance.new("Frame")
tabBar.Name = "TabBar"
tabBar.Size = UDim2.new(1, -20, 0, 30)
tabBar.Position = UDim2.new(0, 10, 0, 48)
tabBar.BackgroundTransparency = 1
tabBar.Parent = mainFrame

local tabLayout = Instance.new("UIListLayout")
tabLayout.Parent = tabBar
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Padding = UDim.new(0, 6)
tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left

local function createTabButton(text)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 100, 1, 0)
    btn.BackgroundColor3 = Color3.fromRGB(45, 45, 70)
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.TextColor3 = Color3.fromRGB(220, 220, 245)
    btn.AutoButtonColor = false
    btn.Parent = tabBar

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = btn

    local s = Instance.new("UIStroke")
    s.Thickness = 1
    s.Color = Color3.fromRGB(120, 120, 190)
    s.Transparency = 0.4
    s.Parent = btn

    return btn
end

local foodTabButton = createTabButton("Food")
local playerTabButton = createTabButton("Player")

--====== PAGE HOLDER ======--

local pageHolder = Instance.new("Frame")
pageHolder.Name = "PageHolder"
pageHolder.Size = UDim2.new(1, -20, 1, -90)
pageHolder.Position = UDim2.new(0, 10, 0, 84)
pageHolder.BackgroundTransparency = 1
pageHolder.Parent = mainFrame

-- Food Page
local foodScroll = Instance.new("ScrollingFrame")
foodScroll.Name = "FoodPage"
foodScroll.Size = UDim2.new(1, 0, 1, 0)
foodScroll.BackgroundTransparency = 1
foodScroll.BorderSizePixel = 0
foodScroll.ScrollBarThickness = 4
foodScroll.ScrollingDirection = Enum.ScrollingDirection.Y
foodScroll.ElasticBehavior = Enum.ElasticBehavior.Never
foodScroll.Parent = pageHolder

local foodPadding = Instance.new("UIPadding")
foodPadding.PaddingTop = UDim.new(0, 4)
foodPadding.PaddingLeft = UDim.new(0, 2)
foodPadding.PaddingRight = UDim.new(0, 2)
foodPadding.PaddingBottom = UDim.new(0, 4)
foodPadding.Parent = foodScroll

local foodLayout = Instance.new("UIListLayout")
foodLayout.Parent = foodScroll
foodLayout.SortOrder = Enum.SortOrder.LayoutOrder
foodLayout.Padding = UDim.new(0, 6)

foodScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
foodLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    foodScroll.CanvasSize = UDim2.new(0, 0, 0, foodLayout.AbsoluteContentSize.Y + 10)
end)

-- Player Page
local playerScroll = Instance.new("ScrollingFrame")
playerScroll.Name = "PlayerPage"
playerScroll.Size = UDim2.new(1, 0, 1, 0)
playerScroll.BackgroundTransparency = 1
playerScroll.BorderSizePixel = 0
playerScroll.ScrollBarThickness = 4
playerScroll.ScrollingDirection = Enum.ScrollingDirection.Y
playerScroll.ElasticBehavior = Enum.ElasticBehavior.Never
playerScroll.Parent = pageHolder

local playerPadding = Instance.new("UIPadding")
playerPadding.PaddingTop = UDim.new(0, 4)
playerPadding.PaddingLeft = UDim.new(0, 2)
playerPadding.PaddingRight = UDim.new(0, 2)  -- ✅ ตรงนี้แก้จาก UDim2 เป็น UDim
playerPadding.PaddingBottom = UDim.new(0, 4)
playerPadding.Parent = playerScroll

local playerLayout = Instance.new("UIListLayout")
playerLayout.Parent = playerScroll
playerLayout.SortOrder = Enum.SortOrder.LayoutOrder
playerLayout.Padding = UDim.new(0, 6)

playerScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
playerLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    playerScroll.CanvasSize = UDim2.new(0, 0, 0, playerLayout.AbsoluteContentSize.Y + 10)
end)

-- Tab switch
local function setTab(active)
    if active ~= "Food" and active ~= "Player" then
        active = "Food"
    end

    settings.activeTab = active
    saveConfig()

    if active == "Food" then
        foodScroll.Visible = true
        playerScroll.Visible = false
        foodTabButton.BackgroundColor3 = Color3.fromRGB(90, 90, 130)
        playerTabButton.BackgroundColor3 = Color3.fromRGB(45, 45, 70)
    else
        foodScroll.Visible = false
        playerScroll.Visible = true
        foodTabButton.BackgroundColor3 = Color3.fromRGB(45, 45, 70)
        playerTabButton.BackgroundColor3 = Color3.fromRGB(90, 90, 130)
    end
end

foodTabButton.MouseButton1Click:Connect(function()
    setTab("Food")
end)

playerTabButton.MouseButton1Click:Connect(function()
    setTab("Player")
end)

setTab(settings.activeTab or "Food")

--====== FOOD AUTO ======--

local foods = {
    "BloodstoneCycad",
    "GoldMango",
    "DragonFruit",
    "DeepseaPearlFruit",
    "ColossalPinecone",
    "CandyCorn",
    "VoltGinkgo",
    "Durian",
    "Pumpkin",
    "FrankenKiwi",
}

local autoStatus = {}

local function startFoodLoop(name)
    task.spawn(function()
        while autoStatus[name] and foodRemote do
            for _ = 1, 3 do
                pcall(function()
                    foodRemote:FireServer(name)
                end)
            end
            task.wait(60)
        end
    end)
end

local function createFoodButton(name)
    autoStatus[name] = settings.foods[name] == true

    local button = Instance.new("TextButton")
    button.Name = name .. "Button"
    button.Size = UDim2.new(1, -10, 0, 30)
    button.BackgroundColor3 = autoStatus[name] and ON_COLOR or OFF_COLOR
    button.BorderSizePixel = 0
    button.AutoButtonColor = false
    button.Text = name .. (autoStatus[name] and " [ON]" or " [OFF]")
    button.Font = Enum.Font.Gotham
    button.TextSize = 15
    button.TextColor3 = Color3.fromRGB(235, 235, 245)
    button.Parent = foodScroll

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = button

    local btnStroke = Instance.new("UIStroke")
    btnStroke.Thickness = 1
    btnStroke.Color = Color3.fromRGB(140, 140, 190)
    btnStroke.Transparency = 0.4
    btnStroke.Parent = button

    button.MouseEnter:Connect(function()
        local base = autoStatus[name] and ON_COLOR or OFF_COLOR
        button.BackgroundColor3 = base:Lerp(Color3.new(1, 1, 1), 0.08)
    end)

    button.MouseLeave:Connect(function()
        button.BackgroundColor3 = autoStatus[name] and ON_COLOR or OFF_COLOR
    end)

    button.MouseButton1Click:Connect(function()
        autoStatus[name] = not autoStatus[name]
        settings.foods[name] = autoStatus[name]
        saveConfig()

        if autoStatus[name] then
            button.Text = name .. " [ON]"
            button.BackgroundColor3 = ON_COLOR
            if foodRemote then
                startFoodLoop(name)
            end
        else
            button.Text = name .. " [OFF]"
            button.BackgroundColor3 = OFF_COLOR
        end
    end)

    if autoStatus[name] and foodRemote then
        startFoodLoop(name)
    end
end

for _, f in ipairs(foods) do
    createFoodButton(f)
end

--====== PLAYER : AUTO JUMP ======--

local autoJumpEnabled = settings.autoJump == true

local function autoJumpLoop()
    while autoJumpEnabled do
        local char = player.Character or player.CharacterAdded:Wait()
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
        task.wait(300)
    end
end

local function createAutoJumpButton()
    local button = Instance.new("TextButton")
    button.Name = "AutoJumpButton"
    button.Size = UDim2.new(1, -10, 0, 30)
    button.BackgroundColor3 = autoJumpEnabled and ON_COLOR or OFF_COLOR
    button.BorderSizePixel = 0
    button.AutoButtonColor = false
    button.Text = "Auto Jump " .. (autoJumpEnabled and "[ON]" or "[OFF]")
    button.Font = Enum.Font.Gotham
    button.TextSize = 15
    button.TextColor3 = Color3.fromRGB(235, 235, 245)
    button.Parent = playerScroll

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = button

    local btnStroke = Instance.new("UIStroke")
    btnStroke.Thickness = 1
    btnStroke.Color = Color3.fromRGB(140, 140, 190)
    btnStroke.Transparency = 0.4
    btnStroke.Parent = button

    button.MouseEnter:Connect(function()
        local base = autoJumpEnabled and ON_COLOR or OFF_COLOR
        button.BackgroundColor3 = base:Lerp(Color3.new(1, 1, 1), 0.08)
    end)

    button.MouseLeave:Connect(function()
        button.BackgroundColor3 = autoJumpEnabled and ON_COLOR or OFF_COLOR
    end)

    button.MouseButton1Click:Connect(function()
        autoJumpEnabled = not autoJumpEnabled
        settings.autoJump = autoJumpEnabled
        saveConfig()

        if autoJumpEnabled then
            button.Text = "Auto Jump [ON]"
            button.BackgroundColor3 = ON_COLOR
            task.spawn(autoJumpLoop)
        else
            button.Text = "Auto Jump [OFF]"
            button.BackgroundColor3 = OFF_COLOR
        end
    end)

    if autoJumpEnabled then
        task.spawn(autoJumpLoop)
    end
end

createAutoJumpButton()

--====== PLAYER : AUTO CLAIM COIN ======--

local LocalPlayer = player
local cam = workspace.CurrentCamera

local function getCharacter()
    local char = LocalPlayer.Character
    if not char or not char.Parent then
        char = LocalPlayer.CharacterAdded:Wait()
    end
    return char
end

local function getHRP()
    local char = getCharacter()
    return char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart")
end

local farmSlots = {}
local currentIndex = 1

local function isFarmSlot(inst)
    if not inst:IsA("BasePart") then return false end
    local n = inst.Name:lower()
    if n:match("^farm_split") then return true end
    if n:find("waterfarm") then return true end
    return false
end

local function collectFarmSlots()
    local art = workspace:FindFirstChild("Art")
    if not art then return {} end

    local mypos = getHRP().Position
    local bestData

    for i = 1, 5 do
        local island = art:FindFirstChild("Island_" .. i)
        if island then
            local data = {slots = {}, nearest = math.huge}
            for _, inst in ipairs(island:GetDescendants()) do
                if isFarmSlot(inst) then
                    table.insert(data.slots, inst)
                    local d = (inst.Position - mypos).Magnitude
                    if d < data.nearest then
                        data.nearest = d
                    end
                end
            end
            if #data.slots > 0 and (not bestData or data.nearest < bestData.nearest) then
                bestData = data
            end
        end
    end

    if not bestData then return {} end

    table.sort(bestData.slots, function(a, b)
        if a.Position.X == b.Position.X then
            return a.Position.Z < b.Position.Z
        end
        return a.Position.X < b.Position.X
    end)

    return bestData.slots
end

local function refreshSlots()
    farmSlots = collectFarmSlots()
    currentIndex = (#farmSlots == 0) and 0 or 1
end

local function warpTo(slot)
    if not slot then return end
    local hrp = getHRP()
    hrp.CFrame = CFrame.new(slot.Position + Vector3.new(0, 5, 0))
end

local function warpNext()
    if #farmSlots == 0 then return end
    currentIndex += 1
    if currentIndex > #farmSlots then
        currentIndex = 1
    end
    warpTo(farmSlots[currentIndex])
end

local savedCamType, savedCamSubject, savedCamCFrame

local function lockCamera()
    savedCamType = cam.CameraType
    savedCamSubject = cam.CameraSubject
    savedCamCFrame = cam.CFrame

    cam.CameraType = Enum.CameraType.Scriptable
    cam.CFrame = savedCamCFrame
end

local function restoreCamera()
    if savedCamType then
        cam.CameraType = savedCamType
    end
    if savedCamSubject then
        cam.CameraSubject = savedCamSubject
    end
    savedCamType = nil
    savedCamSubject = nil
    savedCamCFrame = nil
end

local autoCoinEnabled = settings.autoCoin == true
local autoCoinRunning = false
local autoDelayPerSlot = 0.0001
local originalCFrame = nil

local function startAutoOnce()
    if autoCoinRunning then return end

    refreshSlots()
    if #farmSlots == 0 then return end

    originalCFrame = getHRP().CFrame
    lockCamera()
    autoCoinRunning = true

    task.spawn(function()
        for _ = 1, #farmSlots do
            if not autoCoinRunning then break end
            warpNext()
            task.wait(autoDelayPerSlot)
        end

        if originalCFrame then
            local hrp = getHRP()
            hrp.CFrame = originalCFrame
        end

        autoCoinRunning = false
        restoreCamera()
    end)
end

local function stopAutoOnce()
    autoCoinRunning = false
    restoreCamera()
end

local function autoCoinLoop()
    while autoCoinEnabled do
        startAutoOnce()
        local mins = math.clamp(settings.autoCoinMinutes or 5, 1, 10)
        task.wait(mins * 60)
    end
end

local function createAutoCoinButton()
    local button = Instance.new("TextButton")
    button.Name = "AutoCoinButton"
    button.Size = UDim2.new(1, -10, 0, 30)
    button.BackgroundColor3 = autoCoinEnabled and ON_COLOR or OFF_COLOR
    button.BorderSizePixel = 0
    button.AutoButtonColor = false
    button.Text = "Auto Claim Coin " .. (autoCoinEnabled and "[ON]" or "[OFF]")
    button.Font = Enum.Font.Gotham
    button.TextSize = 15
    button.TextColor3 = Color3.fromRGB(235, 235, 245)
    button.Parent = playerScroll

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = button

    local btnStroke = Instance.new("UIStroke")
    btnStroke.Thickness = 1
    btnStroke.Color = Color3.fromRGB(140, 140, 190)
    btnStroke.Transparency = 0.4
    btnStroke.Parent = button

    button.MouseEnter:Connect(function()
        local base = autoCoinEnabled and ON_COLOR or OFF_COLOR
        button.BackgroundColor3 = base:Lerp(Color3.new(1, 1, 1), 0.08)
    end)

    button.MouseLeave:Connect(function()
        button.BackgroundColor3 = autoCoinEnabled and ON_COLOR or OFF_COLOR
    end)

    button.MouseButton1Click:Connect(function()
        autoCoinEnabled = not autoCoinEnabled
        settings.autoCoin = autoCoinEnabled
        saveConfig()

        if autoCoinEnabled then
            button.Text = "Auto Claim Coin [ON]"
            button.BackgroundColor3 = ON_COLOR
            task.spawn(autoCoinLoop)
        else
            button.Text = "Auto Claim Coin [OFF]"
            button.BackgroundColor3 = OFF_COLOR
            stopAutoOnce()
        end
    end)

    if autoCoinEnabled then
        task.spawn(autoCoinLoop)
    end
end

local function createAutoCoinSlider()
    local sliderValue = math.clamp(settings.autoCoinMinutes or 5, 1, 10)

    local container = Instance.new("Frame")
    container.Name = "AutoCoinSlider"
    container.Size = UDim2.new(1, -10, 0, 60)
    container.BackgroundTransparency = 1
    container.Parent = playerScroll

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, 0, 0, 24)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.TextColor3 = Color3.fromRGB(235, 235, 245)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = ("Auto Claim Interval: %d min"):format(sliderValue)
    label.Parent = container

    local sliderFrame = Instance.new("Frame")
    sliderFrame.Size = UDim2.new(1, 0, 0, 22)
    sliderFrame.Position = UDim2.new(0, 0, 0, 30)
    sliderFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 60)
    sliderFrame.BorderSizePixel = 0
    sliderFrame.Parent = container

    local sliderCorner = Instance.new("UICorner")
    sliderCorner.CornerRadius = UDim.new(0, 8)
    sliderCorner.Parent = sliderFrame

    local sliderStroke = Instance.new("UIStroke")
    sliderStroke.Thickness = 1
    sliderStroke.Color = Color3.fromRGB(140, 140, 190)
    sliderStroke.Transparency = 0.4
    sliderStroke.Parent = sliderFrame

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -16, 0, 4)
    bar.Position = UDim2.new(0, 8, 0.5, -2)
    bar.BackgroundColor3 = Color3.fromRGB(70, 70, 110)
    bar.BorderSizePixel = 0
    bar.Parent = sliderFrame

    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(1, 0)
    barCorner.Parent = bar

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 18)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.BackgroundColor3 = Color3.fromRGB(90, 170, 120)
    knob.BorderSizePixel = 0
    knob.Parent = sliderFrame

    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob

    local dragging = false

    local function setKnobByValue(val)
        val = math.clamp(val, 1, 10)
        sliderValue = val
        settings.autoCoinMinutes = val
        saveConfig()
        label.Text = ("Auto Claim Interval: %d min"):format(val)

        local t = (val - 1) / 9 -- 0..1
        knob.Position = UDim2.new(t, 0, 0.5, 0)
    end

    local function updateFromX(x)
        local barPos = bar.AbsolutePosition.X
        local barSize = bar.AbsoluteSize.X
        if barSize <= 0 then return end

        local alpha = (x - barPos) / barSize
        alpha = math.clamp(alpha, 0, 1)

        local val = math.floor(alpha * 9 + 0.5) + 1
        setKnobByValue(val)
    end

    knob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
        end
    end)

    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateFromX(input.Position.X)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            updateFromX(input.Position.X)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    setKnobByValue(sliderValue)
end

createAutoCoinButton()
createAutoCoinSlider()
