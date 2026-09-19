if _G.RideUrMoM_Instance then
    pcall(function()
        _G.RideUrMoM_Instance:Destroy()
    end)
    _G.RideUrMoM_Running = false
    task.wait(0.5)
end

if _G.RideUrMoM_Connections then
    for _, conn in ipairs(_G.RideUrMoM_Connections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(_G.RideUrMoM_Connections)
end
_G.RideUrMoM_Connections = {}

local function trackConnection(conn)
    table.insert(_G.RideUrMoM_Connections, conn)
    return conn
end

if _G.RideUrMoM_Billboards then
    for _, bb in pairs(_G.RideUrMoM_Billboards) do
        pcall(function() bb:Destroy() end)
    end
    table.clear(_G.RideUrMoM_Billboards)
end
_G.RideUrMoM_Billboards = {}

_G.RideUrMoM_Running = true
local currentScriptSession = tick()
_G.RideUrMoM_Session = currentScriptSession

task.wait(5)

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

local playerGui = (gethui and gethui()) or LocalPlayer:WaitForChild("PlayerGui")
local coreRoblox = CoreGui:FindFirstChild("RobloxGui") or playerGui

local function cleanupOldWidgets()
    for _, parent in ipairs({coreRoblox, playerGui, CoreGui}) do
        local old = parent:FindFirstChild("AetherMobileWidget")
        if old then pcall(function() old:Destroy() end) end
    end
end
cleanupOldWidgets()

local queueTeleport = (syn and syn.queue_on_teleport) or queue_on_teleport or (fluxus and fluxus.queue_on_teleport)
local httpRequest = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
local AUTO_EXEC_CODE = 'loadstring(game:HttpGet("https://raw.githubusercontent.com/Diablo4925/Ride-A-Pet/refs/heads/main/Gay.lua"))()'
local CONFIG_FILE = "RideUrMoM_Config.json"
local VISITED_SERVERS_FILE = "RideUrMoM_Visited.json"
local SERVER_POOL_FILE = "RideUrMoM_ServerPool.json"

local AutoExecEnabled = true
local AutoHopEnabled = false
local AutoFarmActive = false
local EspActive = false
local HopDelay = 5
local scanFailTime = 0
local isHopping = false
local currentFpsCap = 30
local disable3dActive = false
local autoPurgePopups = true

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Remotes = ReplicatedStorage:WaitForChild("Remotes", 5)
local GameRemotes = Remotes and Remotes:FindFirstChild("Game")
local EggPickupRemote = GameRemotes and GameRemotes:FindFirstChild("EggPickup")

local VOID_FALL_HEIGHT = -650
local DROP_TIME = 0.2
local WARP_WAIT = 0.75
local PICKUP_DURATION = 2.0
local HOLD_EGG_DELAY = 0.8

local currentTween = nil
local trackedBillboards = _G.RideUrMoM_Billboards

local RealEggDatabase = {
    ["Admin Egg"]        = {Luck = 999999999999, Color = Color3.fromRGB(255, 240, 70),  Tag = "ADMIN"},
    ["Devil Fruit Egg"]  = {Luck = 999999999999, Color = Color3.fromRGB(255, 65, 85),   Tag = "SECRET"},
    ["Dragon Egg"]       = {Luck = 500000000000, Color = Color3.fromRGB(255, 75, 75),   Tag = "PREM"},
    ["Giant Egg"]        = {Luck = 500000000000, Color = Color3.fromRGB(255, 160, 50),  Tag = "PREM"},
    ["Cherub Egg"]       = {Luck = 1000000000000, Color = Color3.fromRGB(244, 180, 255), Tag = "1T"},
    ["Solaris Egg"]      = {Luck = 300000000000,  Color = Color3.fromRGB(255, 130, 30),  Tag = "300B"},
    ["Blackhole Egg"]    = {Luck = 100000000000,  Color = Color3.fromRGB(186, 104, 255), Tag = "100B"},
    ["Galaxy Egg"]       = {Luck = 1500000000,    Color = Color3.fromRGB(255, 120, 220), Tag = "1.5B"},
    ["Aurora Egg"]       = {Luck = 300000000,     Color = Color3.fromRGB(80, 250, 210),  Tag = "300M"},
    ["Soul Egg"]         = {Luck = 7000000,  Color = Color3.fromRGB(60, 230, 160),  Tag = "7M"},
    ["Sinister Egg"]     = {Luck = 3000000,  Color = Color3.fromRGB(255, 75, 75),   Tag = "3M"},
    ["Flaming Egg"]      = {Luck = 1000000,  Color = Color3.fromRGB(255, 130, 60),  Tag = "1M"},
    ["Dominus Egg"]      = {Luck = 700000,   Color = Color3.fromRGB(255, 80, 90),   Tag = "700K"},
    ["Asteroid Egg"]     = {Luck = 500000,   Color = Color3.fromRGB(255, 175, 60),  Tag = "500K"},
    ["Skull Egg"]        = {Luck = 250000,   Color = Color3.fromRGB(200, 205, 215), Tag = "250K"},
    ["Crystal Egg"]      = {Luck = 150000,   Color = Color3.fromRGB(200, 130, 255), Tag = "150K"},
    ["Diamond Egg"]      = {Luck = 90000,    Color = Color3.fromRGB(70, 210, 255),  Tag = "90K"},
    ["Golden Egg"]       = {Luck = 30000,    Color = Color3.fromRGB(255, 210, 70),  Tag = "30K"},
    ["Glass Egg"]        = {Luck = 10000, Color = Color3.fromRGB(210, 235, 255), Tag = "10K"},
    ["Ice Egg"]          = {Luck = 3000,  Color = Color3.fromRGB(130, 210, 255), Tag = "3K"},
    ["Slime Egg"]        = {Luck = 1000,  Color = Color3.fromRGB(90, 240, 140),  Tag = "1K"},
    ["Flower Egg"]       = {Luck = 750,   Color = Color3.fromRGB(255, 170, 205), Tag = "750"},
    ["Mushroom Egg"]     = {Luck = 500,   Color = Color3.fromRGB(255, 140, 140), Tag = "500"},
    ["Leaf Egg"]         = {Luck = 200,   Color = Color3.fromRGB(100, 220, 80),  Tag = "200"},
    ["Stone Egg"]        = {Luck = 100, Color = Color3.fromRGB(160, 160, 160), Tag = "100"},
    ["Easter Egg"]       = {Luck = 50,  Color = Color3.fromRGB(255, 200, 240), Tag = "50"},
    ["Cracked Egg"]      = {Luck = 30,  Color = Color3.fromRGB(200, 185, 150), Tag = "30"},
    ["Brown Egg"]        = {Luck = 5,   Color = Color3.fromRGB(180, 120, 60),  Tag = "5"},
    ["White Egg"]        = {Luck = 1,   Color = Color3.fromRGB(240, 240, 245), Tag = "1"},
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
    ["Cherub Egg"]      = true,
    ["Blackhole Egg"]   = true,
    ["Solaris Egg"]     = true,
    ["Galaxy Egg"]      = true,
    ["Aurora Egg"]      = true,
    ["Soul Egg"]        = true,
    ["Sinister Egg"]    = true,
    ["Dominus Egg"]     = true,
    ["Skull Egg"]       = true,
    ["Diamond Egg"]     = true,
    ["Crystal Egg"]     = true,
    ["Dragon Egg"]      = true,
    ["Giant Egg"]       = true,
    ["Devil Fruit Egg"] = true,
    ["Admin Egg"]       = true
}

local function setDisable3D(enable)
    disable3dActive = enable
    if RunService.Set3dRenderingEnabled then
        pcall(RunService.Set3dRenderingEnabled, RunService, not enable)
    end
end

local function saveConfig()
    if not writefile then return end
    pcall(function()
        local data = {
            AutoFarm = AutoFarmActive,
            AutoHop = AutoHopEnabled,
            AutoExec = AutoExecEnabled,
            Esp = EspActive,
            Fps = currentFpsCap,
            Disable3D = disable3dActive,
            AutoPurge = autoPurgePopups,
            Selected = SelectedEggs
        }
        writefile(CONFIG_FILE, HttpService:JSONEncode(data))
    end)
end

local function loadConfig()
    if not readfile or not isfile or not isfile(CONFIG_FILE) then return end
    pcall(function()
        local content = readfile(CONFIG_FILE)
        local data = HttpService:JSONDecode(content)
        if data then
            if data.AutoFarm ~= nil then AutoFarmActive = data.AutoFarm end
            if data.AutoHop ~= nil then AutoHopEnabled = data.AutoHop end
            if data.AutoExec ~= nil then AutoExecEnabled = data.AutoExec end
            if data.Esp ~= nil then EspActive = data.Esp end
            if data.Fps ~= nil then currentFpsCap = data.Fps end
            if data.Disable3D ~= nil then
                disable3dActive = data.Disable3D
            elseif data.SafeBlackScreen ~= nil then
                disable3dActive = data.SafeBlackScreen
            end
            if data.AutoPurge ~= nil then autoPurgePopups = data.AutoPurge end
            if data.Selected and type(data.Selected) == "table" then
                SelectedEggs = data.Selected
            end
        end
    end)
end
loadConfig()

if setfpscap and currentFpsCap then
    pcall(setfpscap, currentFpsCap)
end

if disable3dActive then
    task.defer(function()
        setDisable3D(true)
    end)
end

local initialDisplayDefault = {}
for realName, val in pairs(SelectedEggs) do
    if val and RealToDisplay[realName] then
        initialDisplayDefault[RealToDisplay[realName]] = true
    end
end

local VirtualInputManager = game:GetService("VirtualInputManager")

local function secureAntiAFK()
    pcall(function()
        local idledConns = getconnections and getconnections(LocalPlayer.Idled)
        if idledConns then
            for _, conn in pairs(idledConns) do
                if conn.Disable then
                    conn:Disable()
                elseif conn.Disconnect then
                    conn:Disconnect()
                end
            end
        end
    end)
    pcall(function()
        local ps = LocalPlayer:FindFirstChild("PlayerScripts")
        local reusable = ps and ps:FindFirstChild("Reusable")
        local afkScript = reusable and reusable:FindFirstChild("TeleportBackOnAFK")
        if afkScript then
            afkScript.Disabled = true
        end
    end)
end

secureAntiAFK()

local cachedCharacterParts = {}

local function setupHumanoid(char)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.PlatformStand = false
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
    end
end

local function updateCharacterParts(char)
    table.clear(cachedCharacterParts)
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            table.insert(cachedCharacterParts, part)
        end
    end
    setupHumanoid(char)
end

if LocalPlayer.Character then
    updateCharacterParts(LocalPlayer.Character)
end

trackConnection(LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    updateCharacterParts(char)
    trackConnection(char.DescendantAdded:Connect(function(desc)
        if desc:IsA("BasePart") then
            table.insert(cachedCharacterParts, desc)
        end
    end))
    trackConnection(char.DescendantRemoving:Connect(function(desc)
        if desc:IsA("BasePart") then
            local idx = table.find(cachedCharacterParts, desc)
            if idx then
                table.remove(cachedCharacterParts, idx)
            end
        end
    end))
    secureAntiAFK()
end))

task.spawn(function()
    while _G.RideUrMoM_Running and _G.RideUrMoM_Session == currentScriptSession do
        task.wait(60)
        secureAntiAFK()
        pcall(function()
            if VirtualInputManager then
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.RightControl, false, game)
                task.wait(0.05)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.RightControl, false, game)
            end
        end)
        pcall(collectgarbage, "collect")
    end
end)

trackConnection(RunService.Stepped:Connect(function()
    if not _G.RideUrMoM_Running or _G.RideUrMoM_Session ~= currentScriptSession then return end
    local char = LocalPlayer.Character
    if not char then return end

    if AutoFarmActive then
        for i = #cachedCharacterParts, 1, -1 do
            local part = cachedCharacterParts[i]
            if part and part.Parent then
                if part.CanCollide then
                    part.CanCollide = false
                end
            else
                table.remove(cachedCharacterParts, i)
            end
        end
    end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp and not currentTween then
        hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
    end
end))

local renderedEggsFolder = Workspace:FindFirstChild("RenderedEggs")

local eggPromptCache = setmetatable({}, { __mode = "k" })
local eggPartCache = setmetatable({}, { __mode = "k" })
local eggSizeCache = setmetatable({}, { __mode = "k" })

local function getEggPrompt(obj)
    local cached = eggPromptCache[obj]
    if cached and cached.Parent then
        return cached
    end
    local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt then
        eggPromptCache[obj] = prompt
    end
    return prompt
end

local function isWildEgg(obj)
    if not obj or not obj.Parent then return false end
    if not renderedEggsFolder or not renderedEggsFolder.Parent then
        renderedEggsFolder = Workspace:FindFirstChild("RenderedEggs")
    end
    if renderedEggsFolder and obj.Parent ~= renderedEggsFolder then
        return false
    end
    local prompt = getEggPrompt(obj)
    return prompt ~= nil and prompt.Enabled
end

local function getBestPart(obj)
    local cached = eggPartCache[obj]
    if cached and cached.Parent then
        return cached
    end

    local prompt = getEggPrompt(obj)
    if prompt and prompt.Parent then
        if prompt.Parent:IsA("BasePart") then
            eggPartCache[obj] = prompt.Parent
            return prompt.Parent
        elseif prompt.Parent:IsA("Attachment") and prompt.Parent.Parent and prompt.Parent.Parent:IsA("BasePart") then
            eggPartCache[obj] = prompt.Parent.Parent
            return prompt.Parent.Parent
        end
    end
    local part = (obj:IsA("BasePart") and obj)
        or obj:FindFirstChild("Handle")
        or obj:FindFirstChild("EggBase")
        or obj:FindFirstChildWhichIsA("BasePart")

    if part then
        eggPartCache[obj] = part
    end
    return part
end

local function getEggSize(obj)
    local cached = eggSizeCache[obj]
    if cached then return cached end

    local scaleAttr = obj:GetAttribute("Scale") or obj:GetAttribute("Size") or obj:GetAttribute("EggScale")
    if type(scaleAttr) == "number" then
        eggSizeCache[obj] = scaleAttr
        return scaleAttr
    end
    if typeof(scaleAttr) == "Vector3" then
        local mag = scaleAttr.Magnitude
        eggSizeCache[obj] = mag
        return mag
    end

    if obj:IsA("Model") then
        local cf, size = obj:GetBoundingBox()
        local vol = size.X * size.Y * size.Z
        eggSizeCache[obj] = vol
        return vol
    elseif obj:IsA("BasePart") then
        local vol = obj.Size.X * obj.Size.Y * obj.Size.Z
        eggSizeCache[obj] = vol
        return vol
    end

    local best = getBestPart(obj)
    if best then
        local vol = best.Size.X * best.Size.Y * best.Size.Z
        eggSizeCache[obj] = vol
        return vol
    end

    eggSizeCache[obj] = 1
    return 1
end

local activeWildEggs = {}
local candidateListCache = {}

local function registerEgg(egg)
    if isWildEgg(egg) then
        activeWildEggs[egg] = true
    end
end

local function unregisterEgg(egg)
    activeWildEggs[egg] = nil
    eggPromptCache[egg] = nil
    eggPartCache[egg] = nil
    eggSizeCache[egg] = nil
end

local function initEggTracking()
    table.clear(activeWildEggs)
    renderedEggsFolder = Workspace:FindFirstChild("RenderedEggs")
    if not renderedEggsFolder then return end

    for _, egg in ipairs(renderedEggsFolder:GetChildren()) do
        registerEgg(egg)
    end

    trackConnection(renderedEggsFolder.ChildAdded:Connect(function(egg)
        task.wait(0.1)
        registerEgg(egg)
    end))

    trackConnection(renderedEggsFolder.ChildRemoved:Connect(function(egg)
        unregisterEgg(egg)
    end))
end

initEggTracking()

local function getCandidateEggs()
    table.clear(candidateListCache)
    if not renderedEggsFolder or not renderedEggsFolder.Parent then
        initEggTracking()
        if not renderedEggsFolder then return candidateListCache end
    end

    for egg in pairs(activeWildEggs) do
        if egg.Parent == renderedEggsFolder then
            table.insert(candidateListCache, egg)
        else
            unregisterEgg(egg)
        end
    end
    return candidateListCache
end

local function getVisitedServers()
    local visited = {}
    if readfile and isfile and isfile(VISITED_SERVERS_FILE) then
        pcall(function()
            local decoded = HttpService:JSONDecode(readfile(VISITED_SERVERS_FILE))
            if type(decoded) == "table" then
                visited = decoded
            end
        end)
    end
    return visited
end

local function saveVisitedServer(id)
    if not writefile then return end
    pcall(function()
        local visited = getVisitedServers()
        visited[id] = tick()
        for k, v in pairs(visited) do
            if tick() - v > 2400 then
                visited[k] = nil
            end
        end
        writefile(VISITED_SERVERS_FILE, HttpService:JSONEncode(visited))
    end)
end

local cachedFriendServers = {}

local function refreshFriendCache()
    pcall(function()
        local friends = LocalPlayer:GetFriendsOnline(200)
        local newCache = {}
        if friends and type(friends) == "table" then
            for _, f in ipairs(friends) do
                if f.PlaceId == game.PlaceId and f.GameId then
                    newCache[f.GameId] = true
                end
            end
        end
        cachedFriendServers = newCache
    end)
end

task.spawn(function()
    refreshFriendCache()
    while _G.RideUrMoM_Running and _G.RideUrMoM_Session == currentScriptSession do
        task.wait(120)
        refreshFriendCache()
    end
end)

local function getStoredServerPool()
    local pool = {}
    if readfile and isfile and isfile(SERVER_POOL_FILE) then
        pcall(function()
            local decoded = HttpService:JSONDecode(readfile(SERVER_POOL_FILE))
            if type(decoded) == "table" then
                pool = decoded
            end
        end)
    end
    return pool
end

local function saveStoredServerPool(pool)
    if not writefile then return end
    pcall(function()
        writefile(SERVER_POOL_FILE, HttpService:JSONEncode(pool))
    end)
end

local function getAvailableServerFromPool()
    local pool = getStoredServerPool()
    local visited = getVisitedServers()
    local currentJob = game.JobId
    local candidates = {}

    for _, id in ipairs(pool) do
        if type(id) == "string" and id ~= currentJob and not visited[id] and not cachedFriendServers[id] then
            table.insert(candidates, id)
        end
    end

    if #candidates > 0 then
        return candidates[math.random(1, #candidates)]
    end
    return nil
end

local function fetchServersBatch()
    local placeId = game.PlaceId
    local currentJob = game.JobId
    local newPool = {}

    local endpoints = {
        "https://games.roblox.com/v1/games/" .. tostring(placeId) .. "/servers/Public?sortOrder=Asc&limit=100",
        "https://games.roproxy.com/v1/games/" .. tostring(placeId) .. "/servers/Public?sortOrder=Asc&limit=100",
        "https://games.roblox.com/v1/games/" .. tostring(placeId) .. "/servers/Public?sortOrder=Desc&limit=100",
        "https://games.roproxy.com/v1/games/" .. tostring(placeId) .. "/servers/Public?sortOrder=Desc&limit=100"
    }

    for _, baseUrl in ipairs(endpoints) do
        local body = nil

        if httpRequest then
            pcall(function()
                local res = httpRequest({
                    Url = baseUrl,
                    Method = "GET",
                    Headers = {
                        ["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
                        ["Accept"] = "application/json"
                    }
                })
                if res and (res.StatusCode == 200 or res.Status == 200) and res.Body then
                    body = res.Body
                end
            end)
        end

        if not body then
            pcall(function()
                local res = game:HttpGet(baseUrl)
                if res and string.find(res, "data") then
                    body = res
                end
            end)
        end

        if body then
            local ok, data = pcall(function()
                return HttpService:JSONDecode(body)
            end)
            if ok and data and data.data then
                for _, server in ipairs(data.data) do
                    if type(server) == "table" and server.id then
                        local playing = tonumber(server.playing) or 0
                        local maxPlayers = tonumber(server.maxPlayers) or 0
                        if server.id ~= currentJob and (maxPlayers == 0 or maxPlayers - playing >= 1) then
                            table.insert(newPool, server.id)
                        end
                    end
                end
                if #newPool > 0 then
                    saveStoredServerPool(newPool)
                    return newPool
                end
            end
        end
        task.wait(0.25)
    end
    return newPool
end

local function hopServer()
    if isHopping then return end
    isHopping = true

    if AutoExecEnabled and queueTeleport then
        pcall(function()
            queueTeleport(AUTO_EXEC_CODE)
        end)
    end

    saveVisitedServer(game.JobId)

    local targetServer = getAvailableServerFromPool()

    if not targetServer then
        Fluent:Notify({ Title = "Server Hop", Content = "Searching server pool...", Duration = 2 })
        fetchServersBatch()
        targetServer = getAvailableServerFromPool()
    end

    if not targetServer then
        pcall(function()
            if writefile then writefile(VISITED_SERVERS_FILE, "{}") end
        end)
        targetServer = getAvailableServerFromPool()
    end

    if targetServer then
        saveVisitedServer(targetServer)
        Fluent:Notify({ Title = "Server Hop", Content = "Hopping to " .. string.sub(targetServer, 1, 8) .. "...", Duration = 2.5 })
        task.wait(0.3)
        TeleportService:TeleportToPlaceInstance(game.PlaceId, targetServer, LocalPlayer)
    else
        Fluent:Notify({ Title = "Server Hop", Content = "API busy, retrying in 3s...", Duration = 3 })
        task.wait(3)
        isHopping = false
        hopServer()
        return
    end

    task.wait(5)
    isHopping = false
end

pcall(function()
    TeleportService.TeleportInitFailed:Connect(function(player, teleportResult, errorMessage)
        if player == LocalPlayer then
            isHopping = false
            Fluent:Notify({ Title = "Hop Failed", Content = "Retrying another server...", Duration = 2 })
            task.wait(1)
            hopServer()
        end
    end)
end)

local function fastVoidDrop()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    local voidTarget = CFrame.new(hrp.Position.X, VOID_FALL_HEIGHT, hrp.Position.Z)
    local tweenInfo = TweenInfo.new(DROP_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

    if currentTween then
        currentTween:Cancel()
        pcall(function() currentTween:Destroy() end)
        currentTween = nil
    end
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
    if currentTween then
        currentTween:Cancel()
        pcall(function() currentTween:Destroy() end)
        currentTween = nil
    end

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
    if not hrp or not targetPart or not targetPart.Parent then return false end

    local prompt = getEggPrompt(targetObj)
    local promptPart = prompt and prompt.Parent or targetPart
    local targetPos = (promptPart:IsA("BasePart") and promptPart.Position)
        or (promptPart:IsA("Attachment") and promptPart.WorldPosition)
        or targetPart.Position

    local bv = hrp:FindFirstChild("EggFloatVelocity")
    if not bv then
        bv = Instance.new("BodyVelocity")
        bv.Name = "EggFloatVelocity"
        bv.Parent = hrp
    end
    bv.Velocity = Vector3.new(0, 0, 0)
    bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)

    hrp.Anchored = false
    hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
    hrp.CFrame = CFrame.new(targetPos + Vector3.new(0, 0.6, 0.2))

    local endTime = tick() + duration
    local pickedUp = false

    while tick() < endTime do
        if not targetObj.Parent or (renderedEggsFolder and targetObj.Parent ~= renderedEggsFolder) then
            pickedUp = true
            break
        end

        if hrp and promptPart and promptPart.Parent then
            hrp.CFrame = CFrame.new(targetPos + Vector3.new(0, 0.6, 0.2))
            hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        end

        local currentPrompt = getEggPrompt(targetObj)
        if currentPrompt and currentPrompt.Enabled then
            if fireproximityprompt then
                pcall(fireproximityprompt, currentPrompt)
            end
            if VirtualInputManager then
                pcall(function()
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                end)
            end
        end

        if EggPickupRemote and targetObj and targetObj.Parent then
            pcall(function()
                if EggPickupRemote:IsA("RemoteEvent") then
                    EggPickupRemote:FireServer(targetObj)
                else
                    EggPickupRemote:InvokeServer(targetObj)
                end
            end)
        end

        if firetouchinterest and hrp and targetPart and targetPart.Parent then
            pcall(function()
                firetouchinterest(hrp, targetPart, 0)
                firetouchinterest(hrp, targetPart, 1)
            end)
        end

        task.wait(0.04)
    end

    if VirtualInputManager then
        pcall(function()
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
        end)
    end

    if not targetObj.Parent or (renderedEggsFolder and targetObj.Parent ~= renderedEggsFolder) then
        pickedUp = true
    end

    if bv and bv.Parent then
        bv.MaxForce = Vector3.new(0, 0, 0)
    end
    if hrp then
        hrp.Anchored = false
    end

    return pickedUp
end

local validObjs = {}

local function removeBillboard(obj)
    local bb = trackedBillboards[obj]
    if bb then
        pcall(function() bb:Destroy() end)
        trackedBillboards[obj] = nil
    end
end

local function updateEsp()
    if not EspActive then return end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local candidates = getCandidateEggs()
    table.clear(validObjs)

    for i = 1, #candidates do
        local obj = candidates[i]
        local info = RealEggDatabase[obj.Name]
        if info and SelectedEggs[obj.Name] then
            local p = getBestPart(obj)
            if p and p.Parent then
                validObjs[obj] = true
                local bb = trackedBillboards[obj]
                local dist = hrp and math.floor((hrp.Position - p.Position).Magnitude) or 0

                if not bb or not bb.Parent then
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

                    local conn
                    conn = obj.AncestryChanged:Connect(function(_, parent)
                        if not parent then
                            removeBillboard(obj)
                            if conn then conn:Disconnect() end
                        end
                    end)
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
            removeBillboard(obj)
        end
    end
end

task.spawn(function()
    while _G.RideUrMoM_Running and _G.RideUrMoM_Session == currentScriptSession do
        if EspActive then pcall(updateEsp) end
        task.wait(1.5)
    end
end)

task.spawn(function()
    while _G.RideUrMoM_Running and _G.RideUrMoM_Session == currentScriptSession do
        if AutoFarmActive then
            pcall(function()
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local candidates = getCandidateEggs()
                    local bestEgg, bestPart = nil, nil
                    local highestLuck = -1
                    local biggestSize = -1
                    local shortestDist = 99999

                    for i = 1, #candidates do
                        local obj = candidates[i]
                        local info = RealEggDatabase[obj.Name]
                        if info and SelectedEggs[obj.Name] then
                            local p = getBestPart(obj)
                            if p and p.Parent then
                                local dist = (hrp.Position - p.Position).Magnitude
                                local currentSize = getEggSize(obj)

                                local isBetter = false
                                if info.Luck > highestLuck then
                                    isBetter = true
                                elseif info.Luck == highestLuck then
                                    if currentSize > (biggestSize * 1.05) then
                                        isBetter = true
                                    elseif math.abs(currentSize - biggestSize) <= (biggestSize * 0.05) then
                                        if dist < shortestDist then
                                            isBetter = true
                                        end
                                    end
                                end

                                if isBetter then
                                    highestLuck = info.Luck
                                    biggestSize = currentSize
                                    shortestDist = dist
                                    bestEgg = obj
                                    bestPart = p
                                end
                            end
                        end
                    end

                    if bestEgg and bestPart and bestEgg.Parent then
                        scanFailTime = 0
                        local collected = spamEggPickup(bestEgg, bestPart, PICKUP_DURATION)
                        if collected then
                            task.wait(HOLD_EGG_DELAY)
                            fastVoidDrop()
                        end
                    else
                        if AutoHopEnabled and not isHopping then
                            if scanFailTime == 0 then
                                scanFailTime = tick()
                            elseif tick() - scanFailTime >= HopDelay then
                                hopServer()
                            end
                        end
                    end
                end
            end)
        else
            scanFailTime = 0
        end
        task.wait(0.4)
    end
end)

local function purgePopupsAndEffects()
    if not autoPurgePopups then return end
    pcall(function()
        local camera = Workspace.CurrentCamera
        if camera then
            for _, obj in ipairs(camera:GetChildren()) do
                if obj:IsA("BillboardGui") or obj:IsA("Part") then
                    pcall(function() obj:Destroy() end)
                end
            end
        end

        local char = LocalPlayer.Character
        if char then
            for _, bb in ipairs(char:GetDescendants()) do
                if bb:IsA("BillboardGui") and bb.Name ~= "FluentEggBillboard" then
                    pcall(function() bb:Destroy() end)
                end
            end
        end
    end)
end

task.spawn(function()
    while _G.RideUrMoM_Running and _G.RideUrMoM_Session == currentScriptSession do
        task.wait(10)
        purgePopupsAndEffects()
    end
end)

local Window = Fluent:CreateWindow({
    Title = "Ride Ur MoM",
    SubTitle = "By. Diablo",
    TabWidth = 150,
    Size = UDim2.fromOffset(560, 420),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

_G.RideUrMoM_Instance = Fluent.GUI
if Fluent.GUI then
    Fluent.GUI.DisplayOrder = 1000002
end

local Tabs = {
    Main = Window:AddTab({ Title = "Auto Farm", Icon = "play" }),
    Eggs = Window:AddTab({ Title = "Target Eggs", Icon = "egg" }),
    Server = Window:AddTab({ Title = "Server & Hop", Icon = "globe" }),
    Visuals = Window:AddTab({ Title = "Visuals", Icon = "eye" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

Tabs.Main:AddParagraph({
    Title = "Ride Ur MoM • Harvester",
    Content = "Instant void fall return (-650 Y). Prioritizes Highest Luck & Biggest Size."
})

local FarmToggle = Tabs.Main:AddToggle("AutoFarmToggle", {
    Title = "Enable Auto Farm",
    Default = AutoFarmActive
})

FarmToggle:OnChanged(function()
    AutoFarmActive = Fluent.Options.AutoFarmToggle.Value
    if not AutoFarmActive and currentTween then
        currentTween:Cancel()
        currentTween = nil
    end
    saveConfig()
    Fluent:Notify({
        Title = "Ride Ur MoM",
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
    saveConfig()
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
    Title = "Select 300B+ (God-Tier Only)",
    Description = "Filter Cherub Egg [1T] & Solaris Egg [300B]",
    Callback = function()
        local newMap = {}
        for _, disp in ipairs(displayList) do
            local r = DisplayToReal[disp]
            local luck = r and RealEggDatabase[r] and RealEggDatabase[r].Luck or 0
            if luck >= 300000000000 then
                newMap[disp] = true
            end
        end
        updateDropdownDisplay(newMap)
        Fluent:Notify({ Title = "Filter Applied", Content = "Targeting 300B+ (Cherub & Solaris)", Duration = 2 })
    end
})

Tabs.Eggs:AddButton({
    Title = "Select 1.5B+ Luck Only",
    Description = "Filter Cherub, Solaris, Blackhole, Galaxy",
    Callback = function()
        local newMap = {}
        for _, disp in ipairs(displayList) do
            local r = DisplayToReal[disp]
            local luck = r and RealEggDatabase[r] and RealEggDatabase[r].Luck or 0
            if luck >= 1500000000 then
                newMap[disp] = true
            end
        end
        updateDropdownDisplay(newMap)
        Fluent:Notify({ Title = "Filter Applied", Content = "Targeting 1.5B+ eggs", Duration = 2 })
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

Tabs.Server:AddParagraph({
    Title = "Automation & Server Hop",
    Content = "Smart Server Hop avoids friends and recent servers completely."
})

local HopToggle = Tabs.Server:AddToggle("AutoHopToggle", {
    Title = "Auto Hop Server (When No Eggs Found)",
    Default = AutoHopEnabled
})

HopToggle:OnChanged(function()
    AutoHopEnabled = Fluent.Options.AutoHopToggle.Value
    saveConfig()
    Fluent:Notify({
        Title = "Server Hop",
        Content = AutoHopEnabled and "Auto Hop Enabled" or "Auto Hop Disabled",
        Duration = 2
    })
end)

local ExecToggle = Tabs.Server:AddToggle("AutoExecToggle", {
    Title = "Auto Execute On Teleport/Hop",
    Default = AutoExecEnabled
})

ExecToggle:OnChanged(function()
    AutoExecEnabled = Fluent.Options.AutoExecToggle.Value
    saveConfig()
end)

Tabs.Server:AddButton({
    Title = "Server Hop Now",
    Description = "Instantly switch to another server without friends",
    Callback = function()
        hopServer()
    end
})

Tabs.Server:AddButton({
    Title = "Rejoin Current Server",
    Callback = function()
        if AutoExecEnabled and queueTeleport then
            pcall(function() queueTeleport(AUTO_EXEC_CODE) end)
        end
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end
})

local EspToggle = Tabs.Visuals:AddToggle("EspToggle", {
    Title = "Live Egg Billboard ESP",
    Default = EspActive
})

EspToggle:OnChanged(function()
    EspActive = Fluent.Options.EspToggle.Value
    if not EspActive then
        for _, bb in pairs(trackedBillboards) do
            if bb then bb:Destroy() end
        end
        trackedBillboards = {}
    end
    saveConfig()
end)

Tabs.Settings:AddParagraph({
    Title = "Performance & Optimization",
    Content = "Limit FPS and disable 3D world rendering to lower CPU/GPU usage while AFK."
})

local FpsSlider = Tabs.Settings:AddSlider("FpsSlider", {
    Title = "Cap FPS",
    Description = "Set target FPS (15-30 recommended for overnight AFK)",
    Default = currentFpsCap,
    Min = 15,
    Max = 240,
    Rounding = 0
})

FpsSlider:OnChanged(function(Value)
    currentFpsCap = Value
    if setfpscap then
        pcall(setfpscap, Value)
    end
    saveConfig()
end)

local Disable3DToggle = Tabs.Settings:AddToggle("Disable3DToggle", {
    Title = "Disable 3D Rendering",
    Description = "Turn off Roblox 3D engine rendering (saves GPU/battery while keeping 2D UI & farming intact)",
    Default = disable3dActive
})

Disable3DToggle:OnChanged(function()
    disable3dActive = Fluent.Options.Disable3DToggle.Value
    setDisable3D(disable3dActive)
    saveConfig()
    Fluent:Notify({
        Title = "Performance",
        Content = disable3dActive and "3D Rendering Disabled (AFK Mode)" or "3D Rendering Enabled",
        Duration = 2
    })
end)

local PurgeToggle = Tabs.Settings:AddToggle("PurgePopupsToggle", {
    Title = "Auto Purge In-Game Popups & Particles",
    Description = "Clean floating numbers and debris to stop game RAM leaks",
    Default = autoPurgePopups
})

PurgeToggle:OnChanged(function()
    autoPurgePopups = Fluent.Options.PurgePopupsToggle.Value
    saveConfig()
end)

Tabs.Settings:AddButton({
    Title = "Activate Ultimate AFK Mode (Lowest RAM)",
    Description = "Disable 3D Rendering + Cap 15 FPS + Purge popups",
    Callback = function()
        disable3dActive = true
        if Fluent.Options.Disable3DToggle then
            Fluent.Options.Disable3DToggle:SetValue(true)
        else
            setDisable3D(true)
        end
        currentFpsCap = 15
        if Fluent.Options.FpsSlider then
            Fluent.Options.FpsSlider:SetValue(15)
        end
        if setfpscap then pcall(setfpscap, 15) end
        autoPurgePopups = true
        if Fluent.Options.PurgePopupsToggle then
            Fluent.Options.PurgePopupsToggle:SetValue(true)
        end
        purgePopupsAndEffects()
        saveConfig()
        Fluent:Notify({ Title = "Ultimate AFK Activated", Content = "Disable 3D | 15 FPS | Pure Performance", Duration = 3 })
    end
})

local targetGuiParent = (gethui and gethui()) or CoreGui:FindFirstChild("RobloxGui") or LocalPlayer:WaitForChild("PlayerGui")

local WidgetGui = Instance.new("ScreenGui")
WidgetGui.Name = "AetherMobileWidget"
WidgetGui.ResetOnSpawn = false
WidgetGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
WidgetGui.DisplayOrder = 1000000
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
    end
end)

WidgetBtn.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = false
    end
end)

WidgetBtn.InputChanged:Connect(function(input)
    if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and isDragging then
        local delta = input.Position - dragStartPos
        WidgetBtn.Position = UDim2.new(
            btnStartPos.X.Scale,
            btnStartPos.X.Offset + delta.X,
            btnStartPos.Y.Scale,
            btnStartPos.Y.Offset + delta.Y
        )
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
    Title = "Ride Ur MoM v2.4",
    Content = "By. Diablo • Ready | ⚡ Pure Disable 3D Rendering!",
    Duration = 3
})
