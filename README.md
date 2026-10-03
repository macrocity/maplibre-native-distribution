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
