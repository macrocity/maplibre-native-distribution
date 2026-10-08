Macrocity globe SDK binary distribution.

Renderer source: https://github.com/macrocity/maplibre-native/tree/e4be05b5e6c0488b2b8935ecbe67e14bad227ae0

## Android SDK build

The manually triggered **Build Android SDK** workflow (`.github/workflows/android-sdk.yml`) builds each ABI on
its own runner and `merge-android.py` merges them. It uploads two artifacts:

| Artifact | What |
|---|---|
| `android-maven` | `android-maven.zip`, the Maven publication with the stripped `libmaplibre.so` of every ABI |
| `android-native-symbols` | `android-native-symbols.zip`, the unstripped `libmaplibre.so` of every ABI from the same builds (`<abi>/libmaplibre.so`) |

A crash reporter reads files and lines of a MapLibre frame from the unstripped library, found by its GNU build
ID; a rebuild of the same source does not match. `merge-android.py` checks that each unstripped library has debug
info and the build ID of the stripped one in the SDK. Both archives go to the same release of the app; see
`docs/maplibre-native.md` in `macrocity/app`, "Debug symbols".

## Actions artifact cleanup

The separate **Actions storage cleanup** workflow runs hourly and after SDK builds.
It keeps artifacts while their workflow runs, and for 24 hours after completion.
It then moves known SDK artifacts to private releases named `ci-artifacts/run-<run-id>`.
Unknown artifact names and unrelated workflows remain untouched.

The cleanup copies every original artifact ZIP, including intermediate ABI files,
Android native symbols, and iOS dSYMs. It downloads the release copy and compares
SHA-256 hashes before it deletes the Actions copy. Each ZIP has a verified JSON
receipt containing the original artifact metadata, workflow source commit,
archive URL, size, and SHA-256 hash. A failed copy, receipt, or checksum keeps the
original. A restarted workflow also keeps its artifacts. Archives have no automatic
expiry. They are separate from the SDK releases used by the app.

Preview or apply cleanup manually:

```sh
gh workflow run actions-storage.yml --repo macrocity/maplibre-native-distribution -f apply=false
gh workflow run actions-storage.yml --repo macrocity/maplibre-native-distribution -f apply=true
```

Recover the same build after Actions cleanup. Use the artifact ID from its receipt
or cleanup log. This example restores the Android symbols from workflow run
`37319040943`, artifact `11351000513`:

```sh
mkdir -p .local/sdk-recovery
gh release download ci-artifacts/run-37319040943 \
  --repo macrocity/maplibre-native-distribution \
  --pattern '11351000513-android-native-symbols.zip*' --dir .local/sdk-recovery
python3 - <<'PY'
import hashlib, json, pathlib
root = pathlib.Path('.local/sdk-recovery')
receipt = json.loads((root / '11351000513-android-native-symbols.zip.json').read_text())
archive = root / '11351000513-android-native-symbols.zip'
assert hashlib.sha256(archive.read_bytes()).hexdigest() == receipt['archive']['sha256']
print('Verified original artifact:', archive)
PY
unzip .local/sdk-recovery/11351000513-android-native-symbols.zip -d .local/sdk-recovery/symbols
```

An Actions artifact ZIP wraps the build output. The restored directory therefore
contains the original `android-native-symbols.zip`. For `ios-sdk`, it contains the
XCFramework and dSYM archives. Extract those files as usual. Do not rebuild a
historical SDK to replace its symbols: native build IDs must match the shipped SDK.

The script uses Node 22 with no package dependencies. Local checks and preview:

```sh
node --test scripts/actions-storage.test.mjs
GITHUB_REPOSITORY=macrocity/maplibre-native-distribution \
  GITHUB_TOKEN="$(gh auth token)" node scripts/actions-storage.mjs --dry-run
```
