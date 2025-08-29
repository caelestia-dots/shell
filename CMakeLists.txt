cmake_minimum_required(VERSION 3.19)

if(NOT DEFINED VERSION)
    execute_process(COMMAND git describe --tags --abbrev=0
        WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
        OUTPUT_VARIABLE VERSION
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )

    if("${VERSION}" STREQUAL "")
        message(FATAL_ERROR "VERSION is not set and failed to get from git")
    endif()
endif()

string(REGEX REPLACE "^v" "" VERSION "${VERSION}")

project(caelestia-shell VERSION ${VERSION} LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib")

set(INSTALL_LIBDIR "usr/lib/caelestia" CACHE STRING "Library install dir")
set(INSTALL_QMLDIR "usr/lib/qt6/qml" CACHE STRING "QML install dir")
set(INSTALL_QSCONFDIR "etc/xdg/quickshell/caelestia" CACHE STRING "Quickshell config install dir")

add_compile_options(-Wall -Wextra)

if(NOT DONT_BUILD_ASSETS)
    add_subdirectory(assets/cpp)
endif()

if(NOT DONT_BUILD_PLUGIN)
    add_subdirectory(plugin)
endif()

foreach(dir assets components config modules services utils)
    install(DIRECTORY ${dir} DESTINATION "${INSTALL_QSCONFDIR}")
endforeach()
install(FILES shell.qml LICENSE DESTINATION "${INSTALL_QSCONFDIR}")
