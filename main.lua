-- RAX Module v1.0 — Polished, safe, animated UI
-- Place this file as main.lua in your GitHub repo (RAX/main.lua)
-- API: RAX.CreateWindow(opts) -> window
-- window:BringToFront(), window:SetTheme(tbl), window:Notification(text,dur), window:Destroy()
-- Helpers: RAX.AddTab(window, title) -> { Section = function(opts) -> sectionAPI end }

local RAX = {}
RAX.__index = RAX

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

-- helpers
local function new(class, props)
    local obj = Instance.new(class)
    if props then
        for k,v in pairs(props) do
            if k == "Parent" then obj.Parent = v else pcall(function() obj[k] = v end) end
        end
    end
    return obj
end

local function tween(inst, props, t, style, dir)
    t = t or 0.18
    style = style or Enum.EasingStyle.Quad
    dir = dir or Enum.EasingDirection.Out
    local info = TweenInfo.new(t, style, dir)
    local tw = TweenService:Create(inst, info, props)
    tw:Play()
    return tw
end

local function clamp(v, a, b) return math.max(a, math.min(b, v)) end

local function uid()
    return ("RAX_UI_%s_%d"):format(tostring(LocalPlayer.UserId or "anon"), math.floor(tick()*1000))
end

-- default theme
local DefaultTheme = {
    Background = Color3.fromRGB(18,18,18),
    Topbar = Color3.fromRGB(28,28,28),
    Accent = Color3.fromRGB(0,170,85),
    Text = Color3.fromRGB(235,235,235),
    SubText = Color3.fromRGB(170,170,170),
    Element = Color3.fromRGB(36,36,36),
    ElementHover = Color3.fromRGB(46,46,46),
}

-- create unique ScreenGui (non-destructive)
local function createGui(name)
    local pg = LocalPlayer:WaitForChild("PlayerGui")
    -- remove only previous RAX GUIs created by this module (prefix)
    for _, child in ipairs(pg:GetChildren()) do
        if child:IsA("ScreenGui") and tostring(child.Name):match("^RAX_UI_") then
            pcall(function() child:Destroy() end)
        end
    end
    local sg = Instance.new("ScreenGui")
    sg.Name = name
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.DisplayOrder = 1000
    sg.Parent = pg
    return sg
end

-- CreateWindow: returns window object with helpers
function RAX.CreateWindow(opts)
    opts = opts or {}
    local self = setmetatable({}, RAX)
    self._name = uid()
    self._gui = createGui(self._name)
    self._theme = {}
    for k,v in pairs(DefaultTheme) do self._theme[k] = v end
    self._tabs = {}
    self._destroyed = false

    -- main window
    local win = new("Frame", {
        Name = "RAX_Window",
        Parent = self._gui,
        Size = UDim2.new(0,520,0,520),
        Position = UDim2.new(0,40,0,40),
        BackgroundColor3 = self._theme.Background,
        BorderSizePixel = 0,
        ZIndex = 9999,
    })
    new("UICorner", {Parent = win, CornerRadius = UDim.new(0,10)})

    -- topbar
    local top = new("Frame", {Parent = win, Size = UDim2.new(1,0,0,40), BackgroundColor3 = self._theme.Topbar, ZIndex = 10000})
    new("UICorner", {Parent = top, CornerRadius = UDim.new(0,10)})
    local title = new("TextLabel", {Parent = top, Size = UDim2.new(1,-10,1,0), Position = UDim2.new(0,10,0,0), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = self._theme.Text, Text = opts.Title or "RAX Hub", ZIndex = 10001})

    -- tabbar + content
    local tabbar = new("Frame", {Parent = win, Size = UDim2.new(1,0,0,36), Position = UDim2.new(0,0,0,40), BackgroundTransparency = 1, ZIndex = 10000})
    new("UIListLayout", {Parent = tabbar, FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0,6)})
    local content = new("Frame", {Parent = win, Size = UDim2.new(1,-20,1,-96), Position = UDim2.new(0,10,0,88), BackgroundTransparency = 1, ZIndex = 10000})
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

    -- RightControl toggle
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

    -- API methods
    function self:SetTheme(t)
        if not t then return end
        for k,v in pairs(t) do self._theme[k] = v end
        win.BackgroundColor3 = self._theme.Background
        top.BackgroundColor3 = self._theme.Topbar
        title.TextColor3 = self._theme.Text
    end

    function self:Notification(text, duration)
        duration = duration or 2.5
        local notif = new("Frame", {Parent = self._gui, Size = UDim2.new(0,300,0,48), Position = UDim2.new(1,-320,0,40), BackgroundColor3 = self._theme.Element, ZIndex = 11000})
        new("UICorner", {Parent = notif, CornerRadius = UDim.new(0,8)})
        new("TextLabel", {Parent = notif, Size = UDim2.new(1,-12,1,0), Position = UDim2.new(0,6,0,0), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = self._theme.Text, Text = text or "Notification", ZIndex = 11001})
        tween(notif, {Position = UDim2.new(1,-320,0,40)}, 0.28)
        task.delay(duration, function()
            tween(notif, {Position = UDim2.new(1,20,0,40)}, 0.28)
            task.delay(0.28, function() pcall(function() notif:Destroy() end) end)
        end)
    end

    function self:BringToFront()
        if self._gui and self._gui:IsA("ScreenGui") then
            self._gui.DisplayOrder = (self._gui.DisplayOrder or 0) + 1000
        end
    end

    function self:ScanOverlays()
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
        return overlays
    end

    function self:Destroy()
        if self._destroyed then return end
        self._destroyed = true
        pcall(function() if self._gui then self._gui:Destroy() end end)
    end

    -- expose internals for building UI
    self._win = win
    self._tabbar = tabbar
    self._content = content
    self._title = title

    -- small badge to confirm load
    local badge = new("TextLabel", {Parent = win, Size = UDim2.new(0,120,0,20), Position = UDim2.new(1,-140,0,8), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Color3.fromRGB(200,200,200), Text = "RAX loaded", ZIndex = 10002})
    tween(badge, {TextTransparency = 0}, 0.2)

    return self
end

-- AddTab helper: returns {Section = function(opts) -> sectionAPI}
function RAX.AddTab(window, title)
    if not window or not window._tabbar or not window._content then return end
    local id = #window._tabbar:GetChildren() + 1
    local btn = new("TextButton", {Parent = window._tabbar, Size = UDim2.new(0,120,1,0), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = window._theme.SubText or DefaultTheme.SubText, Text = title or ("Tab "..id), ZIndex = 10002})
    local page = new("Frame", {Parent = window._content, Size = UDim2.new(1,0,0,0), BackgroundTransparency = 1, Visible = false, AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 10000})
    new("UIListLayout", {Parent = page, FillDirection = Enum.FillDirection.Vertical, Padding = UDim.new(0,8)})
    if btn:IsA("GuiButton") then
        btn.MouseButton1Click:Connect(function()
            for _, c in ipairs(window._content:GetChildren()) do if c:IsA("Frame") then c.Visible = false end end
            page.Visible = true
        end)
    end
    if #window._tabbar:GetChildren() == 1 then btn:MouseButton1Click() end

    local function Section(opts)
        opts = opts or {}
        local section = new("Frame", {Parent = page, Size = UDim2.new(1,0,0,0), BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y})
        local header = new("Frame", {Parent = section, Size = UDim2.new(1,0,0,28), BackgroundTransparency = 1})
        local titleLabel = new("TextLabel", {Parent = header, Size = UDim2.new(1,-28,1,0), Position = UDim2.new(0,8,0,0), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = window._theme.Text, Text = opts.Title or "Section"})
        local toggleBtn = new("TextButton", {Parent = header, Size = UDim2.new(0,20,0,20), Position = UDim2.new(1,-28,0.5,-10), BackgroundColor3 = window._theme.Element, Text = "-", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = window._theme.Text})
        new("UICorner", {Parent = toggleBtn, CornerRadius = UDim.new(0,6)})
        local body = new("Frame", {Parent = section, Size = UDim2.new(1,0,0,0), BackgroundTransparency = 1, Visible = true, AutomaticSize = Enum.AutomaticSize.Y})
        new("UIListLayout", {Parent = body, FillDirection = Enum.FillDirection.Vertical, Padding = UDim.new(0,6)})

        local expanded = true
        toggleBtn.MouseButton1Click:Connect(function()
            expanded = not expanded
            body.Visible = expanded
            toggleBtn.Text = expanded and "-" or "+"
            tween(toggleBtn, {BackgroundColor3 = expanded and window._theme.Accent or window._theme.Element}, 0.18)
        end)

        local api = {}

        function api:Toggle(opts) -- opts: Title, Value, Callback
            opts = opts or {}
            local holder = new("Frame", {Parent = body, Size = UDim2.new(1,0,0,28), BackgroundTransparency = 1})
            local label = new("TextLabel", {Parent = holder, Size = UDim2.new(1,-60,1,0), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = window._theme.Text, Text = opts.Title or "Toggle"})
            local switch = new("Frame", {Parent = holder, Size = UDim2.new(0,44,0,20), Position = UDim2.new(1,-50,0.5,-10), BackgroundColor3 = window._theme.Element})
            new("UICorner", {Parent = switch, CornerRadius = UDim.new(0,10)})
            local knob = new("Frame", {Parent = switch, Size = UDim2.new(0,18,0,18), Position = UDim2.new(0,1,0.5,-9), BackgroundColor3 = Color3.fromRGB(255,255,255)})
            new("UICorner", {Parent = knob, CornerRadius = UDim.new(0,9)})

            local state = opts.Value or false
            local function setState(v, noCb)
                state = v
                if state then
                    tween(knob, {Position = UDim2.new(1, -19, 0.5, -9)}, 0.18)
                    tween(switch, {BackgroundColor3 = window._theme.Accent}, 0.18)
                else
                    tween(knob, {Position = UDim2.new(0, 1, 0.5, -9)}, 0.18)
                    tween(switch, {BackgroundColor3 = window._theme.Element}, 0.18)
                end
                if not noCb and type(opts.Callback) == "function" then task.spawn(function() pcall(opts.Callback, state) end) end
            end

            switch.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then setState(not state) end
            end)
            setState(state, true)
            return function() return state end
        end

        function api:Button(opts)
            opts = opts or {}
            local btn = new("TextButton", {Parent = body, Size = UDim2.new(1,0,0,30), BackgroundColor3 = window._theme.Element, Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = window._theme.Text, Text = opts.Title or "Button"})
            new("UICorner", {Parent = btn, CornerRadius = UDim.new(0,6)})
            btn.MouseEnter:Connect(function() tween(btn, {BackgroundColor3 = window._theme.ElementHover}, 0.12) end)
            btn.MouseLeave:Connect(function() tween(btn, {BackgroundColor3 = window._theme.Element}, 0.12) end)
            btn.MouseButton1Click:Connect(function()
                if type(opts.Callback) == "function" then task.spawn(function() pcall(opts.Callback) end) end
                tween(btn, {BackgroundTransparency = 0.6}, 0.06)
                task.delay(0.06, function() tween(btn, {BackgroundTransparency = 0}, 0.12) end)
            end)
        end

        function api:Slider(opts)
            opts = opts or {}
            local min, max, step = opts.Value and opts.Value.Min or 0, opts.Value and opts.Value.Max or 100, opts.Step or 1
            local default = opts.Value and opts.Value.Default or min
            local holder = new("Frame", {Parent = body, Size = UDim2.new(1,0,0,44), BackgroundTransparency = 1})
            local label = new("TextLabel", {Parent = holder, Size = UDim2.new(1,0,0,16), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = window._theme.Text, Text = (opts.Title or "Slider") .. " (" .. tostring(default) .. ")"})
            local bar = new("Frame", {Parent = holder, Size = UDim2.new(1,0,0,10), Position = UDim2.new(0,0,0,24), BackgroundColor3 = window._theme.Element})
            new("UICorner", {Parent = bar, CornerRadius = UDim.new(0,6)})
            local fill = new("Frame", {Parent = bar, Size = UDim2.new((default - min) / (max - min), 0, 1, 0), BackgroundColor3 = window._theme.Accent})
            new("UICorner", {Parent = fill, CornerRadius = UDim.new(0,6)})

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

        function api:Input(opts)
            opts = opts or {}
            local holder = new("Frame", {Parent = body, Size = UDim2.new(1,0,0,28), BackgroundTransparency = 1})
            new("TextLabel", {Parent = holder, Size = UDim2.new(0.45,0,1,0), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = window._theme.Text, Text = opts.Title or "Input"})
            local box = new("TextBox", {Parent = holder, Size = UDim2.new(0.55,-6,1,0), Position = UDim2.new(0.45,6,0,0), BackgroundColor3 = window._theme.Element, TextColor3 = window._theme.Text, Font = Enum.Font.Gotham, TextSize = 13, PlaceholderText = opts.Placeholder or ""})
            new("UICorner", {Parent = box, CornerRadius = UDim.new(0,6)})
            box.FocusLost:Connect(function(enter) if enter and type(opts.Callback) == "function" then task.spawn(function() pcall(opts.Callback, box.Text) end) end end)
        end

        function api:Dropdown(opts)
            opts = opts or {}
            local holder = new("Frame", {Parent = body, Size = UDim2.new(1,0,0,30), BackgroundTransparency = 1})
            local label = new("TextLabel", {Parent = holder, Size = UDim2.new(0.5,0,1,0), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = window._theme.Text, Text = opts.Title or "Dropdown"})
            local btn = new("TextButton", {Parent = holder, Size = UDim2.new(0.5,-6,1,0), Position = UDim2.new(0.5,6,0,0), BackgroundColor3 = window._theme.Element, TextColor3 = window._theme.Text, Font = Enum.Font.Gotham, TextSize = 13, Text = opts.Default or "Select"})
            new("UICorner", {Parent = btn, CornerRadius = UDim.new(0,6)})
            local list = new("Frame", {Parent = holder, Size = UDim2.new(1,0,0,0), Position = UDim2.new(0,0,1,6), BackgroundColor3 = window._theme.Element, Visible = false, AutomaticSize = Enum.AutomaticSize.Y})
            new("UIListLayout", {Parent = list, FillDirection = Enum.FillDirection.Vertical, Padding = UDim.new(0,4)})
            new("UICorner", {Parent = list, CornerRadius = UDim.new(0,6)})

            btn.MouseButton1Click:Connect(function() list.Visible = not list.Visible end)
            if type(opts.Options) == "table" then
                for _, opt in ipairs(opts.Options) do
                    local item = new("TextButton", {Parent = list, Size = UDim2.new(1,-8,0,28), Position = UDim2.new(0,4,0,0), BackgroundColor3 = window._theme.Element, Text = tostring(opt), TextColor3 = window._theme.Text, Font = Enum.Font.Gotham, TextSize = 13})
                    new("UICorner", {Parent = item, CornerRadius = UDim.new(0,6)})
                    item.MouseButton1Click:Connect(function()
                        btn.Text = tostring(opt)
                        list.Visible = false
                        if type(opts.Callback) == "function" then task.spawn(function() pcall(opts.Callback, opt) end) end
                    end)
                end
            end
        end

        return api
    end

    return {Section = Section}
end

return RAX
