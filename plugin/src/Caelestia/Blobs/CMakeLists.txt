qml_module(caelestia-blobs
    URI Caelestia.Blobs
    SOURCES
        blobgroup.cpp
        blobshape.cpp
        blobrect.cpp
        blobinvertedrect.cpp
        blobmaterial.cpp
    LIBRARIES
        Qt::Quick
)

qt_add_shaders(caelestia-blobs "blob_shaders"
    BATCHABLE OPTIMIZED NOHLSL NOMSL
    PREFIX "/"
    FILES
        shaders/blob.frag
        shaders/blob.vert
)
