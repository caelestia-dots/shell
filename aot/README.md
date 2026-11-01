# AOT QML build

`CAELESTIA_AOT_QML=ON` compiles the shell QML into the `Caelestia.Qml`
module tree with `qt_add_qml_module`/`qmlcachegen`. The normal source build
stays the default; this option only changes the build and install output.

The source tree is not moved. `prepare.py` copies the QML into
`build/aot-qml/src`, rewrites `qs.*` and relative imports to the generated
`Caelestia.Qml.*` modules, and emits the CMake module definitions. Assets and
the lock config are symlinked into the build config root so paths resolve.

```sh
cmake -B build-aot -G Ninja \
    -DCAELESTIA_AOT_QML=ON \
    -DVERSION= -DGIT_REVISION=
cmake --build build-aot

# Run the compiled shell from the build tree
QML2_IMPORT_PATH="$PWD/build-aot/qml" \
    qs -p "$PWD/build-aot/aot-qml/shell.qml"
```

`cmake --install build-aot` installs the generated launcher plus the compiled
modules. A local measurement of the time from launch to `Configuration Loaded`
(same session, second instance) was about 0.66 s for the source tree and
0.52 s for the AOT build, averaged over four runs.
