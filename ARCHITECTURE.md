# MacroStudio Architecture

## Scope of version 0.3.0

Version 0.3.0 edits, creates, deletes, organizes, and searches Blizzard-native macros. Search uses simple case-insensitive substring matching; advanced query syntax, history/Trash, existing-macro rename/icon/scope changes, duplication, import/export, launchers, and action-bar integration remain unimplemented.

Native WoW frames and APIs are used directly. Runtime addon code has no third-party dependency. The Python/Lupa headless harness is development-only.

## Module responsibilities

```text
Core.lua
|-- Database.lua
|-- MacroRepository.lua
|-- MetadataRepository.lua
|-- Utils/Helpers.lua
|-- Search.lua
`-- UI/MainFrame.lua
    |-- UI/Dialogs.lua
    |-- UI/IconPicker.lua
    |-- UI/MacroDialog.lua
    |-- UI/Sidebar.lua
    |-- UI/MacroList.lua
    `-- UI/Editor.lua
```

- `MacroRepository.lua` is the only layer that calls `GetNumMacros`, `GetMacroInfo`, `EditMacro`, `CreateMacro`, or `DeleteMacro`.
- `MetadataRepository.lua` owns virtual organization records and removes the trusted record for a MacroStudio-deleted macro before reconciliation.
- `Utils/Helpers.lua` centralizes Blizzard scrolling EditBox construction, exact overlay borders, mouse/focus configuration, tooltips, and disabled styling.
- `Search.lua` performs read-only matching against native macro fields and attached metadata.
- `UI/Editor.lua` derives Save/Delete state and owns the editor's complete four-edge focus treatment.
- `UI/MacroDialog.lua` derives Create state and owns the movable dialog and modal lifecycle.
- `UI/IconPicker.lua` uses Blizzard's icon provider when available and compatible API fallbacks otherwise.
- `UI/MacroList.lua` decides which scope headers are meaningful for the active filter.
- `UI/MainFrame.lua` coordinates selection, native mutations, organization refresh, dialogs, and the interaction-blocking modal overlay.

UI modules never call raw native macro mutation APIs.

## Blizzard-owned and MacroStudio-owned data

Blizzard owns every native macro's name, body, icon, scope, and current enumeration index. MacroStudio writes through the native macro APIs and never creates a parallel execution mechanism.

`MacroStudioDB` schema 2 stores only settings and virtual metadata. Organization records use opaque IDs and carry a reconciliation snapshot:

```text
scope, lastKnownIndex, name, icon, body
```

The last-known index is evidence, not a durable key. Categories, Favorites, and tags have no effect on native execution.

## Exact native mutation rules

Every Save and Delete starts from a copied snapshot. Immediately before the mutation, the repository re-reads the enumerated index and requires index, scope, name, icon, and body to match. This prevents a shifted neighbor or same-name duplicate from becoming the target.

Save passes the enumerated index to `EditMacro`, refreshes, and resolves the returned/original/unique full-field result. Create refreshes capacity, validates all fields, calls `CreateMacro`, refreshes, and selects the returned or uniquely matching record. Delete refreshes, revalidates the exact snapshot, calls `DeleteMacro(index)`, and requires the relevant scope count to decrease by one.

`UPDATE_MACROS` can fire around a native mutation. `UI/MainFrame.lua` defers that event while the repository is operating, then performs one controlled metadata reconciliation. For Delete, the trusted metadata record is removed first so a shifted neighbor cannot inherit it.

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
body, dirty, length, overBy, targetSafe,
canSave, saveReason, canRevert, canDelete, deleteReason
```

Save requires a selected dirty target, at most 255 characters, no combat, no external conflict, and an exact current snapshot. Delete additionally requires a clean buffer. Create is disabled while combat-locked, at capacity, or while automatic selection would discard a dirty draft. Repository methods repeat the important validation defensively.

The main editor and creation dialog use Blizzard's `ScrollingEditBoxTemplate` with a registered `MinimalScrollBar`. The template owns caret rendering, mouse drag selection, multiline keyboard navigation, and cursor scrolling; MacroStudio hooks its scripts without replacing that native behavior.

The one-pixel Backdrop border sits below child frames, so the main editor also uses four exact edge textures on a non-interactive frame above its scrolling controls. Focus and blur recolor all four edges together; the overlay shares the editor border's anchors and therefore remains aligned during resize and scroll.

Programmatic loads suppress text-change handling, then recompute once. External refresh never overwrites a dirty draft.

## Input and Favorite UI

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
