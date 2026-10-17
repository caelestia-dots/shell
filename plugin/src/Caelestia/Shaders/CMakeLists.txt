qml_module(caelestia-shaders
    URI Caelestia.Shaders
    SOURCES
        shaders.cpp
)

qt_add_shaders(caelestia-shaders "shaders"
    BATCHABLE OPTIMIZED NOHLSL NOMSL
    GLSL "300es,330"
    PREFIX "/shaders"
    FILES
        crossfade.frag
)
