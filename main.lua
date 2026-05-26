-- RAX UI - super simple screen gui api

local RAX = {}
RAX.__index = RAX

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local function createScreenGui()
    local gui = Instance.new("ScreenGui")
    gui.Name = "RAX_UI"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    return gui
end

local function createDraggableFrame(parent, title)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 320, 0, 260)
    frame.Position = UDim2.new(0, 50, 0, 50)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    frame.BorderSizePixel = 0
    frame.Parent = parent

    local topbar = Instance.new("Frame")
    topbar.Size = UDim2.new(1, 0, 0, 26)
    topbar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    topbar.BorderSizePixel = 0
    topbar.Parent = frame

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -10, 1, 0)
    titleLabel.Position = UDim2.new(0, 5, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 14
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.Text = title or "RAX"
    titleLabel.Parent = topbar

    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -10, 1, -36)
    content.Position = UDim2.new(0, 5, 0, 31)
    content.BackgroundTransparency = 1
    content.Parent = frame

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 6)
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = content

    -- drag
    local dragging, dragStart, startPos
    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    topbar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)

    return frame, content
end

-- WINDOW
function RAX.CreateWindow(opts)
    local self = setmetatable({}, RAX)
    self.Gui = createScreenGui()
    self.Frame, self.Content = createDraggableFrame(self.Gui, opts.Title or "RAX")
    self.Tabs = {}
    return self
end

-- TAB (for now just returns the window as a “tab” proxy)
function RAX:Tab(opts)
    local tab = {}
    tab._parent = self.Content
    return setmetatable(tab, {__index = RAX})
end

-- SECTION
function RAX:Section(opts)
    local section = Instance.new("Frame")
    section.BackgroundTransparency = 1
    section.Size = UDim2.new(1, 0, 0, 0)
    section.AutomaticSize = Enum.AutomaticSize.Y
    section.Parent = self._parent or self.Content

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 4)
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = section

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 18)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 13
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextColor3 = Color3.fromRGB(200, 200, 200)
    title.Text = opts.Title or "Section"
    title.Parent = section

    local wrapper = {}
    wrapper._parent = section
    return setmetatable(wrapper, {__index = RAX})
end

-- TOGGLE
function RAX:Toggle(opts)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, 0, 0, 22)
    holder.BackgroundTransparency = 1
    holder.Parent = self._parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -40, 1, 0)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.Text = opts.Title or "Toggle"
    label.Parent = holder

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 32, 0, 18)
    button.Position = UDim2.new(1, -34, 0.5, -9)
    button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    button.BorderSizePixel = 0
    button.Font = Enum.Font.GothamBold
    button.TextSize = 12
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Text = opts.Value and "ON" or "OFF"
    button.Parent = holder

    local state = opts.Value or false

    local function setState(v)
        state = v
        button.Text = state and "ON" or "OFF"
        button.BackgroundColor3 = state and Color3.fromRGB(0, 170, 85) or Color3.fromRGB(60, 60, 60)
        if opts.Callback then
            task.spawn(opts.Callback, state)
        end
    end

    button.MouseButton1Click:Connect(function()
        setState(not state)
    end)

    setState(state)
end

-- BUTTON
function RAX:Button(opts)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 0, 22)
    button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    button.BorderSizePixel = 0
    button.Font = Enum.Font.Gotham
    button.TextSize = 13
    button.TextColor3 = Color3.fromRGB(230, 230, 230)
    button.Text = opts.Title or "Button"
    button.Parent = self._parent

    button.MouseButton1Click:Connect(function()
        if opts.Callback then
            task.spawn(opts.Callback)
        end
    end)
end

-- INPUT
function RAX:Input(opts)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, 0, 0, 24)
    holder.BackgroundTransparency = 1
    holder.Parent = self._parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.5, -4, 1, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.Text = opts.Title or "Input"
    label.Parent = holder

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0.5, -4, 1, 0)
    box.Position = UDim2.new(0.5, 4, 0, 0)
    box.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    box.BorderSizePixel = 0
    box.Font = Enum.Font.Gotham
    box.TextSize = 13
    box.TextColor3 = Color3.fromRGB(230, 230, 230)
    box.PlaceholderText = opts.Placeholder or ""
    box.Text = ""
    box.Parent = holder

    box.FocusLost:Connect(function(enter)
        if enter and opts.Callback then
            task.spawn(opts.Callback, box.Text)
        end
    end)
end

-- SLIDER (simple numeric)
function RAX:Slider(opts)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, 0, 0, 30)
    holder.BackgroundTransparency = 1
    holder.Parent = self._parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 14)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.Text = (opts.Title or "Slider") .. " (" .. tostring(opts.Value.Default) .. ")"
    label.Parent = holder

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, 0, 0, 8)
    bar.Position = UDim2.new(0, 0, 0, 18)
    bar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    bar.BorderSizePixel = 0
    bar.Parent = holder

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(0, 170, 85)
    fill.BorderSizePixel = 0
    fill.Parent = bar

    local uis = game:GetService("UserInputService")
    local dragging = false
    local min, max, step = opts.Value.Min, opts.Value.Max, opts.Step or 1
    local current = opts.Value.Default

    local function setValueFromX(x)
        local rel = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local raw = min + (max - min) * rel
        local snapped = math.floor(raw / step + 0.5) * step
        snapped = math.clamp(snapped, min, max)
        current = snapped
        fill.Size = UDim2.new((snapped - min) / (max - min), 0, 1, 0)
        label.Text = (opts.Title or "Slider") .. " (" .. tostring(snapped) .. ")"
        if opts.Callback then
            task.spawn(opts.Callback, snapped)
        end
    end

    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            setValueFromX(input.Position.X)
        end
    end)

    uis.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            setValueFromX(input.Position.X)
        end
    end)

    uis.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    -- init
    setValueFromX(bar.AbsolutePosition.X + bar.AbsoluteSize.X * ((current - min) / (max - min)))
end

return RAX
