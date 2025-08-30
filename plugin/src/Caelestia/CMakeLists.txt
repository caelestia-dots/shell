qt_add_qml_module(caelestia
    URI Caelestia
    VERSION 0.1
    SOURCES
        cutils.hpp cutils.cpp
        cachingimagemanager.hpp cachingimagemanager.cpp
)

qt_query_qml_module(caelestia
    URI module_uri
    VERSION module_version
    PLUGIN_TARGET module_plugin_target
    TARGET_PATH module_target_path
    QMLDIR module_qmldir
    TYPEINFO module_typeinfo
    QML_FILES module_qml_files
    RESOURCES module_resources
)

set(module_dir "${INSTALL_QMLDIR}/${module_target_path}")
install(TARGETS caelestia LIBRARY DESTINATION "${module_dir}" RUNTIME DESTINATION "${module_dir}")
install(TARGETS "${module_plugin_target}" LIBRARY DESTINATION "${module_dir}" RUNTIME DESTINATION "${module_dir}")
install(FILES "${module_qmldir}" DESTINATION "${module_dir}")
install(FILES "${module_typeinfo}" DESTINATION "${module_dir}")

target_link_libraries(caelestia PRIVATE Qt::Core Qt::Qml Qt::Gui)
