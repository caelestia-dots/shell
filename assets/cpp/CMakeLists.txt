find_package(PkgConfig REQUIRED)
pkg_check_modules(PIPEWIRE REQUIRED libpipewire-0.3)
pkg_check_modules(AUBIO REQUIRED aubio)

# Version
add_executable(version version.cpp)
target_compile_definitions(version PRIVATE
    PROJECT_NAME="${PROJECT_NAME}"
    VERSION="${VERSION}"
    GIT_REVISION="${GIT_REVISION}"
    DISTRIBUTOR="${DISTRIBUTOR}"
)
install(TARGETS version DESTINATION ${INSTALL_LIBDIR})

# Beat detector
add_executable(beat_detector beat-detector.cpp)
target_include_directories(beat_detector SYSTEM PRIVATE ${PIPEWIRE_INCLUDE_DIRS} ${AUBIO_INCLUDE_DIRS})
target_link_libraries(beat_detector PRIVATE ${PIPEWIRE_LIBRARIES} ${AUBIO_LIBRARIES})
install(TARGETS beat_detector DESTINATION ${INSTALL_LIBDIR})
