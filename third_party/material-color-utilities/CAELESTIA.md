# material-color-utilities (vendored)

Upstream: https://github.com/material-foundation/material-color-utilities (C++ sources under `cpp/`,
Apache-2.0, see `LICENSE`). Taken from the upstream `main` branch archive; the commit wasn't recorded.

The caelestia shell uses this for HCT, CAM16, luminance and the quantizer (Wu, then WSMeans, and
Celebi). The scheme, dynamic colour and temperature code is ported in `plugin/src/Caelestia/Material`
so the colours match materialyoucolor, the Python library the caelestia CLI uses.

## Local changes

- `cpp/quantize/wsmeans.cc`: `absl::flat_hash_map` replaced by `std::unordered_map`, so the tree
  needs no Abseil.
- `cpp/utils/utils.cc`: `absl::StrCat` replaced by `std::format("{:x}", ...)`.
- `cpp/temperature/temperature_cache.h`: `#include <optional>` added (it was missing).
- `cpp/cam/viewing_conditions.h`: `kDefaultViewingConditions` holds materialyoucolor's
  `ViewingConditions.DEFAULT` in full precision. Upstream rounds the constants to nine decimals,
  which moves Hct hues by about 1e-5 and flips some colours by one step in the 8-bit channels.

Only the sources listed in `plugin/src/Caelestia/Material/CMakeLists.txt` are built.
