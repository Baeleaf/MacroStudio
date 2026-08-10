# MacroStudio Testing

Enable Lua errors (`/console scriptErrors 1`, then `/reload`) and keep Blizzard's Macro UI available for comparison.

## Automated preflight

With Python 3 and `lupa` installed, run from the addon root:

```powershell
py .\tests\preflight.py
```

The harness compiles every Lua source and exercises stubbed Retail APIs for native macro safety, exact Account and Character pickup indices, duplicate-name and filtered-row drag targeting, stale/combat refusal, dirty-draft independence, unchanged organization metadata, icon identity deduplication, metadata reconciliation, search/navigation combinations, native scrolling EditBoxes, focus borders, and modal safety. Headless tests verify which index reaches `PickupMacro`; they cannot validate the real cursor or action-bar drop.

## Milestone 4: drag native macros to action bars (unreleased)

This feature is not included in MacroStudio 1.0.0. Test it from the `feature/action-bar-drag` branch with Lua errors enabled.

### Basic drag and replacement

- [ ] Drag an Account macro to an empty action-bar slot, click it, and confirm normal macro behavior.
- [ ] Drag a Character macro to an empty action-bar slot, click it, and confirm normal macro behavior.
- [ ] Drag a macro onto an occupied slot and confirm Blizzard's normal replacement or swap behavior.
- [ ] Repeat on more than one standard Blizzard action bar.
- [ ] Confirm normal row clicks still select macros and list scrolling remains usable.

### Identity, search, and organization

- [ ] Create same-name macros with different icons and bodies. Drag each and confirm the correct native macro reaches the bar.
- [ ] Drag from search results, Favorites, a category, and a combined search/category view. Confirm every visible row targets the expected macro.
- [ ] Confirm dragging does not change category, tags, Favorite state, body, name, icon, or scope.

### Dirty drafts and stale rows

- [ ] Make an unsaved edit, then drag the selected macro. Confirm the draft stays dirty and is not saved.
- [ ] Confirm the action bar receives the existing saved native macro, not the unsaved draft.
- [ ] Change or delete a visible macro through Blizzard's Macro UI immediately before dragging it. Confirm MacroStudio refuses a stale target instead of picking up a neighbor.

### Combat and cursor behavior

- [ ] Attempt a drag during combat. Confirm the cursor is unchanged and MacroStudio reports that macros cannot be moved during combat.
- [ ] Confirm there are no Lua errors, blocked-action errors, or protected-action errors.
- [ ] Pick up a macro, then cancel with right-click or Escape as supported by WoW. Confirm the cursor returns to normal and MacroStudio stays usable.
- [ ] Drop a macro and confirm no Save, Refresh, or Reload is required afterward.

### Optional third-party action bars

- [ ] If available, repeat a basic drag with a popular action-bar addon.
- [ ] Record the addon and version. Compatibility is useful feedback, not a milestone requirement.

## Load and window lifecycle

- [ ] Log in and `/reload`; MacroStudio stays closed with no Lua error.
- [ ] `/macrostudio` and `/ms` toggle it; X and Escape close it.
- [ ] Move/resize, `/reload`, reopen, and confirm geometry persists.
- [ ] Confirm the visible macro-list header has **+ New Macro** and no Refresh button.
- [ ] Confirm `/ms refresh` still refreshes and opens the window.
- [ ] Confirm schema 1 settings migrate to schema 2 and organization data survives reload/login.

## Live search and filtering

- [ ] Search an exact macro-name fragment; only case-insensitive matches remain.
- [ ] Search text found only in the complete body, such as `@mouseover`, `nodead`, `Flash Heal`, or `/cast`; the correct macro appears even when the text is outside its preview.
- [ ] Search an assigned tag and an assigned category name; matching macros appear even when those words are absent from name/body.
- [ ] Verify `MOUSEOVER`, `mouseover`, and `MouseOver` produce equivalent results.
- [ ] Combine a query with All, Account, Character, Favorites, and a category; only their matching macros appear.
- [ ] With search active, confirm empty scope sections disappear and zero results show one message: `No macros match "query".`
- [ ] Type character by character; results update immediately without Enter, Refresh, or visible editor/sidebar rebuilding.
- [ ] Use click placement, Home/End, Ctrl+A, Backspace/Delete, copy/paste, and the visible native caret in Search.
- [ ] Press Escape with text present; the query clears but the current navigation filter and search focus remain. Press Escape again; focus releases.
- [ ] Click the clear X; the query clears, the current navigation filter remains selected, and its full results return.
- [ ] Close/reopen MacroStudio in the same session; the query remains. `/reload`; the query resets.

## Search state safety

- [ ] Make a dirty draft, then search so its selected macro disappears; the macro remains selected and the draft stays byte-for-byte intact.
- [ ] With search active, add/remove a matching tag, change category, and toggle Favorite in the Favorites view; results update immediately without manual Refresh.
- [ ] Open Create Macro while searching; the modal overlay blocks Search and closing the dialog preserves the query.
- [ ] Create a macro that matches the current search/filter; it appears normally and becomes selected.
- [ ] Create one that does not match; query/filter remain unchanged and the new macro remains selected in the editor while hidden from the list.
- [ ] Delete a matching disposable macro; it disappears automatically while query and navigation filter remain unchanged.

## Icon picker identity

- [ ] Open the icon picker and confirm exactly one question-mark option appears.
- [ ] Select it, create a `#showtooltip` macro, and confirm the selected icon remains stable and behaves normally.
- [ ] Confirm all non-question-mark icons remain available.

## Native caret and keyboard behavior

- [ ] Click at the beginning, middle, and end of multiple editor lines; the native caret lands at the click.
- [ ] Drag forward and backward across text and lines; selection, copy, cut, paste, undo, and redo behave normally.
- [ ] Use arrows, Home/End, Ctrl+arrows, Page Up/Down, mouse wheel, and the scrollbar; the caret stays visible without jumping to the end.
- [ ] Click blank space below short text; the editor focuses and places the caret at the end.
- [ ] Repeat click placement and selection in category create/rename, tag creation, macro name, and new-macro body fields.
- [ ] In category/tag dialogs, Enter submits through validation, invalid input remains visible with an inline error, and Escape cancels.
- [ ] In the new-macro dialog, Enter/Tab in Name moves to Body; Enter in Body inserts a newline; Escape cancels.

## Editor focus border

- [ ] Click the main editor; top, right, bottom, and left edges all change to the same blue focus treatment.
- [ ] Click another text field or press Escape; all four edges return to the same normal treatment.
- [ ] Resize MacroStudio while the editor is focused; every edge remains exactly aligned.
- [ ] Scroll, select another macro, enter/leave combat, Save, and Revert while focused; the border remains complete and the native caret/selection behavior does not change.

## Create Macro modal safety and movement

- [ ] Open **+ New Macro** and attempt to click the macro list, editor, category navigation, Favorite, tags, Save, Revert, Delete, and New Macro behind it; none respond.
- [ ] Confirm the dimmed overlay covers the complete main window after resizing, including the title bar and resize grip.
- [ ] Click Cancel; the dialog and overlay disappear and the selected main editor becomes interactive.
- [ ] Reopen and press Escape from Name and Body; modal state clears each time.
- [ ] Reopen, choose an icon, then close Create Macro; the icon picker also closes and no invisible overlay remains.
- [ ] Successfully create a macro; the dialog closes, the repository refreshes automatically, the new macro is selected, and the editor is usable without Refresh.
- [ ] Drag the dialog from its title bar; it moves and remains clamped on-screen.
- [ ] Drag/click in Name, Body, scope, and icon controls; they interact normally and never move the window.
- [ ] Close and reopen the dialog; it displays correctly at its prior clamped position.

## Combat with Create Macro open

- [ ] Open Create Macro, enter valid Name and Body text, then enter combat.
- [ ] Confirm the form stays open with all text, scope, and icon intact.
- [ ] Confirm Create remains protected/disabled and the underlying main window remains interaction-blocked.
- [ ] Leave combat; confirm the form remains intact and nothing creates automatically.
- [ ] Click Create manually; confirm normal creation, selection, modal cleanup, and restored editor interaction.

## Reactive editor and Save eligibility

- [ ] Type one character: count, dirty label, Save, Revert, and New Macro state update immediately.
- [ ] Remove it: clean state returns without Refresh.
- [ ] Programmatic selection, Save, Revert, and refresh do not create false dirty state.
- [ ] At 229 characters state is normal; 230 warns; 255 permits Save; 256 remains intact and blocks Save.
- [ ] Dirty selection change shows confirmation; Cancel preserves the draft and Accept loads the requested macro.
- [ ] A clean external body change reloads on `UPDATE_MACROS`.
- [ ] A dirty external conflict preserves the draft and blocks Save/Delete until Revert or safe refresh.
- [ ] A stale native target visibly disables Save; forcing the action cannot write a neighbor.

## Favorites, tags, categories, and filter sections

- [ ] Favorites show a reliable Blizzard atlas in navigation, rows, and editor, with no missing-box glyphs.
- [ ] Toggle Favorite; editor state is obvious from icon treatment, label, and backdrop. Tooltip explains it.
- [ ] **+ Add** lists existing unassigned tags and **Create New Tag...**; assigned tags are absent.
- [ ] Choosing an existing tag assigns it immediately. Case-only variants reuse canonical spelling.
- [ ] Empty, over-limit, and duplicate tag input stays open with visible validation; Enter and Escape work.
- [ ] Create/rename categories with empty, over-limit, and case-only duplicate input; errors are visible and correctable.
- [ ] Deleting a category only uncategorizes its macros and never changes native data.
- [ ] All shows Account and Character headers, including empty scopes.
- [ ] Account shows only Account; Character shows only Character.
- [ ] Favorites and category filters omit zero-result scope sections and show one generic no-match message when empty.
- [ ] Changing filters never alters the selected editor body.

## Create native macro

- [ ] Open **+ New Macro**; verify Name, Account/Character scope, live capacity, icon, Body, count, inline status, Create, and Cancel.
- [ ] Blank and over-limit names visibly block Create. Verify the native name maximum used by the client.
- [ ] At 255 body characters Create is allowed; at 256 it is blocked without truncation.
- [ ] Fill Account capacity and Character capacity separately; the full scope is blocked with its count shown.
- [ ] Choose several icons. Confirm the selected icon persists in the form and resulting Blizzard macro.
- [ ] Use the question-mark icon with a `#showtooltip` body and confirm normal dynamic tooltip behavior.
- [ ] Create one Account and one Character macro. Each appears in Blizzard's Macro UI, refreshes automatically, and becomes the selected clean macro.
- [ ] Create a duplicate name and confirm both records remain selectable with duplicate warnings.
- [ ] With a dirty editor draft, New Macro is disabled and the draft is preserved.
- [ ] Enter combat with the dialog open; Create disables visibly. Leave combat; valid creation re-enables without automatic action.

## Delete native macro

- [ ] Clean selected macro: Delete is enabled and confirmation names the exact scope and macro.
- [ ] Cancel leaves native data and metadata unchanged.
- [ ] Confirm permanently deletes the Blizzard macro, clears selection, refreshes the list, and removes its MacroStudio metadata.
- [ ] With dirty text, Delete is disabled with a tooltip directing Save/Revert.
- [ ] With an external conflict or stale target, Delete is disabled and cannot target the shifted neighbor.
- [ ] In combat, Delete is visibly disabled; leaving combat only recomputes state.
- [ ] Create same-name duplicates with different bodies/icons, delete the second, and confirm the first remains unchanged.
- [ ] Delete an organized macro above another macro so indexes shift; confirm the neighbor does not inherit category, Favorite, or tags.
- [ ] Confirm there is no Trash/history claim or recovery UI.

## Regression and real-client API checks

- [ ] Account/Character icons, names, bodies, indexes, counts, and previews match Blizzard's Macro UI.
- [ ] Saving one same-name duplicate never modifies the other.
- [ ] Revert reads native data without writing.
- [ ] The editor remains usable in combat while native Create/Save/Delete stay blocked.
- [ ] `UPDATE_MACROS` timing around Create, Save, Delete, and Blizzard's Macro UI causes no flicker, wrong selection, or metadata transfer.
- [ ] Test non-ASCII name/body/tag character counts against Blizzard acceptance behavior.
- [ ] Test empty Account/Character collections, both capacities full, multiple UI scales, minimum window size, popup placement, and icon-picker scrolling.
- [ ] `/ms debug on` logs concise actions without macro bodies; `/ms debug off` returns to quiet operation.
