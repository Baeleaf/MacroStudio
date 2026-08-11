"""Headless construction smoke test for MacroStudio's full TOC load path."""

from lupa.lua51 import LuaRuntime


def run_ui_smoke(root):
    lua = LuaRuntime(unpack_returned_tuples=True)
    load = lua.eval("loadstring")
    lua.execute(
        r"""
        Constants = { MacroConsts = { MAX_ACCOUNT_MACROS = 3, MAX_CHARACTER_MACROS = 2 } }
        MAX_ACCOUNT_MACROS = 3
        MAX_CHARACTER_MACROS = 2
        MAX_MACRO_NAME_LENGTH = 16
        CANCEL = "Cancel"
        SlashCmdList = {}
        hash_SlashCmdList = {}
        SLASH_COMMAND = { MACRO = "MACRO" }
        SLASH_MACRO1 = "/macro"
        SLASH_MACRO2 = "/m"
        nativeMacroOpenCalls = 0
        blizzardMacroOpenCalls = 0
        function ShowMacroFrame() blizzardMacroOpenCalls = blizzardMacroOpenCalls + 1 end
        function NativeMacroHandler()
            nativeMacroOpenCalls = nativeMacroOpenCalls + 1
            ShowMacroFrame()
        end
        SlashCmdList.MACRO = NativeMacroHandler
        function issecurevariable() return true end
        C_AddOns = { LoadAddOn = function() return true end }
        UISpecialFrames = {}
        StaticPopupDialogs = {}
        MacroStudioDB = nil
        combat = false
        enumerationCalls = 0
        shiftDown = false
        pickupCalls = {}
        editCalls = 0
        deleteCalls = 0
        actionInfoCalls = 0
        deferTimers = false
        timerCallbacks = {}
        nativeMacroEventCallback = nil
        createdAccountMacro = nil
        createdCharacterMacro = nil
        baseAccountMacro = { name = "Account", icon = 101, selectedIcon = 101, body = "/cast [@mouseover] Heal" }
        baseCharacterMacro = { name = "Character", icon = 102, selectedIcon = 102, body = "/say character" }
        lastEditCall = nil
        actionSlots = {
            [3] = { "macro", 1001, "spell", "Account", 101 },
            [15] = { "macro", 1001, "spell", "Account", 101 },
            [25] = { "macro", 1, nil, "Character", 102 },
        }

        local Frame = {}
        local focusedFrame = nil
        Frame.__index = function(_, key)
            return Frame[key] or function() end
        end

        local function RunHandlers(frame, event, ...)
            if frame.scripts[event] then
                frame.scripts[event](frame, ...)
            end
            for _, handler in ipairs(frame.hooks[event] or {}) do
                handler(frame, ...)
            end
        end

        function Frame:SetSize(width, height) self.width, self.height = width, height end
        function Frame:SetWidth(width) self.width = width end
        function Frame:SetHeight(height) self.height = height end
        function Frame:SetFrameLevel(level) self.frameLevel = level end
        function Frame:SetFrameStrata(strata) self.frameStrata = strata end
        function Frame:SetAllPoints() self.allPoints = true end
        function Frame:SetMovable(movable) self.movable = movable and true or false end
        function Frame:SetClampedToScreen(clamped) self.clamped = clamped and true or false end
        function Frame:EnableMouse(enabled) self.mouseEnabled = enabled and true or false end
        function Frame:EnableMouseWheel(enabled) self.mouseWheelEnabled = enabled and true or false end
        function Frame:RegisterForDrag(button) self.dragButton = button end
        function Frame:RegisterForClicks(...) self.clickButtons = { ... } end
        function Frame:RegisterEvent(event)
            local registeredEvents = rawget(self, "registeredEvents") or {}
            registeredEvents[event] = true
            self.registeredEvents = registeredEvents
        end
        function Frame:StartMoving() self.moving = true end
        function Frame:ClearAllPoints() self.clearedPoints = true end
        function Frame:StopMovingOrSizing() self.moving = false end
        function Frame:GetWidth() return rawget(self, "width") or 500 end
        function Frame:GetHeight() return rawget(self, "height") or 300 end
        function Frame:GetStringHeight()
            local lines = 1
            for _ in string.gmatch(rawget(self, "text") or "", "\n") do lines = lines + 1 end
            return lines * 14
        end
        function Frame:GetPoint() return "CENTER", UIParent, "CENTER", 0, 0 end
        function Frame:GetName() return rawget(self, "name") end
        function Frame:GetFrameLevel() return rawget(self, "frameLevel") or 1 end
        function Frame:GetEffectiveScale() return 1 end
        function Frame:GetCenter() return rawget(self, "centerX") or 960, rawget(self, "centerY") or 540 end
        function Frame:SetMaxLetters(maximum) self.maxLetters = maximum end
        function Frame:SetText(value)
            local text = tostring(value or "")
            if rawget(self, "maxLetters") and self.maxLetters > 0 then
                text = text:sub(1, self.maxLetters)
            end
            self.text = text
            RunHandlers(self, "OnTextChanged", false)
        end
        function Frame:SetUserText(value)
            local text = tostring(value or "")
            if rawget(self, "maxLetters") and self.maxLetters > 0 then
                text = text:sub(1, self.maxLetters)
            end
            self.text = text
            RunHandlers(self, "OnTextChanged", true)
        end
        function Frame:SetWordWrap(enabled) self.wordWrap = enabled and true or false end
        function Frame:GetText() return rawget(self, "text") or "" end
        function Frame:GetNumLetters() return #(rawget(self, "text") or "") end
        function Frame:SetScript(event, handler) self.scripts[event] = handler end
        function Frame:HookScript(event, handler)
            self.hooks[event] = self.hooks[event] or {}
            table.insert(self.hooks[event], handler)
        end
        function Frame:GetScript(event) return self.scripts[event] end
        function Frame:Show()
            local wasShown = rawget(self, "shown") == true
            self.shown = true
            if not wasShown then RunHandlers(self, "OnShow") end
        end
        function Frame:Hide()
            local wasShown = rawget(self, "shown") == true
            self.shown = false
            if wasShown then RunHandlers(self, "OnHide") end
        end
        function Frame:IsShown() return rawget(self, "shown") == true end
        function Frame:SetShown(shown)
            if shown then self:Show() else self:Hide() end
        end
        function Frame:SetFocus()
            if focusedFrame == self then return end
            if focusedFrame then
                local previous = focusedFrame
                focusedFrame = nil
                previous.focused = false
                RunHandlers(previous, "OnEditFocusLost")
            end
            focusedFrame = self
            self.focused = true
            RunHandlers(self, "OnEditFocusGained")
        end
        function Frame:ClearFocus()
            if focusedFrame ~= self then return end
            focusedFrame = nil
            self.focused = false
            RunHandlers(self, "OnEditFocusLost")
        end
        function Frame:HasFocus() return self.focused == true end
        function Frame:SetEnabled(enabled) self.enabled = enabled and true or false end
        function Frame:SetChecked(checked) self.checked = checked and true or false end
        function Frame:GetChecked() return rawget(self, "checked") == true end
        function Frame:IsEnabled() return rawget(self, "enabled") ~= false end
        function Frame:SetVerticalScroll(value) self.verticalScroll = value end
        function Frame:GetVerticalScroll() return rawget(self, "verticalScroll") or 0 end
        function Frame:SetMinMaxValues(minimum, maximum) self.minimum, self.maximum = minimum, maximum end
        function Frame:SetValue(value)
            self.value = value
            if self.scripts.OnValueChanged then self.scripts.OnValueChanged(self, value) end
        end
        function Frame:CreateTexture()
            local texture = setmetatable({ scripts = {}, hooks = {}, shown = true }, Frame)
            local textures = rawget(self, "textures")
            if not textures then
                textures = {}
                self.textures = textures
            end
            table.insert(textures, texture)
            return texture
        end
        function Frame:SetColorTexture(red, green, blue, alpha)
            self.color = { red, green, blue, alpha }
        end
        function Frame:SetTexture(texture) self.texture = texture end
        function Frame:TriggerScript(event, ...) RunHandlers(self, event, ...) end
        function Frame:CreateFontString()
            return setmetatable({ scripts = {}, hooks = {}, shown = true, text = "" }, Frame)
        end

        function CreateFrame(_, name, parent, template)
            local frame = setmetatable({
                name = name,
                parent = parent,
                template = template,
                scripts = {},
                hooks = {},
                shown = true,
                enabled = true,
                text = "",
            }, Frame)
            frame.Text = frame:CreateFontString()
            if template == "ScrollingEditBoxTemplate" then
                local editBox = CreateFrame("EditBox", nil, frame)
                local scrollBox = CreateFrame("Frame", nil, frame)
                frame.GetEditBox = function() return editBox end
                frame.GetScrollBox = function() return scrollBox end
            end
            return frame
        end

        function RunDeferredTimers()
            local callbacks = timerCallbacks
            timerCallbacks = {}
            for _, callback in ipairs(callbacks) do
                callback()
            end
        end

        C_Timer = {
            After = function(_, callback)
                if deferTimers then
                    timerCallbacks[#timerCallbacks + 1] = callback
                else
                    callback()
                end
            end,
        }

        ScrollUtil = {
            RegisterScrollBoxWithScrollBar = function() end,
        }

        UIParent = CreateFrame("Frame", "UIParent")
        UIParent:SetSize(1920, 1080)
        Minimap = CreateFrame("Frame", "Minimap", UIParent)
        Minimap:SetSize(140, 140)
        Minimap.centerX, Minimap.centerY = 960, 540
        function GetCursorPosition() return 1000, 580 end
        GameTooltip = CreateFrame("Frame", "GameTooltip")
        function GameTooltip:SetOwner(owner, anchor)
            self.tooltipOwner = owner
            self.tooltipAnchor = anchor
        end
        function GameTooltip:SetText(text, red, green, blue, alpha, wrap)
            assert(alpha == nil or type(alpha) == "number",
                "GameTooltip:SetText alpha must be numeric")
            assert(wrap == nil or type(wrap) == "boolean",
                "GameTooltip:SetText wrap must be boolean")
            self.tooltipTitle = text
            self.tooltipAlpha = alpha
            self.tooltipWrap = wrap
        end
        function GameTooltip:AddLine(text, red, green, blue, wrap)
            assert(wrap == nil or type(wrap) == "boolean",
                "GameTooltip:AddLine wrap must be boolean")
            self.tooltipBody = text
        end


        function StaticPopup_Show(key, text1, text2, data)
            local dialog = CreateFrame("Frame")
            dialog.data = data
            dialog.key, dialog.text1, dialog.text2 = key, text1, text2
            lastStaticPopup = dialog
            return dialog
        end

        function InCombatLockdown() return combat end
        function strlenutf8(value) return #value end
        playerGUID = "Player-1-CURRENT"
        playerName = "Current"
        playerRealm = "Test Realm"
        serverTime = 1767225600
        function UnitGUID(unit) return unit == "player" and playerGUID or nil end
        function UnitFullName() return playerName, playerRealm end
        function UnitName() return playerName, playerRealm end
        function GetRealmName() return playerRealm end
        function GetNormalizedRealmName() return "TestRealm" end
        function GetServerTime() return serverTime end
        function date() return "Jan 01, 2026" end
        function GetNumMacros()
            enumerationCalls = enumerationCalls + 1
            return createdAccountMacro and 2 or 1, createdCharacterMacro and 2 or 1
        end
        function GetMacroInfo(index)
            if index == 1 then
                return baseAccountMacro.name, baseAccountMacro.displayIcon or baseAccountMacro.icon, baseAccountMacro.body
            end
            if index == 2 and createdAccountMacro then
                return createdAccountMacro.name, createdAccountMacro.displayIcon or createdAccountMacro.icon, createdAccountMacro.body
            end
            if index == 4 then
                return baseCharacterMacro.name, baseCharacterMacro.displayIcon or baseCharacterMacro.icon, baseCharacterMacro.body
            end
            if index == 5 and createdCharacterMacro then
                return createdCharacterMacro.name, createdCharacterMacro.displayIcon or createdCharacterMacro.icon, createdCharacterMacro.body
            end
            return nil
        end
        C_Macro = {
            GetSelectedMacroIcon = function(index)
                local macro = index == 1 and baseAccountMacro
                    or index == 2 and createdAccountMacro
                    or index == 4 and baseCharacterMacro
                    or index == 5 and createdCharacterMacro
                    or nil
                return macro and (macro.selectedIcon or macro.icon) or nil
            end,
        }
        function GetMacroSpell(index)
            return index == 1 and 1001 or nil
        end
        function GetMacroItem() return nil end
        function GetMacroIcons(list)
            list[#list + 1] = 134400
            list[#list + 1] = 101
            list[#list + 1] = "Interface\\Icons\\INV_Misc_QuestionMark"
            list[#list + 1] = "INV_Misc_QuestionMark"
            list[#list + 1] = 135000
        end
        function GetMacroItemIcons() end
        function GetFileIDFromPath(path)
            if type(path) == "string" and path:lower():find("inv_misc_questionmark", 1, true) then
                return 134400
            end
            return nil
        end
        function EditMacro(index, name, icon, body)
            editCalls = editCalls + 1
            lastEditCall = { index = index, name = name, icon = icon, body = body }
            local macro = index == 1 and baseAccountMacro
                or index == 2 and createdAccountMacro
                or index == 4 and baseCharacterMacro
                or index == 5 and createdCharacterMacro
                or nil
            if not macro then return nil end
            macro.name = name or macro.name
            macro.selectedIcon = icon or macro.selectedIcon or macro.icon
            macro.icon = icon or macro.icon
            macro.body = body or macro.body
            if nativeMacroEventCallback then nativeMacroEventCallback() end
            return index
        end
        function IsShiftKeyDown() return shiftDown end
        function CreateMacro(name, icon, body, perCharacter)
            if perCharacter then
                if createdCharacterMacro then return nil end
                createdCharacterMacro = { name = name, icon = icon, selectedIcon = icon, body = body }
                if nativeMacroEventCallback then nativeMacroEventCallback() end
                return 5
            end
            if createdAccountMacro then return nil end
            createdAccountMacro = { name = name, icon = icon, selectedIcon = icon, body = body }
            if nativeMacroEventCallback then nativeMacroEventCallback() end
            return 2
        end
        function DeleteMacro(index)
            deleteCalls = deleteCalls + 1
            if index == 2 then
                createdAccountMacro = nil
            elseif index == 5 then
                createdCharacterMacro = nil
            end
            if nativeMacroEventCallback then nativeMacroEventCallback() end
        end
        function PickupMacro(index)
            pickupCalls[#pickupCalls + 1] = index
        end
        function GetActionInfo(slot)
            actionInfoCalls = actionInfoCalls + 1
            local action = actionSlots[slot]
            if not action then return nil end
            return action[1], action[2], action[3]
        end
        C_ActionBar = {
            GetActionText = function(slot) return actionSlots[slot] and actionSlots[slot][4] or nil end,
            GetActionTexture = function(slot) return actionSlots[slot] and actionSlots[slot][5] or nil end,
        }
        """
    )

    namespace = lua.table()
    toc_order = [
        "Core.lua",
        "Utils/Helpers.lua",
        "Database.lua",
        "Access.lua",
        "MinimapButton.lua",
        "MacroRepository.lua",
        "CharacterMacroLibrary.lua",
        "ActionBarRepository.lua",
        "MetadataRepository.lua",
        "Search.lua",
        "UI/Dialogs.lua",
        "UI/IconPicker.lua",
        "UI/MacroDialog.lua",
        "UI/Editor.lua",
        "UI/MacroList.lua",
        "UI/Sidebar.lua",
        "UI/Settings.lua",
        "UI/MainFrame.lua",
    ]
    for relative_path in toc_order:
        source = (root / relative_path).read_text(encoding="utf-8")
        result = load(source, "@" + relative_path)
        chunk, error = result if isinstance(result, tuple) else (result, None)
        assert chunk is not None, error
        chunk("MacroStudio", namespace)

    smoke = load(
        r"""
        local _, ms = ...
        ms:OnAddonLoaded()
        local libraryStore = MacroStudioDB.characterLibrary
        libraryStore.characters["guid:Player-1-OFFLINE"] = {
            id = "guid:Player-1-OFFLINE",
            guid = "Player-1-OFFLINE",
            name = "Archived",
            realm = "Other Realm",
            displayName = "Archived - Other Realm",
            normalizedDisplay = "archived - other realm",
            identityCertain = true,
            lastSynced = serverTime - 86400,
            macros = {
                { order = 1, name = "ArchiveHeal", icon = 777, body = "/cast Offline Library Heal" },
            },
        }
        libraryStore.order[1] = "guid:Player-1-OFFLINE"
        local originalNativeMacroHandler = SlashCmdList.MACRO
        ms:OnPlayerLogin()
        assert(ms.initialized, "full UI should initialize")
        assert(ms.frame and not ms.frame:IsShown(), "main window should remain hidden on login")
        assert(ms.selectedMacro and ms.selectedMacro.name == "Account", "initial refresh should select a macro")
        assert(MacroStudioDB.schemaVersion == 4
                and MacroStudioDB.settings.useMacroStudioSlashCommands
                and MacroStudioDB.settings.showMinimapButton
                and MacroStudioDB.settings.minimapAngle == 225,
            "schema 4 access settings should default on without replacing other settings")
        assert(SLASH_MACROSTUDIO1 == "/macrostudio" and SLASH_MACROSTUDIO2 == "/ms"
                and SlashCmdList.MACROSTUDIO and SlashCmdList.MACRO == ms.Access.takeoverHandler,
            "/ms aliases should remain dedicated while the default native macro aliases are claimed")
        SlashCmdList.MACROSTUDIO("")
        assert(ms.frame:IsShown(), "/ms should open MacroStudio")
        SlashCmdList.MACROSTUDIO("")
        assert(not ms.frame:IsShown(), "/macrostudio should use the same dedicated toggle handler")
        SlashCmdList.MACRO("")
        assert(ms.frame:IsShown(), "/m should open MacroStudio by default")
        SlashCmdList.MACRO("")
        assert(not ms.frame:IsShown(), "/macro should use the same toggle handler")
        assert(ms.Access:SetTakeoverEnabled(false)
                and SlashCmdList.MACRO == originalNativeMacroHandler,
            "disabling takeover should immediately restore the exact native handler")
        SlashCmdList.MACRO("")
        assert(nativeMacroOpenCalls == 1, "restored /m should invoke Blizzard's captured handler")
        assert(ms.Access:SetTakeoverEnabled(true)
                and SlashCmdList.MACRO == ms.Access.takeoverHandler,
            "re-enabling takeover should safely reclaim the native aliases")
        local nativeOpensBeforeFallback = nativeMacroOpenCalls
        SlashCmdList.MACROSTUDIO("blizzard")
        assert(nativeMacroOpenCalls == nativeOpensBeforeFallback + 1 and blizzardMacroOpenCalls == 2 and not ms.frame:IsShown(),
            "/ms blizzard should use the native Macro UI without changing MacroStudio visibility")
        local sharedSettingsOpen = ms.Access.OpenSettings
        local sharedSettingsToggle = ms.Access.ToggleSettings
        local sharedSettingsOpenCalls = 0
        local sharedSettingsToggleCalls = 0
        local lastSettingsToggleSource
        ms.Access.OpenSettings = function(access, ...)
            sharedSettingsOpenCalls = sharedSettingsOpenCalls + 1
            return sharedSettingsOpen(access, ...)
        end
        ms.Access.ToggleSettings = function(access, source, ...)
            sharedSettingsToggleCalls = sharedSettingsToggleCalls + 1
            lastSettingsToggleSource = source
            return sharedSettingsToggle(access, source, ...)
        end

        ms.frame:Show()
        assert(ms.Settings.frame == nil, "title Settings should not require prior slash initialization")
        assert(ms.settingsButton.clickButtons[1] == "LeftButtonUp"
                and ms.settingsButton:GetFrameLevel() > ms.modalOverlay:GetFrameLevel(),
            "the title Settings control should remain clickable above its modal overlay")
        ms.settingsButton:TriggerScript("OnMouseDown", "LeftButton")
        local sharedSettingsFrame = ms.Settings.frame
        assert(sharedSettingsToggleCalls == 1 and lastSettingsToggleSource == "title"
                and sharedSettingsOpenCalls == 1 and sharedSettingsFrame:IsShown()
                and ms.frame:IsShown() and ms:IsMainWindowModalBlocked(),
            "title mouse-down should defer through the shared controller and open Settings")
        assert(ms.Settings.takeoverCheckbox:IsEnabled() and ms.Settings.minimapCheckbox:IsEnabled()
                and ms.Settings.statusText:GetWidth() == 420,
            "Settings controls should remain interactive in the minimum-size-safe layout")
        ms.settingsButton:TriggerScript("OnMouseDown", "LeftButton")
        assert(sharedSettingsToggleCalls == 2 and not sharedSettingsFrame:IsShown()
                and ms.frame:IsShown() and not ms:IsMainWindowModalBlocked(),
            "a second title click should close Settings while keeping MacroStudio open")
        ms.settingsButton:TriggerScript("OnMouseDown", "LeftButton")
        assert(sharedSettingsToggleCalls == 3 and sharedSettingsOpenCalls == 2
                and ms.Settings.frame == sharedSettingsFrame and sharedSettingsFrame:IsShown(),
            "repeated title toggles should reuse the one Settings frame")
        sharedSettingsFrame:Hide()
        assert(not ms.Access:IsSettingsShown() and not ms:IsMainWindowModalBlocked(),
            "manual Settings close should derive clean state from the actual frame")
        ms.settingsButton:TriggerScript("OnMouseDown", "LeftButton")
        assert(sharedSettingsToggleCalls == 4 and sharedSettingsOpenCalls == 3
                and sharedSettingsFrame:IsShown(),
            "title Settings should reopen after a manual close")
        sharedSettingsFrame:Hide()
        SlashCmdList.MACROSTUDIO("settings")
        SlashCmdList.MACROSTUDIO("settings")
        assert(sharedSettingsOpenCalls == 5 and sharedSettingsToggleCalls == 4
                and ms.Settings.frame == sharedSettingsFrame and sharedSettingsFrame:IsShown(),
            "/ms settings should open or raise the existing frame without toggling it closed")
        sharedSettingsFrame:Hide()
        local enumerationsBeforeSlashRefresh = enumerationCalls
        SlashCmdList.MACROSTUDIO("refresh")
        assert(enumerationCalls > enumerationsBeforeSlashRefresh and ms.frame:IsShown(),
            "the existing /ms refresh fallback should remain available")
        SlashCmdList.MACROSTUDIO("debug on")
        assert(ms.debug, "the existing debug-on command should remain available")
        SlashCmdList.MACROSTUDIO("debug off")
        assert(not ms.debug, "the existing debug-off command should remain available")
        assert(ms.MinimapButton.button and ms.MinimapButton.button:IsShown(),
            "the optional minimap launcher should be visible by default")
        ms.MinimapButton:SetShown(false)
        assert(not ms.MinimapButton.button:IsShown()
                and not MacroStudioDB.settings.showMinimapButton,
            "the minimap setting should hide the launcher immediately")
        MacroStudio_AddonCompartmentOnClick("MacroStudio", "LeftButton")
        assert(not ms.frame:IsShown(),
            "the AddOn Compartment launcher should remain available while the minimap button is hidden")
        ms.MinimapButton:SetShown(true)
        ms.MinimapButton.button:TriggerScript("OnClick", "LeftButton")
        assert(ms.frame:IsShown(), "left-clicking the minimap launcher should toggle MacroStudio")
        ms.MinimapButton.button:TriggerScript("OnClick", "LeftButton")
        assert(not ms.frame:IsShown(), "a second minimap left-click should close MacroStudio")
        ms.MinimapButton.button:TriggerScript("OnDragStart")
        ms.MinimapButton.button:TriggerScript("OnUpdate")
        ms.MinimapButton.button:TriggerScript("OnDragStop")
        assert(MacroStudioDB.settings.minimapAngle ~= 225
                and ms.MinimapButton.button:GetScript("OnUpdate") == nil,
            "minimap dragging should persist angle without leaving a per-frame update running")
        ms.MinimapButton.button:TriggerScript("OnClick", "LeftButton")
        ms.MinimapButton.button:TriggerScript("OnClick", "RightButton")
        assert(lastSettingsToggleSource == "minimap" and ms.frame:IsShown()
                and ms.Settings.frame == sharedSettingsFrame and sharedSettingsFrame:IsShown(),
            "first minimap right-click should open MacroStudio and the shared Settings frame")
        ms.MinimapButton.button:TriggerScript("OnClick", "RightButton")
        assert(not ms.frame:IsShown() and not sharedSettingsFrame:IsShown(),
            "second minimap right-click should close Settings and MacroStudio")
        ms.MinimapButton.button:TriggerScript("OnClick", "RightButton")
        assert(ms.frame:IsShown() and sharedSettingsFrame:IsShown()
                and ms.Settings.frame == sharedSettingsFrame,
            "third minimap right-click should reopen both without duplicating Settings")
        ms.MinimapButton.button:TriggerScript("OnClick", "RightButton")
        assert(not ms.frame:IsShown() and not sharedSettingsFrame:IsShown(),
            "repeated minimap right-click toggles should remain stable")

        sharedSettingsFrame:Show()
        assert(sharedSettingsFrame:IsShown() and not ms.frame:IsShown(),
            "orphan normalization fixture should start with only Settings shown")
        ms.MinimapButton.button:TriggerScript("OnClick", "RightButton")
        assert(not sharedSettingsFrame:IsShown() and not ms.frame:IsShown(),
            "minimap right-click should close an orphaned Settings frame safely")

        ms.frame:Show()
        ms.MinimapButton.button:TriggerScript("OnClick", "RightButton")
        assert(ms.frame:IsShown() and sharedSettingsFrame:IsShown(),
            "with MacroStudio already open, minimap right-click should open Settings")
        sharedSettingsFrame:Hide()
        assert(ms.frame:IsShown() and not ms.Access:IsSettingsShown(),
            "manual Settings close should not leave stale controller state")
        ms.MinimapButton.button:TriggerScript("OnClick", "RightButton")
        assert(ms.frame:IsShown() and sharedSettingsFrame:IsShown()
                and ms.Settings.frame == sharedSettingsFrame,
            "minimap right-click should reopen Settings after manual close")
        ms.MinimapButton.button:TriggerScript("OnClick", "RightButton")
        assert(not ms.frame:IsShown() and not sharedSettingsFrame:IsShown(),
            "closing the reopened minimap workflow should dismiss both frames")
        local editsBeforeCombatAccess, deletesBeforeCombatAccess = editCalls, deleteCalls
        combat = true
        SlashCmdList.MACROSTUDIO("")
        SlashCmdList.MACROSTUDIO("")
        SlashCmdList.MACRO("")
        SlashCmdList.MACRO("")
        ms.MinimapButton.button:TriggerScript("OnClick", "LeftButton")
        ms.MinimapButton.button:TriggerScript("OnClick", "LeftButton")
        MacroStudio_AddonCompartmentOnClick("MacroStudio", "LeftButton")
        MacroStudio_AddonCompartmentOnClick("MacroStudio", "LeftButton")
        combat = false
        assert(SlashCmdList.MACRO == ms.Access.takeoverHandler
                and editCalls == editsBeforeCombatAccess and deleteCalls == deletesBeforeCombatAccess,
            "all MacroStudio access launchers should remain safe in combat without native writes")
        ms.frame:Show()
        ms.frame:SetSize(ms.MIN_WIDTH, ms.MIN_HEIGHT)
        local syncsBeforeWorldEntry = ms.CharacterMacroLibrary:GetSyncCount()
        local enumerationsBeforeWorldEntry = enumerationCalls
        ms.eventFrame:TriggerScript("OnEvent", "PLAYER_ENTERING_WORLD")
        assert(ms.CharacterMacroLibrary:GetSyncCount() == syncsBeforeWorldEntry + 1
                and enumerationCalls > enumerationsBeforeWorldEntry,
            "world entry should defer one live repository and current snapshot refresh")
        local librarySyncsBeforeBrowse = ms.CharacterMacroLibrary:GetSyncCount()
        local enumerationsBeforeBrowse = enumerationCalls
        local scansBeforeBrowse = ms.ActionBarRepository:GetScanCount()
        assert(#ms.Sidebar.visibleCharacterButtons == 2,
            "sidebar should show the current and stored offline characters")
        ms:SetFilter("characters")
        assert(#ms.MacroList.visibleRows == 2,
            "All Characters should group only current and offline Character macros")
        local offlineRow
        for _, row in ipairs(ms.MacroList.visibleRows) do
            if row.macro.source == "SNAPSHOT" then offlineRow = row end
        end
        assert(offlineRow and offlineRow.macro.characterDisplayName == "Archived - Other Realm",
            "offline rows should carry their source character identity")
        assert(rawget(offlineRow, "dragButton") == nil and not offlineRow.usageText:IsShown()
                and not offlineRow.favorite:IsShown(),
            "offline rows must not be draggable or expose action-bar/Favorite state")
        local pickupsBeforeOfflineDrag = #pickupCalls
        offlineRow:GetScript("OnDragStart")(offlineRow)
        assert(#pickupCalls == pickupsBeforeOfflineDrag,
            "offline row drag attempts must never pick up a native macro")
        offlineRow:TriggerScript("OnEnter")
        assert(GameTooltip.tooltipTitle == "ArchiveHeal"
                and GameTooltip.tooltipBody:find("read%-only snapshot")
                and GameTooltip.tooltipBody:find("Archived %- Other Realm")
                and GameTooltip.tooltipBody:find("Last synced"),
            "offline hover should clearly identify read-only ownership and snapshot age")
        offlineRow:TriggerScript("OnLeave")
        offlineRow:GetScript("OnClick")(offlineRow)
        local offlineSnapshot = ms.Helpers:CopyMacro(ms.selectedMacro)
        assert(ms.Editor.state.offline and ms.Editor.copyButton:IsShown()
                and not ms.Editor.saveButton:IsShown() and not ms.Editor.deleteButton:IsShown(),
            "offline selection should replace native mutation actions with Copy")
        assert(ms.Editor.copyButton:GetText() == "Copy to Current Character",
            "Copy action should remain complete at minimum window size")
        assert(ms.Editor.scopeText.wordWrap,
            "offline character identity and read-only state should use responsive wrapping")
        assert(ms.Editor.editBox:IsEnabled() and ms.Editor.scopeText:GetText():find("Read%-only snapshot")
                and not ms.Editor.favoriteButton:IsShown() and not ms.Editor.categoryButton:IsShown(),
            "offline bodies should stay selectable while organization controls remain unavailable")
        assert(not ms.Editor.nameBox:IsShown()
                and ms.Editor.offlineNameText:IsShown()
                and ms.Editor.offlineNameText:GetText() == offlineSnapshot.name,
            "offline snapshot names should render as plain header text instead of an EditBox")
        assert(not ms.Editor.iconButton:IsShown()
                and ms.Editor.offlineIcon:IsShown()
                and ms.Editor.offlineIcon.texture == offlineSnapshot.icon
                and rawget(ms.Editor.iconButton, "macroStudioTooltipTitle") == nil,
            "offline snapshot icons should be display-only without hover or picker affordances")
        local offlineName, offlineIcon = ms.Editor:GetName(), ms.Editor:GetIcon()
        ms.Editor.nameBox:SetUserText("Blocked Rename")
        ms.Editor:ChooseIcon()
        assert(ms.Editor:GetName() == offlineName and ms.Editor:GetIcon() == offlineIcon
                and not ms.Editor:IsDirty()
                and not (ms.IconPicker.frame and ms.IconPicker.frame:IsShown()),
            "offline name/icon mutation attempts must not open a picker or create a draft")
        ms.Editor.editBox:SetText("/say mutation attempt")
        assert(ms.Editor:GetBody() == offlineSnapshot.body and not ms.Editor:IsDirty(),
            "offline text mutation attempts should restore the stored body without becoming dirty")
        local editsBeforeOfflineActions, deletesBeforeOfflineActions = editCalls, deleteCalls
        ms:SaveSelectedMacro()
        ms:RequestDeleteSelectedMacro()
        assert(editCalls == editsBeforeOfflineActions and deleteCalls == deletesBeforeOfflineActions,
            "offline Save/Delete requests must stop before native mutation APIs")


        ms:SetSearchQuery("other realm")
        assert(#ms.MacroList.visibleRows == 1
                and ms.MacroList.visibleRows[1].macro.characterKey == offlineSnapshot.characterKey,
            "All Characters search should match character realm metadata")
        ms:SetSearchQuery("offline library")
        assert(#ms.MacroList.visibleRows == 1
                and ms.MacroList.visibleRows[1].macro.name == "ArchiveHeal",
            "All Characters search should match offline macro bodies")
        assert(enumerationCalls == enumerationsBeforeBrowse
                and ms.ActionBarRepository:GetScanCount() == scansBeforeBrowse
                and ms.CharacterMacroLibrary:GetSyncCount() == librarySyncsBeforeBrowse,
            "library browsing and search must remain in-memory and side-effect free")
        ms:SetSearchQuery("")
        ms:SetFilter("libraryCharacter", offlineSnapshot.characterKey)
        ms:SelectMacro(offlineSnapshot)

        combat = true
        ms:UpdateCombatState()
        assert(not ms.Editor.copyButton:IsEnabled() and ms.Editor.stateText:GetText():find("Read%-only"),
            "combat should disable Copy while preserving the read-only snapshot view")
        assert(not ms:CopySelectedSnapshotToCurrentCharacter() and createdCharacterMacro == nil,
            "combat must block snapshot copy before native creation")
        combat = false
        ms:UpdateCombatState()
        assert(createdCharacterMacro == nil,
            "leaving combat must never retry or automatically create the blocked copy")
        assert(ms:CopySelectedSnapshotToCurrentCharacter(),
            "a valid offline snapshot should copy through the native Character macro path")
        assert(createdCharacterMacro
                and createdCharacterMacro.name == offlineSnapshot.name
                and createdCharacterMacro.icon == offlineSnapshot.icon
                and createdCharacterMacro.body == offlineSnapshot.body,
            "Copy should preserve the snapshot name, icon, and body exactly")
        assert(ms.activeFilter.kind == "character" and not ms:IsOfflineMacro(ms.selectedMacro)
                and ms.selectedMacro.scope == "CHARACTER",
            "successful Copy should select the new live current-character macro")
        assert(libraryStore.characters[offlineSnapshot.characterKey].macros[1].body == offlineSnapshot.body,
            "Copy must not mutate the source snapshot")

        ms:SetFilter("libraryCharacter", offlineSnapshot.characterKey)
        ms:PromptForgetActiveCharacter()
        assert(lastStaticPopup and lastStaticPopup.key == "MACROSTUDIO_FORGET_CHARACTER"
                and StaticPopupDialogs.MACROSTUDIO_FORGET_CHARACTER.text:find("does not delete any WoW macros"),
            "Forget Character should require explicit, deletion-safe confirmation")
        StaticPopupDialogs.MACROSTUDIO_FORGET_CHARACTER.OnAccept(lastStaticPopup, lastStaticPopup.data)
        assert(not ms.CharacterMacroLibrary:GetCharacter(offlineSnapshot.characterKey)
                and createdCharacterMacro and ms.MacroRepository:FindByIndex(5),
            "Forget should remove only MacroStudio snapshot data, never native macros")

        local helperText = ms.MacroList.visibleEmptyLabels[#ms.MacroList.visibleEmptyLabels]
        assert(helperText and helperText.wordWrap
                and helperText:GetText() == "Log into another character with MacroStudio enabled to add it to your library.",
            "Characters helper text should remain complete and wrapped at minimum window size")
        for index = 1, 12 do
            assert(ms.MetadataRepository:CreateCategory("Scale Category " .. index),
                "scale-test Categories should be created")
        end
        for index = 1, 20 do
            local characterId = "guid:Player-1-SCALE-" .. index
            libraryStore.characters[characterId] = {
                id = characterId,
                guid = "Player-1-SCALE-" .. index,
                name = "Scale" .. index,
                realm = "Large Library",
                displayName = "Scale" .. index .. " - Large Library",
                normalizedDisplay = ("Scale" .. index .. " - Large Library"):lower(),
                identityCertain = true,
                lastSynced = serverTime - index,
                macros = {},
            }
            libraryStore.order[#libraryStore.order + 1] = characterId
        end

        MacroStudioDB.settings.characterLibraryExpanded = nil
        ms.Sidebar:Rebuild(ms.activeFilter)
        assert(ms.frame:GetWidth() == ms.MIN_WIDTH and ms.frame:GetHeight() == ms.MIN_HEIGHT,
            "sidebar scaling should retain the supported minimum window size")
        assert(#ms.Sidebar.visibleCategoryButtons == 12 and ms.Sidebar.newButton:IsShown(),
            "Categories and its controls should remain accessible before a large character library")
        assert(not ms.Sidebar.charactersExpanded
                and #ms.Sidebar.visibleCharacterButtons == 0
                and ms.Sidebar.characterToggleButton.Text:GetText() == "Characters"
                and ms.Sidebar.characterToggleIcon.texture == "Interface\\Buttons\\UI-PlusButton-UP"
                and rawget(ms.Sidebar.characterToggleButton, "macroStudioTooltipTitle") == nil,
            "large libraries should default to an obvious collapsed Characters control")
        GameTooltip.tooltipTitle = nil
        ms.Sidebar.characterToggleButton:TriggerScript("OnEnter")
        assert(rawget(GameTooltip, "tooltipTitle") == nil,
            "Characters disclosure hover should not show a tooltip")
        ms.Sidebar.characterToggleButton:TriggerScript("OnLeave")
        assert(ms.Sidebar.allCharactersButton:IsShown(),
            "All Characters should remain visible while individual characters are collapsed")
        ms.Sidebar.allCharactersButton:GetScript("OnClick")(ms.Sidebar.allCharactersButton)
        assert(ms.activeFilter.kind == "characters" and not ms.Sidebar.charactersExpanded,
            "All Characters should remain usable without expanding individual entries")

        ms.Sidebar:ToggleCharacterList()
        assert(MacroStudioDB.settings.characterLibraryExpanded
                and ms.Sidebar.charactersExpanded
                and #ms.Sidebar.visibleCharacterButtons == 21
                and ms.Sidebar.characterToggleButton.Text:GetText() == "Characters"
                and ms.Sidebar.characterToggleIcon.texture == "Interface\\Buttons\\UI-MinusButton-UP"
                and rawget(ms.Sidebar.characterToggleButton, "macroStudioTooltipTitle") == nil,
            "Characters should use an obvious expanded control and show every character")
        ms.Sidebar:ToggleCharacterList()
        assert(MacroStudioDB.settings.characterLibraryExpanded == false
                and not ms.Sidebar.charactersExpanded
                and #ms.Sidebar.visibleCharacterButtons == 0
                and ms.Sidebar.characterToggleIcon.texture == "Interface\\Buttons\\UI-PlusButton-UP"
                and rawget(ms.Sidebar.characterToggleButton, "macroStudioTooltipTitle") == nil,
            "Characters should collapse without changing the active filter")

        ms:Toggle()
        assert(not ms.frame:IsShown(), "window toggle should close the minimum-size frame")
        ms:Toggle()
        assert(ms.frame:IsShown()
                and MacroStudioDB.settings.characterLibraryExpanded == false
                and not ms.Sidebar.charactersExpanded,
            "character collapse state should persist through close and reopen")
        ms.Database:Initialize()
        ms.Sidebar:Rebuild(ms.activeFilter)
        assert(MacroStudioDB.settings.characterLibraryExpanded == false
                and not ms.Sidebar.charactersExpanded
                and ms.Sidebar.allCharactersButton:IsShown(),
            "character collapse state should persist through SavedVariables reinitialization")
        ms:SetSearchQuery("")
        ms:SetFilter("all")
        ms:SelectMacro(ms.MacroRepository:GetAll()[1])

        assert(ms.Editor.nameBox:IsShown() and ms.Editor.nameBox:IsEnabled()
                and ms.Editor.iconButton:IsShown() and ms.Editor.iconButton:IsEnabled()
                and not ms.Editor.offlineNameText:IsShown() and not ms.Editor.offlineIcon:IsShown()
                and ms.Editor:GetName() == "Account" and ms.Editor:GetIcon() == 101,
            "live native macros should expose editable name and icon controls")
        ms.Editor.nameBox:SetUserText('Bad"Name')
        assert(ms.Editor:GetName() == "BadName"
                and ms.Editor.notice.message:find("Quotation")
                and ms.Editor.state.nameDirty,
            "name drafting should strip unsupported quotation marks with inline feedback")
        ms.Editor.nameBox:SetUserText("12345678901234567")
        assert(ms.Editor:GetName() == "1234567890123456"
                and ms.Editor.state.validContent,
            "the live name field should enforce Blizzard's 16-letter limit")
        ms:RevertSelectedMacro()

        ms.Editor.nameBox:SetUserText("Account Draft")
        assert(ms.Editor.state.nameDirty and not ms.Editor.state.iconDirty
                and not ms.Editor.state.bodyDirty and ms.Editor.saveButton:IsEnabled(),
            "name-only changes should participate in unified dirty state")
        ms:RevertSelectedMacro()
        assert(ms.Editor:GetName() == "Account" and not ms.Editor:IsDirty(),
            "Revert should restore a name-only draft")

        local function chooseEditorIcon(icon)
            for _, button in ipairs(ms.IconPicker.buttons) do
                if button.iconValue == icon then
                    button:GetScript("OnClick")(button)
                    return
                end
            end
            error("expected picker icon " .. tostring(icon))
        end

        ms.Editor.iconButton:GetScript("OnClick")(ms.Editor.iconButton)
        assert(ms.IconPicker.frame:IsShown() and ms:IsMainWindowModalBlocked(),
            "clicking the live icon should open the existing picker modally")
        chooseEditorIcon(135000)
        assert(ms.Editor:GetIcon() == 135000 and ms.Editor.state.iconDirty
                and not ms.Editor.state.nameDirty and not ms.Editor.state.bodyDirty
                and not ms.IconPicker.frame:IsShown() and not ms:IsMainWindowModalBlocked(),
            "icon-only selection should update the draft and safely close modal state")
        ms:RevertSelectedMacro()
        assert(ms.Editor:GetIcon() == 101 and not ms.Editor:IsDirty(),
            "Revert should restore an icon-only draft")

        ms.Editor.iconButton:GetScript("OnClick")(ms.Editor.iconButton)
        ms.IconPicker.frame:Hide()
        assert(ms.Editor:GetIcon() == 101 and not ms.Editor:IsDirty()
                and not ms:IsMainWindowModalBlocked(),
            "canceling the editor icon picker should leave the form unchanged")

        ms.Editor.iconButton:GetScript("OnClick")(ms.Editor.iconButton)
        chooseEditorIcon(ms.DEFAULT_ICON)
        assert(ms.Editor:GetIcon() == ms.DEFAULT_ICON and ms.Editor.state.iconDirty,
            "the canonical question-mark icon should be available as an editable draft")
        ms:RevertSelectedMacro()
        assert(ms.Editor:GetIcon() == 101 and not ms.Editor:IsDirty(),
            "Revert should restore the saved icon after a question-mark draft")

        ms.Editor.editBox:SetUserText("/say body only")
        assert(ms.Editor.state.bodyDirty and not ms.Editor.state.nameDirty
                and not ms.Editor.state.iconDirty,
            "body-only changes should remain part of the same dirty form")
        ms:RevertSelectedMacro()

        local identityCategory = ms.MetadataRepository:CreateCategory("Identity Safety")
        assert(identityCategory and ms.MetadataRepository:SetCategory(ms.selectedMacro, identityCategory.id),
            "identity-save metadata fixture category")
        assert(ms.MetadataRepository:AddTag(ms.selectedMacro, "IdentityTag"),
            "identity-save metadata fixture tag")
        ms.MetadataRepository:ToggleFavorite(ms.selectedMacro)

        ms.Editor.nameBox:SetUserText("Renamed Account")
        ms.Editor.iconButton:GetScript("OnClick")(ms.Editor.iconButton)
        chooseEditorIcon(135000)
        ms.Editor.editBox:SetUserText("/say renamed searchable body")
        assert(ms.Editor.state.nameDirty and ms.Editor.state.iconDirty
                and ms.Editor.state.bodyDirty and ms.Editor.state.canSave,
            "name, icon, and body should form one valid combined draft")

        ms:SetFilter("favorites")
        ms:SetSearchQuery("renamed")
        actionSlots[3] = { "macro", 1001, "spell", "Renamed Account", 135000 }
        actionSlots[15] = { "macro", 1001, "spell", "Renamed Account", 135000 }
        deferTimers = true
        nativeMacroEventCallback = function()
            ms:OnMacrosChanged("UPDATE_MACROS")
        end
        local editsBeforeIdentitySave = editCalls
        ms:SaveSelectedMacro()
        assert(editCalls == editsBeforeIdentitySave + 1
                and lastEditCall.index == 1
                and lastEditCall.name == "Renamed Account"
                and lastEditCall.icon == 135000
                and lastEditCall.body == "/say renamed searchable body",
            "Save should issue one exact-index EditMacro call with all three fields")
        assert(#timerCallbacks == 1,
            "synchronous UPDATE_MACROS and Save should debounce to one settled refresh")
        RunDeferredTimers()
        assert(baseAccountMacro.name == "Renamed Account"
                and baseAccountMacro.selectedIcon == 135000
                and baseAccountMacro.body == "/say renamed searchable body"
                and ms.selectedMacro.name == "Renamed Account"
                and not ms.Editor:IsDirty(),
            "successful Save should reconcile the native result and clean the complete form")
        local identityPresentation = ms.MetadataRepository:GetPresentation(ms.selectedMacro)
        assert(identityPresentation.favorite
                and identityPresentation.categoryId == identityCategory.id
                and identityPresentation.tags[1] == "IdentityTag",
            "Favorites, categories, and tags should remain attached through name/icon changes")
        assert(ms.activeFilter.kind == "favorites" and ms:GetSearchQuery() == "renamed"
                and #ms.MacroList.visibleRows == 1
                and ms.MacroList.visibleRows[1].macro.name == "Renamed Account",
            "saved name/body search updates should preserve the active filter and query")
        local renamedUsage, renamedSlots = ms.ActionBarRepository:GetUsage(ms.selectedMacro)
        assert(renamedUsage == 2 and renamedSlots[1] == 3 and renamedSlots[2] == 15,
            "action-bar usage should reconcile after a name/icon/body save")

        ms:SetSearchQuery("")
        ms:SetFilter("all")
        ms.Editor.nameBox:SetUserText("Account")
        ms.Editor.iconButton:GetScript("OnClick")(ms.Editor.iconButton)
        chooseEditorIcon(101)
        ms.Editor.editBox:SetUserText("/cast [@mouseover] Heal")
        actionSlots[3] = { "macro", 1001, "spell", "Account", 101 }
        actionSlots[15] = { "macro", 1001, "spell", "Account", 101 }
        ms:SaveSelectedMacro()
        assert(#timerCallbacks == 1, "restore Save should retain the debounced refresh path")
        RunDeferredTimers()
        assert(baseAccountMacro.name == "Account" and baseAccountMacro.selectedIcon == 101
                and baseAccountMacro.body == "/cast [@mouseover] Heal",
            "combined identity test cleanup should restore the live native macro")
        identityPresentation = ms.MetadataRepository:GetPresentation(ms.selectedMacro)
        assert(identityPresentation.favorite
                and identityPresentation.categoryId == identityCategory.id
                and identityPresentation.tags[1] == "IdentityTag",
            "metadata should also survive a second identity edit")
        ms.MetadataRepository:ToggleFavorite(ms.selectedMacro)
        nativeMacroEventCallback = nil
        deferTimers = false

        ms.Editor.nameBox:SetUserText("Combat Draft")
        local editsBeforeBlockedSave = editCalls
        combat = true
        ms:UpdateCombatState()
        ms:SaveSelectedMacro()
        assert(editCalls == editsBeforeBlockedSave
                and ms.Editor:GetName() == "Combat Draft" and ms.Editor:IsDirty(),
            "combat should block Save without discarding the name/icon/body draft")
        combat = false
        ms:UpdateCombatState()
        assert(editCalls == editsBeforeBlockedSave and ms.Editor:GetName() == "Combat Draft",
            "leaving combat must not retry an identity save")
        ms:RevertSelectedMacro()

        ms:SelectMacro(ms.MacroRepository:FindByIndex(4))
        ms.Editor.nameBox:SetUserText("Draft Character")
        ms.Editor:SetDraftIcon(135000)
        ms.Editor.editBox:SetUserText("/say dirty body")
        baseCharacterMacro.name = "External Char"
        baseCharacterMacro.icon = 134400
        baseCharacterMacro.selectedIcon = 134400
        baseCharacterMacro.body = "/say external native change"
        ms:RefreshMacros("external identity test")
        assert(ms.Editor.externalConflict
                and ms.Editor:GetName() == "Draft Character"
                and ms.Editor:GetIcon() == 135000
                and ms.Editor:GetBody() == "/say dirty body"
                and ms.Editor.stateText:GetText()
                    == "This macro changed outside MacroStudio. Revert to load the latest version.",
            "external UPDATE_MACROS should preserve the full draft and show an actionable conflict")
        editsBeforeBlockedSave = editCalls
        ms:SaveSelectedMacro()
        assert(editCalls == editsBeforeBlockedSave,
            "external conflicts must stop before EditMacro")
        ms:RevertSelectedMacro()
        assert(ms.selectedMacro and ms.selectedMacro.index == 4
                and ms.Editor:GetName() == "External Char"
                and ms.Editor:GetIcon() == 134400
                and ms.Editor:GetBody() == "/say external native change"
                and not ms.Editor:IsDirty() and not ms.Editor.externalConflict
                and ms.Editor.state.canDelete and not ms.Editor.state.canSave,
            "Revert should load the latest name, icon, and body and restore normal eligibility")
        ms.Editor.nameBox:SetUserText("Character")
        ms.Editor:SetDraftIcon(102)
        ms.Editor.editBox:SetUserText("/say character")
        ms:SaveSelectedMacro()
        assert(baseCharacterMacro.name == "Character"
                and baseCharacterMacro.selectedIcon == 102
                and baseCharacterMacro.body == "/say character"
                and not ms.Editor:IsDirty(),
            "external-conflict test cleanup should restore the Character macro")

        createdAccountMacro = {
            name = "Delete Target", icon = 105, selectedIcon = 105, body = "/say delete me",
        }
        ms:RefreshMacros("external deletion fixture")
        ms:SelectMacro(ms.MacroRepository:FindByIndex(2))
        ms.Editor.nameBox:SetUserText("Delete Draft")
        ms.Editor:SetDraftIcon(135000)
        ms.Editor.editBox:SetUserText("/say preserve until revert")
        createdAccountMacro = nil
        ms:RefreshMacros("external deletion test")
        assert(ms.Editor.externalConflict and ms.selectedMacro.index == 2,
            "external deletion should preserve the dirty draft until the user chooses Revert")
        local editsBeforeDeletedRevert = editCalls
        ms:RevertSelectedMacro()
        assert(not ms.selectedMacro and not ms.Editor.macro
                and not ms.Editor:IsDirty()
                and ms.Editor.stateText:GetText():find("deleted outside MacroStudio")
                and editCalls == editsBeforeDeletedRevert,
            "Revert after external deletion should clear selection without targeting a neighbor")

        ms:SelectMacro(ms.MacroRepository:FindByIndex(1))
        identityPresentation = ms.MetadataRepository:GetPresentation(ms.selectedMacro)
        assert(identityPresentation.categoryId == identityCategory.id
                and identityPresentation.tags[1] == "IdentityTag",
            "unrelated metadata should remain stable through conflict recovery")

        local accountRow = ms.MacroList.visibleRows[1]
        assert(accountRow and accountRow.dragButton == "LeftButton",
            "macro rows should register for native left-button dragging")
        assert(accountRow.usageText:IsShown() and accountRow.usageText:GetText() == "On Bar",
            "a used Account macro row should show the subtle usage indicator")
        accountRow:TriggerScript("OnEnter")
        assert(GameTooltip.tooltipTitle == "Account"
                and GameTooltip.tooltipBody == "Click to select\nDrag to place on an action bar"
                    .. "\n\nOn action bars: 2 placements.",
            "normal row hover should hide raw action slot numbers: "
                .. tostring(GameTooltip.tooltipTitle) .. " | "
                .. tostring(GameTooltip.tooltipBody))
        accountRow:TriggerScript("OnLeave")
        shiftDown = true
        accountRow:TriggerScript("OnEnter")
        assert(GameTooltip.tooltipTitle == "Account"
                and GameTooltip.tooltipBody == "Click to select\nDrag to place on an action bar"
                    .. "\n\nOn action bars: 2 placements.\nAction Bar slots: 3, 15",
            "Shift-row hover should reveal raw action slot numbers: "
                .. tostring(GameTooltip.tooltipTitle) .. " | "
                .. tostring(GameTooltip.tooltipBody))
        accountRow:TriggerScript("OnLeave")
        shiftDown = false
        assert(ms.Editor.usageButton:IsShown()
                and ms.Editor.usageButton.Text:GetText() == "On action bars: 2 slots",
            "selected macro detail should show the complete cached placement count")
        ms.Editor.usageButton:TriggerScript("OnEnter")
        assert(GameTooltip.tooltipTitle == "Action Bar Usage"
                and GameTooltip.tooltipBody
                    == "This saved native macro is on an action bar in 2 placements.",
            "normal editor hover should hide raw action slot numbers")
        ms.Editor.usageButton:TriggerScript("OnLeave")
        shiftDown = true
        ms.Editor.usageButton:TriggerScript("OnEnter")
        assert(GameTooltip.tooltipTitle == "Action Bar Usage"
                and GameTooltip.tooltipBody
                    == "This saved native macro is on an action bar in 2 placements."
                        .. "\n\nAction Bar slots: 3, 15",
            "Shift-editor hover should reveal raw action slot numbers")
        ms.Editor.usageButton:TriggerScript("OnLeave")
        shiftDown = false

        local scansBeforeSameNameCreate = ms.ActionBarRepository:GetScanCount()
        deferTimers = true
        nativeMacroEventCallback = function()
            ms:OnMacrosChanged("UPDATE_MACROS")
        end
        local createdSameName, sameNameMacro = ms:CreateNativeMacro({
            name = "Account",
            icon = 202,
            body = "/say same-name duplicate",
            scope = "ACCOUNT",
        })
        assert(createdSameName and sameNameMacro and sameNameMacro.index == 2,
            "same-name Create should return the exact new native macro")
        assert(#timerCallbacks == 1
                and ms.ActionBarRepository:GetScanCount() == scansBeforeSameNameCreate,
            "native Create and synchronous UPDATE_MACROS should debounce to one deferred refresh")
        RunDeferredTimers()
        local originalAccount = ms.MacroRepository:FindByIndex(1)
        local originalCount, originalSlots = ms.ActionBarRepository:GetUsage(originalAccount)
        assert(ms.ActionBarRepository:GetScanCount() == scansBeforeSameNameCreate + 1
                and originalCount == 2
                and originalSlots[1] == 3
                and originalSlots[2] == 15,
            "creating a distinguishable same-name macro must preserve existing action-bar usage")

        local scansBeforeSameNameDelete = ms.ActionBarRepository:GetScanCount()
        assert(ms:DeleteSelectedMacro(ms.Helpers:CopyMacro(sameNameMacro)),
            "same-name regression cleanup should delete the exact created macro")
        assert(#timerCallbacks == 1
                and ms.ActionBarRepository:GetScanCount() == scansBeforeSameNameDelete,
            "native Delete and synchronous UPDATE_MACROS should debounce to one deferred refresh")
        RunDeferredTimers()
        originalAccount = ms.MacroRepository:FindByIndex(1)
        originalCount, originalSlots = ms.ActionBarRepository:GetUsage(originalAccount)
        assert(ms.ActionBarRepository:GetScanCount() == scansBeforeSameNameDelete + 1
                and originalCount == 2
                and originalSlots[1] == 3
                and originalSlots[2] == 15,
            "deleting a same-name neighbor must preserve settled exact action-bar usage")
        nativeMacroEventCallback = nil
        deferTimers = false
        ms:SetFilter("all")
        ms:SelectMacro(originalAccount)
        accountRow = ms.MacroList.visibleRows[1]

        local scansBeforeActionChange = ms.ActionBarRepository:GetScanCount()
        actionSlots[3] = nil
        actionSlots[15] = { "spell", 12345 }
        ms.eventFrame:TriggerScript("OnEvent", "ACTIONBAR_SLOT_CHANGED", 3)
        assert(ms.ActionBarRepository:GetScanCount() == scansBeforeActionChange + 1,
            "a native slot event should request one cached usage refresh")
        assert(not accountRow.usageText:IsShown() and not ms.Editor.usageButton:IsShown(),
            "removing and replacing all macro actions should clear row and selected detail state")
        actionSlots[7] = { "macro", 1001, "spell", "Account", 101 }
        ms.eventFrame:TriggerScript("OnEvent", "ACTIONBAR_SLOT_CHANGED", 7)
        assert(accountRow.usageText:IsShown()
                and ms.Editor.usageButton.Text:GetText() == "On action bars: 1 slot",
            "placing a native macro should restore usage automatically without manual refresh")

        accountRow:GetScript("OnDragStart")(accountRow)
        assert(pickupCalls[#pickupCalls] == 1,
            "Account row drag should pick up its exact native index")
        assert(ms.selectedMacro.name == "Account",
            "dragging should not change normal row selection")

        ms:SetFilter("character")
        local characterRow = ms.MacroList.visibleRows[1]
        assert(characterRow and characterRow.macro.scope == "CHARACTER",
            "Character filter should expose the Character row")
        assert(characterRow.usageText:IsShown(),
            "Character rows should read usage from their exact offset native index")
        characterRow:GetScript("OnDragStart")(characterRow)
        assert(pickupCalls[#pickupCalls] == 4,
            "Character row drag should use its account-capacity offset index")
        assert(ms.selectedMacro.name == "Account",
            "dragging an unselected row should leave selection intact")
        characterRow:GetScript("OnClick")(characterRow)
        assert(ms.selectedMacro.name == "Character",
            "normal clicking should still select a draggable row")
        ms:SelectMacro(ms.MacroRepository:GetAll()[1])
        ms:SetFilter("all")

        assert(ms.Editor.editBox:IsEnabled(), "selected macro editor should be enabled")
        assert(ms.Editor.editorHost.template == "ScrollingEditBoxTemplate",
            "main editor should use Blizzard's native scrolling edit box")
        assert(#ms.Editor.editorFocusBorderEdges == 4,
            "editor focus border should use four explicit edge regions")
        assert(ms.Editor.editorFocusBorder:GetFrameLevel() > ms.Editor.scrollBar:GetFrameLevel(),
            "editor focus border should render above the scrolling controls")
        ms.Editor.editBox:SetFocus()
        assert(ms.Editor.editorFocusBorderActive,
            "editor focus should activate the complete border")
        for _, edge in ipairs(ms.Editor.editorFocusBorderEdges) do
            assert(edge.color[1] == 0.25 and edge.color[2] == 0.62 and edge.color[3] == 1,
                "every editor edge should receive the focused color")
        end
        ms.Editor.editBox:ClearFocus()
        assert(not ms.Editor.editorFocusBorderActive,
            "editor blur should restore the normal border")
        for _, edge in ipairs(ms.Editor.editorFocusBorderEdges) do
            assert(edge.color[1] == 0.18 and edge.color[2] == 0.22 and edge.color[3] == 0.28,
                "every editor edge should receive the normal color")
        end

        ms.Helpers:ShowTooltip(
            ms.MacroList.newMacroButton,
            "Create Native Macro",
            "Create an Account or Character macro."
        )
        assert(GameTooltip.tooltipOwner == ms.MacroList.newMacroButton,
            "button hover should anchor the shared tooltip")
        assert(GameTooltip.tooltipTitle == "Create Native Macro"
                and GameTooltip.tooltipBody == "Create an Account or Character macro.",
            "button hover should populate the expected tooltip")
        assert(GameTooltip.tooltipAlpha == 1 and GameTooltip.tooltipWrap == true,
            "tooltip title should pass numeric alpha before the wrap flag")
        ms.Helpers:HideTooltip()
        assert(not GameTooltip:IsShown(), "button leave should hide the shared tooltip")

        local searchBox = ms.MacroList.searchBox
        local enumerationBeforeSearch = enumerationCalls
        local scansBeforeSearch = ms.ActionBarRepository:GetScanCount()
        assert(searchBox and searchBox:IsEnabled(), "search box should construct as an enabled native EditBox")
        assert(ms.MacroList.searchPlaceholder:IsShown(), "empty unfocused search should show its placeholder")

        searchBox:SetText("account")
        local dirtyDragRow = ms.MacroList.visibleRows[1]
        ms.Editor.editBox:SetText("/say unsaved action-bar draft")
        local editCallsBeforeDrag = editCalls
        dirtyDragRow:GetScript("OnDragStart")(dirtyDragRow)
        assert(pickupCalls[#pickupCalls] == 1 and editCalls == editCallsBeforeDrag,
            "dirty dragging should pick up the saved native macro without calling Save")
        assert(ms.Editor:GetBody() == "/say unsaved action-bar draft" and ms.Editor:IsDirty(),
            "dirty dragging should preserve the unsaved editor draft")
        assert(ms.Editor.usageButton:IsShown(),
            "saved-macro usage should remain visible while the editor has a dirty draft")
        assert(ms.Editor.notice and ms.Editor.notice.message:find("saved version"),
            "dirty dragging should explain that the saved version was picked up")

        local pickupCountBeforeCombat = #pickupCalls
        combat = true
        ms:UpdateCombatState()
        dirtyDragRow:GetScript("OnDragStart")(dirtyDragRow)
        assert(#pickupCalls == pickupCountBeforeCombat,
            "combat should refuse row pickup without changing the cursor payload")
        assert(ms.Editor.notice and ms.Editor.notice.message:find("during combat"),
            "combat refusal should show a concise player-facing message")
        combat = false
        ms:UpdateCombatState()
        ms.Editor:SetEditorText(ms.Editor.savedBody)
        searchBox:SetText("")

        searchBox:SetFocus()
        searchBox:SetText("@mouseover")
        assert(ms:GetSearchQuery() == "@mouseover", "search state should update while typing")
        assert(#ms.MacroList.visibleRows == 1 and ms.MacroList.visibleRows[1].macro.name == "Account",
            "search should match complete macro body text")
        assert(ms.MacroList.visibleRows[1].usageText:IsShown(),
            "search result rows should preserve cached action-bar usage state")
        assert(not ms.MacroList.searchPlaceholder:IsShown() and ms.MacroList.clearSearchButton:IsShown(),
            "active search should hide its placeholder and show Clear")

        searchBox:SetText("ACCOUNT")
        assert(#ms.MacroList.visibleRows == 1 and ms.MacroList.visibleRows[1].macro.name == "Account",
            "search should match macro names case-insensitively")
        ms:SetFilter("character")
        assert(#ms.MacroList.visibleRows == 0,
            "navigation filters should combine with, not be replaced by, search")
        assert(ms.MacroList.visibleEmptyLabels[1]:GetText() == 'No macros match "ACCOUNT".',
            "empty search results should use one query-specific message")
        searchBox:SetText("character")
        assert(#ms.MacroList.visibleRows == 1 and ms.MacroList.visibleRows[1].macro.scope == "CHARACTER",
            "Character plus query should show only matching Character macros")

        ms:SetFilter("all")
        searchBox:SetText("")
        local category = ms.MetadataRepository:CreateCategory("Mythic+")
        assert(category, "search smoke category should be created")
        assert(ms.MetadataRepository:SetCategory(ms.selectedMacro, category.id),
            "search smoke category should be assigned")
        assert(ms.MetadataRepository:AddTag(ms.selectedMacro, "Interrupt"),
            "search smoke tag should be assigned")
        ms.MetadataRepository:ToggleFavorite(ms.selectedMacro)
        ms:RefreshOrganizationUI()

        ms:SetFilter("favorites")
        searchBox:SetText("INTERRUPT")
        assert(#ms.MacroList.visibleRows == 1 and ms.MacroList.visibleRows[1].macro.name == "Account",
            "Favorites plus query should match assigned tags case-insensitively")
        ms.MacroList.visibleRows[1]:GetScript("OnDragStart")(ms.MacroList.visibleRows[1])
        assert(pickupCalls[#pickupCalls] == 1,
            "Favorites-filtered rows should retain the exact native pickup index")
        ms:SetFilter("category", category.id)
        searchBox:SetText("mythic+")
        assert(#ms.MacroList.visibleRows == 1,
            "category-filtered search should match the assigned category name")
        ms.MacroList.visibleRows[1]:GetScript("OnDragStart")(ms.MacroList.visibleRows[1])
        assert(pickupCalls[#pickupCalls] == 1,
            "search plus category rows should retain the exact native pickup index")
        ms.MacroList.clearSearchButton:GetScript("OnClick")(ms.MacroList.clearSearchButton)
        assert(ms:GetSearchQuery() == "" and ms.activeFilter.kind == "category",
            "Clear should preserve the current navigation filter")

        ms:SetFilter("all")
        ms.Editor.editBox:SetText("/say unsaved search draft")
        searchBox:SetText("character")
        assert(ms.Editor:GetBody() == "/say unsaved search draft" and ms.Editor:IsDirty(),
            "search hiding the selected macro must preserve its dirty editor draft")
        assert(ms.selectedMacro.name == "Account" and #ms.MacroList.visibleRows == 1,
            "hidden selection should remain selected independently of visible results")
        ms.Editor:SetEditorText(ms.Editor.savedBody)

        searchBox:SetText("temporary")
        searchBox:TriggerScript("OnEscapePressed")
        assert(ms:GetSearchQuery() == "" and searchBox:HasFocus(),
            "Escape should clear a nonempty query while keeping search focus")
        searchBox:TriggerScript("OnEscapePressed")
        assert(not searchBox:HasFocus(), "Escape on an empty search should release focus")
        assert(enumerationCalls == enumerationBeforeSearch,
            "live search and navigation refinement must not re-enumerate Blizzard macros")
        assert(ms.ActionBarRepository:GetScanCount() == scansBeforeSearch,
            "search and filter rendering must read cached usage without rescanning native action slots")

        searchBox:SetText("account")
        ms.Dialogs:ShowNewCategory(function() return true end)
        assert(ms.Dialogs.inputFrame:IsShown(), "category input should open before modal test")
        ms.MacroDialog:Open({ scope = "ACCOUNT", icon = ms.DEFAULT_ICON })
        assert(not ms.Dialogs.inputFrame:IsShown(),
            "entering Create Macro modal state should close other main-window input")
        assert(ms.MacroDialog:IsShown(), "new macro dialog should construct and open")
        assert(ms:GetSearchQuery() == "account" and searchBox:GetText() == "account",
            "opening the modal should preserve search state")
        assert(ms:IsMainWindowModalBlocked(), "new macro dialog should enter modal state")
        assert(ms.modalOverlay:IsShown() and ms.modalOverlay.mouseEnabled and ms.modalOverlay.mouseWheelEnabled,
            "modal overlay should consume main-window mouse and wheel interaction")
        assert(ms.modalOverlay.allPoints and ms.modalOverlay:GetFrameLevel() > ms.Editor.panel:GetFrameLevel(),
            "modal overlay should cover the complete main window above its controls")
        assert(ms.MacroDialog.bodyHost.template == "ScrollingEditBoxTemplate",
            "macro dialog should use Blizzard's native scrolling edit box")
        assert(ms.MacroDialog.frame.movable and ms.MacroDialog.titleBar.dragButton == "LeftButton",
            "new macro dialog should be movable only through its title bar")
        assert(ms.MacroDialog.frame.clamped, "movable dialog should remain clamped on-screen")
        assert(rawget(ms.MacroDialog.nameBox, "dragButton") == nil and rawget(ms.MacroDialog.bodyBox, "dragButton") == nil,
            "text fields should never initiate dialog dragging")
        ms.MacroDialog.titleBar:GetScript("OnDragStart")(ms.MacroDialog.titleBar)
        assert(ms.MacroDialog.frame.moving, "title drag should start dialog movement")
        ms.MacroDialog.titleBar:GetScript("OnDragStop")(ms.MacroDialog.titleBar)
        assert(not ms.MacroDialog.frame.moving, "title drag stop should end dialog movement")

        ms.MacroDialog.nameBox:SetText("Smoke")
        assert(ms.MacroDialog.createButton:IsEnabled(), "valid dialog should enable Create")
        ms.MacroDialog.bodyBox:SetText("/say preserved")
        combat = true
        ms:UpdateCombatState()
        assert(ms.MacroDialog.nameBox:GetText() == "Smoke"
            and ms.MacroDialog.bodyBox:GetText() == "/say preserved",
            "combat transitions should preserve the modal form")
        assert(ms.MacroDialog:IsShown() and ms:IsMainWindowModalBlocked(),
            "combat should not close or unblock the modal")
        assert(not ms.MacroDialog.createButton:IsEnabled(),
            "combat should block Create without auto-submitting")
        combat = false
        ms:UpdateCombatState()
        assert(ms.MacroDialog.createButton:IsEnabled(),
            "leaving combat should only re-enable valid manual creation")

        ms.Editor.editBox:SetText("/say dirty")
        assert(not ms.MacroDialog.createButton:IsEnabled(), "dirty editor should disable dialog Create")
        ms.Editor:SetEditorText(ms.Editor.savedBody)
        assert(ms.MacroDialog.createButton:IsEnabled(), "clean editor should restore valid dialog Create")
        local pickerIcons = ms.IconPicker:BuildIconList()
        assert(#pickerIcons == 3 and pickerIcons[1] == ms.DEFAULT_ICON
                and pickerIcons[2] == 101 and pickerIcons[3] == 135000,
            "icon picker should retain native icons while canonicalizing question-mark aliases")
        ms.IconPicker:Open(ms.DEFAULT_ICON, function() end)
        assert(ms.IconPicker.frame:IsShown(), "icon picker should construct and open")
        ms.MacroDialog:Close()
        assert(ms:GetSearchQuery() == "account" and searchBox:GetText() == "account",
            "closing the modal should restore interaction without clearing search")
        assert(not ms.MacroDialog:IsShown() and not ms:IsMainWindowModalBlocked(),
            "closing the dialog should completely clear modal state")
        assert(not ms.modalOverlay:IsShown() and not ms.IconPicker.frame:IsShown(),
            "closing the dialog should leave no overlay or child picker behind")
        assert(ms.Editor.editBox:HasFocus(),
            "closing the modal should restore focus to the selected editor")

        ms.MacroDialog:Open({ scope = "ACCOUNT", icon = ms.DEFAULT_ICON })
        ms.MacroDialog.nameBox:GetScript("OnEscapePressed")(ms.MacroDialog.nameBox)
        assert(not ms.MacroDialog:IsShown() and not ms:IsMainWindowModalBlocked(),
            "Escape should close the dialog and clear modal state")

        ms.MacroDialog:Open({ scope = "ACCOUNT", icon = ms.DEFAULT_ICON })
        ms.MacroDialog.cancelButton:GetScript("OnClick")(ms.MacroDialog.cancelButton)
        assert(not ms.MacroDialog:IsShown() and not ms:IsMainWindowModalBlocked(),
            "Cancel should close the dialog and clear modal state")

        local realCreateNativeMacro = ms.CreateNativeMacro
        ms.MacroDialog:Open({ scope = "ACCOUNT", icon = ms.DEFAULT_ICON })
        ms.MacroDialog.nameBox:SetText("Created")
        ms.CreateNativeMacro = function()
            return true, ms.selectedMacro
        end
        ms.MacroDialog:Submit()
        ms.CreateNativeMacro = realCreateNativeMacro
        assert(not ms.MacroDialog:IsShown() and not ms:IsMainWindowModalBlocked(),
            "successful Create should close the dialog and clear modal state")
        assert(not ms.modalOverlay:IsShown() and ms.Editor.editBox:HasFocus(),
            "successful Create cleanup should restore normal editor interaction")

        ms.Dialogs:ShowNewCategory(function() return false, "Visible validation" end)
        ms.Dialogs.inputEditBox:SetText("")
        ms.Dialogs:SubmitInput()
        assert(ms.Dialogs.inputError:GetText() == "Visible validation", "input errors should stay visible")

        ms.Access:SetTakeoverEnabled(false)
        SLASH_COLLISION1 = "/m"
        SlashCmdList.COLLISION = function() end
        ms.Access.unavailableReason = nil
        local collisionEnabled, collisionReason = ms.Access:SetTakeoverEnabled(true)
        assert(not collisionEnabled and collisionReason:find("Another addon")
                and SlashCmdList.MACRO == originalNativeMacroHandler,
            "a competing /m owner should be detected without overwriting either handler")
        SlashCmdList.MACROSTUDIO("")
        assert(SlashCmdList.MACROSTUDIO ~= nil,
            "a takeover collision must leave the dedicated /ms command operational")
        """,
        "@ui-smoke",
    )
    smoke("MacroStudio", namespace)
