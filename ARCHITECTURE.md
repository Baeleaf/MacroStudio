# MacroStudio Architecture

## Release scope

Version 1.3.0 targets Retail 12.1.5 (Interface 120105) and introduces the accepted Warcraft-native UI as the default, with an optional Legacy appearance. It preserves the macro workflows and schema 4 saved data. Current release preparation and live smoke-test status are recorded in `RELEASE-1.3.0.md`.

`settings.appearance` is account-wide and defaults to `warcraft` for new and existing installs without an explicit choice. `UI/LegacyTheme.lua` chooses the active presentation after saved-data initialization, before constructing frames. Both presentations share the same UI controllers and macro repositories; no feature implementation is forked. Palette arrays are updated in place so existing editor status/focus references remain valid. A changed preference stays pending until reload. Settings offers an explicit Reload UI action and blocks that action while a macro draft or creation form is open. The appearance preference is an additive schema 4 setting; no database reset or schema bump is needed.

Version 1.0.0 is the initial public release. It edits, creates, deletes, organizes, and searches Blizzard-native macros. Search uses simple case-insensitive substring matching; advanced query syntax, history/Trash, scope changes, duplication, import/export, and launchers remain unimplemented.

Version 1.1.0 hands native macros to WoW's normal cursor system so players can drag saved macros onto action bars.

Version 1.2.0 observes native Retail action slots and reports where exact saved macros are present. It adds an account-wide cross-character library while keeping the current character native and live; offline snapshots remain read-only and can be copied into a new native Character macro. The editor treats a live native macro's name, saved icon, and body as one draft.

Version 1.2.0 also makes MacroStudio the default `/m` and `/macro` destination, with immediate opt-out, a native-window fallback, compact persistent settings, and optional minimap and AddOn Compartment launchers. It does not replace or modify Blizzard's Macro UI internals, manage action bars, inspect action-bar addon frames, or provide offline native macro access.

Native WoW frames and APIs are used directly. Runtime addon code has no third-party dependency. The Python/Lupa headless harness is development-only.

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
|-- MacroLinter.lua
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
- `Utils/Helpers.lua` centralizes Blizzard scrolling EditBox construction, exact overlay borders, mouse/focus configuration, tooltips, and disabled styling.
- `Search.lua` performs read-only matching against native macro fields and attached metadata.
- `MacroLinter.lua` analyzes text only and returns deterministic advisory diagnostics; it has no WoW API, execution, compiler, repository, or SavedVariables dependency.
- `UI/Editor.lua` owns the unified name/icon/body draft, derives Save/Delete state, reuses the icon picker, and owns the editor's complete four-edge focus treatment.
- `UI/MacroDialog.lua` derives Create state and owns the movable dialog and modal lifecycle.
- `UI/IconPicker.lua` uses Blizzard's icon provider when available and compatible API fallbacks otherwise.
- `UI/MacroList.lua` decides which scope headers are meaningful for the active filter and starts native left-button row drags.
- `UI/Settings.lua` owns the compact General settings presentation and immediate checkbox state.
- `UI/MainFrame.lua` coordinates selection, native mutations and pickup notices, organization refresh, dialogs, and the interaction-blocking modal overlay.

UI modules never call raw native macro mutation or pickup APIs.

## Milestone 10: advisory macro linting (unreleased)

`MacroLinter:Analyze(body)` returns a fresh array of `{ code, severity, line, column, message }` records, ordered by line and column. Locations are 1-based; columns count Lua string bytes, not rendered glyphs. CRLF and CR line endings normalize to LF for analysis only. The analyzer never rewrites the supplied text. Error, Warning and Suggestion are presentation severities; the MVP emits only Error and Warning.

The command allowlist is `/cast`, `/use`, and `/castsequence` (English spellings, case-insensitive). Each semicolon alternative is scanned for leading conditional groups. Empty `[]`, adjacent groups, whitespace-separated groups, unknown conditional names/values, and deliberate empty alternatives are accepted. Once an action payload begins, its brackets are opaque. Hyperlink data and labels are skipped when finding semicolon boundaries. Other commands, Lua, chat, and comments are ignored. This deliberately avoids a universal bracket validator or an incomplete list of valid conditional keywords.

| Code | Severity | Trigger |
| --- | --- | --- |
| `UNCLOSED_CONDITIONAL` | Error | A leading conditional `[` is not closed before the alternative/line ends. |
| `UNEXPECTED_CLOSE` | Error | A leading conditional prefix contains an unmatched `]`. |
| `NESTED_CONDITIONAL` | Error | A conditional opens another `[` before its closing `]`. |
| `MISSING_ARGUMENT` | Warning | No alternative has an action after its leading conditions; for `/castsequence`, a reset option alone also has no action. Suppressed on structurally malformed lines to avoid cascading noise. |
| `DUPLICATE_SHOWTOOLTIP` | Warning | A second or subsequent standalone `#showtooltip` directive; each cites the first directive's line. |

Missing arguments are warnings because a player may intentionally build a no-op. The analyzer does not flag individual empty alternatives, empty comma-separated sequence entries, unknown spells/items, reset values, aliases/localized command names, brackets inside action payloads, or runtime usability. A clean result means only that these supported checks found no issue. It does not establish that a macro works in gameplay or combat.

### Editor integration and safety

`UI/Editor.lua:UpdateEditorState` calls `UpdateLint` on the current EditBox body. The analysis cache is limited to the current body and selected record, so typing, unsuppressed text changes, Save/Revert, selection changes, clean external reloads and read-only snapshot restoration use the same path. Oversized drafts are analyzed too; no diagnostics are truncated. Work scales with text size (plus diagnostic sorting), and native macros remain limited to 255 characters by the existing validation. No timers, per-frame polling, persistence, or additional schema are introduced.

The footer summary shares the character-count row without moving the editor inset. Hover shows one wrapped finding with severity, line, byte column, rule and an explanation. Click/scroll advances, right-click/scroll up goes back, and navigation wraps so every finding is reachable even for oversized pasted drafts. Editing resets the finding page and refreshes an open tooltip. Selection clearing hides the indicator. Both appearances use this shared controller and their existing palette/fonts.

Lint does not set editor text, caret, selection, focus, native macros or saved data. Its diagnostics never enter the `canSave` expression, content validation, or repository mutations. Existing combat, length, exact-target, offline and conflict restrictions remain authoritative. Tooltip navigation does not navigate the caret or invoke a protected action.

### Retail source research and Lua feasibility (2026-10-24)

Reviewed the current extracted Blizzard UI `live` sources. [SlashCommands.lua](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_ChatFrameBase/Shared/SlashCommands.lua) sends cast/use options through `SecureCmdOptionParse`; the two handlers can resolve spells or items. It separately routes `/script` through policy checks and `RunScript`. MacroStudio calls none of those functions during analysis. [CastSequenceManager.lua](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_ChatFrameBase/Shared/CastSequenceManager.lua) parses secure options first, then a leading `reset=...` token and comma-separated actions. Neither source justifies treating every slash command as conditional syntax. These are source-level observations, not live-client validation or a guarantee for every Retail build.

The [Lua 5.1 manual](https://www.lua.org/manual/5.1/manual.html#pdf-loadstring) defines `loadstring` as returning a compiled function or a syntax error. Compilation alone does not invoke that function. A future validator could compile only the text after `/run` or `/script` and discard the function, never calling it. It could report grammar errors only, not API availability, protected operations, combat restrictions, or runtime behavior. It must also reject binary chunks and handle source locations and client policy differences.

Blizzard's [RestrictedExecution.lua](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_RestrictedAddOnEnvironment/RestrictedExecution.lua) uses internal `loadstring_untainted` with environment control to build restricted closures; that is not evidence of a supported addon validation API. We have not demonstrated normal-addon compiler availability/security behavior in the target client. Consequently Lua syntax checking is deferred, consistent with issue #1. The shipped linter never compiles or executes user input, and it never treats an entire macro as Lua. Follow-up work requires target-client compile-only verification, policy review and non-execution regression coverage before inclusion.

## Blizzard-owned and MacroStudio-owned data

Blizzard owns every native macro's name, body, icon, scope, and current enumeration index. Native macros continue to use the native macro APIs. The unreleased MacroStudio macro library described below owns a separate storage and execution path.

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

The themed Copy to dropdown offers Current Character, Account Macros, and MacroStudio Macros. `ValidateSnapshotCopy` re-resolves the exact offline record and validates each destination separately; full native scopes disable only their own rows, leaving shared storage available. `CopySelectedSnapshot` verifies the selected snapshot still matches the menu's captured source before creating a fresh macro through the existing creation path. Native destinations use Character or Account scope; shared copies use `source = "STUDIO"` and never allocate native slots or assign keys. Success selects the new macro and switches to its destination filter. Copy never transfers organization metadata or modifies the source snapshot.

Copy retains the existing name/body/icon validation, question-mark icon behavior, duplicate-name safety, combat lockdown and repository refresh. The menu closes after selection, outside clicks, selection changes, modal dialogs, window closure or combat. Stale menu targets, removed snapshots, invalid content, blocked destinations and modal/dirty state are rechecked before creation; blocked copies are never retried automatically.

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

Macro-list rows and the editor icon register for Blizzard's native left-button drag gesture. `OnDragStart` routes the saved snapshot through `RequestPickupMacro`. Native macros use `MacroRepository:Pickup`, which re-reads the same native index and requires index, scope, name, icon, and body to match before calling `PickupMacro(index)`. It never looks up a macro by name, so duplicate names remain safe. A stale row is refused rather than redirected to a shifted neighbor.

`PickupMacro` is unavailable during combat lockdown. MacroStudio checks `InCombatLockdown()` first, leaves the cursor unchanged, and shows a concise message instead of attempting a secure workaround. It also does not call `ClearCursor`, matching Blizzard's own Macro UI handoff behavior when the cursor already holds something.

Pickup uses the saved macro and never saves an editor draft. When dragging the dirty editor selection, MacroStudio explains that the saved version was placed on the cursor. Shared macros use the persistent linked native copy described below.

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

The main editor and creation dialog use Blizzard's `ScrollingEditBoxTemplate` with a registered `WowTrimScrollBar`. The template owns caret rendering, mouse drag selection, multiline keyboard navigation, and cursor scrolling; MacroStudio hooks its scripts without replacing that native behavior. Lists use intrinsic scroll frames connected through `ScrollUtil.InitScrollFrameWithScrollBar`.

The editor's eight-piece native inset border sits below child controls. Four exact edge textures on a non-interactive frame above its scrolling controls provide a focus cue. Focus and blur recolor all four edges together; the overlay shares the editor border's anchors and therefore remains aligned during resize and scroll. See `UI-THEME.md` for the native frame resource audit and live visual acceptance status.

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

## MacroStudio macros and named color styles (unreleased)

`StudioMacroRepository.lua` owns additive schema 4 `studioMacros = {nextId, records}` and `studioBindings[characterId][studioId] = key`. Definitions carry stable opaque numeric-string IDs, a single internal STUDIO scope, and a revision. The library version 2 migration promotes prior Account and Character definitions into this shared collection, clears obsolete owners, and preserves IDs, names, bodies, revisions, metadata and per-character key assignments. Runtime records use `source = "STUDIO"` and a string index `studio:<id>`; they never impersonate a native macro index. All managed definitions enter the shared live catalog. Account/Character filters remain specific to Blizzard macros, while All Macros, Favorites and category views can include the shared collection. Native snapshots and action-bar lookup remain native-only.

Managed CRUD validates the current saved snapshot and the same 255-character executable-body limit. It never calls CreateMacro, EditMacro, DeleteMacro or PickupMacro. The normal editor, filters, category/tag/Favorite metadata and search are shared. Metadata reconciliation follows the stable Studio ID and excludes managed records from native identity matching. Native refresh events preserve managed drafts without manufacturing a native external conflict. MacroStudio creation remains available when both native scopes are full.

Keys are saved per character for the shared definitions. `UI/KeybindButton.lua` provides one themed button below Category and Tags, visible only for shared macros. It displays Not Bound or a readable assigned key, with hover instructions and game-binding disclosure. Left-click starts capture; the first supported keyboard key, middle/extra mouse button or wheel direction (with modifiers) commits immediately. Right-click while idle clears; Esc cancels without changing the assignment. Primary mouse buttons remain reserved for normal UI interaction. Duplicate managed keys are rejected while listening remains active for a retry.

A temporary transparent input frame consumes keyboard, mouse and wheel input while listening; it is hidden after success, Esc, selection or draft changes, window closure, another modal, stale targets, or combat. No delayed binding is applied when combat ends. The editor reserves one additional row only for shared macros; the top-right indicator reports action-bar usage independently. Definitions, deletion, and binding writes are blocked in combat. No code compiles or runs user macro text from insecure addon code.

One secure action button per bound definition holds its saved macrotext. A secure state-handler owner binds real hardware key presses directly to these buttons. Its state driver clears its own bindings during pet battles, vehicles, possession and override bars, restoring them when normal context returns. The protected snippets read attribute values rather than interpolating user input into code. Rebuild clears old action text, releases previous keys, and rebuilds only validated current-character bindings. Reload reconstructs actions from saved definitions and assignments. Offline native snapshots remain read-only.

### Shared macro action-bar copies

`StudioActionBarRepository.lua` bridges a shared macro to the native macro cursor. Stock bars accept a native macro index, so the first drag creates a persistent exact name/icon/body copy in a free Character slot, falling back to Account. This consumes one native slot per linked macro; direct keybindings and shared library storage remain independent of those limits. No `/click` helper chaining or action-button modification is used. Repeated drags reuse the copy, including after a canceled drop.

Additive `studioActionBarCopies[characterId][studioId]` stores complete native copy snapshots. Reuse, updates and deletion require exactly one same-scope native macro matching all saved content, allowing native index shifts without overwriting an uncertain neighbor. External changes or identical duplicates block synchronization and preserve the draft. A fresh drag can create and link a new copy while leaving the old uncertain copy untouched. Native rows for copies remain visible as ordinary native macros.

Saving a shared definition first synchronizes its verified current-character copy; failure prevents committing the shared edit. Deletion removes a verified current-character copy and unlinks an externally changed one without deleting it. Login reconciles other characters' existing copies with the shared definition or removes verified copies for deleted definitions. Combat delays login reconciliation, while explicit drag/save/delete operations are refused. A busy cursor is checked before any copy creation. Native writes use the existing mutation gate and reconciliation, and action-bar usage resolves through the verified native copy.

`UI/ColorStyles.lua` defines a unified style list: Warcraft (default), Legacy, Emerald, Violet and Ember. Each choice determines its base presentation and colors. Legacy uses the original blue/gray layout; the colored presets use Warcraft geometry. Initialization applies the selected presentation and then its palette, mutating arrays in place to preserve editor references. Warning/error colors remain semantic.

`settings.style` is the canonical saved choice; `settings.appearance` is derived for existing frame construction. Saved legacy appearance maps to Legacy, the former Warcraft Frost preset maps to Legacy, and other Warcraft colors retain their named style. Older `settings.colorStyles` data is preserved for rollback. Settings exposes only the unified radio list. Selection stages the complete choice, never partially recolors live frames, and uses the existing draft/form-protected Reload UI action.

Tests exercise managed definitions beyond both native count limits, key scope/cleanup, the exact secure snippets against a modeled frame API, CRUD/search/metadata integration, five fresh unified style starts including contrast, and eight saved-choice upgrade cases. Native secure input routing and visual/taint acceptance still require the live checklist in TESTING.md.
