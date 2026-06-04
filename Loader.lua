--[[ ZeroX Loader — แจกให้ลูกค้า ]]

local API_URL     = "https://zerox-api-production.up.railway.app"
local KEY_FILE    = "ZeroX_key.txt"
local GAME_ID     = "SurviveZombieArena"  -- เปลี่ยนตามแต่ละเกม
local Players     = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local plr         = Players.LocalPlayer

local function getHWID()
    local id
    -- 1) Standard executor function
    pcall(function() if gethwid then id = gethwid() end end)
    -- 2) Synapse-style
    if not id then pcall(function() if syn and syn.get_hwid then id = syn.get_hwid() end end) end
    -- 3) Identifier as fallback
    if not id then pcall(function() if identifyexecutor then id = (identifyexecutor()) .. "-" end end) end
    -- 4) RbxAnalytics ClientId (changes per install but stable per machine usually)
    if not id then
        pcall(function() id = (id or "") .. game:GetService("RbxAnalyticsService"):GetClientId() end)
    end
    return id or "UNKNOWN-HWID"
end

local function loadSavedKey()
    if isfile and isfile(KEY_FILE) then
        local ok, k = pcall(readfile, KEY_FILE)
        if ok and k and k ~= "" then return k end
    end
    return nil
end

local function saveKey(k, expiresAt)
    pcall(function() if writefile then writefile(KEY_FILE, k) end end)
    if expiresAt then
        pcall(function() if writefile then writefile("ZeroX_expiry.txt", tostring(expiresAt)) end end)
    end
end

local function clearKey()
    pcall(function() if delfile then delfile(KEY_FILE) end end)
end

local function httpRequest(opts)
    local fn = request                                  -- Potassium, Delta, Solara, Wave, Xeno
              or (http and http.request)                -- generic http
              or http_request                           -- old executors
              or (syn and syn.request)                  -- Synapse X
              or (fluxus and fluxus.request)            -- Fluxus
              or (krnl_request)                         -- Krnl
    if fn then return fn(opts) end
    -- Fallback: HttpService (Studio only, jam'd in live games)
    local res = HttpService:PostAsync(opts.Url, opts.Body, Enum.HttpContentType.ApplicationJson)
    return { Body = res, StatusCode = 200 }
end

local function activate(key)
    local ok, res = pcall(function()
        local r = httpRequest({
            Url     = API_URL .. "/activate",
            Method  = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body    = HttpService:JSONEncode({ key = key, hwid = getHWID(), game_id = GAME_ID }),
        })
        return HttpService:JSONDecode(r.Body)
    end)
    if not ok then return { ok = false, error = "Connection failed" } end
    return res
end

local function runScript(script, sessionToken)
    _G.ZeroX_Session = sessionToken  -- ส่ง session token ให้ main.lua
    _G.ZeroX_HWID    = getHWID()
    local fn, err = loadstring(script)
    if fn then fn() else warn("ZeroX load error:", err) end
end

-- ===== Auto-login: ถ้ามี key เก่าเก็บไว้ ลอง activate เลย =====
local savedKey = loadSavedKey()
if savedKey then
    local res = activate(savedKey)
    if res.ok and res.script then
        runScript(res.script, res.session_token)
        return -- ไม่ต้องแสดง GUI
    end
    -- key ไม่ผ่าน → ลบทิ้งแล้วแสดง GUI ให้ใส่ใหม่
    clearKey()
end

local sg = Instance.new("ScreenGui")
sg.Name = "ZeroXLoader"
sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() sg.Parent = game:GetService("CoreGui") end)
if not sg.Parent then sg.Parent = plr:WaitForChild("PlayerGui") end

local frame = Instance.new("Frame", sg)
frame.Size = UDim2.new(0, 380, 0, 240)
frame.Position = UDim2.new(0.5, -190, 0.5, -120)
frame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
frame.BorderSizePixel = 0
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 14)

local bar = Instance.new("Frame", frame)
bar.Size = UDim2.new(1, 0, 0, 5)
bar.BorderSizePixel = 0
bar.BackgroundColor3 = Color3.fromRGB(99, 102, 241)
Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 14)
local g = Instance.new("UIGradient", bar)
g.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(99,102,241)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(168,85,247)),
})

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 45)
title.Position = UDim2.new(0, 0, 0, 18)
title.BackgroundTransparency = 1
title.Text = "ZeroX"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 30

local sub = Instance.new("TextLabel", frame)
sub.Size = UDim2.new(1, 0, 0, 20)
sub.Position = UDim2.new(0, 0, 0, 60)
sub.BackgroundTransparency = 1
sub.Text = "Enter your key to continue"
sub.TextColor3 = Color3.fromRGB(150, 150, 150)
sub.Font = Enum.Font.Gotham
sub.TextSize = 14

local box = Instance.new("TextBox", frame)
box.Size = UDim2.new(0.85, 0, 0, 42)
box.Position = UDim2.new(0.075, 0, 0, 95)
box.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
box.PlaceholderText = "ZEROX-XXXX-XXXX"
box.Text = ""
box.TextColor3 = Color3.fromRGB(255, 255, 255)
box.PlaceholderColor3 = Color3.fromRGB(90, 90, 90)
box.Font = Enum.Font.Code
box.TextSize = 16
box.ClearTextOnFocus = false
box.BorderSizePixel = 0
Instance.new("UICorner", box).CornerRadius = UDim.new(0, 8)

local btn = Instance.new("TextButton", frame)
btn.Size = UDim2.new(0.85, 0, 0, 42)
btn.Position = UDim2.new(0.075, 0, 0, 148)
btn.BackgroundColor3 = Color3.fromRGB(99, 102, 241)
btn.Text = "Activate"
btn.TextColor3 = Color3.fromRGB(255, 255, 255)
btn.Font = Enum.Font.GothamBold
btn.TextSize = 18
btn.BorderSizePixel = 0
Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
local bg = Instance.new("UIGradient", btn)
bg.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(99,102,241)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(168,85,247)),
})

local status = Instance.new("TextLabel", frame)
status.Size = UDim2.new(1, 0, 0, 24)
status.Position = UDim2.new(0, 0, 0, 200)
status.BackgroundTransparency = 1
status.Text = "discord.gg/AMPb9S7MdM"
status.TextColor3 = Color3.fromRGB(100, 100, 100)
status.Font = Enum.Font.Gotham
status.TextSize = 13

local busy = false
btn.MouseButton1Click:Connect(function()
    if busy then return end
    local key = box.Text:upper():gsub("%s", "")
    if key == "" then
        status.Text = "⚠️ Please enter a key"
        status.TextColor3 = Color3.fromRGB(255, 200, 50)
        return
    end

    busy = true
    btn.Text = "Checking..."
    status.Text = "Verifying key..."
    status.TextColor3 = Color3.fromRGB(150, 150, 150)

    local res = activate(key)

    if res.ok and res.script then
        saveKey(key, res.expires_at) -- จำ key + expiry ไว้
        status.Text = "✅ Success! Loading..."
        status.TextColor3 = Color3.fromRGB(87, 242, 135)
        task.wait(0.5)
        sg:Destroy()
        runScript(res.script, res.session_token)
    else
        busy = false
        btn.Text = "Activate"
        status.Text = "❌ " .. (res.error or "Invalid key")
        status.TextColor3 = Color3.fromRGB(255, 100, 100)
    end
end)
