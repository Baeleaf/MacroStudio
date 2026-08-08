# MacroStudio Milestone 1.1 and 2 Testing

Run these manual in-game tests with Lua errors visible (for example, `/console scriptErrors 1`, then `/reload`) and keep Blizzard's default Macro UI available for comparison.

## Build and TOC verification

The implementation targets Retail build `12.0.7.68974` and Interface `120007`:

```text
## Interface: 120007
```

After a WoW update, compare current addon TOCs or the installed build before changing this value.

## First load and migration

- [ ] Create the Junction using the README command and restart WoW if MacroStudio was not previously installed.
- [ ] Confirm MacroStudio is enabled and loads without a Lua error.
- [ ] Run `/macrostudio` and `/ms`; confirm both toggle the window.
- [ ] Close with X and Escape; confirm the window can reopen.
- [ ] Move and resize the window, `/reload`, reopen it, and confirm geometry is remembered.
- [ ] Upgrade from version 0.1.0 with an existing `MacroStudioDB`; confirm window settings survive and `schemaVersion` becomes 2.
- [ ] Confirm categories, favorites, and tags survive `/reload` and logout/login.

## Milestone 1.1 reactive-state regression

- [ ] Select a macro and type one character. Without clicking Refresh, confirm all four update immediately: character count, **Unsaved changes**, Save enabled, Revert enabled.
- [ ] Delete that character. Confirm the clean state and disabled Save/Revert return immediately.
- [ ] Type, paste, cut, undo, and redo where supported; confirm each text change updates state immediately.
- [ ] Select a different macro after resolving any dirty prompt. Confirm the programmatic load is clean and does not briefly remain dirty.
- [ ] Click Revert after editing. Confirm the restored text is clean without clicking Refresh.
- [ ] Save a valid change. Confirm the counter and buttons reset immediately.
- [ ] At 229 characters, confirm normal state; at 230, confirm the warning state.
- [ ] At exactly 255 characters, confirm Save is permitted.
- [ ] At 256, confirm the text remains intact, the overage is shown, Save is disabled, and Revert remains enabled.

## Enumeration, selection, and duplicate warnings

- [ ] Account and character macros appear in their labeled sections.
- [ ] Icons, names, bodies, counts, and previews match Blizzard's Macro UI.
- [ ] Test empty account/character sections and, if practical, an account with no macros.
- [ ] Confirm multiline display, selection, copy, paste, scrolling, and focus styling.
- [ ] Make a dirty edit and select another macro. Cancel the discard prompt and confirm the draft remains; accept and confirm the requested macro loads.
- [ ] Create two account macros with the same name. Confirm both receive duplicate warnings.
- [ ] Give an account and character macro the same name. Confirm they are not reported as duplicates across scopes.
- [ ] Select same-named macros individually and confirm saving one never modifies the other.

## Categories

- [ ] Create several categories; confirm they appear in the left navigation.
- [ ] Try an empty name and a case-only duplicate; confirm both are rejected.
- [ ] Rename a category and confirm its navigation label and assigned editor label update.
- [ ] Assign a macro to a category and confirm the category filter shows it.
- [ ] Reassign the macro and remove its category by choosing **Uncategorized**.
- [ ] Delete a category with assigned macros. Confirm those macros become uncategorized.
- [ ] Confirm deleting a category does not delete or edit any macro in Blizzard's Macro UI.

## Favorites and tags

- [ ] Toggle Favorite and confirm the editor control and list marker update.
- [ ] Select **Favorites** and confirm only favorite macros are listed.
- [ ] Remove Favorite while that filter is active; confirm the macro leaves the filtered list but remains selected and unchanged natively.
- [ ] Add multiple tags and confirm they display in the editor.
- [ ] Try an empty tag and a case-only duplicate; confirm both are rejected.
- [ ] Remove tags one at a time and confirm the display updates.
- [ ] Confirm category, favorite, and tag actions never change a macro body, name, icon, or scope.

## Navigation filters

- [ ] **All Macros** shows both scopes.
- [ ] **Account Macros** and **Character Macros** show only their respective scopes.
- [ ] **Favorites** shows only favorites.
- [ ] Each category shows only assigned macros.
- [ ] Confirm changing filters does not discard or alter the selected editor body.
- [ ] Confirm search controls are absent; search belongs to Milestone 3.

## External changes and metadata reconciliation

- [ ] Select a clean macro, change its body in Blizzard's Macro UI, and close/save there. Confirm `UPDATE_MACROS` reloads MacroStudio automatically without manual Refresh.
- [ ] Make a dirty MacroStudio draft, change that native macro externally, and confirm the draft remains visible while Save becomes blocked.
- [ ] Click Revert after the conflict and confirm Blizzard's current body loads only when the target resolves safely.
- [ ] Add, delete, or rename other macros so indexes shift. Confirm categories, favorites, and tags follow unique matching macros.
- [ ] Create indistinguishable duplicates around an organized macro. Confirm MacroStudio does not attach its metadata to an arbitrary duplicate.
- [ ] Remove the ambiguity and refresh. Confirm preserved metadata can reattach when a unique match exists.
- [ ] Delete the selected macro externally. Confirm no Lua error and no metadata is silently assigned to a neighbor.
- [ ] Use the Refresh button and `/ms refresh` only as fallback checks; neither should be needed for typing state.

## Save, Revert, and combat

- [ ] Change a body and Save; confirm the dirty state clears and Blizzard's Macro UI shows the same body.
- [ ] Confirm the macro name, icon, and scope did not change.
- [ ] Revert a draft and confirm Blizzard's macro was not written.
- [ ] Create a dirty draft and enter combat. Confirm the draft stays editable/readable and Save becomes unavailable.
- [ ] Leave combat. Confirm Save re-enables for a valid dirty draft and no automatic save occurred.
- [ ] Save manually after combat and verify the native macro updates.

## Debug and real-client checks

- [ ] Enable `/ms debug on`, exercise refresh, selection, reconciliation, Save, and combat, and confirm concise logs appear without full macro bodies.
- [ ] Disable `/ms debug off` and confirm normal use does not spam chat.
- [ ] Verify protected `EditMacro` behavior and its returned index after list reordering.
- [ ] Verify `UPDATE_MACROS` timing around Blizzard's Macro UI.
- [ ] Compare non-ASCII character counts with Blizzard's acceptance behavior.
- [ ] Inspect layout, font clipping, popup placement, scrolling, and minimum resize behavior at the user's UI scale and resolution.

## Automated preflight completed during development

- Lua 5.1 parsing of every addon source file.
- Schema 1 to 2 migration while preserving settings, unknown metadata fields, and history.
- Scope-aware duplicate detection.
- Category/favorite/tag creation, validation, persistence, assignment, removal, and filters.
- Unique index-movement reconciliation and ambiguous-record preservation.
- Immediate dirty/count/Save/Revert transitions and programmatic-load suppression.
- Save, clean external reload, dirty conflict preservation, Revert, and combat gating in a headless WoW API/UI stub.
