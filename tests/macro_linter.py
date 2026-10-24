"""Read-only Lua 5.1 linter fixtures, also invoked by preflight.py."""

from pathlib import Path

from lupa.lua51 import LuaRuntime


def run_linter_tests(root):
    lua = LuaRuntime(unpack_returned_tuples=True)
    namespace = lua.table()
    # Any API/global dependency outside this small standard-library allowlist
    # fails immediately. In particular no compiler, execution, or WoW APIs exist.
    load_isolated = lua.eval(
        """function(source)
            local chunk = assert(loadstring(source, '@MacroLinter.lua'))
            local env = { type = type, ipairs = ipairs, string = string, table = table }
            setmetatable(env, { __index = function(_, key)
                error('Unexpected linter global: ' .. key)
            end })
            setfenv(chunk, env)
            return chunk
        end"""
    )
    load_isolated((root / "MacroLinter.lua").read_text(encoding="utf-8"))("MacroStudio", namespace)
    linter = namespace.MacroLinter

    valid = [
        "", " \n\t", "# comment [", "#showtooltip", "#showtooltip Moonfire",
        "/cast Moonfire", "/use 13", "/use 0 1", "/use item:12345",
        "/cast !Bear Form", "/cast [@focus,harm,nodead] [] Skull Bash",
        "#showtooltip\n/cast [@mouseover,help,nodead] Regrowth; [@target,harm] Moonfire",
        "/cast [mod:ctrl/alt][known:12345] Moonfire; [] Regrowth",
        "/cast [target=focus,nomod] Moonfire", "/cast [future:unknown] Moonfire",
        "/castsequence reset=target/5 Moonfire, Regrowth, null",
        "/castsequence [mod] reset=combat/shift 13, !Moonfire; [] Regrowth",
        "/cast [mod]; Moonfire", "/cast Moonfire;", "/cast ; Moonfire",
        "/myaddon [unclosed; ]", '/run print("[;]")',
        '/script local t={"["}; print(t[1])', '/run error("never execute")',
        "/say [hello", "/click [odd", "/stopmacro [odd",
        "/use |cffffffff|Hitem:12345:0|h[Item; /cast []]|h|r",
        "/cast [mod] |Hspell:123|h[Spell]|h; [] Moonfire",
        "/cast Spell [payload", "/castsequence null, , Moonfire",
        "\t/CAST [] Moonfire", "#showtooltipx\n#showtooltip", None,
    ]
    invalid = [
        ("/cast [harm Moonfire", [("UNCLOSED_CONDITIONAL", "Error", 1, 7)]),
        ("/use ] 13", [("UNEXPECTED_CLOSE", "Error", 1, 6)]),
        ("/cast [[help] Regrowth", [("NESTED_CONDITIONAL", "Error", 1, 8)]),
        ("/cast [help]] Regrowth", [("UNEXPECTED_CLOSE", "Error", 1, 13)]),
        ("/cast", [("MISSING_ARGUMENT", "Warning", 1, 6)]),
        ("/use []", [("MISSING_ARGUMENT", "Warning", 1, 5)]),
        ("/cast [mod] ; []", [("MISSING_ARGUMENT", "Warning", 1, 6)]),
        ("/castsequence", [("MISSING_ARGUMENT", "Warning", 1, 14)]),
        ("/castsequence [mod] reset=target/5", [("MISSING_ARGUMENT", "Warning", 1, 14)]),
        ("#showtooltip\n#showtooltip Moonfire", [("DUPLICATE_SHOWTOOLTIP", "Warning", 2, 1)]),
        ("#showtooltip\r\n\t#SHOWTOOLTIP\r#showtooltip", [
            ("DUPLICATE_SHOWTOOLTIP", "Warning", 2, 2),
            ("DUPLICATE_SHOWTOOLTIP", "Warning", 3, 1),
        ]),
        ("# comment\n/cast Moonfire; [harm", [("UNCLOSED_CONDITIONAL", "Error", 2, 17)]),
        ("/cast [\n/use ] 13", [
            ("UNCLOSED_CONDITIONAL", "Error", 1, 7),
            ("UNEXPECTED_CLOSE", "Error", 2, 6),
        ]),
    ]

    def analyze(body):
        result = linter.Analyze(linter, body)
        return [(d.code, d.severity, d.line, d.column) for d in result.values()]

    for body in valid:
        assert analyze(body) == [], f"False positive: {body!r}: {analyze(body)}"
    for body, expected in invalid:
        assert analyze(body) == expected, f"{body!r}: {analyze(body)} != {expected}"
        assert all(d.message for d in linter.Analyze(linter, body).values())

    # Repeated edits must be independent, deterministic, and return fresh results.
    for _ in range(20):
        assert analyze("/cast [") == invalid[0][1]
        assert analyze("/cast [] Moonfire") == []
    first = linter.Analyze(linter, "/cast [")
    first[1].message = "changed by caller"
    assert linter.Analyze(linter, "/cast [")[1].message != "changed by caller"
    many = "\n".join(["/cast ["] * 1000)
    assert len(linter.Analyze(linter, many)) == 1000, "Do not truncate oversized drafts"
    print(f"PASS macro linter: {len(valid) + len(invalid)} fixtures + 3 isolation/repetition/oversized checks")


if __name__ == "__main__":
    run_linter_tests(Path(__file__).resolve().parents[1])
