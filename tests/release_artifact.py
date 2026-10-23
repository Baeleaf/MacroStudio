"""Verify the exact distribution ZIP, manifest, version and source parity."""

import argparse
import hashlib
import json
from pathlib import Path, PurePosixPath
import re
import zipfile

ROOT = Path(__file__).resolve().parents[1]


def verify_release(version):
    assert re.fullmatch(r"\d+\.\d+\.\d+(?:[-+][0-9A-Za-z.-]+)?", version), "Invalid release version"
    artifact = ROOT / "dist" / f"MacroStudio-v{version}.zip"
    with zipfile.ZipFile(artifact) as archive:
        names = archive.namelist()
        assert len(names) == len(set(names)), "Duplicate archive paths"
        assert archive.testzip() is None, "Corrupt ZIP entry"
        for name in names:
            path = PurePosixPath(name)
            assert "\\" not in name and not path.is_absolute() and ".." not in path.parts, name
            assert path.parts[0] == "MacroStudio" and not name.endswith("/"), name

        toc = archive.read("MacroStudio/MacroStudio.toc").decode("utf-8-sig")
        metadata = dict(re.findall(r"^## ([^:]+):\s*(.+)$", toc, re.MULTILINE))
        assert metadata["Version"].strip() == version
        assert metadata["Interface"].strip() == "120105"
        assert metadata["SavedVariables"].strip() == "MacroStudioDB"
        runtime = [line.strip().replace("\\", "/") for line in toc.splitlines()
                   if line.strip() and not line.startswith("#")]
        icon = metadata["IconTexture"].strip().replace("\\", "/")
        prefix = "Interface/AddOns/MacroStudio/"
        assert icon.startswith(prefix)
        expected = {"MacroStudio/MacroStudio.toc", "MacroStudio/LICENSE",
                    "MacroStudio/" + icon[len(prefix):]}
        expected.update("MacroStudio/" + path for path in runtime)
        assert set(names) == expected, f"Extra/missing entries: {set(names) ^ expected}"
        assert len(runtime) == len(set(runtime)), "Duplicate TOC paths"
        core = archive.read("MacroStudio/Core.lua").decode("utf-8")
        assert re.search(r'MacroStudio\.VERSION\s*=\s*"([^"]+)"', core).group(1) == version
        license_text = archive.read("MacroStudio/LICENSE").decode("utf-8")
        assert "MIT License" in license_text and "Copyright (c) 2026 Baeleaf" in license_text

        entries = []
        for name in sorted(names):
            relative = name.removeprefix("MacroStudio/")
            content = archive.read(name)
            assert content == (ROOT / relative).read_bytes(), f"Outdated source in ZIP: {name}"
            entries.append({"path": name, "bytes": len(content),
                            "sha256": hashlib.sha256(content).hexdigest()})

    manifest = {"filename": artifact.name, "version": version, "interface": 120105,
                "bytes": artifact.stat().st_size,
                "sha256": hashlib.sha256(artifact.read_bytes()).hexdigest(),
                "entries": entries}
    manifest_path = artifact.with_suffix(".manifest.json")
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(f"PASS release artifact: {artifact.name}, {len(entries)} files, {manifest['bytes']} bytes")
    print(f"SHA256 {manifest['sha256']}")
    for entry in entries:
        print(entry["path"])
    return manifest


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("version")
    verify_release(parser.parse_args().version)
