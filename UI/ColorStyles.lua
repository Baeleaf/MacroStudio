local _, MacroStudio = ...
local Theme = MacroStudio.Theme

Theme.colorStyles = {
    { id = "warcraft", name = "Warcraft (default)", appearance = "warcraft" },
    { id = "legacy", name = "Legacy", appearance = "legacy", swatch = { 0.35, 0.72, 1 } },
    { id = "emerald", appearance = "warcraft", name = "Emerald", color = { 0.35, 0.85, 0.60 } },
    { id = "violet", appearance = "warcraft", name = "Violet", color = { 0.76, 0.55, 1 } },
    { id = "ember", appearance = "warcraft", name = "Ember", color = { 1, 0.56, 0.30 } },
}

local defaults = {
    windowTint = { 0.78, 0.68, 0.53, 1 }, workbench = { 0.072, 0.064, 0.055, 1 },
    materialTint = { 0.9, 0.82, 0.71, 0.24 }, editorBackground = { 0.025, 0.023, 0.02, 1 },
    editorRim = { 0.9, 0.81, 0.65, 1 }, insetTint = { 0.7, 0.61, 0.48, 1 },
    insetBorder = { 0.6, 0.52, 0.4, 1 }, selection = { 0.65, 0.47, 0.2, 0.8 },
    hover = { 0.55, 0.43, 0.24, 0.25 }, rowRule = { 0.025, 0.022, 0.018, 0.6 },
    buttonPushed = { 0.72, 0.58, 0.36, 1 }, buttonHighlight = { 1, 0.8, 0.4, 0.45 },
    inputFocus = { 1, 0.88, 0.6, 1 }, inputIdle = { 0.82, 0.76, 0.63, 1 },
    sectionRule = { 0.36, 0.3, 0.22, 1 },
    legacyWindow = { 0.025, 0.03, 0.045, 0.99 }, legacyBorder = { 0.25, 0.3, 0.38, 1 },
    legacyTitle = { 0.35, 0.75, 1, 1 }, legacyEditor = { 0.018, 0.024, 0.035, 1 },
    legacyPanel = { 0.045, 0.055, 0.075, 0.98 }, legacyRow = { 0.06, 0.075, 0.1, 1 },
    legacySelected = { 0.12, 0.24, 0.34, 1 }, legacyHover = { 0.1, 0.16, 0.22, 1 },
    legacyFavorite = { 0.12, 0.22, 0.31, 1 },
}
for key, color in pairs(defaults) do Theme.palette[key] = color end

local function findStyle(id)
    for _, style in ipairs(Theme.colorStyles) do
        if style.id == id then return style end
    end
end

function Theme:GetColorStyle()
    local settings = MacroStudio.db.settings
    local style = findStyle(settings.style)
    if not style then
        -- Upgrade the former design + color pair to a single named choice.
        local oldColors = type(settings.colorStyles) == "table" and settings.colorStyles or {}
        local oldStyle = oldColors[settings.appearance]
        local id = settings.appearance == "legacy" and "legacy"
            or (oldStyle == "frost" and "legacy" or oldStyle)
        style = findStyle(id) or self.colorStyles[1]
        settings.style = style.id
    end
    settings.appearance = style.appearance
    return style
end

function Theme:SetColorStyle(id)
    local style = findStyle(id)
    if not style then return false end
    local settings = MacroStudio.db.settings
    settings.style = id
    settings.appearance = style.appearance
    return true
end

function Theme:ApplyColorStyle()
    local style = self:GetColorStyle()
    self.activeColorStyle = style.id
    if not style.color then return end
    local r, g, b = unpack(style.color)
    local function set(key, red, green, blue, alpha)
        local color = self.palette[key]
        color[1], color[2], color[3], color[4] = red, green, blue, alpha or 1
    end
    for _, key in ipairs({ "gold", "focus", "metal", "legacyTitle" }) do set(key, r, g, b) end
    set("text", 0.88 + r * 0.08, 0.88 + g * 0.08, 0.88 + b * 0.08)
    set("secondary", 0.68 + r * 0.12, 0.68 + g * 0.12, 0.68 + b * 0.12)
    set("border", r * 0.25, g * 0.25, b * 0.25)
    for _, key in ipairs({ "windowTint", "editorRim", "insetTint", "insetBorder", "inputFocus", "inputIdle", "buttonPushed", "legacyBorder" }) do
        set(key, 0.3 + r * 0.6, 0.3 + g * 0.6, 0.3 + b * 0.6)
    end
    set("selection", r * 0.8, g * 0.8, b * 0.8, 0.8)
    set("hover", r * 0.65, g * 0.65, b * 0.65, 0.25)
    set("materialTint", r, g, b, 0.24)
    set("buttonHighlight", r, g, b, 0.45)
    set("sectionRule", r * 0.4, g * 0.4, b * 0.4)
    for _, key in ipairs({ "workbench", "legacyWindow", "legacyPanel", "legacyRow" }) do
        set(key, 0.025 + r * 0.045, 0.025 + g * 0.045, 0.025 + b * 0.045)
    end
    for _, key in ipairs({ "editorBackground", "legacyEditor" }) do
        set(key, 0.012 + r * 0.012, 0.012 + g * 0.012, 0.012 + b * 0.012)
    end
    for _, key in ipairs({ "legacySelected", "legacyFavorite", "legacyHover" }) do
        set(key, 0.04 + r * 0.18, 0.04 + g * 0.18, 0.04 + b * 0.18)
    end
end
