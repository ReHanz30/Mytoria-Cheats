-- ============================================================
-- MYTORIA SCRIPT V4 - UI & LOGIC
-- ============================================================

-- ====== GLOBAL CONFIGURATION ======
_G.ESPEnabled = true
_G.AimbotEnabled = true
_G.TeamCheck = true
_G.ShowLine = true
_G.ShowHPBar = true
_G.FOVRadius = 120

-- ====== SERVICES ======
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ====== FIREBASE & DATA STORAGE ======
local FIREBASE_URL = "https://mod-mytoria-default-rtdb.asia-southeast1.firebasedatabase.app/keys.json"
local keyExpirySeconds = 0

-- ====== UI CONSTANTS ======
local ACCENT_COLOR = Color3.fromRGB(0, 150, 255)
local BG_DARK = Color3.fromRGB(18, 18, 22)
local BG_HEADER = Color3.fromRGB(25, 25, 30)
local TEXT_COLOR = Color3.fromRGB(255, 255, 255)
local COLOR_SUCCESS = Color3.fromRGB(0, 255, 127)
local COLOR_EXPIRED = Color3.fromRGB(255, 180, 0)
local COLOR_ERROR = Color3.fromRGB(255, 70, 70)

-- ====== UTILITY FUNCTIONS ======
local function secondsToDHMS(s)
    if s <= 0 then return "00D:00H:00M:00S" end
    local days = math.floor(s / 86400)
    s = s % 86400
    local hours = math.floor(s / 3600)
    s = s % 3600
    local minutes = math.floor(s / 60)
    s = s % 60
    return string.format("%02iD:%02iH:%02iM:%02iS", days, hours, minutes, s)
end

local function clamp(v, a, b) return math.max(a, math.min(b, v)) end

-- ============================================================
-- LOGIN UI & LOGIC
-- ============================================================

local function createLoginGui()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "LoginGui"
    ScreenGui.Parent = game:GetService("CoreGui")
    ScreenGui.ResetOnSpawn = false

    local Overlay = Instance.new("Frame", ScreenGui)
    Overlay.Size = UDim2.new(1, 0, 1, 0)
    Overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    Overlay.BackgroundTransparency = 0.5

    local Frame = Instance.new("Frame", Overlay)
    Frame.Size = UDim2.new(0, 320, 0, 200)
    Frame.AnchorPoint = Vector2.new(0.5, 0.5)
    Frame.Position = UDim2.new(0.5, 0, 0.5, 0)
    Frame.BackgroundColor3 = BG_DARK
    Frame.BorderSizePixel = 0
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 8)

    local Title = Instance.new("TextLabel", Frame)
    Title.Size = UDim2.new(1, 0, 0, 40)
    Title.BackgroundTransparency = 1
    Title.Text = "MYTORIA"
    Title.TextColor3 = ACCENT_COLOR
    Title.Font = Enum.Font.SourceSansBold
    Title.TextSize = 26
    Title.Position = UDim2.new(0, 0, 0, 15)

    local TextBox = Instance.new("TextBox", Frame)
    TextBox.Size = UDim2.new(1, -50, 0, 40)
    TextBox.Position = UDim2.new(0.5, -((320 - 50) / 2), 0, 65)
    TextBox.PlaceholderText = "Enter Your Key"
    TextBox.ClearTextOnFocus = false
    TextBox.Font = Enum.Font.Code
    TextBox.TextSize = 16
    TextBox.BackgroundColor3 = BG_HEADER
    TextBox.TextColor3 = TEXT_COLOR
    TextBox.BorderSizePixel = 0
    Instance.new("UICorner", TextBox).CornerRadius = UDim.new(0, 5)

    local Submit = Instance.new("TextButton", Frame)
    Submit.Size = UDim2.new(1, -50, 0, 45)
    Submit.Position = UDim2.new(0.5, -((320 - 50) / 2), 0, 115)
    Submit.Text = "LOGIN"
    Submit.BackgroundColor3 = ACCENT_COLOR
    Submit.TextColor3 = Color3.new(1, 1, 1)
    Submit.Font = Enum.Font.SourceSansBold
    Submit.TextSize = 18
    Submit.BorderSizePixel = 0
    Instance.new("UICorner", Submit).CornerRadius = UDim.new(0, 5)

    local Status = Instance.new("TextLabel", Frame)
    Status.Size = UDim2.new(1, -40, 0, 20)
    Status.Position = UDim2.new(0.5, -((320 - 40) / 2), 0, 170)
    Status.BackgroundTransparency = 1
    Status.Text = ""
    Status.TextColor3 = COLOR_ERROR
    Status.Font = Enum.Font.SourceSans
    Status.TextSize = 14

    return ScreenGui, TextBox, Submit, Status
end

local function validateKey(inputKey, statusLabel)
    local succ, res = pcall(function() return game:HttpGet(FIREBASE_URL) end)
    if not succ then
        statusLabel.Text = "Connection Error"
        statusLabel.TextColor3 = COLOR_ERROR
        return false
    end

    local data = HttpService:JSONDecode(res)
    local currentTime = os.time()
    
    for _, entry in pairs(data) do
        if entry.key == inputKey then
            local expiryTime = os.time({year=2099, month=12, day=31, hour=23, min=59, sec=59})
            if entry.expiry and entry.expiry:match("(%d%d%d%d)-(%d%d)-(%d%d)") then
                local y, m, d = entry.expiry:match("(%d%d%d%d)-(%d%d)-(%d%d)")
                expiryTime = os.time({year=tonumber(y), month=tonumber(m), day=tonumber(d), hour=23, min=59, sec=59})
            end

            keyExpirySeconds = expiryTime - currentTime
            if keyExpirySeconds <= 0 then
                statusLabel.Text = "Key Expired"
                statusLabel.TextColor3 = COLOR_EXPIRED
                return false
            end
            
            if entry.status ~= "active" then
                statusLabel.Text = "Key Invalid or Inactive"
                statusLabel.TextColor3 = COLOR_ERROR
                return false
            end

            statusLabel.Text = "Login Success"
            statusLabel.TextColor3 = COLOR_SUCCESS
            return true
        end
    end
    
    statusLabel.Text = "Key Not Found"
    statusLabel.TextColor3 = COLOR_ERROR
    return false
end

-- ============================================================
-- CORE AIMBOT & ESP LOGIC
-- ============================================================

local ESP = {}
local FOV = Drawing.new("Circle")
FOV.Thickness = 1
FOV.NumSides = 100
FOV.Radius = _G.FOVRadius
FOV.Filled = false
FOV.Color = Color3.fromRGB(255, 0, 0)
FOV.Visible = true
FOV.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

local function IsVisible(part)
    if not part or not part.Parent then return false end
    local origin = Camera.CFrame.Position
    local dir = (part.Position - origin)
    local blacklist = {LocalPlayer.Character}
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = blacklist
    local res = workspace:Raycast(origin, dir.Unit * 1000, params)
    if not res then return true end
    return res.Instance and res.Instance:IsDescendantOf(part.Parent)
end

local function CreateESP(plr)
    if ESP[plr] then return end
    ESP[plr] = {
        Box = Drawing.new("Square"),
        Name = Drawing.new("Text"),
        HPBG = Drawing.new("Square"),
        HP = Drawing.new("Square"),
        Line = Drawing.new("Line")
    }
    local e = ESP[plr]
    e.Box.Thickness = 1; e.Box.Color = Color3.fromRGB(0,255,0); e.Box.Filled = false
    e.Name.Size = 14; e.Name.Center = true; e.Name.Outline = true; e.Name.Color = e.Box.Color
    e.HPBG.Filled = true; e.HPBG.Color = Color3.fromRGB(0,0,0)
    e.HP.Filled = true; e.HP.Color = Color3.fromRGB(0,255,0)
    e.Line.Thickness = 1; e.Line.Color = Color3.fromRGB(255,255,255)
end

local function RemoveESP(plr)
    if not ESP[plr] then return end
    for _, v in pairs(ESP[plr]) do v:Remove() end
    ESP[plr] = nil
end

Players.PlayerRemoving:Connect(RemoveESP)

local function GetBox(plr)
    if not (plr and plr.Character) then return end
    local char = plr.Character
    local head = char:FindFirstChild("Head")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not (head and hrp and humanoid and humanoid.Health > 0) then return end
    local screenPos, vis = Camera:WorldToViewportPoint(hrp.Position)
    if not vis then return end
    local distance = (Camera.CFrame.Position - hrp.Position).Magnitude
    local scale = clamp(2000 / math.max(distance, 0.1), 3, 500)
    local height = 6 * scale
    local width = 4 * scale
    local topLeft = Vector2.new(screenPos.X - width / 2, screenPos.Y - height / 2)
    return topLeft, Vector2.new(width, height), humanoid, head, screenPos
end

local function IsValidTarget(plr)
    if not plr or plr == LocalPlayer or not plr.Character then return false end
    if _G.TeamCheck and plr.Team == LocalPlayer.Team then return false end
    return true
end

local function GetClosestHeadInFOV()
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local bestHead, bestDist = nil, _G.FOVRadius
    for _, plr in ipairs(Players:GetPlayers()) do
        if IsValidTarget(plr) then
            local _, _, humanoid, head = GetBox(plr)
            if head and humanoid and humanoid.Health > 0 then
                local headScr, vis = Camera:WorldToViewportPoint(head.Position)
                if vis then
                    local dist = (Vector2.new(headScr.X, headScr.Y) - center).Magnitude
                    if dist <= _G.FOVRadius and IsVisible(head) and dist < bestDist then
                        bestDist = dist
                        bestHead = head
                    end
                end
            end
        end
    end
    return bestHead
end

RunService.RenderStepped:Connect(function()
    FOV.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    FOV.Radius = _G.FOVRadius
    local anyVisible = false
    for _, plr in ipairs(Players:GetPlayers()) do
        if IsValidTarget(plr) then
            local boxPos, size, humanoid, head, screenPos = GetBox(plr)
            if boxPos and size then
                if not ESP[plr] then CreateESP(plr) end
                local e = ESP[plr]
                local isEspVisible = _G.ESPEnabled
                for _, obj in pairs(e) do obj.Visible = isEspVisible end
                if isEspVisible then
                    e.Box.Position = boxPos
                    e.Box.Size = size
                    e.Name.Position = Vector2.new(boxPos.X + size.X / 2, boxPos.Y - 15)
                    e.Name.Text = plr.Name
                    
                    local hpPerc = clamp(humanoid.Health / math.max(humanoid.MaxHealth, 1), 0, 1)
                    e.HPBG.Visible = _G.ShowHPBar
                    e.HPBG.Size = Vector2.new(4, size.Y)
                    e.HPBG.Position = Vector2.new(boxPos.X - 6, boxPos.Y)
                    e.HP.Visible = _G.ShowHPBar
                    e.HP.Size = Vector2.new(4, size.Y * hpPerc)
                    e.HP.Position = Vector2.new(boxPos.X - 6, boxPos.Y + size.Y * (1 - hpPerc))
                    e.HP.Color = (hpPerc <= 0.3 and Color3.fromRGB(255,0,0)) or (hpPerc <= 0.6 and Color3.fromRGB(255,255,0)) or Color3.fromRGB(0,255,0)

                    e.Line.Visible = _G.ShowLine
                    e.Line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    e.Line.To = Vector2.new(screenPos.X, screenPos.Y)

                    local headScr, headVis = Camera:WorldToViewportPoint(head.Position)
                    if headVis and (Vector2.new(headScr.X, headScr.Y) - FOV.Position).Magnitude <= _G.FOVRadius and IsVisible(head) then
                        anyVisible = true
                    end
                end
            else
                if ESP[plr] then for _, obj in pairs(ESP[plr]) do obj.Visible = false end end
            end
        else
            RemoveESP(plr)
        end
    end
    FOV.Color = anyVisible and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
    FOV.Visible = _G.AimbotEnabled
    if _G.AimbotEnabled then
        local targetHead = GetClosestHeadInFOV()
        if targetHead and targetHead.Position then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetHead.Position)
        end
    end
end)

-- ============================================================
-- MAIN UI (MYTORIA MENU)
-- ============================================================
local createMytoriaGui

createMytoriaGui = function()
    local parent = game:GetService("CoreGui")
    if parent:FindFirstChild("MYTORIA_Menu") then parent.MYTORIA_Menu:Destroy() end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MYTORIA_Menu"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = parent

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 200, 0, 30) 
    mainFrame.Position = UDim2.new(0.01, 0, 0.1, 0)
    mainFrame.BackgroundColor3 = BG_DARK
    mainFrame.BackgroundTransparency = 0.2
    mainFrame.BorderSizePixel = 1
    mainFrame.BorderColor3 = ACCENT_COLOR
    mainFrame.Parent = screenGui
    mainFrame.ClipsDescendants = true
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 5)

    local mainListLayout = Instance.new("UIListLayout", mainFrame)
    mainListLayout.Padding = UDim.new(0, 5)
    mainListLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local header = Instance.new("TextButton")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 30)
    header.BackgroundColor3 = BG_HEADER
    header.Text = "MYTORIA"
    header.Font = Enum.Font.SourceSansBold
    header.TextSize = 18
    header.TextColor3 = ACCENT_COLOR
    header.LayoutOrder = 1
    header.Parent = mainFrame
    header.AutoButtonColor = false
    header.Active = true
    header.Draggable = true -- Allows dragging the entire frame

    local contentFrame = Instance.new("Frame", mainFrame)
    contentFrame.Size = UDim2.new(1, 0, 0, 150)
    contentFrame.BackgroundTransparency = 1
    contentFrame.LayoutOrder = 2
    contentFrame.ClipsDescendants = true
    contentFrame.Visible = true

    local contentList = Instance.new("UIListLayout", contentFrame)
    contentList.Padding = UDim.new(0, 2)
    
    local isContentVisible = true
    local contentHeight = 0

    local function createInfoRow(name, value, color)
        local row = Instance.new("TextLabel", contentFrame)
        row.Size = UDim2.new(1, 0, 0, 15)
        row.BackgroundTransparency = 1
        row.Font = Enum.Font.Code
        row.TextSize = 12
        row.TextColor3 = color or TEXT_COLOR
        row.TextXAlignment = Enum.TextXAlignment.Left
        local formattedName = string.format("%-8s:", name)
        row.Text = "  " .. formattedName .. " " .. value
        return row
    end

    local dateLabel = createInfoRow("Date", os.date("%d/%m/%Y"), TEXT_COLOR)
    local timeLabel = createInfoRow("Time", os.date("%H:%M:%S"), TEXT_COLOR)
    local onlineLabel = createInfoRow("Online", "00:00:00", TEXT_COLOR)
    local expiredLabel = createInfoRow("Expired", secondsToDHMS(keyExpirySeconds), COLOR_EXPIRED)
    
    local startTime = tick()
    local currentExpiry = keyExpirySeconds
    RunService.Heartbeat:Connect(function()
        dateLabel.Text = "  " .. string.format("%-8s:", "Date") .. " " .. os.date("%d/%m/%Y")
        timeLabel.Text = "  " .. string.format("%-8s:", "Time") .. " " .. os.date("%H:%M:%S")
        onlineLabel.Text = "  " .. string.format("%-8s:", "Online") .. " " .. os.date("!%H:%M:%S", tick() - startTime)
        currentExpiry = math.max(0, keyExpirySeconds - (tick() - startTime))
        expiredLabel.Text = "  " .. string.format("%-8s:", "Expired") .. " " .. secondsToDHMS(currentExpiry)
        if currentExpiry <= 0 then expiredLabel.TextColor3 = COLOR_ERROR end
    end)
    
    Instance.new("Frame", contentFrame).Size = UDim2.new(1, -10, 0, 1)
        .BackgroundColor3 = BG_HEADER
        .Position = UDim2.new(0.5, -((200-10)/2), 0, 0)
    
    local function createFeatureRow(name, configKey)
        local rowFrame = Instance.new("Frame", contentFrame)
        rowFrame.Size = UDim2.new(1, 0, 0, 22)
        rowFrame.BackgroundTransparency = 1

        local nameLabel = Instance.new("TextLabel", rowFrame)
        nameLabel.Size = UDim2.new(0.7, 0, 1, 0)
        nameLabel.Position = UDim2.new(0, 8, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = name
        nameLabel.Font = Enum.Font.Code
        nameLabel.TextSize = 13
        nameLabel.TextColor3 = TEXT_COLOR
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left

        local statusButton = Instance.new("TextButton", rowFrame)
        statusButton.Size = UDim2.new(0.3, -13, 1, -6)
        statusButton.Position = UDim2.new(1, -50, 0.5, -((22-6)/2))
        statusButton.Font = Enum.Font.Code
        statusButton.TextSize = 12
        statusButton.TextColor3 = TEXT_COLOR
        statusButton.BorderSizePixel = 0
        Instance.new("UICorner", statusButton).CornerRadius = UDim.new(0, 3)
        
        local function updateStatus()
            local isEnabled = _G[configKey]
            statusButton.Text = isEnabled and "ON" or "OFF"
            statusButton.BackgroundColor3 = isEnabled and ACCENT_COLOR or BG_HEADER
        end
        updateStatus()
        
        statusButton.MouseButton1Click:Connect(function()
            _G[configKey] = not _G[configKey]
            updateStatus()
        end)
    end
    
    createFeatureRow("ESP", "ESPEnabled")
    createFeatureRow("Aimbot", "AimbotEnabled")
    createFeatureRow("Team Check", "TeamCheck")
    createFeatureRow("Show Line", "ShowLine")
    createFeatureRow("Show HP Bar", "ShowHPBar")

    contentHeight = contentList.AbsoluteContentSize.Y
    contentFrame.Size = UDim2.new(1, 0, 0, contentHeight)
    mainFrame.Size = UDim2.new(0, 200, 0, header.AbsoluteSize.Y + contentHeight + mainListLayout.Padding.Offset)

    header.MouseButton1Click:Connect(function()
        isContentVisible = not isContentVisible
        local goalFrameSize = isContentVisible and UDim2.new(0, 200, 0, header.AbsoluteSize.Y + contentHeight + mainListLayout.Padding.Offset) or UDim2.new(0, 200, 0, 30)
        local goalContentSize = isContentVisible and UDim2.new(1, 0, 0, contentHeight) or UDim2.new(1, 0, 0, 0)
        
        TweenService:Create(mainFrame, TweenInfo.new(0.2), {Size = goalFrameSize}):Play()
        contentFrame.Visible = true
        TweenService:Create(contentFrame, TweenInfo.new(0.2), {Size = goalContentSize}):Play()
    end)
end

-- ============================================================
-- SCRIPT EXECUTION START
-- ============================================================

local loginGui, textBox, submitBtn, statusLabel = createLoginGui()

submitBtn.MouseButton1Click:Connect(function()
    if validateKey(textBox.Text, statusLabel) then
        task.delay(1, function() 
            loginGui:Destroy()
            createMytoriaGui()
        end)
    end
end)
