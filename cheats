-- ============================================================
-- SUSANO SCRIPT V3 - PART 1/2: LOGIN & LOGIC
-- ============================================================

-- ====== CONFIG ======
_G.TeamCheck     = true
_G.ESPEnabled    = true
_G.AimbotEnabled = true
_G.ShowLine      = true
_G.ShowHPBar     = true
_G.FOVRadius     = 120

-- ====== SERVICES ======
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ====== FIREBASE CONFIG & DATA STORAGE ======
local FIREBASE_URL = "https://mod-mytoria-default-rtdb.asia-southeast1.firebasedatabase.app/keys.json"
local keyExpiryDate = "N/A"

-- ====== UI COLOR CONSTANTS ======
local BLUE_ACCENT = Color3.fromRGB(0, 110, 255)
local BG_DARK = Color3.fromRGB(2, 6, 13)
local BG_HEADER = Color3.fromRGB(15, 25, 40)
local TEXT_COLOR = Color3.fromRGB(255, 255, 255)
local COLOR_SUCCESS = Color3.fromRGB(0, 255, 100)
local COLOR_EXPIRED = Color3.fromRGB(255, 165, 0)
local COLOR_ERROR = Color3.fromRGB(255, 50, 50)

-- ====== GUI LOGIN (REVISED) ======
local function createLoginGui()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "LoginGui"
    ScreenGui.Parent = game:GetService("CoreGui")

    local Frame = Instance.new("Frame", ScreenGui)
    Frame.Size = UDim2.new(0, 300, 0, 180)
    Frame.Position = UDim2.new(0.5, -150, 0.5, -90)
    Frame.BackgroundColor3 = BG_DARK
    Frame.BorderSizePixel = 0
    
    local UICorner = Instance.new("UICorner", Frame)
    UICorner.CornerRadius = UDim.new(0, 8)

    local UIGradient = Instance.new("UIGradient", Frame)
    UIGradient.Color = ColorSequence.new(Color3.fromRGB(20, 20, 30), Color3.fromRGB(10, 10, 20))
    UIGradient.Rotation = 90
    
    local Title = Instance.new("TextLabel", Frame)
    Title.Size = UDim2.new(1,0,0,35)
    Title.BackgroundTransparency = 1
    Title.Text = "SUSANO ACCESS"
    Title.TextColor3 = BLUE_ACCENT
    Title.Font = Enum.Font.SourceSansBold
    Title.TextSize = 22
    Title.Position = UDim2.new(0, 0, 0, 10)

    local TextBox = Instance.new("TextBox", Frame)
    TextBox.Size = UDim2.new(1, -40, 0, 35)
    TextBox.Position = UDim2.new(0, 20, 0, 55)
    TextBox.PlaceholderText = "Masukkan KEY..."
    TextBox.Text = ""
    TextBox.ClearTextOnFocus = false
    TextBox.Font = Enum.Font.Code
    TextBox.TextSize = 14
    TextBox.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    TextBox.TextColor3 = TEXT_COLOR
    
    Instance.new("UICorner", TextBox).CornerRadius = UDim.new(0, 5)

    local Submit = Instance.new("TextButton", Frame)
    Submit.Size = UDim2.new(1, -40, 0, 40)
    Submit.Position = UDim2.new(0, 20, 0, 100)
    Submit.Text = "LOGIN"
    Submit.BackgroundColor3 = BLUE_ACCENT
    Submit.TextColor3 = TEXT_COLOR
    Submit.Font = Enum.Font.SourceSansBold
    Submit.TextSize = 18
    
    Instance.new("UICorner", Submit).CornerRadius = UDim.new(0, 5)

    local Status = Instance.new("TextLabel", Frame)
    Status.Size = UDim2.new(1, -40, 0, 20)
    Status.Position = UDim2.new(0, 20, 0, 150)
    Status.BackgroundTransparency = 1
    Status.Text = ""
    Status.TextColor3 = COLOR_ERROR
    Status.Font = Enum.Font.SourceSans
    Status.TextSize = 14

    return ScreenGui, TextBox, Submit, Status
end

-- ====== CEK KEY KE FIREBASE (DENGAN STATUS) ======
local function validateKey(inputKey, statusLabel)
    local succ, res = pcall(function()
        return game:HttpGet(FIREBASE_URL)
    end)
    if not succ then
        statusLabel.Text = "Connection Error"
        statusLabel.TextColor3 = COLOR_ERROR
        return false, "Connection Error"
    end

    local data = HttpService:JSONDecode(res)
    local currentTime = os.time()
    local keyFound = false

    for _, entry in pairs(data) do
        if entry.key == inputKey then
            keyFound = true
            local status = entry.status
            local expiry = entry.expiry or "2099-12-31" 

            local year, month, day = expiry:match("(%d%d%d%d)-(%d%d)-(%d%d)")
            if year and month and day then
                local expiryTime = os.time({year=tonumber(year), month=tonumber(month), day=tonumber(day), hour=23, min=59, sec=59})

                if currentTime > expiryTime then
                    keyExpiryDate = os.date("%d/%m/%Y", expiryTime)
                    statusLabel.Text = "Key Expired"
                    statusLabel.TextColor3 = COLOR_EXPIRED
                    return false, "Key Expired"
                end
            end
            
            if status ~= "active" then
                statusLabel.Text = "Key Invalid/Inactive"
                statusLabel.TextColor3 = COLOR_ERROR
                return false, "Key Invalid/Inactive"
            end

            keyExpiryDate = os.date("%d/%m/%Y", os.time({year=tonumber(year), month=tonumber(month), day=tonumber(day)}))
            statusLabel.Text = "Login Success/Valid"
            statusLabel.TextColor3 = COLOR_SUCCESS
            return true, "Login Success/Valid"
        end
    end
    
    if not keyFound then
        statusLabel.Text = "Key Invalid/Not Found"
        statusLabel.TextColor3 = COLOR_ERROR
        return false, "Key Invalid/Not Found"
    end
    
    return false, "Unknown Error"
end

-- ============================================================
-- =============== SCRIPT ESP/AIM V2 =====================
-- ============================================================

-- ===== DRAWING STORAGE =====
local ESP = {}

-- ===== FOV DRAWING (Harus dibuat sebelum loop) =====
local FOV = Drawing.new("Circle")
FOV.Thickness = 1
FOV.NumSides = 100
FOV.Radius = _G.FOVRadius
FOV.Filled = false
FOV.Color = Color3.fromRGB(255,0,0)
FOV.Visible = true
FOV.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)

-- ===== UTILS =====
local function clamp(v,a,b) return math.max(a, math.min(b, v)) end

local function safeRaycast(origin, dir, blacklist)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = blacklist or {}
    local ok, res = pcall(function() return workspace:Raycast(origin, dir, params) end)
    if not ok then return nil end
    return res
end

local function IsVisible(part)
    if not part or not part.Parent then return false end
    local origin = Camera.CFrame.Position
    local dir = (part.Position - origin)
    if dir.Magnitude <= 0.1 then return true end
    local blacklist = {}
    if LocalPlayer and LocalPlayer.Character then
        table.insert(blacklist, LocalPlayer.Character)
    end
    local res = safeRaycast(origin, dir, blacklist)
    if not res then return true end
    return res.Instance and res.Instance:IsDescendantOf(part.Parent)
end

-- ===== DRAWING CREATE / REMOVE =====
local function CreateESP(plr)
    if ESP[plr] then return end
    ESP[plr] = {
        Box = Drawing.new("Square"),
        Name = Drawing.new("Text"),
        HPBG = Drawing.new("Square"),
        HP = Drawing.new("Square"),
        Line = Drawing.new("Line")
    }
    ESP[plr].Box.Thickness = 1
    ESP[plr].Box.Color = Color3.fromRGB(0,255,0)
    ESP[plr].Box.Filled = false
    ESP[plr].Name.Size = 15
    ESP[plr].Name.Center = true
    ESP[plr].Name.Outline = true
    ESP[plr].Name.Color = ESP[plr].Box.Color
    ESP[plr].HPBG.Filled = true
    ESP[plr].HPBG.Color = Color3.fromRGB(0,0,0)
    ESP[plr].HP.Filled = true
    ESP[plr].HP.Color = Color3.fromRGB(0,255,0)
    ESP[plr].Line.Thickness = 1
    ESP[plr].Line.Color = Color3.fromRGB(255,255,255)
end

local function RemoveESP(plr)
    if not ESP[plr] then return end
    for _, v in pairs(ESP[plr]) do
        pcall(function() if v and v.Remove then v:Remove() end end)
    end
    ESP[plr] = nil
end

Players.PlayerRemoving:Connect(function(plr) RemoveESP(plr) end)

-- ===== BOX / TARGET LOGIC (Dilanjutkan di Part 2) =====
local function GetBox(plr)
    if not plr or not plr.Character then return end
    local char = plr.Character
    local head = char:FindFirstChild("Head")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not (head and hrp and humanoid) then return end
    if humanoid.Health <= 0 then return end

    local screenPos, vis = Camera:WorldToViewportPoint(hrp.Position)
    if not vis then return end

    local distance = (Camera.CFrame.Position - hrp.Position).Magnitude
    local scale = clamp(2000 / math.max(distance, 0.1), 3, 500)

    local height = 6 * scale
    local width = 4 * scale
    local topLeft = Vector2.new(screenPos.X - width/2, screenPos.Y - height/2)
    return topLeft, Vector2.new(width, height), humanoid, head, screenPos
end

local function IsValidTarget(plr)
    if not plr then return false end
    if plr == LocalPlayer then return false end
    if _G.TeamCheck and plr.Team == LocalPlayer.Team then return false end
    if not plr.Character then return false end
    return true
end

local function GetClosestHeadInFOV()
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    local bestHead = nil
    local bestDist = _G.FOVRadius
    for _, plr in ipairs(Players:GetPlayers()) do
        if IsValidTarget(plr) then
            local _, _, humanoid, head = GetBox(plr)
            if head and humanoid and humanoid.Health > 0 then
                local headScr, vis = Camera:WorldToViewportPoint(head.Position)
                if vis then
                    local dist = (Vector2.new(headScr.X, headScr.Y) - center).Magnitude
                    if dist <= _G.FOVRadius and IsVisible(head) then
                        if dist < bestDist then
                            bestDist = dist
                            bestHead = head
                        end
                    end
                end
            end
        end
    end
    return bestHead
end

-- ===== MAIN LOOP (ESP/AIMBOT) =====
RunService.RenderStepped:Connect(function()
    FOV.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    FOV.Radius = _G.FOVRadius

    local anyVisible = false
    for _, plr in ipairs(Players:GetPlayers()) do
        if IsValidTarget(plr) then
            local boxPos, size, humanoid, head, screenPos = GetBox(plr)
            if boxPos and size then
                if not ESP[plr] then CreateESP(plr) end
                local e = ESP[plr]
                
                local isEspVisible = _G.ESPEnabled
                e.Box.Visible = isEspVisible
                e.Name.Visible = isEspVisible

                if isEspVisible then
                    e.Box.Position = boxPos
                    e.Box.Size = size
                    e.Box.Color = Color3.fromRGB(0,255,0)
                    e.Name.Position = Vector2.new(boxPos.X + size.X/2, boxPos.Y - 15)
                    e.Name.Text = plr.Name
                    e.Name.Color = e.Box.Color
                end

                local isHpVisible = _G.ShowHPBar and isEspVisible
                e.HP.Visible = isHpVisible
                e.HPBG.Visible = isHpVisible
                if isHpVisible then
                    local hpPerc = clamp(humanoid.Health / math.max(humanoid.MaxHealth, 1), 0, 1)
                    e.HPBG.Size = Vector2.new(4, size.Y)
                    e.HPBG.Position = Vector2.new(boxPos.X - 6, boxPos.Y)
                    e.HP.Size = Vector2.new(4, size.Y * hpPerc)
                    e.HP.Position = Vector2.new(boxPos.X - 6, boxPos.Y + size.Y * (1 - hpPerc))
                    e.HP.Color = (hpPerc <= 0.3 and Color3.fromRGB(255,0,0)) or (hpPerc <= 0.6 and Color3.fromRGB(255,255,0)) or Color3.fromRGB(0,255,0)
                end

                local isLineVisible = _G.ShowLine and isEspVisible
                e.Line.Visible = isLineVisible
                if isLineVisible then
                    e.Line.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                    e.Line.To = Vector2.new(screenPos.X, screenPos.Y)
                end

                local headScr, headVis = Camera:WorldToViewportPoint(head.Position)
                if headVis and (Vector2.new(headScr.X, headScr.Y) - FOV.Position).Magnitude <= _G.FOVRadius and IsVisible(head) then
                    anyVisible = true
                end
            else
                if ESP[plr] then
                    for _, obj in pairs(ESP[plr]) do
                        if obj and obj.Visible ~= nil then obj.Visible = false end
                    end
                end
            end
        else
            RemoveESP(plr)
        end
    end

    FOV.Color = anyVisible and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,0,0)
    FOV.Visible = _G.AimbotEnabled

    if _G.AimbotEnabled then
        local targetHead = GetClosestHeadInFOV()
        if targetHead and targetHead.Position then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetHead.Position)
        end
    end
end)

-- ===== DEKLARASI FUNGSI UI UTAMA (Akan didefinisikan di Part 2) =====
local createSusanoGui 

-- ============================================================
-- =============== SCRIPT START EXECUTION PART 1 =====================
-- ============================================================

local loginGui, textBox, submitBtn, statusLabel = createLoginGui()

submitBtn.MouseButton1Click:Connect(function()
    local inputKey = textBox.Text
    local ok, msg = validateKey(inputKey, statusLabel)
    
    if ok then
        task.delay(1, function() 
            loginGui:Destroy()
            -- createSusanoGui harus didefinisikan di Part 2 agar ini berhasil.
            if createSusanoGui then
                pcall(createSusanoGui)
            else
                print("[INFO] Loading Part 2...")
            end
            print("[LOGIN SUCCESS] Key expires: "..keyExpiryDate)
        end)
    end
end)
-- ============================================================
-- SUSANO SCRIPT V3 - PART 2/2: UI MENU UTAMA LENGKAP
-- CATATAN: Part 1 harus dimuat terlebih dahulu!
-- ============================================================

-- Gunakan variabel global dari Part 1 (LocalPlayer, TweenService, BLUE_ACCENT, BG_DARK, BG_HEADER, TEXT_COLOR, COLOR_EXPIRED, keyExpiryDate, _G)

-- ===== SUSANO UI (MAIN PANEL) - Definisi Lengkap =====
createSusanoGui = function()
    local parent = game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui")
    if parent:FindFirstChild("SUSANO_Menu") then parent.SUSANO_Menu:Destroy() end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SUSANO_Menu"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = parent

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 180, 0, 0)
    mainFrame.Position = UDim2.new(0.01, 0, 0.1, 0)
    mainFrame.BackgroundColor3 = BG_DARK
    mainFrame.BackgroundTransparency = 0.2
    mainFrame.BorderSizePixel = 1
    mainFrame.BorderColor3 = BLUE_ACCENT
    mainFrame.Parent = screenGui
    mainFrame.ClipsDescendants = true
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 5)

    local mainListLayout = Instance.new("UIListLayout", mainFrame)
    mainListLayout.Padding = UDim.new(0, 0)
    mainListLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local function adjustMainFrameHeight()
        pcall(function()
            mainFrame.Size = UDim2.new(0, 180, 0, mainListLayout.AbsoluteContentSize.Y)
        end)
    end

    -- Title Bar
    local titleBar = Instance.new("Frame", mainFrame)
    titleBar.Size = UDim2.new(1, 0, 0, 25)
    titleBar.BackgroundColor3 = BG_HEADER
    titleBar.LayoutOrder = 1
    titleBar.Active = true
    titleBar.Draggable = true

    local titleLabel = Instance.new("TextLabel", titleBar)
    titleLabel.Size = UDim2.new(1,0,1,0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "SUSANO"
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextSize = 16
    titleLabel.TextColor3 = BLUE_ACCENT
    
    -- Info Container
    local infoContainer = Instance.new("Frame", mainFrame)
    infoContainer.Size = UDim2.new(1, 0, 0, 60)
    infoContainer.BackgroundTransparency = 1
    infoContainer.LayoutOrder = 2
    local infoList = Instance.new("UIListLayout", infoContainer)

    local function createInfoRow(parentFrame, name, value, color)
        local row = Instance.new("TextLabel", parentFrame)
        row.Size = UDim2.new(1, 0, 0, 15); row.BackgroundTransparency = 1; row.Font = Enum.Font.Code
        row.TextSize = 12; row.TextColor3 = color or TEXT_COLOR
        row.TextXAlignment = Enum.TextXAlignment.Left; row.Text = "  "..name..": "..value
        return row
    end
    
    createInfoRow(infoContainer, "Date", os.date("%d/%m/%Y"), BLUE_ACCENT)
    local timeLabel = createInfoRow(infoContainer, "Time", os.date("%H:%M:%S"), BLUE_ACCENT)
    local onlineLabel = createInfoRow(infoContainer, "Online", "00:00:00", BLUE_ACCENT)
    createInfoRow(infoContainer, "Expired", keyExpiryDate, COLOR_EXPIRED)

    local startTime = tick()
    RunService.Heartbeat:Connect(function()
        timeLabel.Text = "  Time: "..os.date("%H:%M:%S")
        onlineLabel.Text = "  Online: "..os.date("!%H:%M:%S", tick() - startTime)
    end)
    
    -- Feature Row Function
    local function createFeatureRow(parentFrame, name, configKey, valueType)
        if not configKey then return end
        
        local rowFrame = Instance.new("Frame", parentFrame)
        rowFrame.Size = UDim2.new(1, 0, 0, 20)
        rowFrame.BackgroundColor3 = Color3.fromRGB(15, 25, 40)
        rowFrame.BackgroundTransparency = 0.5

        local lineDecorator = Instance.new("Frame", rowFrame)
        lineDecorator.Size = UDim2.new(0, 2, 0.8, 0); lineDecorator.Position = UDim2.new(0, 5, 0.1, 0)
        lineDecorator.BackgroundColor3 = BLUE_ACCENT; lineDecorator.BorderSizePixel = 0

        local nameLabel = Instance.new("TextLabel", rowFrame)
        nameLabel.Size = UDim2.new(0.7, -10, 1, 0); nameLabel.Position = UDim2.new(0, 10, 0, 0)
        nameLabel.BackgroundTransparency = 1; nameLabel.Text = name; nameLabel.Font = Enum.Font.Code
        nameLabel.TextSize = 12; nameLabel.TextColor3 = TEXT_COLOR
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left

        local statusButton = Instance.new("TextButton", rowFrame)
        statusButton.Size = UDim2.new(0, 40, 0, 16); statusButton.Position = UDim2.new(1, -45, 0, 2)
        statusButton.Font = Enum.Font.Code; statusButton.TextSize = 12
        statusButton.TextColor3 = TEXT_COLOR
        statusButton.AutoButtonColor = false; statusButton.BorderSizePixel = 0
        
        local function updateStatus()
            if valueType == "boolean" then
                local isEnabled = _G[configKey]
                statusButton.Text = isEnabled and "ON" or "OFF"
                statusButton.BackgroundColor3 = isEnabled and BLUE_ACCENT or Color3.fromRGB(40, 40, 40)
            end
        end
        updateStatus()
        
        local clickableArea = Instance.new("TextButton", rowFrame)
        clickableArea.Size = UDim2.new(1,0,1,0); clickableArea.BackgroundTransparency = 1
        clickableArea.Text = ""; clickableArea.AutoButtonColor = false
        clickableArea.MouseButton1Click:Connect(function()
            if valueType == "boolean" then
                _G[configKey] = not _G[configKey]
                updateStatus()
            end
        end)
        
        return rowFrame
    end

    -- Category Collapsible Function (Show/Hide logic)
    local function createCollapsibleCategory(name, layoutOrder, features, startOpened)
        
        local activeFeatures = {}
        for _, feature in ipairs(features) do
            if feature[2] ~= nil then
                table.insert(activeFeatures, feature)
            end
        end

        if #activeFeatures == 0 then return end
        
        local categoryFrame = Instance.new("Frame", mainFrame)
        categoryFrame.BackgroundTransparency = 1
        categoryFrame.Size = UDim2.new(1,0,0,20)
        categoryFrame.LayoutOrder = layoutOrder
        local listLayout = Instance.new("UIListLayout", categoryFrame)
        listLayout.SortOrder = Enum.SortOrder.LayoutOrder

        -- 1. HEADER (LayoutOrder 1)
        local header = Instance.new("TextButton", categoryFrame)
        header.Name = "Header"; header.Size = UDim2.new(1,0,0,20); header.LayoutOrder = 1
        header.BackgroundColor3 = BLUE_ACCENT; header.Text = name
        header.Font = Enum.Font.SourceSansSemibold; header.TextSize = 14
        header.TextColor3 = TEXT_COLOR; header.AutoButtonColor = false

        -- 2. CONTENT CONTAINER (LayoutOrder 2)
        local content = Instance.new("Frame", categoryFrame)
        content.Name = "Content"; content.Size = UDim2.new(1,0,0,0); content.LayoutOrder = 2
        content.BackgroundTransparency = 1; content.ClipsDescendants = true
        content.Visible = startOpened or false
        local contentList = Instance.new("UIListLayout", content)
        
        for _, feature in ipairs(activeFeatures) do
            createFeatureRow(content, feature[1], feature[2], feature[3])
        end
        
        local totalContentHeight = #activeFeatures * 20
        local targetSize = UDim2.new(1,0,0, 20 + totalContentHeight)
        
        if content.Visible then
            categoryFrame.Size = targetSize
            content.Size = UDim2.new(1,0,0, totalContentHeight)
        end

        header.MouseButton1Click:Connect(function()
            content.Visible = not content.Visible
            local targetCategorySize = content.Visible and targetSize or UDim2.new(1,0,0,20)
            local targetContentHeight = content.Visible and UDim2.new(1,0,0, totalContentHeight) or UDim2.new(1,0,0,0)
            
            local tweenCategory = TweenService:Create(categoryFrame, TweenInfo.new(0.2), {Size = targetCategorySize})
            local tweenContent = TweenService:Create(content, TweenInfo.new(0.2), {Size = targetContentHeight})
            
            tweenContent:Play()
            tweenCategory:Play()
            tweenCategory.Completed:Connect(adjustMainFrameHeight)
        end)
        
        return categoryFrame
    end
    
    -- ===== DAFTAR FITUR YANG BERFUNGSI =====
    
    local espFeatures = {
        {"Enable ESP", "ESPEnabled", "boolean"},
        {"Team Check", "TeamCheck", "boolean"},
        {"Show Line", "ShowLine", "boolean"},
        {"Show HP", "ShowHPBar", "boolean"}
    }
    
    local aimFeatures = {
        {"Aim Bot", "AimbotEnabled", "boolean"},
    }
    
    local weaponFeatures = {}
    
    local playerFeatures = {}

    -- Membuat Kategori di UI
    createCollapsibleCategory("ESP", 3, espFeatures, true)
    createCollapsibleCategory("AIM", 4, aimFeatures)
    createCollapsibleCategory("WEAPON", 5, weaponFeatures)
    createCollapsibleCategory("PLAYER", 6, playerFeatures)

    task.wait(0.2)
    adjustMainFrameHeight()
end

-- Panggil fungsi yang dideklarasikan di Part 1 untuk memastikan ia tahu di mana menemukan createSusanoGui
if submitBtn and submitBtn.MouseButton1Click then
    -- Ini adalah hack untuk memastikan fungsi update di Part 1 dapat dipanggil.
    -- Di lingkungan Roblox, jika Part 1 di-loadstring, variabel lokalnya akan hilang.
    -- Jika Anda menggunakan Part 1 dan Part 2 secara berurutan dalam satu eksekusi,
    -- variabel 'createSusanoGui' yang dideklarasikan di Part 1 akan terdefinisi di sini.
    -- Di lingkungan executor modern, ini biasanya akan berfungsi.
    print("[INFO] UI Function (createSusanoGui) is now defined.")
end
