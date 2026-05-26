-- RAX Module v1.0 — Polished, safe, animated UI
-- Place in a ModuleScript or loadstring it. API documented at bottom.

local RAX = {}
RAX.__index = RAX

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- Utilities
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
    time = time or 0.22
    style = style or Enum.EasingStyle.Quad
    dir = dir or Enum.EasingDirection.Out
    local info = TweenInfo.new(time, style, dir)
    local t = TweenService:Create(instance, info, props)
    t:Play()
    return t
end

local function clamp(v, a, b) return math.max(a, math.min(b, v)) end

local function uniqueGuiName()
    local id = tostring(LocalPlayer.UserId or "anon")
    local stamp = tostring(math.floor(tick() * 1000))
    return "RAX_UI_" .. id .. "_" .. stamp
end

-- Persistence helpers stored under PlayerGui.RAX_Settings_<UserId>
local function settingsFolder()
    local pg = LocalPlayer:WaitForChild("PlayerGui")
    local name = "RAX_Settings_" .. tostring(LocalPlayer.UserId or "anon")
    local folder = pg:FindFirstChild(name)
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = name
        folder.Parent = pg
    end
    return folder
end

local function saveSetting(key, value)
    local folder = settingsFolder()
    local obj = folder:FindFirstChild(key)
    if not obj then
        obj = Instance.new("StringValue")
        obj.Name = key
        obj.Parent = folder
    end
    obj.Value = tostring(value)
end

local function loadSetting(key, default)
    local folder = LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("RAX_Settings_" .. tostring(LocalPlayer.UserId or "anon"))
    if not folder then return default end
    local obj = folder:FindFirstChild(key)
    if not obj then return default end
    local v = obj.Value
    if v == "true" then return true end
    if v == "false" then return false end
    local n = tonumber(v)
    if n then return n end
    return v
end

-- Default theme
local DefaultTheme = {
    Background = Color3.fromRGB(18, 18, 18),
    Topbar = Color3.fromRGB(28, 28, 28),
    Accent = Color3.fromRGB(0, 170, 85),
    Text = Color3.fromRGB(235, 235, 235),
    SubText = Color3.fromRGB(170, 170, 170),
    Element = Color3.fromRGB(36, 36, 36),
    ElementHover = Color3.fromRGB(46, 46, 46),
}

-- Create or cleanup GUI created by this module
local function createScreenGui(uniqueName)
    local pg = LocalPlayer:WaitForChild("PlayerGui")
    -- remove only previous GUIs created by this module that match prefix
    for _, child in ipairs(pg:GetChildren()) do
        if child:IsA("ScreenGui") and tostring(child.Name):match("^RAX_UI_") then
            pcall(function() child:Destroy() end)
        end
    end
    local gui = Instance.new("ScreenGui")
    gui.Name = uniqueName
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.Parent = pg
    return gui
end

-- Core API: CreateWindow
function RAX.CreateWindow(opts)
    opts = opts or {}
    local self = setmetatable({}, RAX)
    self._uniqueName = uniqueGuiName()
    self._gui = createScreenGui(self._uniqueName)
    self._theme = {}
    for k, v in pairs(DefaultTheme) do self._theme[k] = v end
    self._tabs = {}
    self._destroyed = false

    -- main frame
    local frame = new("Frame", {
        Name = "RAX_Window",
        Parent = self._gui,
        Size = UDim2.new(0, 520, 0, 520),
        Position = UDim2.new(0, 40, 0, 40),
        BackgroundColor3 = self._theme.Background,
        BorderSizePixel = 0,
        ZIndex = 2,
    })
    new("UICorner", {Parent = frame, CornerRadius = UDim.new(0, 10)})

    -- topbar
    local top = new("Frame", {Parent = frame, Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = self._theme.Topbar, BorderSizePixel = 0})
    new("UICorner", {Parent = top, CornerRadius = UDim.new(0, 10)})
    local title = new("TextLabel", {Parent = top, Size = UDim2.new(1, -10, 1, 0), Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = self._theme.Text, Text = opts.Title or "RAX Hub"})
    self._frame = frame
    self._top = top
    self._title = title

    -- tabbar
    local tabbar = new("Frame", {Parent = frame, Name = "TabBar", Size = UDim2.new(1, 0, 0, 36), Position = UDim2.new(0, 0, 0, 40), BackgroundTransparency = 1})
    new("UIListLayout", {Parent = tabbar, FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6)})
    self._tabbar = tabbar

    -- content
    local content = new("Frame", {Parent = frame, Name = "Content", Size = UDim2.new(1, -20, 1, -96), Position = UDim2.new(0, 10, 0, 88), BackgroundTransparency = 1})
    new("UIListLayout", {Parent = content, FillDirection = Enum.FillDirection.Vertical, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8)})
    self._content = content

    -- drag
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
            if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = input.Position - dragStart
                frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)
    end

    -- keyboard toggle RightControl
    do
        local visible = true
        UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.KeyCode == Enum.KeyCode.RightControl then
                visible = not visible
                frame.Visible = visible
            end
        end)
    end

    -- API methods
    function self:SetTheme(t)
        if not t then return end
        for k, v in pairs(t) do self._theme[k] = v end
        if self._frame and self._top and self._title then
            self._frame.BackgroundColor3 = self._theme.Background
            self._top.BackgroundColor3 = self._theme.Topbar
            self._title.TextColor3 = self._theme.Text
        end
    end

    function self:Notification(opts)
        opts = opts or {}
        local notif = new("Frame", {Parent = self._gui, Size = UDim2.new(0, 300, 0, 48), Position = UDim2.new(1, -320, 0, 40), BackgroundColor3 = self._theme.Element})
        new("UICorner", {Parent = notif, CornerRadius = UDim.new(0, 8)})
        new("TextLabel", {Parent = notif, Size = UDim2.new(1, -12, 1, 0), Position = UDim2.new(0, 6, 0, 0), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = self._theme.Text, Text = opts.Text or "Notification"})
        tween(notif, {Position = UDim2.new(1, -320, 0, 40)}, 0.28)
        task.delay(opts.Duration or 2.5, function()
            tween(notif, {Position = UDim2.new(1, 20, 0, 40)}, 0.28)
            task.delay(0.28, function() pcall(function() notif:Destroy() end) end)
        end)
    end

    function self:Destroy()
        if self._destroyed then return end
        self._destroyed = true
        pcall(function() if self._gui then self._gui:Destroy() end end)
        -- remove settings folder if empty
        local folder = LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("RAX_Settings_" .. tostring(LocalPlayer.UserId or "anon"))
        if folder and #folder:GetChildren() == 0 then pcall(function() folder:Destroy() end) end
    end

    -- Tab creation
    function self:Tab(opts)
        opts = opts or {}
        local id = #self._tabs + 1
        local btnName = ("RAX_TabBtn_%d_%s"):format(id, tostring(LocalPlayer.UserId or "anon"))
        local pageName = ("RAX_Page_%d_%s"):format(id, tostring(LocalPlayer.UserId or "anon"))

        local tabBtn = new("TextButton", {Parent = self._tabbar, Name = btnName, Size = UDim2.new(0, 120, 1, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = self._theme.SubText, Text = opts.Title or ("Tab "..id)})
        local underline = new("Frame", {Parent = tabBtn, Name = btnName .. "_Underline", Size = UDim2.new(1, 0, 0, 3), Position = UDim2.new(0, 0, 1, -3), BackgroundTransparency = 1})
        new("UICorner", {Parent = underline, CornerRadius = UDim.new(0, 4)})

        local page = new("Frame", {Parent = self._content, Name = pageName, Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, Visible = false, AutomaticSize = Enum.AutomaticSize.Y})
        new("UIListLayout", {Parent = page, FillDirection = Enum.FillDirection.Vertical, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8)})
        page.LayoutOrder = id

        if tabBtn:IsA("GuiButton") then
            tabBtn.MouseButton1Click:Connect(function()
                for _, t in ipairs(self._tabs) do
                    if t.page then t.page.Visible = false end
                    if t.btn then tween(t.btn, {TextColor3 = self._theme.SubText}, 0.18) end
                    if t.underline then tween(t.underline, {BackgroundTransparency = 1}, 0.18) end
                end
                page.Visible = true
                tween(tabBtn, {TextColor3 = self._theme.Text}, 0.18)
                tween(underline, {BackgroundTransparency = 0, BackgroundColor3 = self._theme.Accent}, 0.18)
            end)
        else
            warn("RAX: Tab button is not a GuiButton, skipping connect for", tabBtn:GetFullName())
        end

        local tabObj = {btn = tabBtn, underline = underline, page = page}
        table.insert(self._tabs, tabObj)
        if #self._tabs == 1 then tabBtn:MouseButton1Click() end

        -- return a lightweight tab API
        local tabAPI = {}
        function tabAPI:Section(opts)
            opts = opts or {}
            local section = new("Frame", {Parent = page, Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y})
            local header = new("Frame", {Parent = section, Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1})
            local titleLabel = new("TextLabel", {Parent = header, Size = UDim2.new(1, -28, 1, 0), Position = UDim2.new(0, 8, 0, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = self._theme.Text, Text = opts.Title or "Section"})
            local toggleBtn = new("TextButton", {Parent = header, Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(1, -28, 0.5, -10), BackgroundColor3 = self._theme.Element, Text = "-", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = self._theme.Text})
            new("UICorner", {Parent = toggleBtn, CornerRadius = UDim.new(0, 6)})
            local body = new("Frame", {Parent = section, Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, Visible = true, AutomaticSize = Enum.AutomaticSize.Y})
            new("UIListLayout", {Parent = body, FillDirection = Enum.FillDirection.Vertical, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6)})

            local expanded = true
            toggleBtn.MouseButton1Click:Connect(function()
                expanded = not expanded
                body.Visible = expanded
                toggleBtn.Text = expanded and "-" or "+"
                tween(toggleBtn, {BackgroundColor3 = expanded and self._theme.Accent or self._theme.Element}, 0.18)
            end)

            local sectionAPI = {}
            function sectionAPI:Toggle(opts)
                opts = opts or {}
                local holder = new("Frame", {Parent = body, Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1})
                local label = new("TextLabel", {Parent = holder, Size = UDim2.new(1, -60, 1, 0), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = self._theme.Text, Text = opts.Title or "Toggle"})
                local switch = new("Frame", {Parent = holder, Size = UDim2.new(0, 44, 0, 20), Position = UDim2.new(1, -50, 0.5, -10), BackgroundColor3 = self._theme.Element})
                new("UICorner", {Parent = switch, CornerRadius = UDim.new(0, 10)})
                local knob = new("Frame", {Parent = switch, Size = UDim2.new(0, 18, 0, 18), Position = UDim2.new(0, 1, 0.5, -9), BackgroundColor3 = Color3.fromRGB(255, 255, 255)})
                new("UICorner", {Parent = knob, CornerRadius = UDim.new(0, 9)})

                local state = opts.Value or false
                local function setState(v, noCb)
                    state = v
                    if state then
                        tween(knob, {Position = UDim2.new(1, -19, 0.5, -9)}, 0.18)
                        tween(switch, {BackgroundColor3 = self._theme.Accent}, 0.18)
                    else
                        tween(knob, {Position = UDim2.new(0, 1, 0.5, -9)}, 0.18)
                        tween(switch, {BackgroundColor3 = self._theme.Element}, 0.18)
                    end
                    if not noCb and type(opts.Callback) == "function" then
                        task.spawn(function() pcall(opts.Callback, state) end)
                    end
                end

                switch.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then setState(not state) end
                end)
                setState(state, true)
                return function() return state end
            end

            function sectionAPI:Button(opts)
                opts = opts or {}
                local btn = new("TextButton", {Parent = body, Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = self._theme.Element, Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = self._theme.Text, Text = opts.Title or "Button"})
                new("UICorner", {Parent = btn, CornerRadius = UDim.new(0, 6)})
                btn.MouseEnter:Connect(function() tween(btn, {BackgroundColor3 = self._theme.ElementHover}, 0.12) end)
                btn.MouseLeave:Connect(function() tween(btn, {BackgroundColor3 = self._theme.Element}, 0.12) end)
                btn.MouseButton1Click:Connect(function()
                    if type(opts.Callback) == "function" then task.spawn(function() pcall(opts.Callback) end) end
                    tween(btn, {BackgroundTransparency = 0.6}, 0.06)
                    task.delay(0.06, function() tween(btn, {BackgroundTransparency = 0}, 0.12) end)
                end)
            end

            function sectionAPI:Slider(opts)
                opts = opts or {}
                local min, max, step = opts.Value and opts.Value.Min or 0, opts.Value and opts.Value.Max or 100, opts.Step or 1
                local default = opts.Value and opts.Value.Default or min
                local holder = new("Frame", {Parent = body, Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1})
                local label = new("TextLabel", {Parent = holder, Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = self._theme.Text, Text = (opts.Title or "Slider") .. " (" .. tostring(default) .. ")"})
                local bar = new("Frame", {Parent = holder, Size = UDim2.new(1, 0, 0, 10), Position = UDim2.new(0, 0, 0, 24), BackgroundColor3 = self._theme.Element})
                new("UICorner", {Parent = bar, CornerRadius = UDim.new(0, 6)})
                local fill = new("Frame", {Parent = bar, Size = UDim2.new((default - min) / (max - min), 0, 1, 0), BackgroundColor3 = self._theme.Accent})
                new("UICorner", {Parent = fill, CornerRadius = UDim.new(0, 6)})

                local dragging = false
                local function setFromX(x)
                    local rel = clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
                    local raw = min + (max - min) * rel
                    local snapped = math.floor(raw / step + 0.5) * step
                    snapped = clamp(snapped, min, max)
                    fill.Size = UDim2.new((snapped - min) / (max - min), 0, 1, 0)
                    label.Text = (opts.Title or "Slider") .. " (" .. tostring(snapped) .. ")"
                    if type(opts.Callback) == "function" then task.spawn(function() pcall(opts.Callback, snapped) end) end
                end

                bar.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true setFromX(input.Position.X) end end)
                UserInputService.InputChanged:Connect(function(input) if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then setFromX(input.Position.X) end end)
                UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
            end

            function sectionAPI:Input(opts)
                opts = opts or {}
                local holder = new("Frame", {Parent = body, Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1})
                new("TextLabel", {Parent = holder, Size = UDim2.new(0.45, 0, 1, 0), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = self._theme.Text, Text = opts.Title or "Input"})
                local box = new("TextBox", {Parent = holder, Size = UDim2.new(0.55, -6, 1, 0), Position = UDim2.new(0.45, 6, 0, 0), BackgroundColor3 = self._theme.Element, TextColor3 = self._theme.Text, Font = Enum.Font.Gotham, TextSize = 13, PlaceholderText = opts.Placeholder or ""})
                new("UICorner", {Parent = box, CornerRadius = UDim.new(0, 6)})
                box.FocusLost:Connect(function(enter) if enter and type(opts.Callback) == "function" then task.spawn(function() pcall(opts.Callback, box.Text) end) end end)
            end

            function sectionAPI:Dropdown(opts)
                opts = opts or {}
                local holder = new("Frame", {Parent = body, Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1})
                local label = new("TextLabel", {Parent = holder, Size = UDim2.new(0.5, 0, 1, 0), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = self._theme.Text, Text = opts.Title or "Dropdown"})
                local btn = new("TextButton", {Parent = holder, Size = UDim2.new(0.5, -6, 1, 0), Position = UDim2.new(0.5, 6, 0, 0), BackgroundColor3 = self._theme.Element, TextColor3 = self._theme.Text, Font = Enum.Font.Gotham, TextSize = 13, Text = opts.Default or "Select"})
                new("UICorner", {Parent = btn, CornerRadius = UDim.new(0, 6)})
                local list = new("Frame", {Parent = holder, Size = UDim2.new(1, 0, 0, 0), Position = UDim2.new(0, 0, 1, 6), BackgroundColor3 = self._theme.Element, Visible = false, AutomaticSize = Enum.AutomaticSize.Y})
                new("UIListLayout", {Parent = list, FillDirection = Enum.FillDirection.Vertical, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4)})
                new("UICorner", {Parent = list, CornerRadius = UDim.new(0, 6)})

                btn.MouseButton1Click:Connect(function()
                    list.Visible = not list.Visible
                end)

                if type(opts.Options) == "table" then
                    for _, opt in ipairs(opts.Options) do
                        local item = new("TextButton", {Parent = list, Size = UDim2.new(1, -8, 0, 28), Position = UDim2.new(0, 4, 0, 0), BackgroundColor3 = self._theme.Element, Text = tostring(opt), TextColor3 = self._theme.Text, Font = Enum.Font.Gotham, TextSize = 13})
                        new("UICorner", {Parent = item, CornerRadius = UDim.new(0, 6)})
                        item.MouseButton1Click:Connect(function()
                            btn.Text = tostring(opt)
                            list.Visible = false
                            if type(opts.Callback) == "function" then task.spawn(function() pcall(opts.Callback, opt) end) end
                        end)
                    end
                end
            end

            return sectionAPI
        end

        return tabAPI
    end

    return self
end

return RAX
