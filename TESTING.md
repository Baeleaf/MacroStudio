# MacroStudio Milestone 2.1 Testing

Enable Lua errors (`/console scriptErrors 1`, then `/reload`) and keep Blizzard's Macro UI available for comparison.

## Automated preflight

With Python 3 and `lupa` installed, run from the addon root:

```powershell
py .\tests\preflight.py
```

The harness compiles every Lua source and exercises stubbed Retail APIs for scope enumeration, duplicates, capacity/name/body/combat validation, Create, exact-index Delete, stale-target refusal, metadata cleanup, canonical tags, filter section rules, and Favorite/caret wiring. Actual mouse caret feel still requires the real-client tests below.

## Load and window lifecycle

- [ ] Log in and `/reload`; MacroStudio stays closed with no Lua error.
- [ ] `/macrostudio` and `/ms` toggle it; X and Escape close it.
- [ ] Move/resize, `/reload`, reopen, and confirm geometry persists.
- [ ] Confirm the visible macro-list header has **+ New Macro** and no Refresh button.
- [ ] Confirm `/ms refresh` still refreshes and opens the window.
- [ ] Confirm schema 1 settings migrate to schema 2 and organization data survives reload/login.

## Native caret and keyboard behavior

- [ ] Click at the beginning, middle, and end of multiple editor lines; the native caret lands at the click.
- [ ] Drag forward and backward across text and lines; selection, copy, cut, paste, undo, and redo behave normally.
- [ ] Use arrows, Home/End, Ctrl+arrows, Page Up/Down, mouse wheel, and the scrollbar; the caret stays visible without jumping to the end.
- [ ] Click blank space below short text; the editor focuses and places the caret at the end.
- [ ] Repeat click placement and selection in category create/rename, tag creation, macro name, and new-macro body fields.
- [ ] In category/tag dialogs, Enter submits through validation, invalid input remains visible with an inline error, and Escape cancels.
- [ ] In the new-macro dialog, Enter/Tab in Name moves to Body; Enter in Body inserts a newline; Escape cancels.

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

- [ ] Favorites show a reliable Blizzard atlas in navigation, rows, and editor—no missing-box glyphs.
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
- [ ] Search controls are absent.

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
