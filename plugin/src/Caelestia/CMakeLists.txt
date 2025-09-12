find_package(Qt6 REQUIRED COMPONENTS Core Qml Gui Concurrent Sql Quick)
find_package(PkgConfig REQUIRED)
pkg_check_modules(Qalculate IMPORTED_TARGET libqalculate REQUIRED)
pkg_check_modules(Pipewire IMPORTED_TARGET libpipewire-0.3 REQUIRED)
pkg_check_modules(Aubio IMPORTED_TARGET aubio REQUIRED)
pkg_check_modules(Cava IMPORTED_TARGET cava REQUIRED)

set(QT_QML_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/qml")
qt_standard_project_setup(REQUIRES 6.9)

qt_add_qml_module(caelestia
    URI Caelestia
    VERSION ${VERSION}
    SOURCES
        cutils.hpp cutils.cpp
        cachingimagemanager.hpp cachingimagemanager.cpp
        filesystemmodel.hpp filesystemmodel.cpp
        qalculator.hpp qalculator.cpp
        beattracker.hpp beattracker.cpp
        service.hpp service.cpp
        serviceref.hpp serviceref.cpp
        audiocollector.hpp audiocollector.cpp
        audioprovider.hpp audioprovider.cpp
        cavaprovider.hpp cavaprovider.cpp
        appdb.hpp appdb.cpp
        requests.hpp requests.cpp
)

qt_query_qml_module(caelestia
    URI module_uri
    VERSION module_version
    PLUGIN_TARGET module_plugin_target
    TARGET_PATH module_target_path
    QMLDIR module_qmldir
    TYPEINFO module_typeinfo
)

message(STATUS "Created QML module ${module_uri}, version ${module_version}")

set(module_dir "${INSTALL_QMLDIR}/${module_target_path}")
install(TARGETS caelestia LIBRARY DESTINATION "${module_dir}" RUNTIME DESTINATION "${module_dir}")
install(TARGETS "${module_plugin_target}" LIBRARY DESTINATION "${module_dir}" RUNTIME DESTINATION "${module_dir}")
install(FILES "${module_qmldir}" DESTINATION "${module_dir}")
install(FILES "${module_typeinfo}" DESTINATION "${module_dir}")

target_link_libraries(caelestia PRIVATE
    Qt::Core
    Qt::Qml
    Qt::Gui
    Qt::Concurrent
    Qt::Sql
    PkgConfig::Qalculate
    PkgConfig::Pipewire
    PkgConfig::Aubio
    PkgConfig::Cava
    Qt::Quick
)
