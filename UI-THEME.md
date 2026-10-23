# MacroStudio native Warcraft frame system

## Resource audit

The original audit used Retail 12.1.0.69933 on 2026-10-07. The installed client
is now 12.1.5.70448 (checked 2026-10-23); the addon declares Interface `120105`.
Current live source definitions for the shared button/window primitives and
scroll utilities were rechecked on 2026-10-23. This verifies source availability
and APIs; it does not replace
loading the addon and inspecting its rendering in that installed client.

| Purpose | Blizzard resource used |
| --- | --- |
| Main window | `PortraitFrameTemplate`, its NineSlice layout and sculpted portrait corner |
| Secondary windows | `DefaultPanelTemplate`, `ButtonFrameTemplateNoPortrait` NineSlice layout |
| Window material | Native `Interface/FrameGeneral/UI-Background-Rock` and `TopTileStreaks` |
| Shared content recess | `InsetFrameTemplate`, inset NineSlice, warm charcoal base with restrained native rock wash |
| Code editor recess | `InsetFrameTemplate3`, eight `Common-Input-Border` frame pieces |
| Title and subtle rules | `_UI-Frame-TitleTileBg`, `_UI-Frame-InnerTopTile`, `!UI-Frame-InnerRightTile` |
| Physical buttons | `UIPanelButtonGrayTemplate`, separate native up/down/disabled/highlight artwork |
| Search/name fields | `InputBoxTemplate`, native `common-search-border-*` pieces and input scripts |
| Scope tabs | `PanelTopTabButtonTemplate`, native active/inactive pieces and `PanelTemplates_SelectTab`/`DeselectTab` |
| Scrollbars | `WowTrimScrollBar`, native rail, endcaps, arrows and stateful thumb |
| Scrolling text | `ScrollingEditBoxTemplate`, `ScrollUtil.RegisterScrollBoxWithScrollBar` |
| Lists | Intrinsic `ScrollFrame`, `ScrollUtil.InitScrollFrameWithScrollBar` |
| Row selection | `Interface/QuestFrame/UI-QuestTitleHighlight` |
| Icon frame | `Interface/Buttons/UI-Quickslot2` |
| Other controls | `UIPanelCloseButton`, `UICheckButtonTemplate`, `PetJournal-FavoritesIcon`, native resize grip |
| Text, tooltips, confirmations | GameFont family, `GameTooltip`, `StaticPopup` |

Primary implementation sources:

- [SharedUIPanelTemplates.xml](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_SharedXML/Mainline/SharedUIPanelTemplates.xml)
- [NineSliceLayouts.lua](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_SharedXML/Mainline/NineSliceLayouts.lua)
- [UIPanelTemplates.xml](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_UIPanelTemplates/Mainline/UIPanelTemplates.xml)
- [InputBoxTemplates.xml](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_SharedXML/Shared/InputBox/InputBoxTemplates.xml)
- [TrimScrollBar.xml](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_SharedXML/Shared/Scroll/TrimScrollBar.xml)
- [ScrollUtil.lua](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_SharedXML/Shared/Scroll/ScrollUtil.lua)
- [SecureScrollTemplates.xml](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_SharedXML/Mainline/SecureScrollTemplates.xml)

`SecureScrollTemplates.xml` explicitly marks its templates deprecated. The
replacement does not use `UIPanelScrollFrameTemplate` or
`UIPanelScrollBarTemplate`. The old flat styling helper and its custom surface
and button textures were removed. Blizzard artwork is referenced from the game,
not copied into this addon.

## Construction and depth

Warcraft remains the default appearance. `UI/LegacyTheme.lua` provides the
original blue/gray window, blue title and selection, separately bordered columns
and classic panel buttons as an optional presentation. Settings → Appearance
saves the account-wide preference and offers an explicit Reload UI action.
Pending choices do not rebuild live frames or discard drafts. The two designs
share feature controllers, repositories, native editing/scrolling APIs and
saved data. Legacy deliberately retains current supported scrolling APIs rather
than bringing back deprecated scroll templates. The accepted Warcraft frame,
medallion placement and column geometry are unchanged when it is selected.

`UI/WarcraftTheme.lua` constructs native windows, insets, fields and controls.
`Utils/Helpers.lua` routes shared UI factories through it. The TOC loads the
frame system before helpers and UI modules.

The main window has a sculpted metal perimeter, a textured rock surface, one
shared warm charcoal inset and a deeper eight-piece code-editor recess. Library,
Macros and Editor are transparent regions of that common inset, separated by
narrow engraved native edge pieces with a dark groove and faint lit lip. There
are no three bordered cards. The native
portrait corner carries a 46-pixel original emblem beside the title; version
text is subordinate. Settings occupies a physical bottom-frame button.

The restrained polish pass adds a 24%-opacity native rock wash over the warm
base behind Library, Macros and editor metadata. The code surface remains
near-black. Directional inner shadows and a faint lower lip strengthen its
existing native recess without changing its geometry. The title is one font
pixel larger with a warm highlight; the version uses a separate quieter color.
Preview/footer metadata uses a brighter cream-gray with a text shadow, while
editor status uses the normal-size native highlight font. Calculated minimum
contrast against even the brightest possible material wash is 5.02:1 for
preview/footer text and 7.46:1 for ordinary status text; macro text retains
14.46:1 against its code surface. Warning/error color meanings are preserved.

Native normal, hover, pushed and disabled button artwork remains intact.
Favorite uses the native pushed state. Scope selection uses real top tabs.
List rows use native selection washes and dark rules, while search uses
Blizzard's inset input art. Full 25-pixel scrollbars provide track, thumb and
arrows. Existing dropdown menus share the inset and row treatments. Secondary
windows share the native metal perimeter, material and title system.

## Original MacroStudio artwork

The only custom runtime artwork is `Media/MacroStudioIcon.tga`: a transparent
64-pixel scroll-and-quill bronze medallion. Its editable source is
`assets/MacroStudioEmblem.svg`, with PNG exports at 32, 64 and 256 pixels.
The illustration uses solid shapes, rim highlights and cast shadows, without
gradients, lettering or sparkles. The same artwork is used by the title frame,
minimap and AddOn Compartment. It contains no Whisper Messenger artwork.

Rebuild with `node scripts/build-media.cjs [absolute path to sharp]`.
Only the runtime emblem is packaged; the build dependency and editable/export
assets are excluded. Saved-data formats and macro repository behavior remain
unchanged.

## Verification and acceptance status

`py tests/preflight.py` compiles addon Lua under Lua 5.1 and exercises the full
TOC construction path, search, editing, saves, scope selection, Favorites,
metadata, modal cleanup, icon selection, launchers, combat restrictions and
offline character snapshots. Native component construction and multi-page
icon-picker scrolling have explicit regression checks. Packaging verifies its
runtime manifest and portable ZIP paths.

The user accepted the structural direction on 2026-10-07 and supplied a live
screenshot for comparison with Whisper Messenger. They authorized one
restrained polish pass and instructed that visual acceptance be considered
complete afterward unless an obvious regression appeared. That pass is now
complete, with passing behavior checks and no further redesign or screenshot
approval gate. The approved frame, medallion placement, column geometry,
footer Settings control, macro rows and native scrollbar approach are retained.

The supplied screenshot shows Settings at the top, whereas the current source
places it in the footer. The polish preserves the current source layout rather
than moving controls to match that discrepancy. The earlier preparation could
not initialize desktop capture. On 2026-10-23, the owner tested the exact release
ZIP and signed off the live release smoke checklist, including the appearance
selection and Lua-error checks. These are owner-reported results; the agent did
not independently observe the live test or capture new screenshots. Existing
repository screenshots are historical. See `RELEASE-1.3.0.md` for the sign-off
and tested artifact checksum.

