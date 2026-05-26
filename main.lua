-- RAX v2 — Polished UI Module
-- Place this in a ModuleScript or loadstring it directly.
local RAX = {}
RAX.__index = RAX

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- Default theme
local DefaultTheme = {
    Background = Color3.fromRGB(18, 18, 18),
    Topbar = Color3.fromRGB(28, 28, 28),
    Accent = Color3.fromRGB(0, 170, 85),
    Text = Color3.fromRGB(235, 235, 235),
    SubText = Color3.fromRGB(180, 180, 180),
    Element = Color3.fromRGB(36, 36, 36),
    ElementHover = Color3.fromRGB(46, 46, 46),
}

-- Utility helpers
local function new(class, props)
    local obj = Instance.new(class)
    if props then
        for k, v in pairs(props) do
            if k == "Parent" then
                obj.Parent = v
            else
                pcall(function() obj[k] = v end)
            end
        end
    end
    return obj
end

local function tween(instance, props, time, style, dir)
    style = style or Enum.EasingStyle.Quad
    dir = dir or Enum.EasingDirection.Out
    local info = TweenInfo.new(time or 0.25, style, dir)
    local t = TweenService:Create(instance, info, props)
    t:Play()
    return t
end

local function clamp(v, a, b) return math.max(a, math.min(b, v)) end

-- Save / load simple settings on PlayerGui as attributes
local function saveSetting(key, value)
    local gui = LocalPlayer:FindFirstChild("PlayerGui")
    if not gui then return end
    local store = gui:FindFirstChild("RAX_Settings")
    if not store then
        store = Instance.new("Folder")
        store.Name = "RAX_Settings"
        store.Parent = gui
    end
    local attr = store:FindFirstChild(key)
    if not attr then
        attr = Instance.new("StringValue")
        attr.Name = key
        attr.Parent = store
    end
    attr.Value = tostring(value)
end

local function loadSetting(key, default)
    local gui = LocalPlayer:FindFirstChild("PlayerGui")
    if not gui then return default end
    local store = gui:FindFirstChild("RAX_Settings")
    if not store then return default end
    local attr = store:FindFirstChild(key)
    if not attr then return default end
    local v = attr.Value
    if v == "true" then return true end
    if v == "false" then return false end
    local num = tonumber(v)
    if num then return num end
    return v
end

-- Create ScreenGui (single instance)
local function getOrCreateGui()
    local gui = LocalPlayer:FindFirstChild("PlayerGui"):FindFirstChild("RAX_UI")
    if gui then return gui end
    gui = Instance.new("ScreenGui")
    gui.Name = "RAX_UI"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    return gui
end

-- Core window creation
function RAX.CreateWindow(opts)
    opts = opts or {}
    local self = setmetatable({}, RAX)
    self.Gui = getOrCreateGui()
    self.Theme = DefaultTheme
    self.Tabs = {}
    self.ActiveTab = nil

    -- Main frame
    local frame = new("Frame", {
        Name = "RAX_Window",
        Parent = self.Gui,
        Size = UDim2.new(0, 420, 0, 520),
        Position = UDim2.new(0, 40, 0, 40),
        BackgroundColor3 = self.Theme.Background,
        BorderSizePixel = 0,
        ZIndex = 2,
    })

    -- Round corners
    local uic = new("UICorner", {Parent = frame, CornerRadius = UDim.new(0, 8)})

    -- Topbar
    local top = new("Frame", {
        Name = "Topbar",
        Parent = frame,
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = self.Theme.Topbar,
        BorderSizePixel = 0,
    })
    new("UICorner", {Parent = top, CornerRadius = UDim.new(0, 8)})

    local title = new("TextLabel", {
        Parent = top,
        Size = UDim2.new(1, -10, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextColor3 = self.Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = opts.Title or "RAX Hub",
    })

    -- Tab bar
    local tabbar = new("Frame", {
        Name = "TabBar",
        Parent = frame,
        Size = UDim2.new(1, 0, 0, 36),
        Position = UDim2.new(0, 0, 0, 36),
        BackgroundTransparency = 1,
    })
    local tabLayout = new("UIListLayout", {Parent = tabbar, FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6)})
    tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left

    -- Content area
    local content = new("Frame", {
        Name = "Content",
        Parent = frame,
        Size = UDim2.new(1, -20, 1, -92),
        Position = UDim2.new(0, 10, 0, 80),
        BackgroundTransparency = 1,
    })
    local contentLayout = new("UIListLayout", {Parent = content, FillDirection = Enum.FillDirection.Vertical, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8)})
    contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left

    -- store references
    self.Frame = frame
    self.Topbar = top
    self.TitleLabel = title
    self.TabBar = tabbar
    self.Content = content

    -- Dragging
    do
        local dragging, dragStart, startPos
        top.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = input.Position
                startPos = frame.Position
            end
        end)
        top.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = input.Position - dragStart
                frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)
    end

    -- keyboard toggle (RightControl)
    local visible = true
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.RightControl then
            visible = not visible
            tween(frame, {Position = visible and frame.Position or UDim2.new(-1, 0, frame.Position.Y.Scale, frame.Position.Y.Offset)}, 0.35)
        end
    end)

    return self
end

-- Tab creation
function RAX:Tab(opts)
    opts = opts or {}
    local tabBtn = new("TextButton", {
        Parent = self.TabBar,
        Size = UDim2.new(0, 120, 1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = self.Theme.SubText,
        Text = opts.Title or "Tab",
    })
    local underline = new("Frame", {Parent = tabBtn, Size = UDim2.new(1, 0, 0, 3), Position = UDim2.new(0, 0, 1, -3), BackgroundColor3 = Color3.new(0,0,0), BackgroundTransparency = 1})
    new("UICorner", {Parent = underline, CornerRadius = UDim.new(0, 4)})

    local page = {}
    page._parent = self.Content
    page._frame = new("Frame", {Parent = self.Content, Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, Visible = false, AutomaticSize = Enum.AutomaticSize.Y})
    new("UIListLayout", {Parent = page._frame, FillDirection = Enum.FillDirection.Vertical, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8)})
    page._frame.LayoutOrder = #self.Tabs + 1

    -- click behavior
    tabBtn.MouseButton1Click:Connect(function()
        -- hide all pages
        for _, t in ipairs(self.Tabs) do
            if t._frame then t._frame.Visible = false end
            if t._tabBtn then
                tween(t._tabBtn, {TextColor3 = self.Theme.SubText}, 0.18)
                tween(t._tabBtn:FindFirstChildOfClass("Frame"), {BackgroundTransparency = 1}, 0.18)
            end
        end
        page._frame.Visible = true
        tween(tabBtn, {TextColor3 = self.Theme.Text}, 0.18)
        tween(underline, {BackgroundTransparency = 0, BackgroundColor3 = self.Theme.Accent}, 0.18)
        self.ActiveTab = page
    end)

    page._tabBtn = tabBtn
    table.insert(self.Tabs, page)

    -- auto-select first tab
    if #self.Tabs == 1 then
        tabBtn:MouseButton1Click()
    end

    return setmetatable(page, {__index = RAX})
end

-- Section (collapsible)
function RAX:Section(opts)
    opts = opts or {}
    local section = new("Frame", {Parent = self._frame or self._parent, Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y})
    local header = new("Frame", {Parent = section, Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1})
    local title = new("TextLabel", {Parent = header, Size = UDim2.new(1, -28, 1, 0), Position = UDim2.new(0, 8, 0, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = self.Theme.Text, Text = opts.Title or "Section"})
    local toggleBtn = new("TextButton", {Parent = header, Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(1, -28, 0.5, -10), BackgroundColor3 = self.Theme.Element, Text = "+", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = self.Theme.Text})
    new("UICorner", {Parent = toggleBtn, CornerRadius = UDim.new(0, 6)})

    local body = new("Frame", {Parent = section, Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, Visible = false, AutomaticSize = Enum.AutomaticSize.Y})
    new("UIListLayout", {Parent = body, FillDirection = Enum.FillDirection.Vertical, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6)})

    local expanded = true
    local function setExpanded(v)
        expanded = v
        body.Visible = v
        toggleBtn.Text = v and "-" or "+"
        tween(toggleBtn, {BackgroundColor3 = v and self.Theme.Accent or self.Theme.Element}, 0.18)
    end
    toggleBtn.MouseButton1Click:Connect(function() setExpanded(not expanded) end)
    setExpanded(true)

    local wrapper = {}
    wrapper._parent = body
    wrapper._frame = section
    return setmetatable(wrapper, {__index = RAX})
end

-- Toggle (animated switch)
function RAX:Toggle(opts)
    opts = opts or {}
    local holder = new("Frame", {Parent = self._parent, Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1})
    local label = new("TextLabel", {Parent = holder, Size = UDim2.new(1, -60, 1, 0), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = self.Theme.Text, Text = opts.Title or "Toggle"})
    local switch = new("Frame", {Parent = holder, Size = UDim2.new(0, 44, 0, 20), Position = UDim2.new(1, -50, 0.5, -10), BackgroundColor3 = self.Theme.Element})
    new("UICorner", {Parent = switch, CornerRadius = UDim.new(0, 10)})
    local knob = new("Frame", {Parent = switch, Size = UDim2.new(0, 18, 0, 18), Position = UDim2.new(0, 1, 0.5, -9), BackgroundColor3 = Color3.fromRGB(255,255,255)})
    new("UICorner", {Parent = knob, CornerRadius = UDim.new(0, 9)})

    local state = opts.Value or false
    local function setState(v, noCallback)
        state = v
        if state then
            tween(knob, {Position = UDim2.new(1, -19, 0.5, -9)}, 0.18)
            tween(switch, {BackgroundColor3 = self.Theme.Accent}, 0.18)
        else
            tween(knob, {Position = UDim2.new(0, 1, 0.5, -9)}, 0.18)
            tween(switch, {BackgroundColor3 = self.Theme.Element}, 0.18)
        end
        if not noCallback and opts.Callback then
            task.spawn(opts.Callback, state)
        end
    end

    switch.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            setState(not state)
        end
    end)

    setState(state, true)
end

-- Button (animated)
function RAX:Button(opts)
    opts = opts or {}
    local btn = new("TextButton", {Parent = self._parent, Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = self.Theme.Element, Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = self.Theme.Text, Text = opts.Title or "Button"})
    new("UICorner", {Parent = btn, CornerRadius = UDim.new(0, 6)})
    btn.MouseEnter:Connect(function() tween(btn, {BackgroundColor3 = self.Theme.ElementHover}, 0.12) end)
    btn.MouseLeave:Connect(function() tween(btn, {BackgroundColor3 = self.Theme.Element}, 0.12) end)
    btn.MouseButton1Click:Connect(function()
        if opts.Callback then task.spawn(opts.Callback) end
        tween(btn, {BackgroundTransparency = 0.6}, 0.06):Play()
        task.delay(0.06, function() tween(btn, {BackgroundTransparency = 0}, 0.12) end)
    end)
end

-- Input
function RAX:Input(opts)
    opts = opts or {}
    local holder = new("Frame", {Parent = self._parent, Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1})
    local label = new("TextLabel", {Parent = holder, Size = UDim2.new(0.45, 0, 1, 0), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = self.Theme.Text, Text = opts.Title or "Input"})
    local box = new("TextBox", {Parent = holder, Size = UDim2.new(0.55, -6, 1, 0), Position = UDim2.new(0.45, 6, 0, 0), BackgroundColor3 = self.Theme.Element, TextColor3 = self.Theme.Text, Font = Enum.Font.Gotham, TextSize = 13, PlaceholderText = opts.Placeholder or ""})
    new("UICorner", {Parent = box, CornerRadius = UDim.new(0, 6)})
    box.FocusLost:Connect(function(enter)
        if enter and opts.Callback then task.spawn(opts.Callback, box.Text) end
    end)
end

-- Slider (animated)
function RAX:Slider(opts)
    opts = opts or {}
    local min, max, step = opts.Value.Min or 0, opts.Value.Max or 100, opts.Step or 1
    local default = opts.Value.Default or min
    local holder = new("Frame", {Parent = self._parent, Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1})
    local label = new("TextLabel", {Parent = holder, Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = self.Theme.Text, Text = (opts.Title or "Slider") .. " (" .. tostring(default) .. ")"})
    local bar = new("Frame", {Parent = holder, Size = UDim2.new(1, 0, 0, 10), Position = UDim2.new(0, 0, 0, 24), BackgroundColor3 = self.Theme.Element})
    new("UICorner", {Parent = bar, CornerRadius = UDim.new(0, 6)})
    local fill = new("Frame", {Parent = bar, Size = UDim2.new((default - min) / (max - min), 0, 1, 0), BackgroundColor3 = self.Theme.Accent})
    new("UICorner", {Parent = fill, CornerRadius = UDim.new(0, 6)})

    local dragging = false
    local function setFromX(x)
        local rel = clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local raw = min + (max - min) * rel
        local snapped = math.floor(raw / step + 0.5) * step
        snapped = clamp(snapped, min, max)
        fill.Size = UDim2.new((snapped - min) / (max - min), 0, 1, 0)
        label.Text = (opts.Title or "Slider") .. " (" .. tostring(snapped) .. ")"
        if opts.Callback then task.spawn(opts.Callback, snapped) end
    end

    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            setFromX(input.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            setFromX(input.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
end

-- Notification helper
function RAX:Notification(opts)
    opts = opts or {}
    local gui = getOrCreateGui()
    local notif = new("Frame", {Parent = gui, Size = UDim2.new(0, 260, 0, 48), Position = UDim2.new(1, -280, 0, 40), BackgroundColor3 = self.Theme.Element, BorderSizePixel = 0})
    new("UICorner", {Parent = notif, CornerRadius = UDim.new(0, 8)})
    local label = new("TextLabel", {Parent = notif, Size = UDim2.new(1, -12, 1, 0), Position = UDim2.new(0, 6, 0, 0), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = self.Theme.Text, Text = opts.Text or "Notification"})
    notif.Position = UDim2.new(1, 20, 0, 40)
    tween(notif, {Position = UDim2.new(1, -280, 0, 40)}, 0.28)
    task.delay(opts.Duration or 2.5, function()
        tween(notif, {Position = UDim2.new(1, 20, 0, 40)}, 0.28)
        task.delay(0.28, function() notif:Destroy() end)
    end)
end

-- Theme setter
function RAX:SetTheme(theme)
    if not theme then return end
    for k, v in pairs(theme) do self.Theme[k] = v end
    -- apply to main frame if exists
    if self.Frame then
        self.Frame.BackgroundColor3 = self.Theme.Background
        self.Topbar.BackgroundColor3 = self.Theme.Topbar
        self.TitleLabel.TextColor3 = self.Theme.Text
        -- update tab colors
        for _, t in ipairs(self.Tabs) do
            if t._tabBtn then
                t._tabBtn.TextColor3 = self.Theme.SubText
                local u = t._tabBtn:FindFirstChildOfClass("Frame")
                if u then u.BackgroundColor3 = self.Theme.Accent end
            end
        end
    end
end

return RAX
