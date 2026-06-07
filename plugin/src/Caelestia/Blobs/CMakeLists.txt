qml_module(caelestia-blobs
    URI Caelestia.Blobs
    SOURCES
        blobgroup.hpp blobgroup.cpp
        blobshape.hpp blobshape.cpp
        blobrect.hpp blobrect.cpp
        blobinvertedrect.hpp blobinvertedrect.cpp
        blobmaterial.hpp blobmaterial.cpp
    LIBRARIES
        Qt::Quick
)

qt_add_shaders(caelestia-blobs "blob_shaders"
    BATCHABLE OPTIMIZED NOHLSL NOMSL
    GLSL "300es,330"
    PREFIX "/"
    FILES
        shaders/blob.frag
        shaders/blob.vert
)
