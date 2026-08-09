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

function Helpers:ConfigureEditBox(editBox, options)
    if not editBox then
        return
    end

    options = options or {}
    editBox:EnableMouse(true)
    editBox:SetAutoFocus(options.autoFocus == true)
    if editBox.SetAltArrowKeyMode then
        editBox:SetAltArrowKeyMode(false)
    end
end

function Helpers:ConnectScrollableEditBox(editBox, scrollFrame)
    if not editBox or not scrollFrame then
        return
    end

    self:ConfigureEditBox(editBox)
    editBox:SetScript("OnCursorChanged", function(_, _, y, _, cursorHeight)
        local cursorTop = -y
        local cursorBottom = cursorTop + (cursorHeight or 0)
        local offset = scrollFrame:GetVerticalScroll()
        local height = scrollFrame:GetHeight()

        if cursorTop < offset then
            scrollFrame:SetVerticalScroll(math.max(cursorTop, 0))
        elseif cursorBottom > offset + height then
            scrollFrame:SetVerticalScroll(math.max(cursorBottom - height, 0))
        end
    end)

    scrollFrame:EnableMouse(true)
    scrollFrame:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton" and not editBox:HasFocus() then
            editBox:SetFocus()
            editBox:SetCursorPosition(editBox:GetNumLetters())
        end
    end)
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

function Helpers:ShowTooltip(owner, title, text)
    if not owner or not GameTooltip then
        return
    end

    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    if title and title ~= "" then
        GameTooltip:SetText(title, 1, 0.82, 0, true)
    end
    if text and text ~= "" then
        GameTooltip:AddLine(text, 0.82, 0.86, 0.92, true)
    end
    GameTooltip:Show()
end

function Helpers:HideTooltip()
    if GameTooltip then
        GameTooltip:Hide()
    end
end

function Helpers:SetButtonTooltip(button, title, text)
    if not button then
        return
    end

    button.macroStudioTooltipTitle = title
    button.macroStudioTooltipText = text
    if button.macroStudioTooltipInstalled then
        return
    end

    button.macroStudioTooltipInstalled = true
    button:HookScript("OnEnter", function(owner)
        local tooltipTitle = owner.macroStudioTooltipTitle
        local tooltipText = owner.macroStudioTooltipText
        if tooltipTitle or tooltipText then
            Helpers:ShowTooltip(owner, tooltipTitle, tooltipText)
        end
    end)
    button:HookScript("OnLeave", function()
        Helpers:HideTooltip()
    end)
end

function Helpers:SetButtonEnabled(button, enabled)
    if not button then
        return
    end

    enabled = enabled and true or false
    button:SetEnabled(enabled)
    button:SetAlpha(enabled and 1 or 0.45)
    if button.Text then
        button.Text:SetTextColor(enabled and 1 or 0.5, enabled and 0.82 or 0.5, enabled and 0 or 0.5)
    end
end
