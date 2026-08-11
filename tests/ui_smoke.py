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
        function Frame:RegisterEvent(event)
            local registeredEvents = rawget(self, "registeredEvents") or {}
            registeredEvents[event] = true
            self.registeredEvents = registeredEvents
        end
        function Frame:StartMoving() self.moving = true end
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
        function Frame:SetText(value)
            self.text = tostring(value or "")
            RunHandlers(self, "OnTextChanged", false)
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
            if index == 1 then return "Account", 101, "/cast [@mouseover] Heal" end
            if index == 2 and createdAccountMacro then
                return createdAccountMacro.name, createdAccountMacro.icon, createdAccountMacro.body
            end
            if index == 4 then return "Character", 102, "/say character" end
            if index == 5 and createdCharacterMacro then return createdCharacterMacro.name, createdCharacterMacro.icon, createdCharacterMacro.body end
            return nil
        end
        function GetMacroSpell(index)
            return index == 1 and 1001 or nil
        end
        function GetMacroItem() return nil end
        function GetMacroIcons(list)
            list[#list + 1] = 134400
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
        function EditMacro(index, _, _, body)
            editCalls = editCalls + 1
            return index
        end
        function IsShiftKeyDown() return shiftDown end
        function CreateMacro(name, icon, body, perCharacter)
            if perCharacter then
                if createdCharacterMacro then return nil end
                createdCharacterMacro = { name = name, icon = icon, body = body }
                if nativeMacroEventCallback then nativeMacroEventCallback() end
                return 5
            end
            if createdAccountMacro then return nil end
            createdAccountMacro = { name = name, icon = icon, body = body }
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
        ms:OnPlayerLogin()
        assert(ms.initialized, "full UI should initialize")
        assert(ms.frame and not ms.frame:IsShown(), "main window should remain hidden on login")
        assert(ms.selectedMacro and ms.selectedMacro.name == "Account", "initial refresh should select a macro")
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
                and ms.Sidebar.characterToggleButton.macroStudioTooltipTitle == "Show characters",
            "large libraries should default to an obvious collapsed Characters control")
        ms.Sidebar.characterToggleButton:TriggerScript("OnEnter")
        assert(GameTooltip.tooltipTitle == "Show characters",
            "collapsed Characters hover should explain the disclosure action")
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
                and ms.Sidebar.characterToggleButton.macroStudioTooltipTitle == "Hide characters",
            "Characters should use an obvious expanded control and show every character")
        ms.Sidebar.characterToggleButton:TriggerScript("OnEnter")
        assert(GameTooltip.tooltipTitle == "Hide characters",
            "expanded Characters hover should explain the disclosure action")
        ms.Sidebar.characterToggleButton:TriggerScript("OnLeave")
        ms.Sidebar:ToggleCharacterList()
        assert(MacroStudioDB.settings.characterLibraryExpanded == false
                and not ms.Sidebar.charactersExpanded
                and #ms.Sidebar.visibleCharacterButtons == 0
                and ms.Sidebar.characterToggleIcon.texture == "Interface\\Buttons\\UI-PlusButton-UP"
                and ms.Sidebar.characterToggleButton.macroStudioTooltipTitle == "Show characters",
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
        assert(#pickerIcons == 2 and pickerIcons[1] == ms.DEFAULT_ICON,
            "icon picker should canonicalize numeric/path question-mark references to one option")
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
        """,
        "@ui-smoke",
    )
    smoke("MacroStudio", namespace)
