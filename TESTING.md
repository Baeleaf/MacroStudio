# MacroStudio Milestone 1 Testing

These are manual in-game tests. Run them with Lua errors visible (for example, `/console scriptErrors 1`, then `/reload`) and keep Blizzard's default Macro UI available for comparison.

## Build and TOC verification

The development machine used for the initial implementation has Retail build `12.0.7.68974` installed, and current installed Retail addons use Interface `120007`. `MacroStudio.toc` therefore declares:

```text
## Interface: 120007
```

After a WoW update, confirm the build in `World of Warcraft\.build.info` or compare current, updated addon TOCs. If Retail advances beyond 12.0.7 and MacroStudio appears as out of date, update the Interface field only after verifying the new client value.

## First load

- [ ] Create the Junction using the README command.
- [ ] Restart WoW completely if MacroStudio was not previously installed.
- [ ] Confirm MacroStudio appears and is enabled on the character-selection AddOns screen.
- [ ] Log in with Lua errors enabled; confirm no error appears.
- [ ] Run `/macrostudio`; confirm the window opens.
- [ ] Run `/ms`; confirm the window closes, then run it again to reopen.
- [ ] Close with the X and press Escape; confirm the window can reopen.
- [ ] Move and resize the window, `/reload`, reopen it, and confirm its geometry is remembered.

## Enumeration

- [ ] Account macros appear under **ACCOUNT MACROS**.
- [ ] Character macros appear under **CHARACTER MACROS**.
- [ ] Icons and names match Blizzard's Macro UI.
- [ ] Body counts and previews correspond to the macros.
- [ ] Test a character with an empty account or character section; confirm no error.
- [ ] If practical, test an account/character with zero macros; confirm no error and a usable empty window.

## Selection and editor

- [ ] Click several macros and confirm name, icon, scope, and body each match Blizzard's UI.
- [ ] Confirm multiline macros display with line breaks intact.
- [ ] Confirm normal selection, copy, paste, editing, and scrolling work.
- [ ] Confirm the editor border changes visibly when focused.
- [ ] Make a change, click another macro, and confirm a discard prompt appears.
- [ ] Cancel the prompt and confirm the draft is untouched.
- [ ] Accept the prompt and confirm the requested macro loads.
- [ ] Hide/reopen MacroStudio while dirty and confirm the in-memory draft remains.

## Character counter and validation

- [ ] Confirm the counter updates for every edit.
- [ ] At 229 characters, confirm the normal state is shown.
- [ ] At 230 characters, confirm **Approaching the native limit** appears.
- [ ] At exactly 255 characters, confirm Save is permitted.
- [ ] At 256 characters, confirm **Too long by 1 character — cannot save** appears and Save is disabled.
- [ ] Paste a body longer than 255 and confirm it stays intact in the editor rather than being truncated.
- [ ] Include non-ASCII characters if used in real macros and compare the displayed count with Blizzard's acceptance behavior.

## Dirty state, Revert, and Save

- [ ] Select a macro; confirm Save and Revert are disabled while unchanged.
- [ ] Change the body; confirm **Unsaved changes**, Save, and Revert become active.
- [ ] Click Revert; confirm the current body is restored without changing Blizzard's macro.
- [ ] Change the body and click Save; confirm the dirty state clears.
- [ ] `/reload`, reopen MacroStudio, and confirm the saved body remains.
- [ ] Open Blizzard's Macro UI and confirm it shows the same saved body.
- [ ] Confirm the macro's scope, name, and icon did not change.

## External changes and index safety

- [ ] Select a clean macro in MacroStudio, change its body in Blizzard's Macro UI, then Refresh; confirm MacroStudio shows the new body.
- [ ] Make a dirty draft in MacroStudio, change that native macro externally, then Refresh; confirm the draft remains and Save is blocked.
- [ ] Click Revert after that conflict; confirm it loads Blizzard's current body only when the target can be resolved safely.
- [ ] Delete the selected macro externally; confirm MacroStudio reports the missing selection rather than throwing an error.
- [ ] Add/delete/rename other macros so indexes shift; confirm MacroStudio refreshes and never overwrites a different macro.
- [ ] Create duplicate names, select each by icon/body, and confirm editing one does not change the other.
- [ ] Renaming is intentionally unavailable in Milestone 1; test rename/index movement again when Milestone 4 adds it.

## Combat lockdown

- [ ] Create a dirty draft before combat.
- [ ] Enter combat; confirm MacroStudio remains visible and readable.
- [ ] Confirm the draft remains intact and Save becomes unavailable.
- [ ] Open MacroStudio during combat and confirm it loads safely.
- [ ] Leave combat; confirm Save becomes available again for a valid dirty draft.
- [ ] Confirm leaving combat did not automatically save the draft.
- [ ] Save manually after combat and verify the native macro updates.

## Refresh and reload edge cases

- [ ] Use the **Refresh** button and `/ms refresh`; confirm both update the list.
- [ ] Edit in Blizzard's Macro UI and confirm `UPDATE_MACROS` eventually updates MacroStudio without polling.
- [ ] Confirm refresh while dirty never replaces the editor buffer.
- [ ] Reload while MacroStudio is open; confirm no error and reopen it after reload.
- [ ] Enable `/ms debug on`, exercise refresh/select/save/combat, and confirm concise state logs appear without full macro bodies.
- [ ] Disable `/ms debug off` and confirm normal use does not spam chat.

## Items requiring real client validation

- Protected `EditMacro` behavior and its returned index must be verified in combat and after list reordering.
- `UPDATE_MACROS` timing can vary around Blizzard's Macro UI; verify external edits are reflected without draft loss.
- Confirm the current client treats the displayed 255-character count as expected for non-ASCII text.
- Visual sizing, font wrapping, cursor scrolling, and minimum resize behavior require in-game inspection at the user's UI scale and resolution.
