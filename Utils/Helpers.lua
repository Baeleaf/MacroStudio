local _, MacroStudio = ...

local Helpers = {}
MacroStudio.Helpers = Helpers

function Helpers:Trim(value)
    if type(value) ~= "string" then
        return ""
    end
    return value:match("^%s*(.-)%s*$") or ""
end

function Helpers:FirstLine(value, maximumLength)
    local text = type(value) == "string" and value or ""
    text = text:match("([^\r\n]*)") or ""
    text = self:Trim(text)

    if maximumLength and #text > maximumLength then
        return text:sub(1, maximumLength - 3) .. "..."
    end
    return text
end

function Helpers:TextLength(value)
    local text = type(value) == "string" and value or ""
    if type(strlenutf8) == "function" then
        return strlenutf8(text)
    end
    return #text
end

function Helpers:Clamp(value, minimum, maximum)
    value = tonumber(value) or minimum
    if value < minimum then
        return minimum
    end
    if value > maximum then
        return maximum
    end
    return value
end

function Helpers:CopyMacro(macro)
    if type(macro) ~= "table" then
        return nil
    end

    return {
        index = macro.index,
        name = macro.name,
        icon = macro.icon,
        body = macro.body,
        scope = macro.scope,
        duplicateName = macro.duplicateName,
        duplicateCount = macro.duplicateCount,
    }
end

function Helpers:CreatePanel(parent)
    local panel = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    panel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    panel:SetBackdropColor(0.045, 0.055, 0.075, 0.98)
    panel:SetBackdropBorderColor(0.18, 0.22, 0.28, 1)
    return panel
end

function Helpers:CreateLabel(parent, fontObject, text)
    local label = parent:CreateFontString(nil, "OVERLAY", fontObject or "GameFontNormal")
    label:SetText(text or "")
    return label
end

function Helpers:SetButtonEnabled(button, enabled)
    if not button then
        return
    end

    button:SetEnabled(enabled and true or false)
    if button.Text then
        button.Text:SetTextColor(enabled and 1 or 0.5, enabled and 0.82 or 0.5, enabled and 0 or 0.5)
    end
end
