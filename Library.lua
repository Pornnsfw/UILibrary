--!strict
-- GlassHub.lua
-- Reusable transparent Roblox UI library inspired by the older Aether window style.

local Library = {}
Library.__index = Library

Library.Assets = {
    Shadow = "rbxassetid://1316045217",
    Minimize = "rbxassetid://13857987062",
    Close = "rbxassetid://15082305656",
    Resize = "rbxassetid://15082210525",
    Chevron = "rbxassetid://14937709869",
    Arrow = "rbxassetid://14923748517",
    Search = "rbxassetid://13847222481",
    Textbox = "rbxassetid://13868675087",
    GlowDot = "rbxassetid://105506802034513",
    ImageLogo = "rbxassetid://111362591084511",
    FloatingToggle = "rbxassetid://99432006374500",
    Discord = "rbxassetid://119690296342461",
}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

local DEFAULT_THEME = {
    Background    = Color3.fromRGB(20, 14, 32),
    Surface       = Color3.fromRGB(36, 22, 56),
    SurfaceHover  = Color3.fromRGB(56, 34, 88),
    Stroke        = Color3.fromRGB(190, 105, 255),
    StrokeSoft    = Color3.fromRGB(125, 75, 185),
    Text          = Color3.fromRGB(255, 255, 255),
    Muted         = Color3.fromRGB(215, 185, 255),
    Accent        = Color3.fromRGB(180, 80, 255),
    Accent2       = Color3.fromRGB(225, 120, 255),
    Success       = Color3.fromRGB(60, 240, 170),
    Warning       = Color3.fromRGB(255, 205, 70),
    Danger        = Color3.fromRGB(255, 85, 115),
}

local function mergeTheme(theme: any): any
    local merged = {}
    for key, value in pairs(DEFAULT_THEME) do
        merged[key] = value
    end
    if type(theme) == "table" then
        for key, value in pairs(theme) do
            merged[key] = value
        end
    end
    return merged
end

local function tween(object: Instance, time: number, goal: { [string]: any })
    local info = TweenInfo.new(time, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    local anim = TweenService:Create(object, info, goal)
    anim:Play()
    return anim
end

local function make(className: string, props: { [string]: any }?, children: { Instance }?): any
    local object = Instance.new(className)
    if props then
        for key, value in pairs(props) do
            (object :: any)[key] = value
        end
    end
    if children then
        for _, child in ipairs(children) do
            child.Parent = object
        end
    end
    return object
end

local function corner(parent: Instance, radius: number)
    return make("UICorner", {
        CornerRadius = UDim.new(0, radius),
        Parent = parent,
    })
end

local function stroke(parent: Instance, color: Color3, thickness: number?, transparency: number?)
    return make("UIStroke", {
        Color = color,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = parent,
    })
end

local function padding(parent: Instance, left: number, top: number, right: number, bottom: number)
    return make("UIPadding", {
        PaddingLeft = UDim.new(0, left),
        PaddingTop = UDim.new(0, top),
        PaddingRight = UDim.new(0, right),
        PaddingBottom = UDim.new(0, bottom),
        Parent = parent,
    })
end

local function list(parent: Instance, paddingSize: number, direction: Enum.FillDirection?)
    return make("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, paddingSize),
        FillDirection = direction or Enum.FillDirection.Vertical,
        Parent = parent,
    })
end

local function normalizeAsset(image: any): string
    if type(image) == "number" then
        return "rbxassetid://" .. tostring(image)
    end
    if type(image) == "string" then
        if image == "" then
            return ""
        end
        if image:find("rbxassetid://") or image:find("rbxthumb://") or image:find("http") then
            return image
        end
        if Library.Assets[image] then
            return Library.Assets[image]
        end
        return "rbxassetid://" .. image
    end
    return ""
end

local function getParentGui()
    if gethui then
        local ok, h = pcall(gethui)
        if ok and h then return h end
    end
    local ok, parent = pcall(function()
        return CoreGui
    end)
    if ok and parent then
        return parent
    end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local function updateCanvas(scroll: ScrollingFrame, layout: UIListLayout, extra: number?)
    local function refresh()
        scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + (extra or 16))
    end
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(refresh)
    refresh()
end

local function addRipple(button: GuiButton, color: Color3)
    button.ClipsDescendants = true
    button.MouseButton1Down:Connect(function(x, y)
        local ripple = make("Frame", {
            Name = "Ripple",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromOffset(x - button.AbsolutePosition.X, y - button.AbsolutePosition.Y),
            Size = UDim2.fromOffset(0, 0),
            BackgroundColor3 = color,
            BackgroundTransparency = 0.7,
            BorderSizePixel = 0,
            ZIndex = button.ZIndex + 2,
            Parent = button,
        })
        corner(ripple, 100)
        local size = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 2
        tween(ripple, 0.35, {
            Size = UDim2.fromOffset(size, size),
            BackgroundTransparency = 1,
        })
        task.delay(0.4, function()
            if ripple then
                ripple:Destroy()
            end
        end)
    end)
end

local function addPopAnimation(object: GuiObject, finalTransparency: number?)
    local scale = make("UIScale", {
        Scale = 0.985,
        Parent = object,
    })
    local targetTransparency = finalTransparency or object.BackgroundTransparency
    object.BackgroundTransparency = math.min(targetTransparency + 0.16, 1)
    task.defer(function()
        if object.Parent then
            tween(scale, 0.22, { Scale = 1 })
            tween(object, 0.22, { BackgroundTransparency = targetTransparency })
        end
    end)
    return scale
end

local function bindDrag(handle: GuiObject, target: GuiObject)
    local dragging = false
    local dragInput: InputObject? = nil
    local dragStart: Vector3? = nil
    local startPosition: UDim2? = nil

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPosition = target.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input == dragInput and dragStart and startPosition then
            local delta = input.Position - dragStart
            target.Position = UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset + delta.X,
                startPosition.Y.Scale,
                startPosition.Y.Offset + delta.Y
            )
        end
    end)
end

local function createIcon(parent: Instance, image: any, size: number, color: Color3, transparency: number?)
    local asset = normalizeAsset(image)
    local icon = make("ImageLabel", {
        Name = "Icon",
        Size = UDim2.fromOffset(size, size),
        BackgroundTransparency = 1,
        Image = asset,
        ImageColor3 = color,
        ImageTransparency = transparency or 0,
        ScaleType = Enum.ScaleType.Fit,
        Visible = asset ~= "",
        Parent = parent,
    })
    return icon
end

local function createText(parent: Instance, name: string, text: string, size: number, color: Color3, bold: boolean?, order: number?)
    return make("TextLabel", {
        Name = name,
        Text = text,
        Font = bold and Enum.Font.GothamBold or Enum.Font.GothamMedium,
        TextSize = size,
        TextColor3 = color,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextWrapped = true,
        TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
        TextStrokeTransparency = bold and 0.65 or 0.78,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = order or 1,
        Parent = parent,
    })
end

local function createGlassRow(self: any, parent: Instance, title: string, desc: string?, image: any?, height: number?)
    local iconAsset = normalizeAsset(image or "")
    local hasIcon = iconAsset ~= ""
    local leftInset = hasIcon and 56 or 16

    local row = make("TextButton", {
        Name = "GlassRow",
        Text = "",
        AutoButtonColor = false,
        Size = UDim2.new(1, 0, 0, height or 56),
        BackgroundColor3 = self.Theme.Surface,
        BackgroundTransparency = 0.02,
        BorderSizePixel = 0,
        LayoutOrder = 10,
        Parent = parent,
    })
    row.ClipsDescendants = true
    corner(row, 8)
    local rowStroke = stroke(row, self.Theme.StrokeSoft, 1, 0.35)
    addPopAnimation(row, 0.02)

    local rowGlowBar = make("Frame", {
        Name = "GlowBar",
        BackgroundColor3 = self.Theme.Accent,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 8),
        Size = UDim2.new(0, 3, 1, -16),
        BackgroundTransparency = 0.45,
        ZIndex = row.ZIndex + 2,
        Parent = row,
    })
    corner(rowGlowBar, 2)

    make("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, self.Theme.Accent),
            ColorSequenceKeypoint.new(0.25, self.Theme.SurfaceHover),
            ColorSequenceKeypoint.new(1, self.Theme.Surface),
        }),
        Rotation = 0,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.82),
            NumberSequenceKeypoint.new(0.35, 0.96),
            NumberSequenceKeypoint.new(1, 1),
        }),
        Parent = row,
    })

    local iconWrap = make("Frame", {
        Name = "IconWrap",
        BackgroundColor3 = self.Theme.Background,
        BackgroundTransparency = 0.04,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(10, 10),
        Size = UDim2.fromOffset(36, 36),
        Visible = hasIcon,
        ZIndex = row.ZIndex + 1,
        Parent = row,
    })
    corner(iconWrap, 8)
    stroke(iconWrap, self.Theme.Accent, 1, 0.4)
    local icon = createIcon(iconWrap, iconAsset, 18, self.Theme.Accent, 0.05)
    icon.AnchorPoint = Vector2.new(0.5, 0.5)
    icon.Position = UDim2.fromScale(0.5, 0.5)
    icon.ZIndex = iconWrap.ZIndex + 1

    local textWrap = make("Frame", {
        Name = "TextWrap",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(leftInset, 8),
        Size = UDim2.new(1, -leftInset - 46, 1, -16),
        ZIndex = row.ZIndex + 1,
        Parent = row,
    })
    list(textWrap, 2)

    local titleLabel = createText(textWrap, "Title", title, 12, self.Theme.Text, true, 1)
    titleLabel.ZIndex = textWrap.ZIndex + 1
    if desc and desc ~= "" then
        local descLabel = createText(textWrap, "Desc", desc, 10, self.Theme.Muted, false, 2)
        descLabel.ZIndex = textWrap.ZIndex + 1
    end

    row.MouseEnter:Connect(function()
        tween(row, 0.18, { BackgroundTransparency = 0, BackgroundColor3 = self.Theme.SurfaceHover })
        tween(rowStroke, 0.18, { Color = self.Theme.Accent, Transparency = 0, Thickness = 1.3 })
        tween(rowGlowBar, 0.18, { BackgroundTransparency = 0, Size = UDim2.new(0, 4, 1, -10), Position = UDim2.fromOffset(0, 5) })
    end)
    row.MouseLeave:Connect(function()
        tween(row, 0.18, { BackgroundTransparency = 0.02, BackgroundColor3 = self.Theme.Surface })
        tween(rowStroke, 0.18, { Color = self.Theme.StrokeSoft, Transparency = 0.35, Thickness = 1 })
        tween(rowGlowBar, 0.18, { BackgroundTransparency = 0.45, Size = UDim2.new(0, 3, 1, -16), Position = UDim2.fromOffset(0, 8) })
    end)

    return row
end

local function createPageApi(window: any, scroll: ScrollingFrame)
    local api = {}

    function api:Section(props: { [string]: any })
        props = props or {}
        local section = make("Frame", {
            Name = "Section",
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            LayoutOrder = props.Order or 10,
            Parent = scroll,
        })
        list(section, 8)

        local headerWrap = make("Frame", {
            Name = "SectionHeaderWrap",
            Size = UDim2.new(1, 0, 0, 16),
            BackgroundTransparency = 1,
            LayoutOrder = 1,
            Parent = section,
        })
        local hLayout = list(headerWrap, 6, Enum.FillDirection.Horizontal)
        hLayout.VerticalAlignment = Enum.VerticalAlignment.Center

        local dot = make("Frame", {
            Name = "SectionDot",
            Size = UDim2.fromOffset(6, 6),
            BackgroundColor3 = window.Theme.Accent,
            BorderSizePixel = 0,
            Parent = headerWrap,
        })
        corner(dot, 6)
        stroke(dot, window.Theme.Accent, 1, 0.2)

        local header = make("TextLabel", {
            Name = "SectionTitle",
            Text = string.upper(tostring(props.Title or "Section")),
            Font = Enum.Font.GothamBold,
            TextSize = 10,
            TextColor3 = window.Theme.Accent,
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -16, 1, 0),
            Parent = headerWrap,
        })
        header.TextTransparency = 0.05

        local sectionApi = createPageApi(window, section :: any)
        sectionApi.Root = section
        return sectionApi
    end

    function api:Label(props: { [string]: any })
        props = props or {}
        local row = createGlassRow(window, scroll, tostring(props.Title or "Label"), props.Desc or "", props.Image or "", props.Height or 52)
        local item = {}
        function item:SetTitle(value: string)
            local titleLabel = row:FindFirstChild("Title", true)
            if titleLabel and titleLabel:IsA("TextLabel") then
                titleLabel.Text = value
            end
        end
        function item:SetDesc(value: string)
            local descLabel = row:FindFirstChild("Desc", true)
            if descLabel and descLabel:IsA("TextLabel") then
                descLabel.Text = value
            end
        end
        function item:SetVisible(value: boolean)
            row.Visible = value
        end
        return item
    end

    function api:Button(props: { [string]: any })
        props = props or {}
        local callback = props.Callback or function() end
        local row = createGlassRow(window, scroll, tostring(props.Title or "Button"), props.Desc or "", props.Image or "Arrow", props.Height or 54)
        addRipple(row, window.Theme.Accent)

        local glyph = createIcon(row, props.RightIcon or "Arrow", 18, window.Theme.Accent, 0.05)
        glyph.AnchorPoint = Vector2.new(1, 0.5)
        glyph.Position = UDim2.new(1, -16, 0.5, 0)

        row.MouseButton1Click:Connect(function()
            task.spawn(callback)
        end)

        local item = {}
        function item:SetTitle(value: string)
            local titleLabel = row:FindFirstChild("Title", true)
            if titleLabel and titleLabel:IsA("TextLabel") then
                titleLabel.Text = value
            end
        end
        function item:SetVisible(value: boolean)
            row.Visible = value
        end
        return item
    end

    function api:Toggle(props: { [string]: any })
        props = props or {}
        local value = props.Value == true
        local callback = props.Callback or function() end
        local row = createGlassRow(window, scroll, tostring(props.Title or "Toggle"), props.Desc or "", props.Image or "", props.Height or 56)
        addRipple(row, window.Theme.Accent)

        local rowGlowBar = row:FindFirstChild("GlowBar")

        local switch = make("Frame", {
            Name = "Switch",
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -14, 0.5, 0),
            Size = UDim2.fromOffset(44, 22),
            BackgroundColor3 = value and window.Theme.Success or window.Theme.StrokeSoft,
            BackgroundTransparency = value and 0.05 or 0.25,
            BorderSizePixel = 0,
            Parent = row,
        })
        corner(switch, 12)
        local switchStroke = stroke(switch, value and window.Theme.Success or window.Theme.StrokeSoft, value and 1.5 or 1, value and 0.05 or 0.35)

        local knob = make("Frame", {
            Name = "Knob",
            Size = UDim2.fromOffset(16, 16),
            Position = value and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8),
            BackgroundColor3 = window.Theme.Text,
            BorderSizePixel = 0,
            Parent = switch,
        })
        corner(knob, 10)
        local knobGlowDot = make("Frame", {
            Name = "KnobGlowDot",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(6, 6),
            BackgroundColor3 = value and window.Theme.Success or window.Theme.StrokeSoft,
            BorderSizePixel = 0,
            Parent = knob,
        })
        corner(knobGlowDot, 6)

        local knobScale = make("UIScale", {
            Scale = 1,
            Parent = knob,
        })

        local item = {}
        local function setValue(nextValue: boolean, fire: boolean?)
            value = nextValue == true
            tween(switch, 0.18, {
                BackgroundColor3 = value and window.Theme.Success or window.Theme.StrokeSoft,
                BackgroundTransparency = value and 0.05 or 0.25,
            })
            tween(switchStroke, 0.18, {
                Color = value and window.Theme.Success or window.Theme.StrokeSoft,
                Thickness = value and 1.5 or 1,
                Transparency = value and 0.05 or 0.35,
            })
            tween(knob, 0.18, {
                Position = value and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8),
            })
            tween(knobGlowDot, 0.18, {
                BackgroundColor3 = value and window.Theme.Success or window.Theme.StrokeSoft,
            })
            if rowGlowBar and rowGlowBar:IsA("Frame") then
                tween(rowGlowBar, 0.18, {
                    BackgroundColor3 = value and window.Theme.Success or window.Theme.Accent,
                    BackgroundTransparency = value and 0.05 or 0.45,
                })
            end
            tween(knobScale, 0.1, { Scale = 1.12 })
            task.delay(0.1, function()
                if knobScale.Parent then
                    tween(knobScale, 0.12, { Scale = 1 })
                end
            end)
            if fire then
                task.spawn(function()
                    callback(value)
                end)
            end
        end

        row.MouseButton1Click:Connect(function()
            setValue(not value, true)
        end)

        function item:SetValue(nextValue: boolean)
            setValue(nextValue, false)
        end
        function item:GetValue()
            return value
        end
        function item:SetVisible(nextValue: boolean)
            row.Visible = nextValue
        end
        return item
    end

    function api:Textbox(props: { [string]: any })
        props = props or {}
        local callback = props.Callback or function() end
        local row = createGlassRow(window, scroll, tostring(props.Title or "Textbox"), props.Desc or "", props.Image or "Textbox", props.Height or 66)

        local box = make("TextBox", {
            Name = "Input",
            Text = tostring(props.Value or ""),
            PlaceholderText = tostring(props.Placeholder or "Enter text"),
            Font = Enum.Font.GothamMedium,
            TextSize = 11,
            TextColor3 = window.Theme.Text,
            PlaceholderColor3 = window.Theme.Muted,
            TextXAlignment = Enum.TextXAlignment.Left,
            ClearTextOnFocus = props.ClearTextOnFocus == true or props.ClearText == true,
            BackgroundColor3 = window.Theme.Background,
            BackgroundTransparency = 0.08,
            BorderSizePixel = 0,
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -14, 0.5, 0),
            Size = UDim2.fromOffset(props.Width or 150, 30),
            Parent = row,
        })
        corner(box, 7)
        local boxStroke = stroke(box, window.Theme.StrokeSoft, 1, 0.35)
        padding(box, 8, 0, 8, 0)

        box.Focused:Connect(function()
            tween(boxStroke, 0.16, { Color = window.Theme.Accent, Transparency = 0.1 })
        end)
        box.FocusLost:Connect(function(enterPressed)
            tween(boxStroke, 0.16, { Color = window.Theme.StrokeSoft, Transparency = 0.18 })
            callback(box.Text, enterPressed)
        end)

        local item = {}
        function item:SetValue(value: string)
            box.Text = value
        end
        function item:GetValue()
            return box.Text
        end
        function item:SetPlaceholderText(value: string)
            box.PlaceholderText = value
        end
        function item:SetVisible(value: boolean)
            row.Visible = value
        end
        return item
    end

    function api:Dropdown(props: { [string]: any })
        props = props or {}
        local options = props.List or props.Options or {}
        local multi = props.Multi == true
        local title = tostring(props.Title or "Dropdown")
        local desc = tostring(props.Desc or "")
        local callback = props.Callback or function() end
        local selected = props.Value
        if selected == nil and not multi then
            selected = options[1]
        elseif selected == nil and multi then
            selected = {}
        end

        local container = make("Frame", {
            Name = "DropdownContainer",
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            LayoutOrder = 10,
            Parent = scroll,
        })
        list(container, 6)

        local row = createGlassRow(window, container, title, desc, props.Image or "", props.Height or 58)
        addRipple(row, window.Theme.Accent)

        local valueLabel = make("TextLabel", {
            Name = "Value",
            Text = multi and table.concat(selected, ", ") or tostring(selected or "Select"),
            Font = Enum.Font.GothamBold,
            TextSize = 10,
            TextColor3 = window.Theme.Accent,
            TextXAlignment = Enum.TextXAlignment.Right,
            TextTruncate = Enum.TextTruncate.AtEnd,
            TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
            TextStrokeTransparency = 0.68,
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -42, 0.5, 0),
            Size = UDim2.fromOffset(props.ValueWidth or 120, 22),
            Parent = row,
        })

        local chevron = createIcon(row, "Chevron", 18, window.Theme.Muted, 0.05)
        chevron.AnchorPoint = Vector2.new(1, 0.5)
        chevron.Position = UDim2.new(1, -14, 0.5, 0)

        local listFrame = make("Frame", {
            Name = "DropdownList",
            Size = UDim2.new(1, 0, 0, 0),
            BackgroundColor3 = window.Theme.Surface,
            BackgroundTransparency = 0.04,
            BorderSizePixel = 0,
            ClipsDescendants = true,
            Visible = false,
            LayoutOrder = 11,
            Parent = container,
        })
        corner(listFrame, 8)
        stroke(listFrame, window.Theme.Accent, 1, 0.35)
        padding(listFrame, 6, 6, 6, 6)
        local optionLayout = list(listFrame, 4)
        local listScale = make("UIScale", {
            Scale = 1,
            Parent = listFrame,
        })

        local open = false
        local buttons = {}

        local function getDropdownHeight()
            return optionLayout.AbsoluteContentSize.Y + 12
        end

        local function closeDropdown()
            open = false
            tween(listScale, 0.14, { Scale = 0.99 })
            tween(listFrame, 0.16, {
                Size = UDim2.new(1, 0, 0, 0),
                BackgroundTransparency = 1,
            })
            task.delay(0.16, function()
                if not open and listFrame.Parent then
                    listFrame.Visible = false
                end
            end)
        end

        local function openDropdown()
            open = true
            listFrame.Visible = true
            listFrame.Size = UDim2.new(1, 0, 0, 0)
            listFrame.BackgroundTransparency = 1
            listScale.Scale = 0.99
            tween(listScale, 0.18, { Scale = 1 })
            tween(listFrame, 0.2, {
                Size = UDim2.new(1, 0, 0, getDropdownHeight()),
                BackgroundTransparency = 0.04,
            })
        end

        local function selectedContains(value: any)
            if not multi or type(selected) ~= "table" then
                return selected == value
            end
            return table.find(selected, value) ~= nil
        end

        local function refreshValue()
            valueLabel.Text = multi and table.concat(selected, ", ") or tostring(selected or "Select")
            if valueLabel.Text == "" then
                valueLabel.Text = "Select"
            end
            for option, button in pairs(buttons) do
                local active = selectedContains(option)
                button.TextColor3 = active and window.Theme.Accent or window.Theme.Text
                button.BackgroundTransparency = active and 0.04 or 0.14
            end
        end

        local function addOption(option: any)
            local button = make("TextButton", {
                Name = "Option",
                Text = "  " .. tostring(option),
                Font = Enum.Font.GothamMedium,
                TextSize = 11,
                TextColor3 = selectedContains(option) and window.Theme.Accent or window.Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                TextStrokeTransparency = 0.72,
                AutoButtonColor = false,
                BackgroundColor3 = window.Theme.Background,
                BackgroundTransparency = selectedContains(option) and 0.02 or 0.1,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 27),
                Parent = listFrame,
            })
            corner(button, 6)
            addRipple(button, window.Theme.Accent)
            buttons[option] = button
            button.MouseButton1Click:Connect(function()
                if multi then
                    local pos = table.find(selected, option)
                    if pos then
                        table.remove(selected, pos)
                    else
                        table.insert(selected, option)
                    end
                else
                    selected = option
                    closeDropdown()
                end
                refreshValue()
                callback(selected)
            end)
        end

        for _, option in ipairs(options) do
            addOption(option)
        end

        row.MouseButton1Click:Connect(function()
            if open then
                closeDropdown()
            else
                openDropdown()
            end
            tween(chevron, 0.18, { Rotation = open and 180 or 0 })
        end)

        local item = {}
        function item:SetValue(value: any)
            selected = value
            refreshValue()
        end
        function item:GetValue()
            return selected
        end
        function item:Add(value: any)
            table.insert(options, value)
            addOption(value)
            refreshValue()
            if open then
                tween(listFrame, 0.16, { Size = UDim2.new(1, 0, 0, getDropdownHeight()) })
            end
        end
        function item:Clear()
            for _, child in ipairs(listFrame:GetChildren()) do
                if child:IsA("TextButton") then
                    child:Destroy()
                end
            end
            options = {}
            buttons = {}
            selected = multi and {} or nil
            refreshValue()
        end
        function item:SetVisible(value: boolean)
            container.Visible = value
        end
        return item
    end

    function api:Slider(props: { [string]: any })
        props = props or {}
        local min = tonumber(props.Min) or 0
        local max = tonumber(props.Max) or 100
        local value = tonumber(props.Value) or min
        local callback = props.Callback or function() end
        local row = createGlassRow(window, scroll, tostring(props.Title or "Slider"), props.Desc or "", props.Image or "", props.Height or 72)

        local bar = make("Frame", {
            Name = "Bar",
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -14, 0.5, 11),
            Size = UDim2.fromOffset(props.Width or 170, 5),
            BackgroundColor3 = window.Theme.StrokeSoft,
            BackgroundTransparency = 0.18,
            BorderSizePixel = 0,
            Parent = row,
        })
        corner(bar, 4)

        local fill = make("Frame", {
            Name = "Fill",
            Size = UDim2.fromScale(0, 1),
            BackgroundColor3 = window.Theme.Accent,
            BorderSizePixel = 0,
            Parent = bar,
        })
        corner(fill, 4)

        local numberLabel = make("TextLabel", {
            Name = "Number",
            Text = tostring(value),
            Font = Enum.Font.GothamBold,
            TextSize = 10,
            TextColor3 = window.Theme.Accent,
            TextXAlignment = Enum.TextXAlignment.Right,
            TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
            TextStrokeTransparency = 0.68,
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -14, 0.5, -11),
            Size = UDim2.fromOffset(170, 18),
            Parent = row,
        })

        local dragging = false
        local function setValueFromAlpha(alpha: number, fire: boolean?)
            alpha = math.clamp(alpha, 0, 1)
            value = math.floor((min + ((max - min) * alpha)) + 0.5)
            fill.Size = UDim2.fromScale((value - min) / math.max(max - min, 1), 1)
            numberLabel.Text = tostring(value)
            if fire then
                callback(value)
            end
        end

        local function fromX(x: number)
            setValueFromAlpha((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), true)
        end

        bar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                fromX(input.Position.X)
            end
        end)
        bar.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                fromX(input.Position.X)
            end
        end)

        setValueFromAlpha((value - min) / math.max(max - min, 1), false)

        local item = {}
        function item:SetValue(nextValue: number)
            value = math.clamp(nextValue, min, max)
            setValueFromAlpha((value - min) / math.max(max - min, 1), false)
        end
        function item:GetValue()
            return value
        end
        function item:SetVisible(nextValue: boolean)
            row.Visible = nextValue
        end
        return item
    end

    api.Root = scroll
    return api
end

function Library:Window(props: { [string]: any })
    props = props or {}
    local self = setmetatable({}, Library)
    self.Theme = mergeTheme(props.Theme)
    self.Tabs = {}
    self.SelectedTab = nil
    self.Keybind = (props.Config and props.Config.Keybind) or props.Keybind or Enum.KeyCode.RightControl

    local guiName = props.Name or "GlassHub"
    local existing = getParentGui():FindFirstChild(guiName)
    if existing then
        existing:Destroy()
    end

    local screenGui = make("ScreenGui", {
        Name = guiName,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = props.DisplayOrder or 999,
        Parent = getParentGui(),
    })
    if typeof(protectgui) == "function" then
        pcall(protectgui, screenGui)
    elseif typeof(syn) == "table" and typeof((syn :: any).protect_gui) == "function" then
        pcall((syn :: any).protect_gui, screenGui)
    end
    self.ScreenGui = screenGui

    local shadow = make("ImageLabel", {
        Name = "Shadow",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = props.Position or UDim2.fromScale(0.5, 0.5),
        Size = (props.Config and props.Config.Size) or props.Size or UDim2.fromOffset(520, 420),
        BackgroundTransparency = 1,
        Image = Library.Assets.Shadow,
        ImageColor3 = self.Theme.Accent,
        ImageTransparency = 0.22,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(10, 10, 118, 118),
        Parent = screenGui,
    })
    self.Shadow = shadow

    local root = make("Frame", {
        Name = "Window",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, -14, 1, -14),
        BackgroundColor3 = self.Theme.Background,
        BackgroundTransparency = props.Transparency or 0.05,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = shadow,
    })
    corner(root, 14)
    stroke(root, self.Theme.Stroke, 1.2, 0.08)
    self.Root = root

    make("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, self.Theme.SurfaceHover),
            ColorSequenceKeypoint.new(0.5, self.Theme.Surface),
            ColorSequenceKeypoint.new(1, self.Theme.Background),
        }),
        Rotation = 28,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.08),
            NumberSequenceKeypoint.new(0.45, 0.04),
            NumberSequenceKeypoint.new(1, 0.18),
        }),
        Parent = root,
    })

    local glassHighlight = make("Frame", {
        Name = "GlassHighlight",
        Position = UDim2.fromOffset(12, 10),
        Size = UDim2.new(1, -24, 0, 1),
        BackgroundColor3 = self.Theme.Text,
        BackgroundTransparency = 0.62,
        BorderSizePixel = 0,
        Parent = root,
    })
    glassHighlight.ZIndex = root.ZIndex + 1

    local header = make("Frame", {
        Name = "Header",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 58),
        Parent = root,
    })
    self.Header = header
    bindDrag(header, shadow)

    local iconWrap = make("Frame", {
        Name = "IconWrap",
        Position = UDim2.fromOffset(14, 12),
        Size = UDim2.fromOffset(34, 34),
        BackgroundColor3 = self.Theme.Surface,
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        Parent = header,
    })
    corner(iconWrap, 9)
    stroke(iconWrap, self.Theme.StrokeSoft, 1, 0.35)
    local headerIcon = createIcon(iconWrap, props.Icon or "ImageLogo", 19, self.Theme.Accent, 0)
    headerIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    headerIcon.Position = UDim2.fromScale(0.5, 0.5)

    local titleWrap = make("Frame", {
        Name = "TitleWrap",
        Position = UDim2.fromOffset(58, 9),
        Size = UDim2.new(1, -170, 0, 42),
        BackgroundTransparency = 1,
        Parent = header,
    })
    list(titleWrap, 1)

    local titleLabelRef = make("TextLabel", {
        Name = "Title",
        Text = tostring(props.Title or "Glass Hub"),
        Font = Enum.Font.GothamBold,
        TextSize = 15,
        TextColor3 = self.Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
        TextStrokeTransparency = 0.62,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 21),
        LayoutOrder = 1,
        Parent = titleWrap,
    })

    local descLabelRef = make("TextLabel", {
        Name = "Description",
        Text = tostring(props.Desc or props.Subtitle or ""),
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        TextColor3 = self.Theme.Muted,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
        TextStrokeTransparency = 0.78,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 17),
        LayoutOrder = 2,
        Parent = titleWrap,
    })

    function self:SetTitle(newTitle: string)
        titleLabelRef.Text = newTitle
    end

    function self:GetTitle(): string
        return titleLabelRef.Text
    end

    function self:SetSubtitle(newSub: string)
        descLabelRef.Text = newSub
    end
    self.SetSub = self.SetSubtitle

    function self:GetSubtitle(): string
        return descLabelRef.Text
    end

    function self:SetIcon(newIcon: any)
        headerIcon.Image = normalizeAsset(newIcon)
    end

    local controls = make("Frame", {
        Name = "Controls",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -12, 0, 12),
        Size = UDim2.fromOffset(70, 28),
        BackgroundTransparency = 1,
        Parent = header,
    })
    list(controls, 7, Enum.FillDirection.Horizontal)

    local function iconButton(name: string, image: string)
        local button = make("ImageButton", {
            Name = name,
            Image = normalizeAsset(image),
            ImageColor3 = self.Theme.Muted,
            ImageTransparency = 0.05,
            BackgroundColor3 = self.Theme.Surface,
            BackgroundTransparency = 0.12,
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(28, 28),
            AutoButtonColor = false,
            Parent = controls,
        })
        corner(button, 8)
        stroke(button, self.Theme.StrokeSoft, 1, 0.45)
        button.MouseEnter:Connect(function()
            tween(button, 0.15, { BackgroundTransparency = 0.02, ImageColor3 = self.Theme.Text })
        end)
        button.MouseLeave:Connect(function()
            tween(button, 0.15, { BackgroundTransparency = 0.12, ImageColor3 = self.Theme.Muted })
        end)
        return button
    end

    local minButton = iconButton("Minimize", "Minimize")
    local closeButton = iconButton("Close", "Close")

    local divider = make("Frame", {
        Name = "Divider",
        Position = UDim2.new(0, 12, 0, 57),
        Size = UDim2.new(1, -24, 0, 1),
        BackgroundColor3 = self.Theme.StrokeSoft,
        BackgroundTransparency = 0.28,
        BorderSizePixel = 0,
        Parent = root,
    })

    local side = make("Frame", {
        Name = "Sidebar",
        Position = UDim2.fromOffset(12, 70),
        Size = UDim2.new(0, 142, 1, -82),
        BackgroundColor3 = self.Theme.Surface,
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        Parent = root,
    })
    corner(side, 10)
    stroke(side, self.Theme.StrokeSoft, 1, 0.45)
    padding(side, 8, 8, 8, 8)
    local tabList = list(side, 6)
    tabList.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local pages = make("Frame", {
        Name = "Pages",
        Position = UDim2.fromOffset(166, 70),
        Size = UDim2.new(1, -178, 1, -82),
        BackgroundTransparency = 1,
        Parent = root,
    })

    function self:SelectTab(name: string)
        for tabName, tab in pairs(self.Tabs) do
            local selected = tabName == name
            tab.Page.Visible = selected
            tween(tab.Button, 0.16, {
                BackgroundTransparency = selected and 0 or 0.08,
                BackgroundColor3 = selected and self.Theme.SurfaceHover or self.Theme.Surface,
            })
            if tab.Stroke then
                tween(tab.Stroke, 0.16, {
                    Color = self.Theme.Accent,
                    Transparency = selected and 0.15 or 0.75,
                    Thickness = selected and 1.3 or 1,
                })
            end
            if tab.GlowBar then
                tween(tab.GlowBar, 0.16, {
                    BackgroundTransparency = selected and 0 or 1,
                })
            end
            if selected and tab.Scale then
                tween(tab.Scale, 0.1, { Scale = 1.03 })
                task.delay(0.1, function()
                    if tab.Scale.Parent then
                        tween(tab.Scale, 0.12, { Scale = 1 })
                    end
                end)
            end
            if tab.Label then
                tab.Label.TextColor3 = selected and self.Theme.Text or self.Theme.Muted
            end
            if tab.Icon then
                tab.Icon.ImageColor3 = selected and self.Theme.Accent or self.Theme.Muted
            end
        end
        self.SelectedTab = name
    end

    function self:Tab(tabProps: { [string]: any })
        tabProps = tabProps or {}
        local name = tostring(tabProps.Title or ("Tab " .. tostring(#self.Tabs + 1)))
        local tabIconAsset = normalizeAsset(tabProps.Icon or "")
        local hasTabIcon = tabIconAsset ~= ""

        local button = make("TextButton", {
            Name = "Tab_" .. name,
            Text = "",
            Font = Enum.Font.GothamBold,
            TextSize = 11,
            TextColor3 = self.Theme.Muted,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
            TextStrokeTransparency = 0.68,
            AutoButtonColor = false,
            BackgroundColor3 = self.Theme.Surface,
            BackgroundTransparency = 0.08,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 34),
            Parent = side,
        })
        corner(button, 8)
        local tabStroke = stroke(button, self.Theme.Accent, 1, 0.75)
        padding(button, hasTabIcon and 34 or 12, 0, 8, 0)
        addRipple(button, self.Theme.Accent)

        local tabGlowBar = make("Frame", {
            Name = "TabGlowBar",
            Position = UDim2.fromOffset(2, 6),
            Size = UDim2.new(0, 3, 1, -12),
            BackgroundColor3 = self.Theme.Accent,
            BorderSizePixel = 0,
            BackgroundTransparency = 1,
            ZIndex = button.ZIndex + 2,
            Parent = button,
        })
        corner(tabGlowBar, 2)

        local tabIcon = createIcon(button, tabIconAsset, 16, self.Theme.Muted, 0.04)
        tabIcon.AnchorPoint = Vector2.new(0, 0.5)
        tabIcon.Position = UDim2.new(0, 10, 0.5, 0)
        tabIcon.ZIndex = button.ZIndex + 1

        local tabLabel = make("TextLabel", {
            Name = "Label",
            Text = name,
            Font = Enum.Font.GothamBold,
            TextSize = 11,
            TextColor3 = self.Theme.Muted,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
            TextTruncate = Enum.TextTruncate.AtEnd,
            TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
            TextStrokeTransparency = 0.68,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(hasTabIcon and 34 or 10, 0),
            Size = UDim2.new(1, -(hasTabIcon and 42 or 18), 1, 0),
            ZIndex = button.ZIndex + 1,
            Parent = button,
        })
        local tabScale = make("UIScale", {
            Scale = 1,
            Parent = button,
        })

        local page = make("ScrollingFrame", {
            Name = "Page_" .. name,
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = self.Theme.Stroke,
            CanvasSize = UDim2.fromOffset(0, 0),
            Visible = false,
            Parent = pages,
        })
        padding(page, 0, 0, 6, 0)
        local pageLayout = list(page, 8)
        updateCanvas(page, pageLayout, 18)

        local pageApi = createPageApi(self, page)
        pageApi.Name = name
        local window = self

        local subTabs = {}
        local selectedSubTab: string? = nil
        local subTabCount = 0
        local subTabNav: Frame? = nil
        local subTabPages: Frame? = nil

        local function ensureSubTabHost()
            if subTabNav and subTabPages then
                return subTabNav, subTabPages
            end

            subTabNav = make("Frame", {
                Name = "SubTabs",
                Size = UDim2.new(1, 0, 0, 34),
                BackgroundColor3 = self.Theme.Surface,
                BackgroundTransparency = 0.08,
                BorderSizePixel = 0,
                LayoutOrder = 2,
                Parent = page,
            })
            corner(subTabNav, 8)
            stroke(subTabNav, self.Theme.StrokeSoft, 1, 0.18)
            padding(subTabNav, 6, 5, 6, 5)
            local navLayout = list(subTabNav, 6, Enum.FillDirection.Horizontal)
            navLayout.VerticalAlignment = Enum.VerticalAlignment.Center

            subTabPages = make("Frame", {
                Name = "SubTabPages",
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                LayoutOrder = 3,
                Parent = page,
            })
            list(subTabPages, 8)

            return subTabNav, subTabPages
        end

        local function selectSubTab(subName: string)
            for currentName, subTab in pairs(subTabs) do
                local selected = currentName == subName
                subTab.Page.Visible = selected
            tween(subTab.Button, 0.16, {
                BackgroundTransparency = selected and 0 or 0.08,
                BackgroundColor3 = selected and self.Theme.Accent2 or self.Theme.Surface,
            })
            if selected and subTab.Scale then
                tween(subTab.Scale, 0.1, { Scale = 1.03 })
                task.delay(0.1, function()
                    if subTab.Scale.Parent then
                        tween(subTab.Scale, 0.12, { Scale = 1 })
                    end
                end)
            end
                if subTab.Label then
                    subTab.Label.TextColor3 = selected and self.Theme.Text or self.Theme.Muted
                end
                if subTab.Icon then
                    subTab.Icon.ImageColor3 = selected and self.Theme.Accent or self.Theme.Muted
                end
            end
            selectedSubTab = subName
        end

        function pageApi:SelectSubTab(subName: string)
            if subTabs[subName] then
                selectSubTab(subName)
            end
        end

        function pageApi:SubTab(subProps: { [string]: any })
            subProps = subProps or {}
            subTabCount += 1
            local subName = tostring(subProps.Title or subProps.Name or ("SubTab " .. tostring(subTabCount)))
            local subIconAsset = normalizeAsset(subProps.Icon or "")
            local hasSubIcon = subIconAsset ~= ""
            local nav, content = ensureSubTabHost()

            local subButton = make("TextButton", {
                Name = "SubTab_" .. subName,
                Text = "",
                Font = Enum.Font.GothamBold,
                TextSize = 10,
                TextColor3 = window.Theme.Muted,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                TextStrokeTransparency = 0.68,
                AutoButtonColor = false,
                BackgroundColor3 = window.Theme.Surface,
                BackgroundTransparency = 0.08,
                BorderSizePixel = 0,
                Size = UDim2.new(0, subProps.Width or 104, 1, 0),
                Parent = nav,
            })
            corner(subButton, 7)
            padding(subButton, hasSubIcon and 28 or 10, 0, 8, 0)
            addRipple(subButton, window.Theme.Accent)

            local subIcon = createIcon(subButton, subIconAsset, 14, window.Theme.Muted, 0.04)
            subIcon.AnchorPoint = Vector2.new(0, 0.5)
            subIcon.Position = UDim2.new(0, 8, 0.5, 0)
            subIcon.ZIndex = subButton.ZIndex + 1

            local subLabel = make("TextLabel", {
                Name = "Label",
                Text = subName,
                Font = Enum.Font.GothamBold,
                TextSize = 10,
                TextColor3 = window.Theme.Muted,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Center,
                TextTruncate = Enum.TextTruncate.AtEnd,
                TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                TextStrokeTransparency = 0.68,
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(hasSubIcon and 28 or 10, 0),
                Size = UDim2.new(1, -(hasSubIcon and 36 or 18), 1, 0),
                ZIndex = subButton.ZIndex + 1,
                Parent = subButton,
            })
            local subScale = make("UIScale", {
                Scale = 1,
                Parent = subButton,
            })

            local subPage = make("Frame", {
                Name = "SubPage_" .. subName,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Visible = false,
                Parent = content,
            })
            list(subPage, 8)

            local subApi = createPageApi(window, subPage :: any)
            subApi.Name = subName
            subApi.ParentTab = pageApi

            subTabs[subName] = {
                Button = subButton,
                Label = subLabel,
                Icon = subIcon,
                Scale = subScale,
                Page = subPage,
                Api = subApi,
            }

            subButton.MouseButton1Click:Connect(function()
                selectSubTab(subName)
            end)

            if not selectedSubTab then
                selectSubTab(subName)
            end

            return subApi
        end

        pageApi.Subtab = pageApi.SubTab
        pageApi.CreateSubTab = pageApi.SubTab
        pageApi.CreateSubtab = pageApi.SubTab

        self.Tabs[name] = {
            Button = button,
            Label = tabLabel,
            Icon = tabIcon,
            Scale = tabScale,
            Page = page,
            Api = pageApi,
            SubTabs = subTabs,
            Stroke = tabStroke,
            GlowBar = tabGlowBar,
        }

        button.MouseButton1Click:Connect(function()
            self:SelectTab(name)
        end)

        if not self.SelectedTab then
            self:SelectTab(name)
        end

        return pageApi
    end

    function self:Confirm(props: { [string]: any })
        props = props or {}
        local callback = props.Callback or props.ConfirmCallback or function() end
        local cancelCallback = props.CancelCallback or function() end
        local existingOverlay = root:FindFirstChild("ConfirmOverlay")
        if existingOverlay then
            existingOverlay:Destroy()
        end

        local overlay = make("Frame", {
            Name = "ConfirmOverlay",
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 80,
            Parent = root,
        })

        local modal = make("Frame", {
            Name = "ConfirmModal",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.52),
            Size = UDim2.fromOffset(props.Width or 310, props.Height or 150),
            BackgroundColor3 = self.Theme.Surface,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 81,
            Parent = overlay,
        })
        corner(modal, 12)
        stroke(modal, props.Color or self.Theme.Accent, 1.2, 0.08)
        padding(modal, 14, 12, 14, 12)

        make("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, self.Theme.SurfaceHover),
                ColorSequenceKeypoint.new(1, self.Theme.Surface),
            }),
            Rotation = 30,
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.04),
                NumberSequenceKeypoint.new(1, 0.18),
            }),
            Parent = modal,
        })

        local modalScale = make("UIScale", {
            Scale = 0.94,
            Parent = modal,
        })

        local title = createText(modal, "Title", tostring(props.Title or "Are you sure?"), 14, self.Theme.Text, true, 1)
        title.Position = UDim2.fromOffset(0, 0)
        title.Size = UDim2.new(1, 0, 0, 22)
        title.ZIndex = modal.ZIndex + 1

        local desc = createText(modal, "Desc", tostring(props.Desc or props.Message or "Confirm this action."), 11, self.Theme.Muted, false, 2)
        desc.Position = UDim2.fromOffset(0, 28)
        desc.Size = UDim2.new(1, 0, 0, 40)
        desc.ZIndex = modal.ZIndex + 1

        local actions = make("Frame", {
            Name = "Actions",
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, 0, 1, 0),
            Size = UDim2.fromOffset(180, 32),
            BackgroundTransparency = 1,
            ZIndex = modal.ZIndex + 1,
            Parent = modal,
        })
        local actionsLayout = list(actions, 8, Enum.FillDirection.Horizontal)
        actionsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right

        local function makeActionButton(name: string, text: string, color: Color3)
            local button = make("TextButton", {
                Name = name,
                Text = text,
                Font = Enum.Font.GothamBold,
                TextSize = 11,
                TextColor3 = self.Theme.Text,
                TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
                TextStrokeTransparency = 0.72,
                AutoButtonColor = false,
                BackgroundColor3 = color,
                BackgroundTransparency = 0.08,
                BorderSizePixel = 0,
                Size = UDim2.fromOffset(86, 32),
                ZIndex = actions.ZIndex + 1,
                Parent = actions,
            })
            corner(button, 8)
            stroke(button, color, 1, 0.2)
            addRipple(button, self.Theme.Text)
            button.MouseEnter:Connect(function()
                tween(button, 0.15, { BackgroundTransparency = 0 })
            end)
            button.MouseLeave:Connect(function()
                tween(button, 0.15, { BackgroundTransparency = 0.08 })
            end)
            return button
        end

        local cancelButton = makeActionButton("Cancel", tostring(props.CancelText or "Cancel"), self.Theme.StrokeSoft)
        local confirmButton = makeActionButton("Confirm", tostring(props.ConfirmText or "Confirm"), props.Color or self.Theme.Accent)

        local closed = false
        local function close(runConfirm: boolean)
            if closed then
                return
            end
            closed = true
            tween(overlay, 0.16, { BackgroundTransparency = 1 })
            tween(modal, 0.16, { BackgroundTransparency = 1, Position = UDim2.fromScale(0.5, 0.52) })
            tween(modalScale, 0.16, { Scale = 0.94 })
            task.delay(0.17, function()
                if overlay.Parent then
                    overlay:Destroy()
                end
                if runConfirm then
                    task.spawn(callback)
                else
                    task.spawn(cancelCallback)
                end
            end)
        end

        cancelButton.MouseButton1Click:Connect(function()
            close(false)
        end)
        confirmButton.MouseButton1Click:Connect(function()
            close(true)
        end)

        tween(overlay, 0.18, { BackgroundTransparency = 0.42 })
        tween(modal, 0.2, { BackgroundTransparency = 0.04, Position = UDim2.fromScale(0.5, 0.5) })
        tween(modalScale, 0.2, { Scale = 1 })

        return {
            Overlay = overlay,
            Modal = modal,
            Close = close,
        }
    end

    function self:Notify(props: { [string]: any })
        props = props or {}
        local toastPosition = props.Position or UDim2.new(0, 14, 1, -14)
        local toast = make("Frame", {
            Name = "Toast",
            AnchorPoint = Vector2.new(0, 1),
            Position = toastPosition,
            Size = UDim2.fromOffset(props.Width or 270, props.Height or 76),
            BackgroundColor3 = self.Theme.Surface,
            BackgroundTransparency = 0.04,
            BorderSizePixel = 0,
            ZIndex = 50,
            Parent = root,
        })
        corner(toast, 10)
        stroke(toast, props.Color or self.Theme.Accent, 1, 0.2)
        padding(toast, 12, 9, 12, 9)
        list(toast, 3)
        createText(toast, "Title", tostring(props.Title or "Notification"), 12, props.Color or self.Theme.Text, true, 1)
        createText(toast, "Message", tostring(props.Desc or props.Message or ""), 10, self.Theme.Muted, false, 2)
        toast.BackgroundTransparency = 1
        toast.Position = UDim2.new(0, -290, 1, -14)
        tween(toast, 0.25, {
            BackgroundTransparency = 0.04,
            Position = toastPosition,
        })
        task.delay(props.Duration or 3, function()
            if toast.Parent then
                tween(toast, 0.2, {
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, -290, 1, -14),
                })
                task.wait(0.22)
                toast:Destroy()
            end
        end)
        return toast
    end

    function self:SetVisible(value: boolean)
        shadow.Visible = value
    end

    function self:Destroy()
        screenGui:Destroy()
    end

    function self:SetUIToggleKeybind(keyCode: Enum.KeyCode)
        self.Keybind = keyCode
    end

    function self:GetUIToggleKeybind()
        return self.Keybind
    end

    local minimized = false
    minButton.MouseButton1Click:Connect(function()
        minimized = not minimized
        side.Visible = not minimized
        pages.Visible = not minimized
        divider.Visible = not minimized
        tween(shadow, 0.22, {
            Size = minimized and UDim2.fromOffset(shadow.AbsoluteSize.X, 74) or ((props.Config and props.Config.Size) or props.Size or UDim2.fromOffset(520, 420)),
        })
    end)

    closeButton.MouseButton1Click:Connect(function()
        if props.CloseConfirm == false then
            screenGui:Destroy()
            return
        end

        self:Confirm({
            Title = props.CloseTitle or "Close UI?",
            Desc = props.CloseDesc or "Are you sure you want to close this menu?",
            ConfirmText = props.CloseConfirmText or "Close",
            CancelText = props.CloseCancelText or "Cancel",
            Color = self.Theme.Danger,
            Callback = function()
                screenGui:Destroy()
            end,
        })
    end)

    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then
            return
        end
        if input.KeyCode == self.Keybind then
            shadow.Visible = not shadow.Visible
        end
    end)

    root.Size = UDim2.new(1, -24, 1, -24)
    tween(root, 0.18, {
        Size = UDim2.new(1, -14, 1, -14),
    })

    return self
end

return Library
