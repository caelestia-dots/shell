cmake_minimum_required(VERSION 3.19)
find_package(PkgConfig REQUIRED)
pkg_check_modules(PIPEWIRE REQUIRED libpipewire-0.3)
pkg_check_modules(AUBIO REQUIRED aubio)

# Beat detector
add_executable(beat_detector beat-detector.cpp)
target_include_directories(beat_detector PRIVATE ${PIPEWIRE_INCLUDE_DIRS} ${AUBIO_INCLUDE_DIRS})
target_link_libraries(beat_detector PRIVATE ${PIPEWIRE_LIBRARIES} ${AUBIO_LIBRARIES})
install(TARGETS beat_detector DESTINATION ${INSTALL_LIBDIR})
