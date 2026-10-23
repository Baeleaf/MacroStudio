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
    local scrollBar = CreateFrame("EventFrame", nil, parent, MacroStudio.Theme.resources.scrollBar)
    scrollBar:SetWidth(25)
    scrollBar:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -inset, -inset)
    scrollBar:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -inset, inset)
    scrollBar:SetHideIfUnscrollable(true)

    host:SetPoint("TOPLEFT", parent, "TOPLEFT", inset, -inset)
    host:SetPoint("BOTTOMRIGHT", scrollBar, "BOTTOMLEFT", -4, 0)

    local editBox = host:GetEditBox()
    local scrollBox = host:GetScrollBox()
    ScrollUtil.RegisterScrollBoxWithScrollBar(scrollBox, scrollBar)
    scrollBar:SetFrameLevel(host:GetFrameLevel() + 10)
    MacroStudio.Theme:ScrollBar(scrollBar)

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
    return MacroStudio.Theme:CreateInset(parent)
end

function Helpers:CreateRegion(parent)
    return MacroStudio.Theme:CreateRegion(parent)
end

function Helpers:CreateWindow(parent)
    return MacroStudio.Theme:CreateWindow(nil, parent)
end

function Helpers:CreateEditorInset(parent)
    return MacroStudio.Theme:CreateInset(parent, true)
end

function Helpers:CreateButton(parent, name, role)
    local button = CreateFrame("Button", name, parent, MacroStudio.Theme.resources.button)
    MacroStudio.Theme:Button(button, role)
    return button
end

function Helpers:CreateInput(parent)
    local box = CreateFrame("EditBox", nil, parent, MacroStudio.Theme.resources.input)
    MacroStudio.Theme:Input(box)
    return box
end

function Helpers:CreateTab(parent)
    return CreateFrame("Button", nil, parent, MacroStudio.Theme.resources.tab)
end

function Helpers:CreateScrollFrame(parent)
    local frame = CreateFrame("ScrollFrame", nil, parent)
    frame:EnableMouseWheel(true)
    local bar = CreateFrame("EventFrame", nil, frame, MacroStudio.Theme.resources.scrollBar)
    bar:SetWidth(25)
    bar:SetPoint("TOPLEFT", frame, "TOPRIGHT", 2, 0)
    bar:SetPoint("BOTTOMLEFT", frame, "BOTTOMRIGHT", 2, 0)
    bar:SetHideIfUnscrollable(false)
    frame.ScrollBar = bar
    ScrollUtil.InitScrollFrameWithScrollBar(frame, bar)
    MacroStudio.Theme:ScrollBar(bar)
    return frame
end

function Helpers:CreateLabel(parent, fontObject, text)
    local label = parent:CreateFontString(nil, "OVERLAY", fontObject or "GameFontNormal")
    MacroStudio.Theme:Label(label, fontObject)
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
        local color = MacroStudio.Theme.palette.text
        GameTooltip:AddLine(text, color[1], color[2], color[3], true)
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
    MacroStudio.Theme:SetButtonState(button, enabled)
end
