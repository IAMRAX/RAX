-- RAX Hardened Module (single-file)
-- Paste into a ModuleScript or run via loadstring
local RAX = {}
RAX.__index = RAX

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

-- Helpers
local function new(class, props)
    local obj = Instance.new(class)
    if props then
        for k, v in pairs(props) do
            if k == "Parent" then obj.Parent = v else pcall(function() obj[k] = v end) end
        end
    end
    return obj
end

local function tween(inst, props, t)
    t = t or 0.18
    local info = TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tw = TweenService:Create(inst, info, props)
    tw:Play()
    return tw
end

local function uniqueName()
    return ("RAX_UI_%s_%d"):format(tostring(LocalPlayer.UserId or "anon"), math.floor(tick()*1000))
end

-- Non-destructive overlay scanner (prints potential overlays)
local function scanOverlays()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return {} end
    local overlays = {}
    for _, sg in ipairs(pg:GetChildren()) do
        if sg:IsA("ScreenGui") then
            for _, d in ipairs(sg:GetDescendants()) do
                if (d:IsA("Frame") or d:IsA("ImageLabel")) and d.Visible then
                    local bg = d.BackgroundTransparency or 1
                    if d.Size == UDim2.new(1,0,1,0) and bg < 0.95 then
                        table.insert(overlays, {screenGui = sg.Name, path = d:GetFullName(), bgTrans = bg})
                    end
                end
            end
        end
    end
    if #overlays > 0 then
        warn("RAX overlay scan found potential overlays:")
        for _, o in ipairs(overlays) do
            warn(("  %s  -> %s  (BGTrans=%.2f)"):format(o.screenGui, o.path, o.bgTrans))
        end
    end
    return overlays
end

-- Create ScreenGui (unique, high DisplayOrder)
local function createGui(name)
    local pg = LocalPlayer:WaitForChild("PlayerGui")
    local sg = Instance.new("ScreenGui")
    sg.Name = name
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    -- DisplayOrder is the safest way to render above other ScreenGuis without touching them
    sg.DisplayOrder = 1000
    sg.Parent = pg
    return sg
end

-- Build window (small, centered, high ZIndex)
function RAX.CreateWindow(opts)
    opts = opts or {}
    local self = setmetatable({}, RAX)
    self._name = uniqueName()
    self._gui = createGui(self._name)

    -- root window
    local win = new("Frame", {
        Name = "RAX_Window",
        Parent = self._gui,
        Size = UDim2.new(0, 460, 0, 420),
        Position = UDim2.new(0, 60, 0, 60),
        BackgroundColor3 = Color3.fromRGB(18,18,18),
        BorderSizePixel = 0,
        ZIndex = 9999,
    })
    new("UICorner", {Parent = win, CornerRadius = UDim.new(0,10)})

    -- topbar
    local top = new("Frame", {
        Parent = win,
        Size = UDim2.new(1,0,0,40),
        BackgroundColor3 = Color3.fromRGB(28,28,28),
        ZIndex = 10000,
    })
    new("UICorner", {Parent = top, CornerRadius = UDim.new(0,10)})
    local title = new("TextLabel", {
        Parent = top,
        Size = UDim2.new(1,-20,1,0),
        Position = UDim2.new(0,10,0,0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextColor3 = Color3.fromRGB(235,235,235),
        Text = opts.Title or "RAX Hub",
        ZIndex = 10001,
    })

    -- tabbar
    local tabbar = new("Frame", {
        Parent = win,
        Size = UDim2.new(1,0,0,36),
        Position = UDim2.new(0,0,0,40),
        BackgroundTransparency = 1,
        ZIndex = 10000,
    })
    new("UIListLayout", {Parent = tabbar, FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0,6)})

    -- content
    local content = new("Frame", {
        Parent = win,
        Size = UDim2.new(1,-20,1,-96),
        Position = UDim2.new(0,10,0,88),
        BackgroundTransparency = 1,
        ZIndex = 10000,
    })
    new("UIListLayout", {Parent = content, FillDirection = Enum.FillDirection.Vertical, Padding = UDim.new(0,8)})

    -- drag
    do
        local dragging, dragStart, startPos
        top.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = input.Position
                startPos = win.Position
            end
        end)
        top.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = input.Position - dragStart
                win.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)
    end

    -- keyboard toggle (RightControl)
    do
        local visible = true
        UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.KeyCode == Enum.KeyCode.RightControl then
                visible = not visible
                win.Visible = visible
            end
        end)
    end

    -- public API
    function self:ScanOverlays() return scanOverlays() end

    function self:BringToFront()
        -- increase DisplayOrder if needed
        if self._gui and self._gui:IsA("ScreenGui") then
            self._gui.DisplayOrder = (self._gui.DisplayOrder or 0) + 1000
        end
    end

    function self:Notification(text, duration)
        duration = duration or 2.5
        local notif = new("Frame", {Parent = self._gui, Size = UDim2.new(0,300,0,48), Position = UDim2.new(1,-320,0,40), BackgroundColor3 = Color3.fromRGB(36,36,36), ZIndex = 11000})
        new("UICorner", {Parent = notif, CornerRadius = UDim.new(0,8)})
        new("TextLabel", {Parent = notif, Size = UDim2.new(1,-12,1,0), Position = UDim2.new(0,6,0,0), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = Color3.fromRGB(235,235,235), Text = text or "Notification", ZIndex = 11001})
        tween(notif, {Position = UDim2.new(1,-320,0,40)}, 0.28)
        task.delay(duration, function()
            tween(notif, {Position = UDim2.new(1,20,0,40)}, 0.28)
            task.delay(0.28, function() pcall(function() notif:Destroy() end) end)
        end)
    end

    function self:Destroy()
        pcall(function() if self._gui then self._gui:Destroy() end end)
    end

    -- expose some internals for building UI
    self._win = win
    self._tabbar = tabbar
    self._content = content
    self._title = title

    -- quick visible test: small badge so you know it's loaded
    local badge = new("TextLabel", {Parent = win, Size = UDim2.new(0, 120, 0, 20), Position = UDim2.new(1, -140, 0, 8), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Color3.fromRGB(200,200,200), Text = "RAX loaded", ZIndex = 10002})
    tween(badge, {TextTransparency = 0}, 0.2)

    return self
end

-- Example quick builder helpers (optional)
function RAX.AddSimpleTab(window, title)
    if not window or not window._tabbar or not window._content then return end
    local id = #window._content:GetChildren() + 1
    local btn = new("TextButton", {Parent = window._tabbar, Size = UDim2.new(0,120,1,0), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Color3.fromRGB(180,180,180), Text = title or ("Tab "..id), ZIndex = 10002})
    local page = new("Frame", {Parent = window._content, Size = UDim2.new(1,0,0,0), BackgroundTransparency = 1, Visible = false, AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 10000})
    new("UIListLayout", {Parent = page, FillDirection = Enum.FillDirection.Vertical, Padding = UDim.new(0,8)})
    if btn:IsA("GuiButton") then
        btn.MouseButton1Click:Connect(function()
            for _, c in ipairs(window._content:GetChildren()) do if c:IsA("Frame") then c.Visible = false end end
            page.Visible = true
        end)
    end
    -- auto-select first
    if #window._tabbar:GetChildren() == 1 then btn:MouseButton1Click() end
    return page
end

return RAX
