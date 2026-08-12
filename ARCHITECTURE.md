# MacroStudio Architecture

## Release scope

Version 1.0.0 is the initial public release. It edits, creates, deletes, organizes, and searches Blizzard-native macros. Search uses simple case-insensitive substring matching; advanced query syntax, history/Trash, scope changes, duplication, import/export, and launchers remain unimplemented.

Version 1.1.0 hands native macros to WoW's normal cursor system so players can drag saved macros onto action bars.

Version 1.2.0 observes native Retail action slots and reports where exact saved macros are present. It adds an account-wide cross-character library while keeping the current character native and live; offline snapshots remain read-only and can be copied into a new native Character macro. The editor treats a live native macro's name, saved icon, and body as one draft.

Version 1.2.0 also makes MacroStudio the default `/m` and `/macro` destination, with immediate opt-out, a native-window fallback, compact persistent settings, and optional minimap and AddOn Compartment launchers. It does not replace or modify Blizzard's Macro UI internals, manage action bars, inspect action-bar addon frames, or provide offline native macro access.

Native WoW frames and APIs are used directly. Runtime addon code has no third-party dependency. The Python/Lupa headless harness is development-only.

## Milestone 9.1 portable export

`PortableExport.lua` defines portable format v1 as deterministic, human-inspectable JSON. The interchange version is independent from both the SavedVariables schema and addon release:

```text
format = "MacroStudioPortableLibrary"
formatVersion = 1
addonVersion = "1.3.0-r1"
```

The serializer is narrow and purpose-built. It writes only the fields below in a fixed order, encodes control characters with JSON escapes, preserves UTF-8 bytes and macro-body newlines, and never serializes arbitrary Lua tables. Export and future Import must not use `load`, `loadstring`, or any evaluation of exported text. There is no runtime serialization dependency.

```text
portable library
|-- format, formatVersion, addonVersion
|-- accountMacros[]
|   `-- id, order, scope, name, icon { kind, value }, body
|-- currentCharacter
|   |-- id
|   |-- identity { guid, name, realm, identityCertain }
|   `-- macros[]
|-- offlineCharacters[]
|   |-- id
|   |-- identity { guid, name, realm, identityCertain }
|   |-- lastSynced
|   `-- macros[]
`-- organization
    |-- categories[] { id, name }
    |-- tags[] { id, name }
    `-- associations[] { macroId, favorite, categoryId, tagIds[] }
```

### Portable content

Account and current-character macro definitions come from the saved in-memory native repository, never the editor draft. Each definition includes its native scope, exact saved name, selected icon identity, unchanged body, and deterministic export-local ID/order. A numeric icon remains a numeric file identity; a path remains an exact string path.

The current character carries source GUID when available plus name and realm for context. Offline characters are emitted in stored library order with separate identities, optional last-synced timestamps, and ordered snapshots. A foreign GUID is source context only; MS9.2 must never treat it as proof that an imported Character macro belongs to the current native character.

Categories retain their explicit order. Canonical tags use deterministic case-insensitive order. Organization associations point to export-local macro IDs derived from exact live repository attachments. Duplicate names therefore remain separate, and metadata attached to only one duplicate cannot migrate to its neighbor by name. Unresolved/stale reconciliation records are not guessed onto an export target.

### Intentionally excluded state

Portable format v1 does not contain:

- native macro indices or durable native handles;
- action-bar slots, cached `On Bar` usage, resolved spell/item identities, or action-bar events;
- reconciliation caches, stale-index evidence, conflict state, dirty drafts, or open-dialog state;
- SavedVariables schema internals, migration counters, debug state, or temporary caches;
- window position/size, minimap position/visibility, slash-command takeover, or other local presentation settings;
- `macros-cache.txt` or any Blizzard cache-file content.

These values are runtime-derived, machine-specific, transient, or unsafe as portable identity. Export does not serialize `MacroStudioDB` wholesale.

### Read-only generation and display

`PortableExport:Generate()` only observes `MacroRepository`, `CharacterMacroLibrary`, and `MetadataRepository`. It does not refresh repositories or snapshots and cannot call `CreateMacro`, `EditMacro`, or `DeleteMacro`. Export works during combat, does not save/discard a dirty editor, and does not change categories, tags, Favorites, action bars, ordering, or local settings.

`UI/ExportDialog.lua` presents the complete string in one native scrolling EditBox with unlimited configured letters. After assignment it compares the EditBox text byte-for-byte with the generated export. A 4 MiB safety ceiling is far above the tested near-full native and multi-character libraries; exceeding it or any client truncation produces a visible failure and no partial backup text. Addons cannot write to the operating-system clipboard, so the user explicitly selects the text and presses Ctrl+C.

### MS9.2 Import contract

Import is intentionally absent from MS9.1. A future importer must treat all text as untrusted data and follow this sequence:

1. Parse JSON without executing code.
2. Require the known format name/version and validate every type, length, required field, reference, and count within conservative limits.
3. Resolve all category, tag, character, icon, and macro-ID references before proposing changes.
4. Present a preview of creations, metadata associations, unsupported content, and duplicate/conflict choices.
5. Never treat a native index, macro name alone, or foreign GUID as current native identity.
6. Perform no native write until the user explicitly confirms the validated plan.
7. Revalidate capacity, combat state, and exact native targets immediately before each authorized write, and fail safely without overwriting existing macros.

## Milestone 8 Retail and 12.1 access research

Research compared installed Retail `12.0.7.68974` and extracted Blizzard UI source commit `c878310d8432a65bac029c7bacc24eeb2e662bbe` with 12.1 source tag `12.1.0`, commit `057e2e1429765a2b9e9eb100889f2b7e50317307` (`12.1.0.69214`). In both clients, `Blizzard_ChatFrameBase` registers the logical `SLASH_COMMAND.MACRO` command through `SlashCommandUtil.CheckAddSlashCommand`; the localized `SLASH_MACRO1` and `SLASH_MACRO2` aliases supply `/macro` and `/m` on the English client. `CheckAddSlashCommand` installs one callback in `SlashCmdList` for both aliases.

The Retail slash registry intentionally keeps `SlashCmdList` and `hash_SlashCmdList` accessible for addons that dynamically register, unregister, or invoke commands. Before parsing a slash command, ChatFrame imports current alias/handler registrations into its hash. Replacing the existing logical command callback therefore takes effect without reload; restoring the exact captured callback gives both aliases back immediately without fabricating Blizzard behavior.

MacroStudio waits one zero-delay timer after `PLAYER_LOGIN` before capture so normal addon load and login handlers can settle. It requires the current logical callback to be a secure Blizzard-owned variable and checks for another registered command key using `/m` or `/macro`. If ownership is already changed or ambiguous, takeover fails conservatively, reports the limitation in Settings/debug output, and leaves the competing handler plus MacroStudio's dedicated `/ms` and `/macrostudio` commands untouched. MacroStudio does not poll or repeatedly reclaim aliases. An addon that replaces the command later can still win by load order; when MacroStudio notices that condition during opt-out, it does not overwrite the newer owner.

Blizzard's macro command performs the client policy checks and calls `ShowMacroFrame()`. Retail loads the load-on-demand `Blizzard_MacroUI` through `MacroFrame_LoadUI()` and then calls `MacroFrame_Show()`/`ShowUIPanel`. In 12.1, the same public `ShowMacroFrame()` entry point is supplied by `Blizzard_MacroUI_Bootstrap.lua [Bootstrap]`, which loads the addon and shows the frame. `/ms blizzard` first invokes the trusted captured Blizzard callback, preserving its current policy and load/show behavior; `ShowMacroFrame()` plus the load-on-demand API remains a guarded fallback if capture is unavailable. Neither path reads, saves, or discards a MacroStudio draft.

The current AddOn Compartment implementation enumerates enabled addons at `PLAYER_ENTERING_WORLD` and reads `AddonCompartmentFunc`, optional `AddonCompartmentFuncOnEnter`/`AddonCompartmentFuncOnLeave`, and `IconTexture`/`IconAtlas` TOC metadata. MacroStudio uses those supported metadata fields and global callbacks. It does not register against `AddonCompartmentFrame` internals, and this launcher remains independent of the optional traditional minimap button.

### Access and settings model

`Access.lua` owns every slash entry and the AddOn Compartment callbacks. `/ms` and `/macrostudio` always remain registered to MacroStudio. The persisted takeover flag selects either the stable MacroStudio callback or the exact captured Blizzard callback for the native logical command key. `/ms blizzard`, `/ms settings`, `/ms refresh`, debug controls, help, and the empty toggle command are dispatched without passing unknown text into chat.

The same `Access.lua` controller owns Settings visibility. `/ms settings` opens or raises the singleton Settings frame, the title-bar control toggles that frame while leaving the main window open, and minimap right-click toggles Settings together with the main window. Every decision derives from the frames' actual shown state rather than a parallel visibility flag.

`MinimapButton.lua` creates one native, draggable button using `Media/MacroStudioIcon.tga`. Drag updates exist only between `OnDragStart` and `OnDragStop`; the saved angle is converted to a fixed radial point on the standard Blizzard minimap. No library, permanent `OnUpdate`, protected write, or custom-minimap compatibility claim is involved. `UI/Settings.lua` provides the two General checkboxes and applies both settings immediately.

Schema 4 adds only `useMacroStudioSlashCommands = true`, `showMinimapButton = true`, and `minimapAngle = 225`. Migration remains idempotent and non-destructive. Existing window geometry, category/tag/Favorite metadata, character snapshots, and every unrelated preference remain untouched.

## Milestone 7 Retail macro identity research

Research used installed Retail `12.0.7.68974` and the matching extracted Blizzard UI source at commit `c878310d8432a65bac029c7bacc24eeb2e662bbe`. Blizzard's Macro UI calls `EditMacro(actualIndex, name, iconTexture)` for name/icon changes and `EditMacro(actualIndex, nil, nil, body)` for body changes. The name/icon path uses the returned global macro index to restore selection, so MacroStudio must treat that return as reconciliation evidence rather than assume an edit preserves enumeration position.

The native selector limits names to 16 letters, strips quotation marks before submission, and enables confirmation only for a nonempty result. It performs no duplicate-name rejection. Account and Character macros share the global native index space; Blizzard subtracts the active scope's base only for its tab-local selection, and `EditMacro` has no scope-changing argument.

For icon editing, Blizzard reads the saved choice with `C_Macro.GetSelectedMacroIcon(actualIndex)`. This is distinct from a potentially resolved `GetMacroInfo` texture for a dynamic `#showtooltip` macro. The icon provider reserves its first entry for `Interface\\Icons\\INV_MISC_QUESTIONMARK`, then exposes the normal macro icon collections. MacroStudio therefore carries the saved selected icon through drafts and exact-target validation while allowing the rendered native icon to resolve normally.

Generated API documentation marks `UPDATE_MACROS` as synchronous. Name, icon, and body saves must therefore use the existing native-mutation gate and one deferred reconciliation after the single `EditMacro` call. The operation remains a protected native write: MacroStudio permits drafting in combat but retains its `InCombatLockdown()` Save guard and never retries automatically after combat.

## Module responsibilities

```text
Core.lua
|-- Database.lua
|-- Access.lua
|-- MinimapButton.lua
|-- MacroRepository.lua
|-- CharacterMacroLibrary.lua
|-- ActionBarRepository.lua
|-- MetadataRepository.lua
|-- Utils/Helpers.lua
|-- Search.lua
`-- UI/MainFrame.lua
    |-- UI/Dialogs.lua
    |-- UI/IconPicker.lua
    |-- UI/MacroDialog.lua
    |-- UI/Sidebar.lua
    |-- UI/MacroList.lua
    |-- UI/Settings.lua
    `-- UI/Editor.lua
```

- `Access.lua` owns dedicated slash commands, conservative native-handler capture/restore, native fallback access, the shared Settings controller, and supported AddOn Compartment callbacks.
- `MinimapButton.lua` owns the optional native minimap launcher and persisted radial placement.
- `MacroRepository.lua` is the only layer that calls `GetNumMacros`, `GetMacroInfo`, `EditMacro`, `CreateMacro`, `DeleteMacro`, or `PickupMacro`.
- `CharacterMacroLibrary.lua` resolves conservative character identity, replaces the current character snapshot from saved live repository data, builds cross-character views, and forgets offline snapshots.
- `ActionBarRepository.lua` owns native action-slot inspection and builds a conservative, read-only exact macro snapshot to raw-slot lookup.
- `MetadataRepository.lua` owns virtual organization records, preserves them through trusted native identity edits, and removes the trusted record for a MacroStudio-deleted macro before reconciliation.
- `PortableExport.lua` builds portable format v1 and serializes only its fixed interchange schema in deterministic JSON.
- `UI/ExportDialog.lua` owns the singleton scrollable Export view, exact display verification, and visible size/truncation failures.
- `Utils/Helpers.lua` centralizes Blizzard scrolling EditBox construction, exact overlay borders, mouse/focus configuration, tooltips, and disabled styling.
- `Search.lua` performs read-only matching against native macro fields and attached metadata.
- `UI/Editor.lua` owns the unified name/icon/body draft, derives Save/Delete state, reuses the icon picker, and owns the editor's complete four-edge focus treatment.
- `UI/MacroDialog.lua` derives Create state and owns the movable dialog and modal lifecycle.
- `UI/IconPicker.lua` uses Blizzard's icon provider when available and compatible API fallbacks otherwise.
- `UI/MacroList.lua` decides which scope headers are meaningful for the active filter and starts native left-button row drags.
- `UI/Settings.lua` owns the compact General settings presentation and immediate checkbox state.
- `UI/MainFrame.lua` coordinates selection, native mutations and pickup notices, organization refresh, dialogs, and the interaction-blocking modal overlay.

UI modules never call raw native macro mutation or pickup APIs.

## Blizzard-owned and MacroStudio-owned data

Blizzard owns every native macro's name, body, icon, scope, and current enumeration index. MacroStudio writes through the native macro APIs and never creates a parallel execution mechanism.

`MacroStudioDB` schema 4 stores settings, virtual metadata, and the account-wide character snapshot library. Organization records use opaque IDs and carry a reconciliation snapshot:

```text
scope, lastKnownIndex, name, icon, body
```

The last-known index is evidence, not a durable key. Categories, Favorites, and tags have no effect on native execution.

Native repository records retain both the rendered `GetMacroInfo` texture and the saved `C_Macro.GetSelectedMacroIcon` value. Exact edit and metadata identity uses the saved choice so a dynamic question-mark icon can resolve visually without changing the target snapshot.

## Cross-character macro library

### Retail API research

Research used installed Retail `12.0.7.68974` and matching Blizzard UI source `12.0.7 (68974)`. Blizzard Macro UI uses `GetNumMacros()` for Account/current-character counts and `GetMacroInfo(index)` over the loaded native collection; Character indices are offset by `MAX_ACCOUNT_MACROS`. `CreateMacro`, `EditMacro`, `DeleteMacro`, and `PickupMacro` likewise operate only on that loaded collection.

Generated Retail `C_Macro` documentation provides no supported way to enumerate or select another offline character's macros. MacroStudio therefore never invents an offline native handle. `UnitGUID("player")` provides the preferred durable character identity, while `UnitFullName`, `UnitName`, `GetRealmName`, and `GetNormalizedRealmName` provide display data. `UPDATE_MACROS`, login, and deferred `PLAYER_ENTERING_WORLD` handling refresh the current native repository and snapshot.

### Storage, identity, and lifecycle

Schema 3 adds this account-wide SavedVariables model:

```text
characterLibrary
|-- order[] -> character key
`-- characters[character key]
    |-- id, guid, name, realm, displayName, normalizedDisplay
    |-- identityCertain, lastSynced
    `-- macros[]
        `-- order, name, body, icon
```

The normal key is `guid:<player GUID>`. A rename or realm transfer updates the display fields on that same GUID record. Different GUIDs remain separate even when Name-Realm is identical. When a GUID is unavailable, MacroStudio creates a new uncertain identity instead of merging by name; this preserves data and fails safely.

Every successful refresh replaces that character's complete stored macro array. It copies only saved live Character macro fields and never editor drafts, Account macros, native indices, action-bar slots, or organization metadata. Save, Create, Delete, `UPDATE_MACROS`, login, manual refresh, and world entry feed the same event-driven path; there is no per-frame scan.

```text
current native macro event
        |
        v
MacroRepository refresh
        |
        v
replace current GUID snapshot

navigation/search
        |
        v
read live current data + stored offline data
```

### Live and offline safety

Cross-character records carry an explicit `source`: `LIVE` for the current character and `SNAPSHOT` for offline characters. Current-character views always rebuild from `MacroRepository`; the stored copy never overrides live data. Offline records never contain a native index, so they cannot target `EditMacro`, `DeleteMacro`, `PickupMacro`, or action-bar usage.

Offline editor text remains enabled for native selection, scrolling, and copy shortcuts, but any mutation is immediately restored from the snapshot. Save, Revert, Delete, drag, action-bar usage, Favorite, category, and tag controls are unavailable. Organization metadata is intentionally not associated with offline snapshots because the existing metadata identity is scoped to loaded native macros.

Copy to Current Character re-resolves the exact offline record, then calls the existing `CreateNativeMacro` path with only name, body, icon, and Character scope. Native name/body/icon validation, capacity, combat lockdown, question-mark icon behavior, duplicate names, repository refresh, and current snapshot refresh remain owned by the existing creation path. Copy never transfers organization metadata or modifies the source snapshot.

Forget Character is limited to offline records, requires confirmation, and deletes only that character key from `characterLibrary`. It cannot forget the current character or touch Blizzard macros, Account macros, or unrelated MacroStudio data.

The cross-character invariants are:

1. Offline snapshots are data copies, never native macro handles.
2. Native macro indices are never persisted as offline identity.
3. Character identity is never merged by display name alone.
4. Duplicate macro names remain legal and isolated by character.
5. Current-character live data always wins over its stored snapshot.
6. Offline data cannot invoke Save, Delete, pickup, or action-bar lookup against a native index.
7. Ambiguous identity preserves separate data rather than mutating another character.

## Exact native mutation rules

Every Save and Delete starts from a copied snapshot. Immediately before the mutation, the repository re-reads the enumerated index and requires index, scope, name, saved icon choice, and body to match. This prevents a shifted neighbor or same-name duplicate from becoming the target.

Save validates the complete draft, passes the enumerated index plus name, saved icon, and body to one `EditMacro` call, refreshes, and resolves the returned/original/unique full-field result. A returned index is evidence, not durable identity. Duplicate names remain legal, and no save path finds a target by name. Create refreshes capacity, validates all fields, calls `CreateMacro`, refreshes, and selects the returned or uniquely matching record. Delete refreshes, revalidates the exact snapshot, calls `DeleteMacro(index)`, and requires the relevant scope count to decrease by one.

Name validation follows Retail's 16-letter limit, removes unsupported quotation marks, and rejects only empty results; duplicate names are not rejected. For a dirty external conflict, Revert compares the pre-event repository baseline with the settled native list. It accepts a unique unchanged identity or a stable edited slot whose surrounding scope topology proves it did not shift; deletion or ambiguity clears selection instead of targeting a neighbor.

`UPDATE_MACROS` can fire synchronously during a native mutation or before action-bar identity has settled. `UI/MainFrame.lua` coalesces those notifications and defers one repository, snapshot, metadata, and action-bar reconciliation until after the mutation completes. For Delete, the trusted metadata record is still removed first so a shifted neighbor cannot inherit it.

## Native action-bar drag handoff

Macro-list rows register for Blizzard's native left-button drag gesture. `OnDragStart` passes the row's saved snapshot to `MacroRepository:Pickup`, which re-reads the same native index and requires index, scope, name, icon, and body to match before calling `PickupMacro(index)`. It never looks up a macro by name, so duplicate names remain safe. A stale row is refused rather than redirected to a shifted neighbor.

`PickupMacro` is unavailable during combat lockdown. MacroStudio checks `InCombatLockdown()` first, leaves the cursor unchanged, and shows a concise message instead of attempting a secure workaround. It also does not call `ClearCursor`, matching Blizzard's own Macro UI handoff behavior when the cursor already holds something.

Pickup uses the saved native macro. It never saves an editor draft, creates a temporary macro, or changes category, tag, Favorite, body, name, icon, or scope metadata. When the dragged row is the dirty editor selection, MacroStudio explains that the saved version was placed on the cursor.

MacroStudio stops after `PickupMacro(index)`. Blizzard's standard action buttons receive the normal cursor payload and perform their own drop, swap, and cancel behavior. MacroStudio does not call `PlaceAction`, emulate action buttons, or hardcode action-bar frame names. Compatible third-party bars can consume the same native payload, but real-client testing is still required.

## Native action-bar usage inspection

Research was performed against installed Retail `12.0.7.68974` and the matching `12.0.7 (68974)` Blizzard UI source. Current FrameXML proves that `GetActionInfo(slot)` does not reliably return a native macro index for type `macro`. When the subtype is `spell`, Blizzard compares the returned ID directly with spell IDs; unresolved macros may expose no useful resolved subtype. Treating that number as a macro index can therefore assign a slot to an unrelated macro whose index happens to equal a resolved action ID.

Retail exposes no read-only underlying macro-index getter for an occupied action slot. MacroStudio instead starts from `C_ActionBar.GetActionText(slot)`, then requires current spell/item resolution from `GetMacroSpell` or `GetMacroItem` to agree with the action subtype and ID. A fixed macro icon must also agree with `C_ActionBar.GetActionTexture(slot)`; a dynamic question-mark icon is accepted only when spell or item resolution provides non-name evidence. The action text is one candidate attribute, never identity by itself.

Exactly one candidate must satisfy every available attribute, and its full repository snapshot is re-read before caching. Zero candidates are unresolved; multiple candidates are ambiguous. Both results intentionally omit the indicator. This preserves the invariant: MacroStudio never displays `On Bar` unless action-bar usage can be safely associated with that exact saved native macro.

Retail FrameXML defines 12 slots per action page and page indexes through 18: normal and multi-action pages, followed by vehicle page 16, temporary shapeshift page 17, and override page 18. MacroStudio scans raw slots 1 through 216. Normal hover reports placement presence and, when there are multiple placements, the count; Shift-hover additionally reveals the raw slot numbers for diagnostics. MacroStudio does not infer player-facing bar names because paging, bonus, stance, vehicle, and override states can remap which page the main bar presents.

The generated Retail API documentation identifies `ACTIONBAR_SLOT_CHANGED` as the native content-change event; Blizzard's own action-button handler treats payload `0` as an all-slots change. MacroStudio also refreshes for:

- `PLAYER_ENTERING_WORLD`
- `ACTIONBAR_PAGE_CHANGED`
- `UPDATE_BONUS_ACTIONBAR`
- `UPDATE_VEHICLE_ACTIONBAR`
- `UPDATE_OVERRIDE_ACTIONBAR`
- `UPDATE_SHAPESHIFT_FORM`
- `UPDATE_POSSESS_BAR`

`UPDATE_MACROS` remains part of macro reconciliation. Its handler schedules one deferred, debounced refresh that rebuilds the macro repository before action usage, so Create, Save, Delete, rename, and index shifts are checked against settled exact snapshots. An action-only event performs the same current-snapshot validation against the existing repository; a mismatch is omitted until reconciliation instead of being assigned to a neighbor.

The data path is:

```text
native action-bar event
        |
        v
one deferred scan of slots 1..216
        |
        v
unique text + resolution + icon evidence + full snapshot validation
        |
        v
cached index -> sorted raw slot list
        |
        +--> visible row indicator/tooltip
        `--> selected editor count/tooltip
```

The scan is event-driven and observational: there is no `OnUpdate`, protected write, cursor mutation, secure-frame workaround, `PlaceAction`, or third-party frame inspection. `/ms debug on` logs only structural slot/type/ID/subtype/text/resolution-result fields and never macro bodies. Search, filtering, row rendering, and dirty editor changes only read the cache and never rescan native slots.

## Duplicate names and metadata reconciliation

Duplicate detection is case-insensitive and isolated by scope. Names are never used alone for Save or Delete.

Meaningful metadata records reconcile against currently unclaimed macros using decreasing confidence:

1. unique scope/name/icon/body;
2. unique scope/name/icon;
3. unique scope/name/body.

Ambiguous or unmatched records remain stored but unattached. Each current macro can receive at most one record. Empty records are pruned.

## Search and filter flow

```text
MacroRepository:GetAll() (already refreshed in memory)
        |
        v
active navigation predicate
        |
        v
Search:Matches(name, complete body, category, tags)
        |
        v
MacroList:Rebuild(visible matches)

selected macro + editor draft --------------------> unchanged
```

Each search keystroke updates only the in-memory query and rebuilds pooled macro-list rows. It does not call Blizzard enumeration APIs, reconcile metadata, rebuild the sidebar/editor, or write SavedVariables. A straightforward substring scan is sufficient for Retail's bounded macro collection, so no debounce is used.

Search refines the active All, Account, Character, Favorites, or category view. While a query is active, empty scope sections are omitted and one query-specific message represents zero results. Clearing the query retains the navigation filter.

Selection is intentionally independent from visibility. Search can hide the selected row while its editor and dirty draft remain intact. Metadata mutations rebuild the list immediately; Create and Delete preserve both query and navigation state. The query remains in memory while the window is toggled and resets when the addon initializes after `/reload` or login.

## Central editor and action state

`Editor:UpdateEditorState()` derives:

```text
name, icon, body,
nameDirty, iconDirty, bodyDirty, dirty,
validContent, length, overBy, targetSafe,
canSave, saveReason, canRevert, canDelete, deleteReason
```

Save requires a selected dirty live target, a valid nonempty name and saved icon, at most 255 body characters, no combat, no external conflict, and an exact current snapshot. Delete additionally requires the complete form to be clean. Create is disabled while combat-locked, at capacity, or while automatic selection would discard a dirty draft. Repository methods repeat the important validation defensively.

The main editor and creation dialog use Blizzard's `ScrollingEditBoxTemplate` with a registered `MinimalScrollBar`. The template owns caret rendering, mouse drag selection, multiline keyboard navigation, and cursor scrolling; MacroStudio hooks its scripts without replacing that native behavior.

The one-pixel Backdrop border sits below child frames, so the main editor also uses four exact edge textures on a non-interactive frame above its scrolling controls. Focus and blur recolor all four edges together; the overlay shares the editor border's anchors and therefore remains aligned during resize and scroll.

Programmatic loads suppress name/body change handling, load the saved icon draft, then recompute once. Revert restores all three saved fields. External refresh never overwrites a dirty name, icon, or body draft.

## Input and Favorite UI

The live name field enforces the native maximum and provides inline validation. Clicking the live icon opens the shared picker in modal state; choosing an icon changes only the draft, and closing without a choice leaves it unchanged. Offline snapshots replace those controls with plain name text and a display-only icon while the body remains selectable for copying.

Category and tag text input uses one custom dialog. Enter invokes the same validated submit path as the visible button, Escape cancels, and invalid input stays in the dialog with an inline error.

Tag Add menus contain all unique existing tags not assigned to the selected macro, plus **Create New Tag...**. Tag spelling is canonicalized case-insensitively.

Favorites use Blizzard's `PetJournal-FavoritesIcon` atlas rather than Unicode font glyphs. The editor also changes the atlas treatment, label, and backdrop so active state is obvious without relying on color alone.

## Modal macro creation

Showing Create Macro activates a full-size, mouse-enabled overlay above every main-window control and below the `FULLSCREEN_DIALOG` creation frame. The overlay consumes clicks and mouse-wheel input; it is functional input blocking, not only a dimming effect. Metadata menus and tooltips are closed as modal state begins.

The dialog can move only from its dedicated title bar. Name, body, scope, icon, and the blocked underlying search control do not start movement, and the frame remains clamped to the screen.

The dialog's `OnHide` path is the single cleanup point for Cancel, Escape, the close button, successful creation, and main-window closure. It clears form focus, closes a child icon picker, hides the modal overlay, and restores focus to an enabled selected editor when the main window remains open. Combat state updates validation in place: form contents and modal blocking remain, Create stays blocked, and leaving combat never submits automatically.

## Combat and non-destructive invariants

- The workspace and drafts remain readable/editable in combat; native Create, Save, and Delete are blocked.
- Leaving combat recomputes eligibility and never auto-saves.
- Over-limit text is never truncated.
- Dirty drafts are never silently replaced.
- Ambiguous native targets and metadata are never guessed.
- Category/tag/Favorite actions never mutate a native macro.
- Imported text, when implemented, must never be executed as Lua.
