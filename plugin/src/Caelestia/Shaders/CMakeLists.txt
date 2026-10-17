qml_module(caelestia-shaders
    URI Caelestia.Shaders
    SOURCES
        shaders.hpp
    LIBRARIES
        Qt::Gui
        caelestia-config
)

qt_add_shaders(caelestia-shaders "shaders"
    BATCHABLE OPTIMIZED NOHLSL NOMSL
    GLSL "300es,330"
    PREFIX "/shaders"
    FILES
        crossfade.frag
        chromatic-bloom.frag
        colour-distance.frag
        crosshatch.frag
        crosswarp.frag
        directional.frag
        directional-wipe.frag
        fade-colour.frag
        glitch.frag
        glitch-displace.frag
        heat-melt.frag
        ink-splash.frag
        inkwell-drop.frag
        iris.frag
        morph.frag
        parametric-glitch.frag
        perlin.frag
        pixelate.frag
        pixelfade-wave.frag
        plasma-flow.frag
        polka-dots-curtain.frag
        puzzle-right.frag
        random-squares.frag
        smoke.frag
        soft-warp-fade.frag
        voronoi-shatter.frag
        zoom-blur-pull.frag
)
