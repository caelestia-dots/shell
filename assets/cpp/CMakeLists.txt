find_package(PkgConfig REQUIRED)
pkg_check_modules(PIPEWIRE REQUIRED libpipewire-0.3)
pkg_check_modules(AUBIO REQUIRED aubio)

# Beat detector
add_executable(beat_detector beat-detector.cpp)
add_executable(capslock_state capslock-state.cpp)
target_include_directories(beat_detector PRIVATE ${PIPEWIRE_INCLUDE_DIRS} ${AUBIO_INCLUDE_DIRS})
target_link_libraries(beat_detector PRIVATE ${PIPEWIRE_LIBRARIES} ${AUBIO_LIBRARIES})
install(TARGETS beat_detector DESTINATION ${INSTALL_LIBDIR})
install(TARGETS capslock_state DESTINATION ${INSTALL_LIBDIR})
