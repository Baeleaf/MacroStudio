local _, MacroStudio = ...
local Keybind = {}
MacroStudio.KeybindButton = Keybind

local MODIFIER_KEYS = { LSHIFT=true, RSHIFT=true, LCTRL=true, RCTRL=true, LALT=true, RALT=true }
local MOUSE_KEYS = { LeftButton="BUTTON1", RightButton="BUTTON2", MiddleButton="BUTTON3" }
local KEY_LABELS = { MOUSEWHEELUP="Mouse Wheel Up", MOUSEWHEELDOWN="Mouse Wheel Down", BUTTON3="Middle Mouse" }

function Keybind:FormatKey(key)
    if not key then return "Not Bound" end
    local labels = {}
    for _, modifier in ipairs({ {"ALT-", "Alt"}, {"CTRL-", "Ctrl"}, {"SHIFT-", "Shift"} }) do
        if key:sub(1, #modifier[1]) == modifier[1] then
            labels[#labels + 1], key = modifier[2], key:sub(#modifier[1] + 1)
        end
    end
    local mouse = key:match("^BUTTON(%d+)$")
    labels[#labels + 1] = KEY_LABELS[key] or (mouse and ("Mouse " .. mouse))
        or (type(GetBindingText) == "function" and GetBindingText(key, "KEY_")) or key
    return table.concat(labels, " + ")
end

function Keybind:GetOverrideLabel(key)
    local action = key and type(GetBindingAction) == "function" and GetBindingAction(key, true) or ""
    if action:match("^CLICK MacroStudioAction%d+:") then action = GetBindingAction(key, false) or "" end
    if action == "" or action:match("^CLICK MacroStudioAction%d+:") then return nil end
    return _G["BINDING_NAME_" .. action] or (action:match("^CLICK ") and "another addon's action") or action
end

function Keybind:GetBlockedReason()
    if not MacroStudio.StudioMacroRepository:IsStudio(self.macro) then return "Select a MacroStudio macro to assign a keybind." end
    if InCombatLockdown() then return "Keybinds cannot be changed during combat." end
    if MacroStudio:IsMainWindowModalBlocked() then return "Close the open dialog before changing a keybind." end
    if MacroStudio.Editor:IsDirty() then return "Save or Revert the draft before changing its keybind." end
    if not MacroStudio.StudioMacroRepository:IsSnapshotCurrent(self.macro) then
        return "This macro changed. Revert or select it again before changing its keybind."
    end
end

function Keybind:Refresh()
    if not self.button then return end
    local visible = MacroStudio.StudioMacroRepository:IsStudio(self.macro)
    local reason = self:GetBlockedReason()
    if reason and self.captureMacro then self:CancelCapture() end
    local key = visible and MacroStudio.StudioMacroRepository:GetBinding(self.macro) or nil
    self.button:SetShown(visible)
    self.button:SetText(self.captureMacro and "Press a key, click, or scroll..." or self:FormatKey(key))
    MacroStudio.Helpers:SetButtonEnabled(self.button, reason == nil)
    if self.captureMacro then self.button.Text:SetTextColor(unpack(MacroStudio.Theme.palette.warning)) end
    local text = reason or (self.captureMacro
        and "Press a key, middle/extra mouse button, or scroll the wheel.\nEsc cancels without changing the current keybind."
        or "Left-click to set keybind.\nRight-click to clear.\nApplies to this character only.")
    local override = self:GetOverrideLabel(key)
    if override then text = text .. "\nOverrides " .. override .. " while MacroStudio is enabled." end
    if self.captureError then text = self.captureError .. "\n\n" .. text end
    MacroStudio.Helpers:SetButtonTooltip(self.button, "Keybind", text)
    if self.captureMacro then MacroStudio.Helpers:ShowTooltip(self.button, "Keybind", text) end
end

function Keybind:CancelCapture()
    self.captureMacro, self.captureError = nil, nil
    if self.captureFrame then self.captureFrame:Hide() end
    MacroStudio.Helpers:HideTooltip()
    self:Refresh()
end

function Keybind:SetMacro(macro)
    self:CancelCapture()
    self.macro = macro and MacroStudio.Helpers:CopyMacro(macro) or nil
    self:Refresh()
end

function Keybind:StartCapture()
    local reason = self:GetBlockedReason()
    if reason then MacroStudio.Editor:SetNotice(reason, true); return false end
    self.captureMacro = MacroStudio.Helpers:CopyMacro(self.macro)
    self.captureError = nil
    MacroStudio.Editor.editBox:ClearFocus()
    MacroStudio.Editor.nameBox:ClearFocus()
    MacroStudio.Editor:HideMetadataMenus()
    self.captureFrame:SetPropagateKeyboardInput(false)
    self.captureFrame:Show()
    self:Refresh()
    return true
end

function Keybind:Apply(key)
    local reason = self:GetBlockedReason()
    if reason then self:CancelCapture(); MacroStudio.Editor:SetNotice(reason, true); return false end
    local macro = self.captureMacro or self.macro
    local override = self:GetOverrideLabel(key)
    local ok, failure = MacroStudio.StudioMacroRepository:SetBinding(macro, key)
    if not ok then
        self.captureError = failure
        MacroStudio.Editor:SetNotice(failure, true)
        self:Refresh()
        return false
    end
    self:CancelCapture()
    MacroStudio.Editor:RefreshActionBarUsage()
    MacroStudio.MacroList:RefreshUsage()
    MacroStudio.Editor:SetNotice(key and ("Keybind set to " .. self:FormatKey(key) .. "."
        .. (override and (" Overrides " .. override .. " while MacroStudio is enabled.") or "")) or "Keybind cleared.", false)
    return true
end

function Keybind:Capture(key)
    if not self.captureMacro then return false end
    if key == "ESCAPE" then self:CancelCapture(); return false end
    if MODIFIER_KEYS[key] then return false end
    local prefix = ""
    if IsAltKeyDown() then prefix = prefix .. "ALT-" end
    if IsControlKeyDown() then prefix = prefix .. "CTRL-" end
    if IsShiftKeyDown() then prefix = prefix .. "SHIFT-" end
    return self:Apply(prefix .. key)
end

function Keybind:Create(parent)
    local button = MacroStudio.Helpers:CreateButton(parent)
    button:SetSize(212, 24)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "RightButton" then self:Apply(nil) else self:StartCapture() end
    end)
    button:SetScript("OnHide", function() if self.captureMacro then self:CancelCapture() end end)
    self.button = button

    -- Only visible while listening. Consume input so the captured key/click
    -- cannot also type into the draft, activate a game binding or click the UI.
    local capture = CreateFrame("Frame", nil, button)
    self.captureFrame = capture
    capture:SetAllPoints(UIParent)
    capture:SetFrameStrata("FULLSCREEN_DIALOG")
    capture:SetFrameLevel(button:GetFrameLevel() + 20)
    capture:EnableKeyboard(true)
    capture:EnableMouse(true)
    capture:EnableMouseWheel(true)
    capture:SetScript("OnKeyDown", function(_, key) self:Capture(key) end)
    capture:SetScript("OnMouseDown", function() end)
    capture:SetScript("OnMouseUp", function(_, mouseButton)
        self:Capture(MOUSE_KEYS[mouseButton] or mouseButton:gsub("^Button", "BUTTON"))
    end)
    capture:SetScript("OnMouseWheel", function(_, delta)
        if delta ~= 0 then self:Capture(delta > 0 and "MOUSEWHEELUP" or "MOUSEWHEELDOWN") end
    end)
    capture:SetScript("OnHide", function() if self.captureMacro then self:CancelCapture() end end)
    capture:Hide()
    button:Hide()
    return button
end
