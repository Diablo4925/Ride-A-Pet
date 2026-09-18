local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Remotes = ReplicatedStorage:WaitForChild("Remotes", 5)
local GameRemotes = Remotes and Remotes:FindFirstChild("Game")
local EggPickupRemote = GameRemotes and GameRemotes:FindFirstChild("EggPickup")

local VOID_FALL_HEIGHT = -650
local DROP_TIME = 0.2
local WARP_WAIT = 0.85
local PICKUP_DURATION = 3.0

local AutoFarmActive = false
local EspActive = true
local currentTween = nil
local trackedBillboards = {}

local RealEggDatabase = {
    ["Cherub Egg"] = {Luck = 1000000000000, Color = Color3.fromRGB(244, 180, 255), Tag = "1T"},
    ["Blackhole Egg"] = {Luck = 100000000000, Color = Color3.fromRGB(186, 104, 255), Tag = "100B"},
    ["Galaxy Egg"] = {Luck = 1500000000, Color = Color3.fromRGB(255, 120, 220), Tag = "1.5B"},
    ["Aurora Egg"] = {Luck = 300000000, Color = Color3.fromRGB(80, 250, 210), Tag = "300M"},
    ["Soul Egg"] = {Luck = 7000000, Color = Color3.fromRGB(60, 230, 160), Tag = "7M"},
    ["Sinister Egg"] = {Luck = 3000000, Color = Color3.fromRGB(255, 75, 75), Tag = "3M"},
    ["Flaming Egg"] = {Luck = 1000000, Color = Color3.fromRGB(255, 130, 60), Tag = "1M"},
    ["Dominus Egg"] = {Luck = 700000, Color = Color3.fromRGB(255, 80, 90), Tag = "700k"},
    ["Asteroid Egg"] = {Luck = 500000, Color = Color3.fromRGB(255, 175, 60), Tag = "500k"},
    ["Skull Egg"] = {Luck = 250000, Color = Color3.fromRGB(200, 205, 215), Tag = "250k"},
    ["Crystal Egg"] = {Luck = 150000, Color = Color3.fromRGB(200, 130, 255), Tag = "150k"},
    ["Diamond Egg"] = {Luck = 90000, Color = Color3.fromRGB(70, 210, 255), Tag = "90k"},
    ["Golden Egg"] = {Luck = 30000, Color = Color3.fromRGB(255, 210, 70), Tag = "30k"},
    ["Glass Egg"] = {Luck = 10000, Color = Color3.fromRGB(210, 235, 255), Tag = "10k"},
    ["Ice Egg"] = {Luck = 3000, Color = Color3.fromRGB(130, 210, 255), Tag = "3k"},
    ["Slime Egg"] = {Luck = 1000, Color = Color3.fromRGB(90, 240, 140), Tag = "1k"},
    ["Flower Egg"] = {Luck = 750, Color = Color3.fromRGB(255, 170, 205), Tag = "750"},
    ["Mushroom Egg"] = {Luck = 500, Color = Color3.fromRGB(255, 140, 140), Tag = "500"},
    ["Dragon Egg"] = {Luck = 500000000000, Color = Color3.fromRGB(255, 75, 75), Tag = "PREM"},
    ["Giant Egg"] = {Luck = 500000000000, Color = Color3.fromRGB(255, 160, 50), Tag = "PREM"},
    ["Devil Fruit Egg"] = {Luck = 999999999999, Color = Color3.fromRGB(255, 65, 85), Tag = "SECRET"},
    ["Admin Egg"] = {Luck = 999999999999, Color = Color3.fromRGB(255, 240, 70), Tag = "ADMIN"}
}

local DisplayToReal = {}
local RealToDisplay = {}
local displayList = {}

for realName, data in pairs(RealEggDatabase) do
    local dispName = realName .. " [" .. data.Tag .. "]"
    DisplayToReal[dispName] = realName
    RealToDisplay[realName] = dispName
    table.insert(displayList, dispName)
end

table.sort(displayList, function(a, b)
    local rA = DisplayToReal[a]
    local rB = DisplayToReal[b]
    return RealEggDatabase[rA].Luck > RealEggDatabase[rB].Luck
end)

local SelectedEggs = {
    ["Cherub Egg"] = true,
    ["Blackhole Egg"] = true,
    ["Galaxy Egg"] = true,
    ["Aurora Egg"] = true,
    ["Soul Egg"] = true,
    ["Sinister Egg"] = true,
    ["Flaming Egg"] = true,
    ["Dominus Egg"] = true,
    ["Asteroid Egg"] = true,
    ["Skull Egg"] = true,
    ["Diamond Egg"] = true,
    ["Crystal Egg"] = true,
    ["Dragon Egg"] = true,
    ["Giant Egg"] = true,
    ["Devil Fruit Egg"] = true,
    ["Admin Egg"] = true
}

local initialDisplayDefault = {}
for realName, val in pairs(SelectedEggs) do
    if val and RealToDisplay[realName] then
        initialDisplayDefault[RealToDisplay[realName]] = true
    end
end

LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new(0, 0))
end)

task.spawn(function()
    while true do
        task.wait(300)
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new(0, 0))
        end)
    end
end)

RunService.Stepped:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end

    if AutoFarmActive then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.PlatformStand = false
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
    end
    if hrp and not currentTween then
        hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
    end
end)

local function isWildEgg(obj)
    local isUnderPlot = obj:FindFirstAncestor("Plots") or obj:FindFirstAncestor("Plot") or obj:FindFirstAncestor("Nests") or obj:FindFirstAncestor("EggBaskets")
    return not isUnderPlot
end

local function getBestPart(obj)
    if obj:IsA("BasePart") then return obj end
    return obj:FindFirstChild("EggBase") or obj:FindFirstChild("Handle") or obj:FindFirstChildWhichIsA("BasePart")
end

local function getCandidateEggs()
    local list = {}
    local rendered = Workspace:FindFirstChild("RenderedEggs")
    if rendered then
        for _, obj in ipairs(rendered:GetChildren()) do
            table.insert(list, obj)
        end
    end
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj.Name:match("Egg") and not obj:FindFirstAncestor("Plots") then
            table.insert(list, obj)
        end
    end
    return list
end

local function fastVoidDrop()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    local voidTarget = CFrame.new(hrp.Position.X, VOID_FALL_HEIGHT, hrp.Position.Z)
    local tweenInfo = TweenInfo.new(DROP_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

    if currentTween then currentTween:Cancel() end
    currentTween = TweenService:Create(hrp, tweenInfo, {CFrame = voidTarget})
    currentTween:Play()

    local completed = false
    local conn
    conn = currentTween.Completed:Connect(function()
        completed = true
    end)

    local timeout = tick() + DROP_TIME + 0.4
    while not completed and tick() < timeout do
        task.wait(0.02)
    end

    if conn then conn:Disconnect() end
    if currentTween then currentTween:Cancel() currentTween = nil end

    if hrp and hrp.Parent then
        hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
    end

    task.wait(WARP_WAIT)
    return true
end

local function spamEggPickup(targetObj, targetPart, duration)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local endTime = tick() + duration

    while tick() < endTime do
        if hrp and targetPart and targetPart.Parent then
            hrp.CFrame = CFrame.new(targetPart.Position + Vector3.new(0, 1.5, 0))
            hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        end

        if fireproximityprompt and targetObj then
            local prompt = targetObj:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt then fireproximityprompt(prompt) end
        end

        if EggPickupRemote and targetObj then
            pcall(function()
                if EggPickupRemote:IsA("RemoteEvent") then
                    EggPickupRemote:FireServer(targetObj)
                else
                    EggPickupRemote:InvokeServer(targetObj)
                end
            end)
        end

        if firetouchinterest and hrp and targetPart then
            firetouchinterest(hrp, targetPart, 0)
            firetouchinterest(hrp, targetPart, 1)
        end

        if not targetObj.Parent then break end
        task.wait(0.08)
    end
end

local function updateEsp()
    if not EspActive then return end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local candidates = getCandidateEggs()
    local validObjs = {}

    for _, obj in ipairs(candidates) do
        local info = RealEggDatabase[obj.Name]
        if info and SelectedEggs[obj.Name] and isWildEgg(obj) then
            local p = getBestPart(obj)
            if p and p.Parent then
                validObjs[obj] = true
                local bb = trackedBillboards[obj]
                local dist = hrp and math.floor((hrp.Position - p.Position).Magnitude) or 0

                if not bb then
                    bb = Instance.new("BillboardGui")
                    bb.Name = "FluentEggBillboard"
                    bb.Size = UDim2.new(0, 130, 0, 22)
                    bb.AlwaysOnTop = true
                    bb.Adornee = p
                    bb.Parent = p

                    local frame = Instance.new("Frame", bb)
                    frame.Size = UDim2.new(1, 0, 1, 0)
                    frame.BackgroundColor3 = Color3.fromRGB(15, 18, 24)
                    frame.BackgroundTransparency = 0.2
                    frame.BorderSizePixel = 0
                    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)
                    local st = Instance.new("UIStroke", frame)
                    st.Color = info.Color
                    st.Thickness = 1.2

                    local label = Instance.new("TextLabel", frame)
                    label.Name = "Text"
                    label.Size = UDim2.new(1, 0, 1, 0)
                    label.BackgroundTransparency = 1
                    label.Text = string.format("%s [%s] • %dm", obj.Name, info.Tag, dist)
                    label.TextColor3 = Color3.fromRGB(240, 245, 255)
                    label.Font = Enum.Font.GothamBold
                    label.TextSize = 9

                    trackedBillboards[obj] = bb
                else
                    local l = bb:FindFirstChild("Text", true)
                    if l then
                        l.Text = string.format("%s [%s] • %dm", obj.Name, info.Tag, dist)
                    end
                end
            end
        end
    end

    for obj, bb in pairs(trackedBillboards) do
        if not validObjs[obj] or not obj.Parent then
            if bb then bb:Destroy() end
            trackedBillboards[obj] = nil
        end
    end
end

task.spawn(function()
    while true do
        if EspActive then pcall(updateEsp) end
        task.wait(1.5)
    end
end)

task.spawn(function()
    while true do
        if AutoFarmActive then
            pcall(function()
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local candidates = getCandidateEggs()
                    local bestEgg, bestPart = nil, nil
                    local highestLuck = -1
                    local shortestDist = 99999

                    for _, obj in ipairs(candidates) do
                        local info = RealEggDatabase[obj.Name]
                        if info and SelectedEggs[obj.Name] and isWildEgg(obj) then
                            local p = getBestPart(obj)
                            if p and p.Parent and isWildEgg(p) then
                                local dist = (hrp.Position - p.Position).Magnitude

                                if info.Luck > highestLuck then
                                    highestLuck = info.Luck
                                    shortestDist = dist
                                    bestEgg = obj
                                    bestPart = p
                                elseif info.Luck == highestLuck and dist < shortestDist then
                                    shortestDist = dist
                                    bestEgg = obj
                                    bestPart = p
                                end
                            end
                        end
                    end

                    if bestEgg and bestPart and bestEgg.Parent then
                        hrp.CFrame = CFrame.new(bestPart.Position + Vector3.new(0, 1.5, 0))
                        hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                        hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)

                        spamEggPickup(bestEgg, bestPart, PICKUP_DURATION)
                        fastVoidDrop()
                    end
                end
            end)
        end
        task.wait(0.4)
    end
end)

local Window = Fluent:CreateWindow({
    Title = "Aether Suite",
    SubTitle = "Ride A Pet • Fluent Edition",
    TabWidth = 150,
    Size = UDim2.fromOffset(560, 420),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Main = Window:AddTab({ Title = "Auto Farm", Icon = "play" }),
    Eggs = Window:AddTab({ Title = "Target Eggs", Icon = "egg" }),
    Visuals = Window:AddTab({ Title = "Visuals", Icon = "eye" })
}

Tabs.Main:AddParagraph({
    Title = "Void Warp Harvester",
    Content = "Instant void fall return (-650 Y). Noclip, Anti-Ragdoll, and Anti-AFK are active."
})

local FarmToggle = Tabs.Main:AddToggle("AutoFarmToggle", {
    Title = "Enable Auto Farm",
    Default = false
})

FarmToggle:OnChanged(function()
    AutoFarmActive = Fluent.Options.AutoFarmToggle.Value
    if not AutoFarmActive and currentTween then
        currentTween:Cancel()
        currentTween = nil
    end
    Fluent:Notify({
        Title = "Harvester Engine",
        Content = AutoFarmActive and "Auto Farm Started!" or "Auto Farm Stopped.",
        Duration = 2.5
    })
end)

Tabs.Eggs:AddParagraph({
    Title = "Egg Selection & Filters",
    Content = "Choose which wild eggs to target."
})

local EggDropdown = Tabs.Eggs:AddDropdown("EggSelector", {
    Title = "Select Eggs",
    Values = displayList,
    Multi = true,
    Default = initialDisplayDefault
})

local function syncSelectionFromDropdown(val)
    local updated = {}
    for dispName, isSelected in pairs(val) do
        if isSelected then
            local r = DisplayToReal[dispName]
            if r then
                updated[r] = true
            end
        end
    end
    SelectedEggs = updated
end

EggDropdown:OnChanged(function(Value)
    syncSelectionFromDropdown(Value)
end)

local function updateDropdownDisplay(newDisplayMap)
    table.clear(EggDropdown.Value)
    for k, v in pairs(newDisplayMap) do
        if v == true then
            EggDropdown.Value[k] = true
        end
    end
    syncSelectionFromDropdown(EggDropdown.Value)
    if EggDropdown.BuildDropdownList then
        EggDropdown:BuildDropdownList()
    end
    if EggDropdown.Display then
        EggDropdown:Display()
    end
end

Tabs.Eggs:AddButton({
    Title = "Select 100B+ Luck Only",
    Description = "Filter Cherub, Blackhole, and God-tier eggs",
    Callback = function()
        local newMap = {}
        for _, disp in ipairs(displayList) do
            local r = DisplayToReal[disp]
            local luck = r and RealEggDatabase[r] and RealEggDatabase[r].Luck or 0
            if luck >= 100000000000 then
                newMap[disp] = true
            end
        end
        updateDropdownDisplay(newMap)
        Fluent:Notify({ Title = "Filter Applied", Content = "Targeting 100B+ eggs", Duration = 2 })
    end
})

Tabs.Eggs:AddButton({
    Title = "Select All Eggs",
    Callback = function()
        local newMap = {}
        for _, disp in ipairs(displayList) do
            newMap[disp] = true
        end
        updateDropdownDisplay(newMap)
        Fluent:Notify({ Title = "Filter Applied", Content = "All eggs selected", Duration = 2 })
    end
})

Tabs.Eggs:AddButton({
    Title = "Clear All Selections",
    Callback = function()
        updateDropdownDisplay({})
        Fluent:Notify({ Title = "Filter Applied", Content = "Cleared all selections", Duration = 2 })
    end
})

local EspToggle = Tabs.Visuals:AddToggle("EspToggle", {
    Title = "Live Egg Billboard ESP",
    Default = true
})

EspToggle:OnChanged(function()
    EspActive = Fluent.Options.EspToggle.Value
    if not EspActive then
        for _, bb in pairs(trackedBillboards) do if bb then bb:Destroy() end end
        trackedBillboards = {}
    end
end)

local targetGuiParent = (gethui and gethui()) or CoreGui:FindFirstChild("RobloxGui") or LocalPlayer:WaitForChild("PlayerGui")

if targetGuiParent:FindFirstChild("AetherMobileWidget") then
    targetGuiParent.AetherMobileWidget:Destroy()
end

local WidgetGui = Instance.new("ScreenGui")
WidgetGui.Name = "AetherMobileWidget"
WidgetGui.ResetOnSpawn = false
WidgetGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
WidgetGui.Parent = targetGuiParent

local WidgetBtn = Instance.new("TextButton")
WidgetBtn.Name = "WidgetToggleBtn"
WidgetBtn.Size = UDim2.new(0, 48, 0, 48)
WidgetBtn.Position = UDim2.new(0, 18, 0.45, 0)
WidgetBtn.BackgroundColor3 = Color3.fromRGB(18, 21, 28)
WidgetBtn.BorderSizePixel = 0
WidgetBtn.Text = "⚡"
WidgetBtn.TextColor3 = Color3.fromRGB(0, 220, 255)
WidgetBtn.Font = Enum.Font.GothamBold
WidgetBtn.TextSize = 22
WidgetBtn.Active = true
WidgetBtn.Parent = WidgetGui

Instance.new("UICorner", WidgetBtn).CornerRadius = UDim.new(0, 14)
local wStroke = Instance.new("UIStroke", WidgetBtn)
wStroke.Color = Color3.fromRGB(45, 52, 68)
wStroke.Thickness = 1.4

local isDragging = false
local dragStartPos, btnStartPos

WidgetBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = true
        dragStartPos = input.Position
        btnStartPos = WidgetBtn.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                isDragging = false
            end
        end)
    end
end)

WidgetBtn.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        if isDragging then
            local delta = input.Position - dragStartPos
            WidgetBtn.Position = UDim2.new(
                btnStartPos.X.Scale,
                btnStartPos.X.Offset + delta.X,
                btnStartPos.Y.Scale,
                btnStartPos.Y.Offset + delta.Y
            )
        end
    end
end)

WidgetBtn.MouseButton1Click:Connect(function()
    if Fluent.GUI then
        Fluent.GUI.Enabled = not Fluent.GUI.Enabled
    else
        Window:Minimize()
    end
end)

Fluent:Notify({
    Title = "Aether Loaded",
    Content = "Ready",
    Duration = 3
})
