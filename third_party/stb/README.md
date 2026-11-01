# stb_image (vendored)

`stb_image.h` is v2.29, public domain (see the header), from
https://github.com/nothings/stb. It's the copy materialyoucolor 3.0.2 bundles, which the caelestia
CLI's quantizer decodes with. Using the same decoder keeps the wallpaper thumbnails' pixels, and so
their colours, identical to the CLI's.

Its single implementation is compiled in `plugin/src/Caelestia/Material/stb_decode.cc`.
