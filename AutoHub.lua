repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

local player = Players.LocalPlayer or Players.PlayerAdded:Wait()
local playerGui = player:WaitForChild("PlayerGui")

-- ลองหา Remote ถ้าไม่มี = ไม่พัง แค่กดแล้วไม่ยิง
local foodRemoteFolder = ReplicatedStorage:FindFirstChild("Remote")
local foodRemote = foodRemoteFolder and foodRemoteFolder:FindFirstChild("FoodStoreRE")

--==================== SCREEN GUI ====================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FoodGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

--==================== ปุ่มล่างซ้าย (ลากได้ + เปิดแทบ) ====================

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
toggleButton.Parent = screenGui

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 10)
toggleCorner.Parent = toggleButton

toggleButton.Visible = false -- ซ่อนตอนเริ่มเกม

--==================== หน้าต่างหลัก ====================

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

--==================== TITLE BAR ====================

local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 42)
titleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 60)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame
titleBar.ZIndex = 2

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

--==================== ฟังก์ชันลาก (ล็อกกล้อง) ====================

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

--==================== TAB BAR (Food / Player) ====================

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

--==================== PAGE HOLDER ====================

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
foodScroll.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
foodScroll.BottomImage = foodScroll.TopImage
foodScroll.MidImage = foodScroll.TopImage
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
foodLayout.Changed:Connect(function()
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
playerScroll.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
playerScroll.BottomImage = playerScroll.TopImage
playerScroll.MidImage = playerScroll.TopImage
playerScroll.Parent = pageHolder
playerScroll.Visible = false

local playerPadding = Instance.new("UIPadding")
playerPadding.PaddingTop = UDim.new(0, 4)
playerPadding.PaddingLeft = UDim.new(0, 2)
playerPadding.PaddingRight = UDim.new(0, 2)
playerPadding.PaddingBottom = UDim.new(0, 4)
playerPadding.Parent = playerScroll

local playerLayout = Instance.new("UIListLayout")
playerLayout.Parent = playerScroll
playerLayout.SortOrder = Enum.SortOrder.LayoutOrder
playerLayout.Padding = UDim.new(0, 6)

playerScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
playerLayout.Changed:Connect(function()
    playerScroll.CanvasSize = UDim2.new(0, 0, 0, playerLayout.AbsoluteContentSize.Y + 10)
end)

--==================== TAB SWITCH ====================

local function setTab(active)
    if active == "Food" then
        foodScroll.Visible = true
        playerScroll.Visible = false
        foodTabButton.BackgroundColor3 = Color3.fromRGB(90, 90, 130)
        playerTabButton.BackgroundColor3 = Color3.fromRGB(45, 45, 70)
    elseif active == "Player" then
        foodScroll.Visible = false
        playerScroll.Visible = true
        foodTabButton.BackgroundColor3 = Color3.fromRGB(45, 45, 70)
        playerTabButton.BackgroundColor3 = Color3.fromRGB(90, 90, 130)
    end
end

setTab("Food")

foodTabButton.MouseButton1Click:Connect(function()
    setTab("Food")
end)

playerTabButton.MouseButton1Click:Connect(function()
    setTab("Player")
end)

--==================== FOOD AUTO ====================

local foods = {
    "BloodstoneCycad",
    "GoldMango",
    "DragonFruit",
    "DeepseaPearlFruit",
    "ColossalPinecone",
    "CandyCorn",
    "Durian",
    "Pumpkin",
    "FrankenKiwi"
}

local autoStatus = {}
local OFF_COLOR = Color3.fromRGB(70, 70, 95)
local ON_COLOR  = Color3.fromRGB(90, 170, 120)

local function createFoodButton(name)
    autoStatus[name] = false

    local button = Instance.new("TextButton")
    button.Name = name .. "Button"
    button.Size = UDim2.new(1, -10, 0, 30)
    button.BackgroundColor3 = OFF_COLOR
    button.BorderSizePixel = 0
    button.AutoButtonColor = false
    button.Text = name .. " [OFF]"
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

        if autoStatus[name] then
            button.Text = name .. " [ON]"
            button.BackgroundColor3 = ON_COLOR
        else
            button.Text = name .. " [OFF]"
            button.BackgroundColor3 = OFF_COLOR
        end

        if autoStatus[name] and foodRemote then
            task.spawn(function()
                while autoStatus[name] and foodRemote do
                    for i = 1, 3 do
                        foodRemote:FireServer(name)
                    end
                    task.wait(10)
                end
            end)
        end
    end)
end

for _, f in ipairs(foods) do
    createFoodButton(f)
end

--==================== PLAYER PAGE : AUTO JUMP ====================

local autoJumpEnabled = false

local function autoJumpLoop()
    while autoJumpEnabled do
        local char = player.Character or player.CharacterAdded:Wait()
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
        task.wait(10)
    end
end

local function createAutoJumpButton()
    local button = Instance.new("TextButton")
    button.Name = "AutoJumpButton"
    button.Size = UDim2.new(1, -10, 0, 30)
    button.BackgroundColor3 = OFF_COLOR
    button.BorderSizePixel = 0
    button.AutoButtonColor = false
    button.Text = "Auto Jump [OFF]"
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

        if autoJumpEnabled then
            button.Text = "Auto Jump [ON]"
            button.BackgroundColor3 = ON_COLOR
            task.spawn(autoJumpLoop)
        else
            button.Text = "Auto Jump [OFF]"
            button.BackgroundColor3 = OFF_COLOR
        end
    end)
end

createAutoJumpButton()
