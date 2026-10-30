find_package(caelestia REQUIRED)
caelestia_setup()
caelestia_setup_warnings()

if(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
    add_compile_options(-Wno-nonportable-include-path)
endif()

find_package(Qt6 REQUIRED COMPONENTS ShaderTools Core Qml Gui Quick QuickControls2 Concurrent Sql Network DBus Multimedia)
find_package(PkgConfig REQUIRED)
pkg_check_modules(Qalculate IMPORTED_TARGET libqalculate REQUIRED)
pkg_check_modules(Pipewire IMPORTED_TARGET libpipewire-0.3 REQUIRED)
pkg_check_modules(Aubio IMPORTED_TARGET aubio REQUIRED)
pkg_check_modules(Cava IMPORTED_TARGET libcava QUIET)
if(NOT Cava_FOUND)
    pkg_check_modules(Cava IMPORTED_TARGET cava REQUIRED)
endif()
include(cmake/sensorslib.cmake)

set(QT_QML_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/qml")
qt_standard_project_setup(REQUIRES 6.9)

include(cmake/pch.cmake)
include(cmake/qml-module.cmake)

# Shared helpers
add_library(caelestia-util STATIC src/util/refgated.cpp)
qt_extract_metatypes(caelestia-util)
file(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/include")
file(CREATE_LINK "${CMAKE_CURRENT_SOURCE_DIR}/src/util" "${CMAKE_CURRENT_BINARY_DIR}/include/util" SYMBOLIC)
target_include_directories(caelestia-util PUBLIC "${CMAKE_CURRENT_BINARY_DIR}/include")
target_link_libraries(caelestia-util PUBLIC Qt::Core)
set_target_properties(caelestia-util PROPERTIES POSITION_INDEPENDENT_CODE ON)

add_subdirectory(3rdparty/rgbcx)
add_subdirectory(src/Caelestia)
