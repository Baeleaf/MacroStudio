local _, MacroStudio = ...
local Theme = {}
MacroStudio.Theme = Theme
-- Retail frame construction. Regions share one inset; no per-column borders.
Theme.palette = {
    gold = { 1, 0.82, 0, 1 }, text = { 0.9, 0.85, 0.74, 1 },
    muted = { 0.6, 0.57, 0.51, 1 }, metal = { 0.92, 0.78, 0.55, 1 },
    secondary = { 0.74, 0.70, 0.63, 1 }, version = { 0.52, 0.49, 0.43, 1 },
    border = { 0.18, 0.16, 0.12, 1 }, focus = { 0.56, 0.43, 0.23, 1 },
    warning = { 0.94, 0.68, 0.3, 1 }, error = { 0.9, 0.36, 0.3, 1 },
    success = { 0.55, 0.73, 0.43, 1 },
}
Theme.spacing = { margin = 14, gap = 8, title = 24, row = 44, navigation = 24 }
Theme.icon = "Interface\\AddOns\\MacroStudio\\Media\\MacroStudioIcon.tga"
Theme.resources = {
    window = "PortraitFrameTemplate", dialog = "DefaultPanelTemplate",
    inset = "InsetFrameTemplate", editor = "InsetFrameTemplate3",
    button = "UIPanelButtonGrayTemplate", input = "InputBoxTemplate",
    tab = "PanelTopTabButtonTemplate", scrollingEditor = "ScrollingEditBoxTemplate",
    scrollBar = "WowTrimScrollBar",
}
local function tint(texture, color)
    if texture then texture:SetVertexColor(unpack(color)) end
end

function Theme:CreateWindow(name, parent, portrait)
    local frame = CreateFrame("Frame", name, parent or UIParent, portrait and self.resources.window or self.resources.dialog)
    -- Wide sculpted corners, bevels, highlights and shadows are native art.
    frame.NineSlice:SetBorderColor(unpack(self.palette.metal))
    frame.NineSlice:SetFrameLevel(frame:GetFrameLevel() + 5)
    frame.NineSlice:EnableMouse(false)
    frame.Bg:SetVertexColor(unpack(self.palette.windowTint))
    if frame.TopTileStreaks then frame.TopTileStreaks:SetAlpha(0.6) end
    frame.TitleContainer:SetFrameLevel(frame:GetFrameLevel() + 8)
    local band = frame:CreateTexture(nil, "BACKGROUND", nil, -4)
    band:SetPoint("TOPLEFT", 4, -1)
    band:SetPoint("TOPRIGHT", -24, -1)
    band:SetHeight(22)
    band:SetAtlas("_UI-Frame-TitleTileBg")
    band:SetHorizTile(true)
    if portrait then
        frame.PortraitContainer:SetFrameLevel(frame:GetFrameLevel() + 6)
        local emblem = frame.PortraitContainer.portrait
        emblem:SetSize(46, 46)
        emblem:ClearAllPoints()
        emblem:SetPoint("TOPLEFT", frame, "TOPLEFT", 3, 0)
        emblem:SetTexture(self.icon)
        -- The original emblem already has a transparent circular silhouette.
        emblem:RemoveMaskTexture(frame.PortraitContainer.CircleMask)
        frame.macroStudioEmblem = emblem
    end
    return frame
end

function Theme:Dialog(frame, title)
    frame.TitleContainer.TitleText:Hide()
    title:SetParent(frame.TitleContainer)
    title:ClearAllPoints()
    title:SetPoint("LEFT", frame.TitleContainer, "LEFT", 0, 0)
    title:SetPoint("RIGHT", frame.TitleContainer, "RIGHT", 0, 0)
    title:SetJustifyH("CENTER")
    title:SetWordWrap(false)
    title:SetTextColor(unpack(self.palette.gold))
end

function Theme:CreateRegion(parent)
    return CreateFrame("Frame", nil, parent)
end

function Theme:WorkbenchSurface(frame)
    -- A restrained material wash under all three regions, never under code.
    frame.Bg:SetColorTexture(unpack(self.palette.workbench))
    frame.Bg:SetVertexColor(1, 1, 1, 1)
    local material = frame:CreateTexture(nil, "BACKGROUND", nil, -4)
    material:SetAllPoints(frame.Bg)
    material:SetTexture("Interface\\FrameGeneral\\UI-Background-Rock")
    material:SetHorizTile(true)
    material:SetVertTile(true)
    material:SetVertexColor(unpack(self.palette.materialTint))
end

function Theme:SecondaryText(label)
    label:SetTextColor(unpack(self.palette.secondary))
    label:SetShadowColor(0, 0, 0, 0.9)
    label:SetShadowOffset(1, -1)
end

function Theme:CreateInset(parent, editor)
    local frame = CreateFrame("Frame", nil, parent, editor and self.resources.editor or self.resources.inset)
    if editor then
        frame.Bg:SetColorTexture(unpack(self.palette.editorBackground))
        for _, key in ipairs({ "BorderTopRight", "BorderBottomRight", "BorderRightMiddle", "BorderTopLeft",
            "BorderBottomLeft", "BorderLeftMiddle", "BorderTopMiddle", "BorderBottomMiddle" }) do
            tint(frame[key], self.palette.editorRim)
        end
        -- The native eight-piece rim stays intact. Inside it, directional
        -- shadows make the unchanged near-black editing surface sit deeper.
        local top = frame:CreateTexture(nil, "BACKGROUND", nil, 0)
        top:SetPoint("TOPLEFT", 4, -4)
        top:SetPoint("TOPRIGHT", -4, -4)
        top:SetHeight(3)
        top:SetColorTexture(0.008, 0.007, 0.006, 0.75)
        local left = frame:CreateTexture(nil, "BACKGROUND", nil, 0)
        left:SetPoint("TOPLEFT", 4, -7)
        left:SetPoint("BOTTOMLEFT", 4, 4)
        left:SetWidth(2)
        left:SetColorTexture(0.008, 0.007, 0.006, 0.65)
        local bottom = frame:CreateTexture(nil, "BACKGROUND", nil, 0)
        bottom:SetPoint("BOTTOMLEFT", 4, 4)
        bottom:SetPoint("BOTTOMRIGHT", -4, 4)
        bottom:SetHeight(1)
        bottom:SetColorTexture(0.16, 0.14, 0.11, 0.6)
    else
        frame.Bg:SetVertexColor(unpack(self.palette.insetTint))
        frame.NineSlice:SetBorderColor(unpack(self.palette.insetBorder))
    end
    return frame
end

function Theme:Divider(parent, neighbor)
    local edge = parent:CreateTexture(nil, "BORDER")
    edge:SetPoint("TOPLEFT", neighbor, "TOPRIGHT", 3, -2)
    edge:SetPoint("BOTTOMLEFT", neighbor, "BOTTOMRIGHT", 3, 2)
    edge:SetWidth(3)
    edge:SetAtlas("!UI-Frame-InnerRightTile")
    edge:SetVertTile(true)
    edge:SetVertexColor(0.46, 0.4, 0.32, 1)
    local shadow = parent:CreateTexture(nil, "BORDER")
    shadow:SetPoint("TOPLEFT", neighbor, "TOPRIGHT", 2, -2)
    shadow:SetPoint("BOTTOMLEFT", neighbor, "BOTTOMRIGHT", 2, 2)
    shadow:SetWidth(1)
    shadow:SetColorTexture(0.012, 0.01, 0.008, 0.85)
    local lip = parent:CreateTexture(nil, "BORDER")
    lip:SetPoint("TOPLEFT", neighbor, "TOPRIGHT", 6, -2)
    lip:SetPoint("BOTTOMLEFT", neighbor, "BOTTOMRIGHT", 6, 2)
    lip:SetWidth(1)
    lip:SetColorTexture(0.18, 0.15, 0.115, 0.6)
end

function Theme:Section(parent, title)
    title:SetTextColor(unpack(self.palette.gold))
    local rule = parent:CreateTexture(nil, "BORDER")
    rule:SetPoint("TOPLEFT", 7, -29)
    rule:SetPoint("TOPRIGHT", -7, -29)
    rule:SetHeight(3)
    rule:SetAtlas("_UI-Frame-InnerTopTile")
    rule:SetHorizTile(true)
    rule:SetVertexColor(unpack(self.palette.sectionRule))
end

function Theme:Label(label, font)
    label:SetTextColor(unpack(font and font:find("Disable") and self.palette.muted
        or font and font:find("Normal") and self.palette.gold or self.palette.text))
end

function Theme:Button(button, role)
    button.macroStudioRole = role or "button"
    -- Keep separate Blizzard up/down/disabled artwork and its texcoords.
    tint(button:GetNormalTexture(), self.palette.metal)
    tint(button:GetPushedTexture(), self.palette.buttonPushed)
    local disabled = button:GetDisabledTexture()
    if disabled then disabled:SetDesaturated(true) end
    tint(button:GetHighlightTexture(), self.palette.buttonHighlight)
    button:SetNormalFontObject(GameFontNormalSmall)
    button:SetHighlightFontObject(GameFontHighlightSmall)
    button:SetDisabledFontObject(GameFontDisableSmall)
    button:SetPushedTextOffset(1, -1)
    -- Gray-template buttons have no parentKey="Text" in Retail's XML.
    local label = button:GetFontString()
    if not label then
        label = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetPoint("CENTER")
        button:SetFontString(label)
    end
    button.Text = label
end

function Theme:SetButtonState(button, enabled)
    if button.Text then button.Text:SetTextColor(unpack(not enabled and self.palette.muted
        or button.macroStudioRole == "danger" and self.palette.error or self.palette.text)) end
end

function Theme:Tab(button, selected)
    if selected then PanelTemplates_SelectTab(button) else PanelTemplates_DeselectTab(button) end
    button.Text:SetTextColor(unpack(selected and self.palette.gold or self.palette.text))
end

function Theme:ToggleButton(button, selected)
    button:SetButtonState(selected and "PUSHED" or "NORMAL", selected and true or false)
end

function Theme:Input(box)
    box:SetFontObject(GameFontHighlight)
    box:SetTextInsets(6, 6, 0, 0)
    box:SetTextColor(unpack(self.palette.text))
    local function focus(focused)
        for _, key in ipairs({ "Left", "Middle", "Right" }) do
            tint(box[key], focused and self.palette.inputFocus or self.palette.inputIdle)
        end
    end
    focus(false)
    box:HookScript("OnEditFocusGained", function() focus(true) end)
    box:HookScript("OnEditFocusLost", function() focus(false) end)
end

function Theme:Row(row)
    local selection = row:CreateTexture(nil, "BACKGROUND")
    selection:SetAllPoints(row)
    selection:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    selection:SetVertexColor(unpack(self.palette.selection))
    selection:Hide()
    row.macroStudioSelection = selection
    local hover = row:CreateTexture(nil, "HIGHLIGHT")
    hover:SetAllPoints(row)
    hover:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    hover:SetVertexColor(unpack(self.palette.hover))
    local shadow = row:CreateTexture(nil, "BORDER")
    shadow:SetPoint("BOTTOMLEFT")
    shadow:SetPoint("BOTTOMRIGHT")
    shadow:SetHeight(1)
    shadow:SetColorTexture(unpack(self.palette.rowRule))
end

function Theme:RowState(row)
    row.macroStudioSelection:SetShown(row.selected == true)
    local label = rawget(row, "nameText") or rawget(row, "Text")
    if label then label:SetTextColor(unpack(row.selected == true and self.palette.gold or self.palette.text)) end
end

function Theme:ScrollBar(bar)
    if not bar then return end
    if bar.Background then
        for _, key in ipairs({ "Begin", "Middle", "End" }) do tint(bar.Background[key], self.palette.metal) end
    end
end

function Theme:IconBorder(parent, icon)
    local rim = parent:CreateTexture(nil, "OVERLAY")
    rim:SetPoint("TOPLEFT", icon, "TOPLEFT", -4, 4)
    rim:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 4, -4)
    rim:SetTexture("Interface\\Buttons\\UI-Quickslot2")
    rim:SetTexCoord(0.2, 0.8, 0.2, 0.8)
    rim:SetVertexColor(unpack(self.palette.metal))
    return rim
end

