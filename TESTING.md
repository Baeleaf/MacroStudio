# MacroStudio Testing

Enable Lua errors (`/console scriptErrors 1`, then `/reload`) and keep Blizzard's Macro UI available for comparison.

## Automated preflight

With Python 3 and `lupa` installed, run from the addon root:

```powershell
py .\tests\preflight.py
```

The harness compiles every Lua source and exercises stubbed Retail APIs for native macro safety, resolved spell/item/plain action identities, accidental ID/index collisions, duplicate ambiguity, exact Account and Character pickup, multiple placements, removal/replacement, stale identity omission and reconciliation, unified name/icon/body drafts, exact one-call `EditMacro` saves, returned-index changes, combat and external-conflict guards, metadata preservation, filtered cached indicators, event-driven refresh, search scan independence, icon identity deduplication, native scrolling EditBoxes, focus borders, and modal safety. Headless tests verify API call and cache behavior; they cannot prove real-client cursor, action-slot visuals, paging, combat, or taint behavior.

The Milestone 6 harness additionally covers schema migration, GUID isolation, uncertain identity, same-name characters, complete snapshot replacement, zero-macro snapshots, live-current precedence, read-only mutation guards, duplicate/capacity/combat copy validation, in-memory cross-character search, and snapshot-only forgetting. Headless checks do not prove real cross-character persistence; the completed live-client phases below provide that coverage.

The Milestone 7 harness additionally covers unified name/icon/body drafts, one-call exact-index saves, duplicate-name edits, saved question-mark icon identity, action-bar reconciliation, all-field external conflict recovery, external deletion safety, and distinct live versus offline editor presentation.

The Milestone 8 harness additionally covers default slash takeover, exact native-handler restoration, native fallback, preserved refresh/debug commands, settings migration, minimap visibility and radial persistence, launcher clicks, AddOn Compartment metadata, combat-safe opening, and conservative collision failure. Headless checks cannot prove real client slash load order, native frame visibility, minimap interaction, taint, or third-party ownership; test those phases live.

The Milestone 9.1 harness parses synthetic portable JSON and covers deterministic ordering, both native scopes, 20 offline characters with 600 ordered snapshots, duplicate-name metadata identity, categories, tags, Favorites, numeric/path icons, multiline/quoted/backslash/Unicode/empty/maximum bodies, dirty-draft exclusion, combat, zero native writes, both entry points, singleton open/close, exact large-text display, and visible oversize failure. Headless checks cannot prove live WoW keyboard selection, Ctrl+C, clipboard behavior, EditBox rendering performance, taint, or the maintainer's real library size; complete the live phases below.

The Milestone 9.2 harness adds a dedicated synthetic Import suite plus full-TOC UI smoke coverage. It exercises non-executable JSON parsing, malformed/truncated/unsupported input, duplicate keys/IDs/references, Unicode and escapes, the large MS9.1 format-v1 fixture, exact reuse, same-name safety, ambiguity, Account/Character capacity, explicit current-character mapping, confirmation-before-write, synchronous `UPDATE_MACROS`, final identity reconciliation, additive metadata, GUID/timestamp offline rules, repeat Import, combat/dirty/stale guards, and partial native failure/retry. It asserts that Import never calls `EditMacro` or `DeleteMacro`. Headless checks cannot prove live paste performance, protected API behavior, taint, or cross-account/region persistence; complete the phases below.

## Milestone 9.2: Safe Portable Import

Milestone 9.2 remains under **Unreleased** until these live-client phases pass. Use synthetic data or a reviewed backup; do not use a sole irreplaceable library copy.

### Phase 1 - Build and access

- [ ] Confirm WoW reports `1.3.0-r4` with Interface `120100`.
- [ ] Run `/ms import`, then use **Settings -> Import MacroStudio Library**; confirm both open the same Import window.
- [ ] Confirm `/ms export` still opens the tested format-v1 Export window.

### Phase 2 - Validation

- [ ] Paste a valid MS9.1 export and reach Preview without any native mutation.
- [ ] Paste malformed and truncated JSON; confirm both remain on Paste with a useful body-safe error.
- [ ] Change `formatVersion` to `2`; confirm MacroStudio reports that only format version 1 is supported.

### Phase 3 - Round-trip preview

- [ ] Generate a fresh Export on this installation and paste it into Import.
- [ ] Preview only; confirm existing native macros are mostly **Already present**, with no plan to recreate the entire library.
- [ ] Confirm source version/counts and organization/offline counts are plausible.

### Phase 4 - Safe new macro import

- [ ] Use a small synthetic export with one new Account macro, one new Character macro, one category, one tag, and one Favorite.
- [ ] Confirm Preview counts, click **Apply Import**, accept the confirmation, and verify the Results counts.
- [ ] Verify both native macros and their exact metadata.

### Phase 5 - Same-name safety

- [ ] Keep an existing `Import Test` macro with body A and import `Import Test` with body B.
- [ ] Confirm body A is untouched, body B is created separately, and imported metadata attaches only to body B.

### Phase 6 - Exact existing detection

- [ ] Import a uniquely exact existing macro; confirm Preview reports **Already present** and Apply creates no duplicate.
- [ ] With multiple indistinguishable exact destination macros, confirm Preview reports ambiguity and Import skips rather than guesses.

### Phase 7 - Capacity

- [ ] Near Account capacity, confirm an over-capacity full batch disables **Apply Import** before any write.
- [ ] Repeat near Character capacity. Confirm no macro is deleted automatically in either scope.

### Phase 8 - Current-character mapping

- [ ] Confirm Preview explicitly names the logged-in `Character - Realm` destination.
- [ ] With the checkbox enabled, verify source Character macros become native macros for the logged-in character.
- [ ] Disable the checkbox and confirm no native Character macros are planned, while foreign source context remains available as an offline snapshot.
- [ ] Confirm the foreign/source GUID never replaces the current local identity.

### Phase 9 - Cross-character library

- [ ] Import at least two different-GUID offline records, including same-name or same-realm examples; confirm they remain distinct.
- [ ] Confirm a newer source timestamp updates the same GUID, while a newer local snapshot is preserved.
- [ ] Confirm a zero-macro character remains browseable and offline records contain no native/action-bar state.

### Phase 10 - Dirty draft

- [ ] Create a dirty name/icon/body draft, then Paste and Preview an Import.
- [ ] Attempt Apply; confirm it is blocked with the Finish-or-Revert message, the draft is untouched, and no native write occurs.
- [ ] Save or Revert manually, rerun Preview, and apply manually.

### Phase 11 - Combat

- [ ] In combat, confirm Paste and Preview still work.
- [ ] Confirm Apply is blocked, nothing queues for combat end, and no native write occurs.
- [ ] Leave combat and confirm Import runs only after a new manual Apply/confirmation.

### Phase 12 - Stale preview

- [ ] Preview an Import, then create/edit/delete a macro through Blizzard Macro UI.
- [ ] Attempt Apply; confirm MacroStudio cancels the stale plan and requires Validate & Preview again without targeting a shifted neighbor.

### Phase 13 - Repeat Import

- [ ] Import the same small fixture again.
- [ ] Confirm uniquely exact native macros are reused, tags/Favorites do not duplicate, category conflicts preserve destination state, and offline snapshots remain sane.
- [ ] If practical, simulate one native failure mid-batch and confirm retry recognizes the earlier confirmed creations instead of recreating them.

### Phase 14 - Regression

- [ ] Spot-check `/m`, `/macro`, `/ms settings`, minimap, AddOn Compartment, and `/ms export`.
- [ ] Spot-check edit name/icon/body, Save/Revert, action-bar drag and **On Bar**, offline browsing, Forget Character, and Copy to Current Character.
- [ ] Confirm no Lua, taint, blocked-action, or protected-action errors.


## MS9.1 Export Live Fix - 1.3.0-r3

The r3 harness expands the portable fixture to 21 offline characters, including missing optional identity fields, a legacy zero-macro character, stale metadata, CRLF, tabs, links, and invalid UTF-8 validation. Retail error capture identified the failed stage as Export-window construction: `ScrollingEditBoxTemplate` returns an EditBox without `SetWordWrap`, while the earlier headless frame stub incorrectly supplied that method to every frame type. The harness now models that Retail API boundary and verifies stage-specific protected failures.

### A. Confirm build

- [ ] Confirm WoW reports `1.3.0-r3`.

### B. Slash export

1. Run `/ms export` and confirm Enter submits normally.
2. Confirm the Export window opens with visible serialized text.
3. If it fails, record the exact `MacroStudio Export failed at <stage>` message.

### C. Settings export

1. Run `/ms settings` and click **Export MacroStudio Library**.
2. Confirm Export opens and Settings disappears only after Export is visible.
3. If Export fails, confirm Settings remains visible and reports the failure stage.

### D. Reload

- [ ] Run `/reload`, then immediately run `/ms export`; confirm Export opens.

### E. Continue content testing

- [ ] Only after Export opens, resume the existing Milestone 9.1 content phases below.

## MS9.1 Export Entry Fix - 1.3.0-r2

The headless harness invokes the installed `/ms` dispatcher and Settings button script through the same Export controller, enforces the real `SetFontObject` argument shape, and covers standalone visibility plus close/reopen and cross-entry singleton reuse. It cannot prove WoW chat EditBox submission or clearing, so verify those behaviors live.

### Test A - Build

- [ ] Confirm WoW reports `1.3.0-r2`.

### Test B - Slash command

- [ ] Immediately after login, run `/ms export`; confirm the command submits normally and visible export text opens.
- [ ] Close Export and repeat `/ms export`; confirm the same interface reopens.

### Test C - Settings button

- [ ] Run `/ms settings`, click **Export MacroStudio Library**, and confirm Settings closes while Export opens and remains visible.

### Test D - Cross-entry lifecycle

- [ ] Run `/ms export` -> close -> **Settings -> Export** -> close -> `/ms export`; confirm all three openings work.

### Test E - Reload

- [ ] Run `/reload`, then immediately run `/ms export`; confirm Export opens with no Lua or chat error.

### Test F - Combat

- [ ] In combat, run `/ms export`; confirm Export opens without taint, blocked actions, or native writes.

## MS8 Settings Fix - 1.2.0-r3

The headless harness verifies the installed title mouse-down hook, deferred shared-controller call, actual frame state, singleton reuse, overlay level, and minimap toggle transitions. It cannot prove how the live WoW client routes mouse-up through the draggable title-bar region, so complete these focused live checks.

### Test A - Confirm build

- [ ] Verify WoW reports or displays `1.2.0-r3`.

### Test B - Title-bar button

1. Open MacroStudio.
2. Click **Settings** and confirm Settings opens.
3. Click **Settings** again and confirm Settings closes while MacroStudio remains open.
4. Repeat several times, including at minimum window size and after resizing.

### Test C - Minimap right-click

1. Close MacroStudio.
2. Right-click the minimap `/M`; confirm MacroStudio and Settings open.
3. Right-click `/M` again; confirm both close.
4. Right-click again; confirm both reopen.

### Test D - Mixed state

1. Open MacroStudio with `/ms` while Settings is closed.
2. Right-click the minimap `/M`; confirm Settings opens and MacroStudio stays open.
3. Right-click again; confirm Settings and MacroStudio both close.

### Test E - Other entry points

- [ ] Confirm `/ms settings` opens or raises Settings without toggling it closed.
- [ ] Confirm minimap left-click still toggles only MacroStudio.
- [ ] Manually close Settings, then confirm the title button, `/ms settings`, and minimap right-click can reopen it.
- [ ] Toggle the takeover and minimap-button settings and confirm both controls remain interactive.

### Test F - Reload

1. Run `/reload`.
2. Confirm the title-bar Settings toggle once.
3. Confirm the minimap right-click open/close sequence once.

## Live Rapid Smoke Test

This intentionally short checklist is used after WoW patches or hotfixes to decide quickly whether a MacroStudio hotfix is required. It does not replace full milestone testing.

### Phase 1 - Load and Access

- [ ] Confirm there are no startup Lua errors.
- [ ] Open MacroStudio with `/ms`, `/m`, `/macro`, `/ms settings`, `/ms blizzard`, the minimap launcher, and AddOn Compartment.

### Phase 2 - Core Editing

- [ ] Edit a macro's name, icon, and body; Save, then make another draft and Revert.
- [ ] Create and Delete a disposable macro, then sanity-check two same-name macros target the correct native records.

### Phase 3 - Action Bars

- [ ] Drag a macro to an action bar and confirm **On Bar** appears and updates for multiple placements.
- [ ] Edit that macro's name and icon and confirm its action-bar identity remains correct.

### Phase 4 - Cross-Character

- [ ] Browse and search an offline snapshot; confirm its read-only presentation and **Copy to Current Character**.

### Phase 5 - Combat

- [ ] Open MacroStudio in combat; confirm protected writes remain blocked with no taint or blocked-action errors.

### Phase 6 - Persistence

- [ ] Run `/reload`; confirm Settings, window geometry, minimap position, native macro state, and library data persist.

## Milestone 9.1: Portable Export

### Phase 1 - Build and access

- [ ] Confirm the loaded build reports `1.3.0-r3`.
- [ ] Run `/ms export`, then use **Settings -> Export MacroStudio Library**; confirm both open the same Export UI.

### Phase 2 - Export contents

- [ ] Generate a full export and compare its computed Account, current-character, offline-character, offline-snapshot, category, tag, and Favorite counts with the library.
- [ ] Confirm the complete export text is scrollable, inspectable, selectable with Ctrl+A, and copyable with Ctrl+C.

### Phase 3 - Macro fidelity

- [ ] Spot-check a normal macro, multiline body, duplicate name, question-mark icon, long body, punctuation/quotes/backslashes, Unicode, and an empty body.
- [ ] Confirm the serialized values represent the saved native definitions exactly without cleanup or normalization.

### Phase 4 - Organization

- [ ] Spot-check a Favorite, category, tag, and metadata assigned to only one duplicate-name macro.
- [ ] Confirm each association names the intended export-local macro ID rather than a macro name or native index.

### Phase 5 - Cross-character

- [ ] Inspect at least two offline characters and confirm GUID context when available, name, realm, last sync, and ordered snapshots.
- [ ] Confirm same-name characters on different realms remain separate and export does not mutate either snapshot.

### Phase 6 - Dirty draft

- [ ] Create an unsaved name/icon/body edit, generate Export, and confirm the draft remains untouched.
- [ ] Confirm Export contains the latest saved native macro and does not Save or discard the draft.

### Phase 7 - Combat

- [ ] Generate Export during combat; confirm it works with no taint, blocked-action errors, or native macro writes.

### Phase 8 - Large export / reload

- [ ] With the real macro library, generate a full export, scroll throughout it, use Ctrl+A and Ctrl+C, and confirm there is no truncation.
- [ ] Close/reopen Export, run `/reload`, and generate it again with no Lua errors or corrupted UI.

### Phase 9 - Regression

- [ ] Spot-check `/m`, `/macro`, Settings, minimap, Edit, Save/Revert, Create/Delete, action-bar drag, and **On Bar**.
- [ ] Spot-check the offline library and **Copy to Current Character**.

## Milestone 8: Default Macro Window and Access Settings (Completed)

### Phase 1 - Slash takeover

- [x] With takeover enabled, confirm `/ms`, `/macrostudio`, `/m`, and `/macro` all toggle MacroStudio.
- [x] Confirm unknown `/ms` arguments print concise help guidance and are not sent to chat.

### Phase 2 - Blizzard fallback

- [x] Run `/ms blizzard`; confirm Blizzard's native Macro UI opens and any MacroStudio draft remains intact.
- [x] Close/reopen both windows and confirm neither window changes the other's visibility or draft by itself.

### Phase 3 - Takeover setting

- [x] Disable takeover; confirm `/m` and `/macro` immediately return to Blizzard while `/ms` and `/macrostudio` stay with MacroStudio.
- [x] Re-enable takeover; confirm `/m` and `/macro` immediately return to MacroStudio without `/reload`.

### Phase 4 - Settings persistence

- [x] Open General settings from the title-bar button and `/ms settings`; confirm both controls remain usable at minimum window size.
- [x] Toggle each setting, then close/reopen, `/reload`, and logout/login; confirm the selected states persist.

### Phase 5 - Minimap

- [x] Confirm the `/M` button is readable; left-click toggles MacroStudio and right-click toggles MacroStudio together with Settings.
- [x] Drag it around the standard minimap, `/reload`, and confirm the radial position persists.
- [x] Hide and show it in Settings; confirm visibility changes immediately and the remembered position returns.

### Phase 6 - AddOn Compartment

- [x] Confirm MacroStudio appears with its `/M` icon and clicking it toggles MacroStudio.
- [x] Hide the traditional minimap button and confirm AddOn Compartment access remains available.

### Phase 7 - Blizzard coexistence

- [x] Make a dirty name/icon/body draft, run `/ms blizzard`, and edit the same native macro externally.
- [x] Confirm the existing conflict notice and Revert/deletion safety still recover without saving, discarding, or targeting a neighbor.

### Phase 8 - Combat

- [x] During combat, open/toggle through `/m`, `/macro`, `/ms`, the minimap button, and AddOn Compartment; confirm no Lua, taint, blocked-action, or protected-action errors.
- [x] Confirm Save, Create, Delete, Copy to Current Character, and action-bar drag retain their existing combat protections and never retry automatically.

### Phase 9 - Regression

- [x] Spot-check Create, name/icon/body editing, Save/Revert, Delete, search, categories, tags, Favorites, action-bar drag, and On Bar usage.
- [x] Spot-check current/offline character views, Copy to Current Character, Forget Character, and read-only snapshots.

## Milestone 7: Edit Macro Name and Icon (Completed)

### Phase 1 - Name editing

- [x] Rename one Account and one Character macro; Save and Revert each.
- [x] Rename to an existing name and confirm only the selected duplicate changes.

### Phase 2 - Icon editing

- [x] Save and Revert a normal icon change.
- [x] Repeat with the question-mark icon and a `#showtooltip` body.

### Phase 3 - Combined edit

- [x] Change name, icon, and body together; Save and confirm all three persist after `/reload`.

### Phase 4 - Action bars

- [x] Edit an On Bar macro name-only, icon-only, then to a duplicate name; confirm the correct usage indicator remains without Refresh.

### Phase 5 - Search

- [x] Rename and change a body with search plus a Favorite/category filter active; confirm results update and the filter remains.

### Phase 6 - Conflict and stale safety

- [x] Keep a dirty name/icon/body draft, change the native macro externally, and confirm Revert loads the latest native name/icon/body, clears the conflict, and restores normal Save/Delete eligibility.
- [x] With a dirty draft, delete the selected native macro externally; Revert must clear or safely reconcile selection without targeting a neighbor.
- [x] Shift nearby indices and confirm no neighboring or same-name macro is modified.

### Phase 7 - Combat

- [x] Draft name, icon, and body in combat; confirm Save is blocked and leaving combat does not save automatically.
- [x] Click Save manually after combat and confirm the draft persists correctly.

### Phase 8 - Regression

- [x] Check Create/Delete, drag-to-action-bar, On Bar, categories/tags/Favorites, the New Macro modal, and minimum-size layout.
- [x] At minimum size, confirm offline snapshots show a plain read-only name and display-only icon, keep the body selectable/copyable, and retain Copy to Current Character.

## Milestone 6: Cross-Character Macro Library (Completed)

### Phase 1 - Current character snapshot

- [x] Log into Character A and confirm its Character macros appear normally with a Current indicator.
- [x] `/reload`; confirm there is no duplication, data loss, or Lua error.
- [x] At minimum window size, confirm Characters helper and empty-state text remains fully readable.

### Sidebar scalability

- [x] With 20+ known characters and many Categories, confirm Categories and its controls remain accessible without traversing the character list.
- [x] Collapse and expand Characters; confirm the plus/minus icon and individual entries update correctly without a hover tooltip.
- [x] While Characters is collapsed, confirm All Characters remains visible and usable.
- [x] Confirm the collapse state persists through close/reopen and `/reload`.
- [x] At minimum window size, confirm Categories, Library, and the Characters toggle remain usable.

### Phase 2 - Second character

- [x] Log into Character B and confirm B becomes Current.
- [x] Confirm Character A appears under Characters as an offline snapshot.
- [x] Browse A and confirm each stored name, body, and icon matches.

### Phase 3 - Return synchronization

- [x] On A, delete one Character macro and create another.
- [x] Return to B and confirm A shows the complete newer set, with no deleted or duplicate stale entry.

### Phase 4 - Read-only safety

- [x] While on B, browse A and confirm its body is selectable, scrollable, and copyable.
- [x] Confirm editing is restored to saved text and Save, Revert, Delete, Favorite, category, and tag controls are unavailable.
- [x] Confirm drag-to-action-bar is unavailable and no `On Bar` state appears.

### Phase 5 - Copy to Current Character

- [x] Copy one of A's snapshots to B; verify a real Character macro is created with the same name, body, and icon.
- [x] Confirm the new live macro is selected and A's stored snapshot is unchanged.
- [x] Repeat with a duplicate name, at Character capacity, and with a question-mark icon.
- [x] At minimum window size, confirm Copy to Current Character remains fully visible and usable.

### Phase 6 - Search

- [x] In All Characters, search by macro name, complete body, character name, and realm.
- [x] In a specific-character view, search by macro name and body.
- [x] Confirm typing does not visibly rescan native macros or rewrite snapshots.

### Phase 7 - Character identity

- [x] If practical, visit same-name characters on different realms and confirm they remain separate.
- [x] If a tested character is renamed or transferred while retaining its GUID, confirm its one record updates instead of duplicating.

### Phase 8 - Forget Character

- [x] Forget an offline test character and confirm the dialog says only MacroStudio's snapshot is removed.
- [x] Confirm no native Character or Account macro changes and unrelated character snapshots remain.
- [x] Confirm the current character cannot be forgotten.

### Phase 9 - Combat

- [x] Browse and copy text from offline snapshots during combat.
- [x] Attempt Copy to Current Character and confirm it is blocked without Lua, taint, or protected-action errors.
- [x] Leave combat; confirm nothing copies automatically, then click Copy manually and verify normal creation.

### Phase 10 - Regression

- [x] Spot-check Account/current Character macros, search, categories, tags, Favorites, Save/Revert, Create/Delete, drag-to-action-bar, action-bar usage, and the New Macro modal.

## Milestone 5: action-bar usage

- [x] Hover normally and confirm raw slots are hidden; hold Shift before hovering the usage indicator and confirm the raw slot list appears.

### Phase 1: Basic detection

- [x] Place one Account macro and one Character macro on native action slots.
- [x] Verify both row indicators and selected-macro details.
- [x] Remove each macro and verify its indicator disappears automatically.

### Phase 2: Multiple slots

- [x] Place one macro in several slots and verify the count and raw slot list.
- [x] Remove one copy and verify both update automatically.

### Phase 3: Duplicate names

- [x] Create same-name macros with different bodies and icons.
- [x] Place only one on a bar and verify only that exact macro is marked.
- [x] With Macro A already on a bar, create same-name Macro B and confirm Macro A's indicator remains correct without another action-bar trigger.
- [x] Use `/ms debug on` and capture the structural slot identity lines if either macro is unresolved or ambiguous.

### Phase 4: Live changes

- [x] Drag from MacroStudio, move the action, replace it, and remove it.
- [x] Verify every change appears without Refresh or `/reload`.

### Phase 5: Search and organization

- [x] Verify indicators through search, Favorites, a category, and combined search/category views.
- [x] Verify Account and Character filters preserve the correct usage state.

### Phase 6: Combat

- [x] Enter combat and change or use action bars as the client permits.
- [x] Confirm there are no Lua, taint, blocked-action, or protected-action errors.
- [x] Verify usage remains current or reconciles automatically afterward.

## Drag native macros to action bars (1.1.0)

This feature is included in MacroStudio 1.1.0. Test the current development build with Lua errors enabled.

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

## 12.1 PTR Compatibility

PTR smoke testing passed on Interface `120100`, and the maintainer later confirmed the same Interface on live 12.1. The v1.2.0 TOC therefore declares `## Interface: 120100`.

Record the client build, verified Interface number, and MacroStudio commit before testing. Future Interface changes still require client evidence; do not add speculative compatibility code. This is a focused regression pass; use the historical checks below only when a phase fails.

### Branch workflow

- Test 12.1 from the current `main` branch.
- If no changes are needed, do not create a compatibility branch.
- If a 12.1-specific fix is needed, create `fix/12.1-compat`, make and verify the focused fix there, then merge it back into `main`.
- Release a patch version if the compatibility fix needs to ship after 1.1.0.
- Do not create a permanent PTR branch or make speculative fixes.

### Phase 1: Addon load

- [ ] Record PTR build, Interface number, and MacroStudio version/commit.
- [ ] Confirm the PTR client recognizes and enables MacroStudio.
- [ ] Run `/reload` and confirm no Lua errors.
- [ ] Open MacroStudio with `/ms` and `/macrostudio`.
- [ ] Confirm the complete window layout renders correctly.
- [ ] Confirm WoW's AddOns list shows the MacroStudio project icon instead of the question-mark fallback.

### Phase 2: Native macro APIs

- [ ] Compare Account and Character macro names, icons, bodies, counts, and indices with Blizzard's PTR Macro UI.
- [ ] Verify Save, Revert, Create, and Delete.
- [ ] Verify duplicate-name targeting and `UPDATE_MACROS` synchronization.
- [ ] Note any changed API signature, namespace, return value, behavior, or combat restriction.

### Phase 3: Editor and UI

- [ ] Verify the native caret, mouse placement, selection, copy/paste, and scrolling.
- [ ] Verify the complete blue focus border and window resizing.
- [ ] Verify category/tag dialogs, New Macro modal behavior, and the icon picker.
- [ ] Watch for PTR FrameXML, template, layout, atlas, or texture changes.

### Phase 4: Search and organization

- [ ] Search by name, body, category, and tag.
- [ ] Verify Favorites plus Account and Character filters.
- [ ] Run `/reload` and confirm metadata persists.

### Phase 5: Drag to action bars

This is the highest-priority PTR regression phase.

- [ ] Drag an Account macro and a Character macro to action bars.
- [ ] Drag from search, category, and Favorites results.
- [ ] Test duplicate-name macros and an occupied action slot.
- [ ] Cancel a cursor pickup and attempt pickup during combat.
- [ ] Confirm the native cursor payload is correct and watch for blocked actions, protected-action errors, taint, and Lua errors.

### Phase 6: Combat

- [ ] Confirm a dirty draft survives combat.
- [ ] Confirm Save, Create, Delete, and macro pickup remain protected according to PTR behavior.
- [ ] Leave combat and confirm nothing saves, creates, deletes, or moves automatically.

### Phase 7: SavedVariables compatibility

If practical, test with an existing `MacroStudioDB` copied or made available on PTR.

- [ ] Confirm categories, tags, Favorites, and window geometry survive.
- [ ] Confirm existing metadata reconciles to the correct native macros.
- [ ] Confirm the client-version change does not reset or destroy existing data.

### Phase 8: Quick full workflow

- [ ] Open MacroStudio, search for a macro, edit and Save it.
- [ ] Categorize, tag, and Favorite the macro, then drag it to an action bar.
- [ ] Run `/reload` and confirm the macro, organization, and window state persist without errors.

### PTR development Junction

The existing helper can link this same working tree into any verified Retail or PTR AddOns directory. Pass the actual PTR AddOns directory instead of assuming an installation location:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\scripts\setup-junction.ps1" -AddOnsPath "<PTR AddOns directory>"
```

For example only, `<PTR AddOns directory>` might be a client folder ending in `Interface\AddOns`. The supplied directory must already exist. The helper leaves an existing real `MacroStudio` directory or mismatched Junction untouched and reports the conflict for manual review.

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
