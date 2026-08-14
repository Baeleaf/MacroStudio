"""Synthetic parser, preview, and apply coverage for Portable Import v1."""

import copy
import json


def _macro(identifier, order, scope, name, body, icon):
    kind = "file" if isinstance(icon, int) else "path"
    return {
        "id": identifier,
        "order": order,
        "scope": scope,
        "name": name,
        "icon": {"kind": kind, "value": icon},
        "body": body,
    }


def _model():
    return {
        "format": "MacroStudioPortableLibrary",
        "formatVersion": 1,
        "addonVersion": "1.3.0-r3",
        "accountMacros": [
            _macro("account-001", 1, "ACCOUNT", "Exact", "/say exact", 101),
            _macro("account-002", 2, "ACCOUNT", "Same Name", "/say imported", 103),
            _macro(
                "account-003", 3, "ACCOUNT", "Escaped",
                "/say caf\u00e9 \u6f22\u5b57\n\t\"quoted\" \\ path",
                r"Interface\Icons\INV_Misc_QuestionMark",
            ),
        ],
        "currentCharacter": {
            "id": "current-character",
            "identity": {
                "guid": "Player-SOURCE",
                "name": "Source",
                "realm": "Source Realm",
                "identityCertain": True,
            },
            "macros": [
                _macro("current-character-001", 1, "CHARACTER", "Char Exact", "/say char exact", 201),
                _macro("current-character-002", 2, "CHARACTER", "Char New", "/say char new", 202),
            ],
        },
        "offlineCharacters": [
            {
                "id": "offline-update",
                "identity": {"guid": "Player-OFF-UPDATE", "name": "Update", "realm": "Realm A", "identityCertain": True},
                "lastSynced": 200,
                "macros": [_macro("offline-update-001", 1, "CHARACTER", "Updated", "/say source newer", 301)],
            },
            {
                "id": "offline-local-newer",
                "identity": {"guid": "Player-OFF-LOCAL", "name": "Local Newer", "realm": "Realm B", "identityCertain": True},
                "lastSynced": 100,
                "macros": [_macro("offline-local-001", 1, "CHARACTER", "Older", "/say source older", 302)],
            },
            {
                "id": "offline-same-name",
                "identity": {"guid": "Player-OFF-OTHER", "name": "Shared", "realm": "Same Realm", "identityCertain": True},
                "lastSynced": 150,
                "macros": [_macro(
                    "offline-other-001", 1, "CHARACTER",
                    "Historical Macro Name Longer Than Sixteen", "h" * 400, 303,
                )],
            },
            {
                "id": "offline-zero",
                "identity": {"guid": None, "name": "Zero", "realm": "Quiet Realm", "identityCertain": False},
                "lastSynced": None,
                "macros": [],
            },
        ],
        "organization": {
            "categories": [{"id": "category-001", "name": "Imported Category"}],
            "tags": [
                {"id": "tag-001", "name": "Existing Tag"},
                {"id": "tag-002", "name": "Imported Tag"},
            ],
            "associations": [
                {"macroId": "account-001", "favorite": True, "categoryId": "category-001", "tagIds": ["tag-001", "tag-002"]},
                {"macroId": "account-002", "favorite": True, "categoryId": "category-001", "tagIds": ["tag-002"]},
                {"macroId": "current-character-002", "favorite": True, "categoryId": None, "tagIds": ["tag-002"]},
            ],
        },
    }


def _dump(value):
    return json.dumps(value, ensure_ascii=False, separators=(",", ":"))


def run_import_tests(lua, namespace, large_export_text):
    load = lua.eval("loadstring")
    model = _model()
    valid_text = _dump(model)

    invalid_version = copy.deepcopy(model)
    invalid_version["formatVersion"] = 2
    duplicate_ids = copy.deepcopy(model)
    duplicate_ids["accountMacros"][1]["id"] = duplicate_ids["accountMacros"][0]["id"]
    bad_reference = copy.deepcopy(model)
    bad_reference["organization"]["associations"][0]["macroId"] = "missing-macro"
    missing_field = copy.deepcopy(model)
    del missing_field["accountMacros"][0]["body"]
    bad_character = copy.deepcopy(model)
    bad_character["currentCharacter"]["identity"]["identityCertain"] = False
    bad_scope = copy.deepcopy(model)
    bad_scope["accountMacros"][0]["scope"] = "CHARACTER"
    bad_type = copy.deepcopy(model)
    bad_type["accountMacros"][0]["body"] = 42
    extra_key = copy.deepcopy(model)
    extra_key["unexpected"] = True
    duplicate_character = copy.deepcopy(model)
    duplicate_character["offlineCharacters"][0]["id"] = duplicate_character["currentCharacter"]["id"]
    duplicate_tag_ref = copy.deepcopy(model)
    duplicate_tag_ref["organization"]["associations"][0]["tagIds"].append("tag-002")


    capacity_model = copy.deepcopy(model)
    capacity_model["accountMacros"] = [_macro("account-capacity", 1, "ACCOUNT", "Capacity New", "/say capacity", 401)]
    capacity_model["currentCharacter"]["macros"] = []
    capacity_model["offlineCharacters"] = []
    capacity_model["organization"] = {"categories": [], "tags": [], "associations": []}

    ambiguity_model = copy.deepcopy(capacity_model)
    ambiguity_model["accountMacros"] = [
        _macro("account-ambiguous", 1, "ACCOUNT", "Exact", "/say exact", 101),
        _macro("account-distinct", 2, "ACCOUNT", "Exact", "/say different", 101),
    ]

    failure_model = copy.deepcopy(capacity_model)
    failure_model["accountMacros"] = [
        _macro("account-failure-1", 1, "ACCOUNT", "Failure One", "/say one", 501),
        _macro("account-failure-2", 2, "ACCOUNT", "Failure Two", "/say two", 502),
    ]

    native_invalid_model = copy.deepcopy(capacity_model)
    native_invalid_model["accountMacros"] = [
        _macro("account-long-name", 1, "ACCOUNT", "Account Macro Name Longer Than Sixteen", "/say safe", 701),
    ]
    native_invalid_model["currentCharacter"]["macros"] = [
        _macro("character-long-body", 1, "CHARACTER", "Long Body", "b" * 300, 702),
    ]

    test_chunk = load(
        r"""
        local _, ms, validText, largeText, malformed, truncated, unsupported, duplicateIds,
            badReference, missingField, badCharacter, badScope, badType, extraKey, duplicateKey,
            duplicateCharacter, duplicateTagRef, capacityText, ambiguityText, failureText, nativeInvalidText = ...


        local function expectInvalid(text, fragment)
            local ok, message = pcall(ms.PortableImport.ParseAndValidate, ms.PortableImport, text)
            assert(not ok, "invalid portable text unexpectedly validated")
            message = tostring(message)
            assert(message:find(fragment, 1, true), "missing validation detail: " .. fragment .. " in " .. message)
            assert(not message:find("/say imported", 1, true), "validation errors must not dump macro bodies")
        end

        expectInvalid(malformed, "JSON byte")
        expectInvalid(truncated, "JSON byte")
        expectInvalid(unsupported, "supports format version 1")
        expectInvalid(duplicateIds, "duplicates another export-local ID")
        expectInvalid(badReference, "unknown macro ID")
        expectInvalid(missingField, "missing required field")
        expectInvalid(badCharacter, "must reflect whether a GUID is present")
        expectInvalid(badScope, "expected ACCOUNT")
        expectInvalid(badType, "expected a string")
        expectInvalid(extraKey, "unsupported field")
        expectInvalid(duplicateKey, "duplicate object key")
        expectInvalid(duplicateCharacter, "duplicates another character record ID")
        expectInvalid(duplicateTagRef, "duplicates another tag reference")

        local parsed = ms.PortableImport:ParseAndValidate(validText)
        assert(parsed.formatVersion == 1 and parsed.addonVersion == "1.3.0-r3",
            "format v1 and source addon context should validate independently")
        assert(parsed.accountMacros[3].body:find("caf" .. string.char(195, 169), 1, true)
                and parsed.accountMacros[3].body:find(string.char(230, 188, 162, 229, 173, 151), 1, true)
                and parsed.accountMacros[3].body:find("\n\t", 1, true)
                and parsed.accountMacros[3].icon.kind == "path",
            "Unicode, escapes, multiline bodies, and path icons should round-trip through JSON")
        assert(parsed.offlineCharacters[3].macros[1].name == "Historical Macro Name Longer Than Sixteen"
                and #parsed.offlineCharacters[3].macros[1].body == 400,
            "portable validation must preserve offline names and bodies beyond current native limits")

        local large = ms.PortableImport:ParseAndValidate(largeText)
        assert(#large.accountMacros == 120 and #large.offlineCharacters == 21
                and large.offlineCharacters[1].macros[4].name == "Historical Macro Name Longer Than Sixteen"
                and #large.offlineCharacters[1].macros[5].body == 400
                and large.offlineCharacters[1].macros[6].icon.value == 0,
            "current r5 Export output with archival-only values must pass format-v1 Import validation")

        local nativeCreate = CreateMacro
        local function resetDestination()
            Constants.MacroConsts.MAX_ACCOUNT_MACROS = 6
            Constants.MacroConsts.MAX_CHARACTER_MACROS = 5
            MAX_ACCOUNT_MACROS = 6
            MAX_CHARACTER_MACROS = 5
            accountMacros = {
                { name = "Exact", icon = 101, selectedIcon = 101, body = "/say exact" },
                { name = "Same Name", icon = 103, selectedIcon = 103, body = "/say destination" },
            }
            characterMacros = {
                { name = "Char Exact", icon = 201, selectedIcon = 201, body = "/say char exact" },
            }
            MacroStudioDB = {
                schemaVersion = 4,
                settings = { useMacroStudioSlashCommands = true, showMinimapButton = true, minimapAngle = 225 },
                metadata = { records = {}, nextId = 1 },
                categories = { byId = {}, order = {}, nextId = 1 },
                characterLibrary = { characters = {}, order = {} },
                history = {},
            }
            ms.db = MacroStudioDB
            ms.CharacterMacroLibrary.currentCharacter = nil
            ms.CharacterMacroLibrary.syncCount = 0
            ms.MetadataRepository.attachedByIndex = {}
            ms.MetadataRepository.attachedByRecord = {}
            ms.MetadataRepository.reconciliation = {}
            ms.Editor = { IsDirty = function() return false end }
            ms.RefreshOrganizationUI = function() end
            playerGUID, playerName, playerRealm = "Player-DEST", "Destination", "Destination Realm"
            local current = ms.CharacterMacroLibrary:Initialize()
            local macros = ms.MacroRepository:Refresh()
            ms.CharacterMacroLibrary:RefreshCurrentSnapshot(macros, 500)
            local store = MacroStudioDB.characterLibrary
            local function offline(id, guid, name, realm, synced, body)
                store.characters[id] = {
                    id = id, guid = guid, name = name, realm = realm,
                    displayName = name .. " - " .. realm, normalizedDisplay = (name .. " - " .. realm):lower(),
                    identityCertain = true, lastSynced = synced,
                    macros = { { order = 1, name = "Local", icon = 399, body = body } },
                }
                store.order[#store.order + 1] = id
            end
            offline("guid:Player-OFF-UPDATE", "Player-OFF-UPDATE", "Update", "Realm A", 100, "/say local older")
            offline("guid:Player-OFF-LOCAL", "Player-OFF-LOCAL", "Local Newer", "Realm B", 300, "/say local newer")
            offline("guid:Player-OFF-LOCALNAME", "Player-OFF-LOCALNAME", "Shared", "Same Realm", 125, "/say distinct guid")
            ms.MetadataRepository:Reconcile(macros)
            local destinationCategory = assert(ms.MetadataRepository:CreateCategory("Destination Category"))
            assert(ms.MetadataRepository:SetCategory(macros[1], destinationCategory.id))
            assert(ms.MetadataRepository:AddTag(macros[1], "Existing Tag"))
            return macros
        end

        local originalRefreshUI = ms.RefreshOrganizationUI
        local before = resetDestination()
        local synchronousEvents = 0
        CreateMacro = function(...)
            local index = nativeCreate(...)
            synchronousEvents = synchronousEvents + 1
            ms:OnMacrosChanged("UPDATE_MACROS")
            return index
        end

        local nativeBlocked = ms.PortableImport:Preview(nativeInvalidText, { importCharacterMacros = true })
        assert(nativeBlocked.account.blocked == 1 and nativeBlocked.account.create == 0
                and nativeBlocked.character.blocked == 1 and nativeBlocked.character.create == 0
                and nativeBlocked.capacityOK and not nativeBlocked.nativeContentOK and not nativeBlocked.applyOK,
            "portable native-target records should reach Preview and be classified as uncreatable")
        local blockedWarnings = table.concat(nativeBlocked.warnings, " ")
        assert(blockedWarnings:find("Account macro #1 cannot be created: Macro names are limited to 16 characters.", 1, true)
                and blockedWarnings:find("Character macro #1 cannot be created: Macro bodies are limited to 255 characters.", 1, true),
            "Preview should identify each blocked native target and its current client constraint")
        local writesBeforeBlocked = createCalls
        ms.PortableImport:SetActivePlan(nativeBlocked)
        local blockedOK, _, blockedMessage = ms.PortableImport:Apply(nativeBlocked)
        assert(not blockedOK and blockedMessage:find("cannot be created", 1, true)
                and createCalls == writesBeforeBlocked,
            "Apply must reject a native-invalid full batch without silently skipping or writing")
        local disabledModel = ms.PortableImport:ParseAndValidate(nativeInvalidText)
        disabledModel.accountMacros = {}
        local disabledCharacter = ms.PortableImport:BuildPlan(disabledModel, { importCharacterMacros = false })
        assert(disabledCharacter.character.disabled == 1 and disabledCharacter.character.blocked == 0
                and disabledCharacter.nativeContentOK and disabledCharacter.applyOK,
            "a source Character record should not face native constraints when its native import is disabled")
        local plan = ms.PortableImport:Preview(validText, { importCharacterMacros = true })
        assert(plan.account.create == 2 and plan.account.present == 1 and plan.account.ambiguous == 0,
            "preview should reuse only unique exact Account matches and create same-name different content")
        assert(plan.character.create == 1 and plan.character.present == 1 and plan.character.disabled == 0,
            "preview should target source Character macros to the destination current character")
        assert(plan.currentCharacter == "Destination - Destination Realm",
            "preview must make the destination current character explicit")
        assert(plan.capacityOK and plan.nativeContentOK and plan.applyOK
                and plan.accountAvailable == 4 and plan.characterAvailable == 4,
            "preview should preflight live native scope capacity and content")
        assert(plan.offline.added == 3 and plan.offline.updated == 1 and plan.offline.kept == 1,
            "offline planning should add foreign/zero records, update newer GUID data, and preserve newer local data")
        assert(plan.categoryConflicts == 1 and plan.categoriesAdded == 1 and plan.tagsAdded == 1,
            "preview should expose additive organization work and destination category conflicts")

        local createsBefore, editsBefore, deletesBefore = createCalls, editCalls, deleteCalls
        ms.PortableImport:SetActivePlan(plan)
        local applied, result, message = ms.PortableImport:Apply(plan)
        assert(applied and result and not message, "safe import should apply after explicit active preview")
        assert(result.accountCreated == 2 and result.accountPresent == 1
                and result.characterCreated == 1 and result.characterPresent == 1,
            "apply should report deterministic Account-then-Character native outcomes")
        assert(synchronousEvents == 3 and ms.nativeMutationInProgress == false and ms.pendingMacroRefresh == nil,
            "synchronous UPDATE_MACROS must be contained and followed by explicit final reconciliation")
        assert(editCalls == editsBefore and deleteCalls == deletesBefore,
            "Import must never overwrite or delete native macros")
        local sameBodies, importedSame = {}, nil
        for _, macro in ipairs(ms.MacroRepository:GetAll()) do
            if macro.name == "Same Name" then sameBodies[macro.body] = true end
            if macro.name == "Same Name" and macro.body == "/say imported" then importedSame = macro end
        end
        assert(sameBodies["/say destination"] and sameBodies["/say imported"] and importedSame,
            "same-name different-content macros must coexist")
        local exact = nil
        for _, macro in ipairs(ms.MacroRepository:GetAll()) do
            if macro.scope == "ACCOUNT" and macro.name == "Exact" and macro.body == "/say exact" then exact = macro end
        end
        local exactPresentation = ms.MetadataRepository:GetPresentation(assert(exact))
        assert(exactPresentation.favorite and exactPresentation.categoryName == "Destination Category"
                and ms.MetadataRepository:IsTagAssigned(exact, "Existing Tag")
                and ms.MetadataRepository:IsTagAssigned(exact, "Imported Tag"),
            "exact identity metadata should merge additively while preserving destination category")
        assert(result.categoriesAdded == 1 and result.tagsAdded == 1 and result.favoritesRestored == 3
                and result.metadataConflicts == 1 and result.metadataSkipped == 0,
            "result counts should describe safe organization merging")
        local store = ms.CharacterMacroLibrary:GetStore()
        assert(store.characters["guid:Player-SOURCE"] and store.characters["guid:Player-OFF-OTHER"],
            "foreign current-character and different-GUID same-name records should remain offline snapshots")
        assert(store.characters["guid:Player-OFF-UPDATE"].lastSynced == 200
                and store.characters["guid:Player-OFF-UPDATE"].macros[1].body == "/say source newer"
                and store.characters["guid:Player-OFF-LOCAL"].lastSynced == 300,
            "newer source GUID snapshots should update while newer local snapshots remain intact")
        assert(store.characters["guid:Player-OFF-OTHER"].macros[1].name
                    == "Historical Macro Name Longer Than Sixteen"
                and #store.characters["guid:Player-OFF-OTHER"].macros[1].body == 400,
            "offline Import should preserve archival macro content exactly without native creation")
        for _, characterId in ipairs(store.order) do
            for _, macro in ipairs(store.characters[characterId].macros or {}) do
                assert(macro.index == nil and macro.lastKnownIndex == nil,
                    "offline imports must never store durable native macro indexes")
            end
        end

        local repeatPlan = ms.PortableImport:Preview(validText, { importCharacterMacros = true })
        assert(repeatPlan.account.create == 0 and repeatPlan.account.present == 3
                and repeatPlan.character.create == 0 and repeatPlan.character.present == 2,
            "repeat preview should reuse uniquely exact native macros instead of duplicating them")
        ms.PortableImport:SetActivePlan(repeatPlan)
        local repeated, repeatResult = ms.PortableImport:Apply(repeatPlan)
        assert(repeated and repeatResult and createCalls == createsBefore + 3,
            "repeat apply should be idempotent for native creation")

        local protectedPlan = ms.PortableImport:Preview(validText, { importCharacterMacros = true })
        ms.PortableImport:SetActivePlan(protectedPlan)
        combat = true
        local combatOK, _, combatMessage = ms.PortableImport:Apply(protectedPlan)
        combat = false
        assert(not combatOK and combatMessage:find("Combat Lockdown", 1, true)
                and createCalls == createsBefore + 3,
            "combat must block Apply without queuing native writes")
        ms.Editor = { IsDirty = function() return true end }
        ms.PortableImport:SetActivePlan(protectedPlan)
        local dirtyOK, _, dirtyMessage = ms.PortableImport:Apply(protectedPlan)
        assert(not dirtyOK and dirtyMessage:find("Finish or Revert", 1, true)
                and createCalls == createsBefore + 3,
            "dirty drafts must block Apply without mutation")
        ms.Editor = { IsDirty = function() return false end }

        local stalePlan = ms.PortableImport:Preview(validText, { importCharacterMacros = true })
        ms.PortableImport:SetActivePlan(stalePlan)
        accountMacros[#accountMacros + 1] = { name = "External", icon = 601, selectedIcon = 601, body = "/say external" }
        local staleOK, _, staleMessage = ms.PortableImport:Apply(stalePlan)
        assert(not staleOK and staleMessage:find("changed after Preview", 1, true),
            "external native changes must invalidate stale preview assumptions")
        table.remove(accountMacros)
        ms.MacroRepository:Refresh()

        accountMacros = {}
        for index = 1, 6 do
            accountMacros[index] = { name = "Full " .. index, icon = 610 + index, selectedIcon = 610 + index, body = "/say full" }
        end
        characterMacros = {}
        ms.MacroRepository:Refresh()
        local capacityPlan = ms.PortableImport:Preview(capacityText, { importCharacterMacros = true })
        assert(not capacityPlan.capacityOK and capacityPlan.account.create == 1 and capacityPlan.accountAvailable == 0,
            "insufficient capacity must block the entire batch before mutation")

        resetDestination()
        accountMacros = {
            { name = "Exact", icon = 101, selectedIcon = 101, body = "/say exact" },
            { name = "Exact", icon = 101, selectedIcon = 101, body = "/say exact" },
        }
        characterMacros = {}
        ms.MacroRepository:Refresh()
        local ambiguity = ms.PortableImport:Preview(ambiguityText, { importCharacterMacros = true })
        assert(ambiguity.account.ambiguous == 1 and ambiguity.account.create == 1,
            "multiple exact destination matches must be skipped while same-name different content remains creatable")

        resetDestination()
        accountMacros, characterMacros = {}, {}
        ms.MacroRepository:Refresh()
        local metadataBefore = 0
        for _ in pairs(MacroStudioDB.metadata.records) do metadataBefore = metadataBefore + 1 end

        local failurePlan = ms.PortableImport:Preview(failureText, { importCharacterMacros = true })
        ms.PortableImport:SetActivePlan(failurePlan)
        local attempts = 0
        CreateMacro = function(...)
            attempts = attempts + 1
            if attempts == 2 then return nil end
            local index = nativeCreate(...)
            ms:OnMacrosChanged("UPDATE_MACROS")
            return index
        end
        local failureOK, partial, failureMessage = ms.PortableImport:Apply(failurePlan)
        assert(not failureOK and partial and partial.partial and partial.accountCreated == 1
                and failureMessage:find("1 of 2 planned", 1, true),
            "unexpected native failure should stop without rollback and report confirmed partial results")
        assert(#accountMacros == 1 and deleteCalls == deletesBefore and editCalls == editsBefore,
            "partial failure must retain successful creations without risky delete or overwrite")
        local metadataAfter = 0
        for _ in pairs(MacroStudioDB.metadata.records) do metadataAfter = metadataAfter + 1 end
        assert(metadataAfter == metadataBefore,
            "metadata must not attach after an unresolved native creation failure")

        CreateMacro = function(...)
            local index = nativeCreate(...)
            ms:OnMacrosChanged("UPDATE_MACROS")
            return index
        end
        local retryPlan = ms.PortableImport:Preview(failureText, { importCharacterMacros = true })
        assert(retryPlan.account.present == 1 and retryPlan.account.create == 1,
            "retry preview should reuse the uniquely exact macro created before partial failure")
        ms.PortableImport:SetActivePlan(retryPlan)
        local retryOK = ms.PortableImport:Apply(retryPlan)
        assert(retryOK and #accountMacros == 2, "retry should create only the unresolved remainder")

        CreateMacro = nativeCreate
        ms.RefreshOrganizationUI = originalRefreshUI
        return true
        """,
        "@portable-import-tests",
    )
    assert test_chunk is not None
    result = test_chunk(
        "MacroStudio", namespace, valid_text, large_export_text,
        "{", valid_text[:-1], _dump(invalid_version), _dump(duplicate_ids),
        _dump(bad_reference), _dump(missing_field), _dump(bad_character), _dump(bad_scope),
        _dump(bad_type), _dump(extra_key), '{"format":1,"format":2}',
        _dump(duplicate_character), _dump(duplicate_tag_ref),
        _dump(capacity_model), _dump(ambiguity_model), _dump(failure_model), _dump(native_invalid_model),
    )
    assert result is True
