"""Package a Bazel-built MapLibre XCFramework with source provenance, license notices and its dSYMs.

package-ios.py <source checkout> <MapLibre.dynamic.xcframework.zip> <dsyms dir> <output dir>

The same checks and layout as `scripts/maplibre/package-sdk.py` of macrocity/app: the archive keeps the simulator
(arm64, x86_64) and device (arm64) slices, and `MapLibre.xcframework.dSYM.zip` holds one
`<slice>/MapLibre.framework.dSYM` per slice, matched to its binary by UUID.
"""
import hashlib
import json
import plistlib
import shutil
import subprocess
import sys
import tempfile
import zipfile
from pathlib import Path

source, xcframework, dsyms, output = map(Path, sys.argv[1:])


def uuids(path):
    out = subprocess.check_output(["dwarfdump", "--uuid", str(path)], text=True)
    return {line.split()[2].strip("()"): line.split()[1] for line in out.splitlines() if line.startswith("UUID:")}


revision = subprocess.check_output(["git", "-C", str(source), "rev-parse", "HEAD"], text=True).strip()
provenance = json.dumps({"repository": "https://github.com/macrocity/maplibre-native", "sourceRevision": revision}, indent=2) + "\n"
output.mkdir(parents=True, exist_ok=True)
target = output / "MapLibre.xcframework.zip"
with zipfile.ZipFile(xcframework) as archive:
    libraries = plistlib.loads(archive.read("MapLibre.xcframework/Info.plist"))["AvailableLibraries"]
    assert any(lib.get("SupportedPlatformVariant") == "simulator" and set(lib["SupportedArchitectures"]) == {"arm64", "x86_64"} for lib in libraries), "Missing simulator architectures"
    assert any(lib.get("SupportedPlatformVariant") is None and "arm64" in lib["SupportedArchitectures"] for lib in libraries), "Missing iOS device architecture"
shutil.copyfile(xcframework, target)
with zipfile.ZipFile(target, "a", zipfile.ZIP_DEFLATED) as archive:
    archive.write(source / "LICENSE.md", "LICENSE.md")
    archive.write(source / "LICENSES.core.md", "LICENSES.core.md")
    archive.write(source / "platform/ios/LICENSE.md", "LICENSES.ios.md")
    archive.writestr("SOURCE.json", provenance)

dsym_target = output / "MapLibre.xcframework.dSYM.zip"
dwarfs = [dwarf for dsym in dsyms.glob("*.dSYM") for dwarf in (dsym / "Contents/Resources/DWARF").iterdir()]
by_uuid = {uuid: dwarf for dwarf in dwarfs for uuid in uuids(dwarf).values()}
with tempfile.TemporaryDirectory() as work, zipfile.ZipFile(target) as archive, zipfile.ZipFile(dsym_target, "w", zipfile.ZIP_DEFLATED) as out:
    work = Path(work)
    for library in plistlib.loads(archive.read("MapLibre.xcframework/Info.plist"))["AvailableLibraries"]:
        slice_id = library["LibraryIdentifier"]
        binary = work / slice_id / "MapLibre"
        binary.parent.mkdir(parents=True)
        binary.write_bytes(archive.read(f"MapLibre.xcframework/{slice_id}/MapLibre.framework/MapLibre"))
        want = uuids(binary)
        missing = [uuid for uuid in want.values() if uuid not in by_uuid]
        assert not missing, f"No dSYM for {slice_id} ({', '.join(missing)})"
        sources = sorted({str(by_uuid[uuid]) for uuid in want.values()})
        dwarf = work / f"{slice_id}.dwarf"
        if len(sources) == 1:
            dwarf.write_bytes(Path(sources[0]).read_bytes())
        else:
            subprocess.check_call(["lipo", "-create", *sources, "-output", str(dwarf)])
        assert uuids(dwarf) == want, f"The dSYM of {slice_id} does not match its binary"
        base = f"{slice_id}/MapLibre.framework.dSYM/Contents"
        out.writestr(f"{base}/Info.plist", (Path(sources[0]).parents[2] / "Info.plist").read_bytes())
        out.write(dwarf, f"{base}/Resources/DWARF/MapLibre")

result = {
    "sourceRevision": revision,
    "ios": {
        "file": target.name,
        "sha256": hashlib.sha256(target.read_bytes()).hexdigest(),
        "dsymFile": dsym_target.name,
        "dsymSha256": hashlib.sha256(dsym_target.read_bytes()).hexdigest(),
    },
}
(output / "ios.json").write_text(json.dumps(result, indent=2) + "\n")
print(json.dumps(result, indent=2))
