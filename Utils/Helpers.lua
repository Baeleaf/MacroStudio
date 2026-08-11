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

function Helpers:GetIconIdentity(icon)
    if type(icon) == "number" then
        return "file:" .. tostring(icon)
    end
    if type(icon) ~= "string" or icon == "" then
        return nil
    end

    if type(GetFileIDFromPath) == "function" then
        local ok, fileId = pcall(GetFileIDFromPath, icon)
        if ok and type(fileId) == "number" and fileId > 0 then
            return "file:" .. tostring(fileId)
        end
    end

    local normalized = icon:lower():gsub("/", "\\"):gsub("%.blp$", ""):gsub("%.tga$", "")
    local basename = normalized:match("([^\\]+)$") or normalized
    if basename == "inv_misc_questionmark" then
        return "file:" .. tostring(MacroStudio.DEFAULT_ICON)
    end
    return "path:" .. normalized
end

function Helpers:IconsEqual(first, second)
    if first == second then
        return true
    end
    local firstIdentity = self:GetIconIdentity(first)
    return firstIdentity ~= nil and firstIdentity == self:GetIconIdentity(second)
end

function Helpers:ConfigureEditBox(editBox, options)
    if not editBox then
        return
    end

    options = options or {}
    editBox:EnableMouse(true)
    if editBox.SetMouseClickEnabled then
        editBox:SetMouseClickEnabled(true)
    end
    if editBox.SetMouseMotionEnabled then
        editBox:SetMouseMotionEnabled(true)
    end
    editBox:SetAutoFocus(options.autoFocus == true)
    if editBox.SetAltArrowKeyMode then
        editBox:SetAltArrowKeyMode(false)
    end
end

function Helpers:CreateNativeScrollingEditBox(parent, inset)
    if not ScrollUtil or not ScrollUtil.RegisterScrollBoxWithScrollBar then
        error("MacroStudio requires Retail's ScrollingEditBoxTemplate support.")
    end

    inset = tonumber(inset) or 5
    local host = CreateFrame("Frame", nil, parent, "ScrollingEditBoxTemplate")
    local scrollBar = CreateFrame("EventFrame", nil, parent, "MinimalScrollBar")
    scrollBar:SetWidth(12)
    scrollBar:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -inset, -inset)
    scrollBar:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -inset, inset)
    scrollBar:SetHideIfUnscrollable(true)

    host:SetPoint("TOPLEFT", parent, "TOPLEFT", inset, -inset)
    host:SetPoint("BOTTOMRIGHT", scrollBar, "BOTTOMLEFT", -4, 0)

    local editBox = host:GetEditBox()
    local scrollBox = host:GetScrollBox()
    ScrollUtil.RegisterScrollBoxWithScrollBar(scrollBox, scrollBar)
    scrollBar:SetFrameLevel(host:GetFrameLevel() + 10)

    self:ConfigureEditBox(editBox)
    editBox:SetMultiLine(true)
    editBox:SetMaxLetters(0)
    editBox:SetCountInvisibleLetters(false)
    if editBox.SetHistoryLines then
        editBox:SetHistoryLines(0)
    end

    return host, editBox, scrollBox, scrollBar
end

function Helpers:ResetNativeScrollingEditBox(scrollBox)
    if scrollBox and scrollBox.ScrollToBegin then
        scrollBox:ScrollToBegin()
    end
end

function Helpers:CreateOverlayBorder(parent, aboveFrame, thickness)
    if not parent then
        return nil, {}
    end

    thickness = math.max(1, tonumber(thickness) or 1)
    local overlay = CreateFrame("Frame", nil, parent)
    overlay:SetAllPoints(parent)
    overlay:SetFrameLevel(math.max(parent:GetFrameLevel(), aboveFrame and aboveFrame:GetFrameLevel() or 0) + 1)
    overlay:EnableMouse(false)

    local top = overlay:CreateTexture(nil, "OVERLAY")
    top:SetPoint("TOPLEFT")
    top:SetPoint("TOPRIGHT")
    top:SetHeight(thickness)

    local bottom = overlay:CreateTexture(nil, "OVERLAY")
    bottom:SetPoint("BOTTOMLEFT")
    bottom:SetPoint("BOTTOMRIGHT")
    bottom:SetHeight(thickness)

    local left = overlay:CreateTexture(nil, "OVERLAY")
    left:SetPoint("TOPLEFT")
    left:SetPoint("BOTTOMLEFT")
    left:SetWidth(thickness)

    local right = overlay:CreateTexture(nil, "OVERLAY")
    right:SetPoint("TOPRIGHT")
    right:SetPoint("BOTTOMRIGHT")
    right:SetWidth(thickness)

    return overlay, { top, right, bottom, left }
end

function Helpers:SetOverlayBorderColor(edges, red, green, blue, alpha)
    for _, edge in ipairs(edges or {}) do
        edge:SetColorTexture(red, green, blue, alpha or 1)
    end
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
        selectedIcon = macro.selectedIcon,
        body = macro.body,
        scope = macro.scope,
        duplicateName = macro.duplicateName,
        duplicateCount = macro.duplicateCount,
        source = macro.source,
        characterKey = macro.characterKey,
        characterGUID = macro.characterGUID,
        characterName = macro.characterName,
        realm = macro.realm,
        characterDisplayName = macro.characterDisplayName,
        lastSynced = macro.lastSynced,
        snapshotOrder = macro.snapshotOrder,
        identityCertain = macro.identityCertain,
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
        GameTooltip:SetText(title, 1, 0.82, 0, 1, true)
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
    if button.macroStudioTooltipInstalled == true then
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
