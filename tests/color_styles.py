"""Fresh-start and upgrade verification for the unified style selector."""
from lupa.lua51 import LuaRuntime


def run_color_style_tests(root):
    for style in ("warcraft", "legacy", "emerald", "violet", "ember"):
        lua = LuaRuntime(unpack_returned_tuples=True)
        ns = lua.table()
        ns.db = lua.table_from({"settings": lua.table_from({
            "style": style,
            "sentinel": "preserve",
        })})
        for file in ("UI/WarcraftTheme.lua", "UI/LegacyTheme.lua", "UI/ColorStyles.lua"):
            lua.eval("loadstring")((root / file).read_text(encoding="utf-8"), "@" + file)("MacroStudio", ns)
        lua.execute('''
            local ms = ...
            local theme = ms.Theme
            local references = {theme.palette.text, theme.palette.error, theme.palette.focus}
            local originalError = {unpack(theme.palette.error)}
            theme:Initialize()
            assert(theme.activeAppearance == ms.db.settings.appearance)
            assert(theme.activeColorStyle == theme:GetColorStyle().id)
            assert(references[1] == theme.palette.text and references[2] == theme.palette.error
                and references[3] == theme.palette.focus, "captured palette references must remain valid")
            for _,color in pairs(theme.palette) do
                assert(#color == 4)
                for _,channel in ipairs(color) do assert(channel >= 0 and channel <= 1) end
            end
            if theme.activeAppearance == "warcraft" then
                for i=1,4 do assert(theme.palette.error[i] == originalError[i], "color styles must retain error semantics") end
            else
                assert(theme.palette.error[1] == 1 and theme.palette.error[2] == 0.3)
            end
            local function luminance(c)
                local result = 0
                for i,weight in ipairs({0.2126,0.7152,0.0722}) do
                    local x = c[i]
                    result = result + weight * (x <= 0.04045 and x / 12.92 or ((x + 0.055) / 1.055)^2.4)
                end
                return result
            end
            local background = theme:IsLegacy() and theme.palette.legacyEditor or theme.palette.editorBackground
            assert((luminance(theme.palette.text)+0.05)/(luminance(background)+0.05) >= 7,
                "all presets must preserve strong macro-text contrast")
            local before = theme.activeColorStyle
            assert(theme:SetColorStyle(before == "emerald" and "ember" or "emerald"))
            assert(theme.activeColorStyle == before and theme:HasPendingAppearance())
            assert(not theme:SetColorStyle("invalid-style"), "unknown style must not overwrite the saved choice")
            assert(theme:SetColorStyle(before))
            assert(not theme:HasPendingAppearance(), "returning to the active style must cancel reload")
            assert(ms.db.settings.sentinel == "preserve")
            theme:Initialize()
            assert(theme.activeColorStyle == before, "initialization must be idempotent")
        ''', ns)
    cases = (
        ({}, "warcraft"),
        ({"appearance": "legacy"}, "legacy"),
        ({"appearance": "warcraft", "colorStyles": {"warcraft": "default"}}, "warcraft"),
        ({"appearance": "warcraft", "colorStyles": {"warcraft": "frost"}}, "legacy"),
        ({"appearance": "warcraft", "colorStyles": {"warcraft": "violet"}}, "violet"),
        ({"appearance": "legacy", "colorStyles": {"legacy": "ember"}}, "legacy"),
        ({"style": "emerald", "appearance": "legacy"}, "emerald"),
        ({"style": "unknown", "appearance": "warcraft"}, "warcraft"),
    )
    for saved, expected in cases:
        lua = LuaRuntime(unpack_returned_tuples=True)
        settings = lua.table_from(saved, recursive=True)
        settings.sentinel = "preserve"
        ns = lua.table_from({"db": lua.table_from({"settings": settings})})
        for file in ("UI/WarcraftTheme.lua", "UI/LegacyTheme.lua", "UI/ColorStyles.lua"):
            lua.eval("loadstring")((root / file).read_text(encoding="utf-8"), "@" + file)("MacroStudio", ns)
        ns.Theme.Initialize(ns.Theme)
        assert settings.style == expected
        assert ns.Theme.activeColorStyle == expected
        assert settings.appearance == ("legacy" if expected == "legacy" else "warcraft")
        ns.Theme.Initialize(ns.Theme)
        assert settings.style == expected and settings.sentinel == "preserve"
    print("PASS unified styles: 5 palettes, contrast, staged application and 8 upgrade cases")
