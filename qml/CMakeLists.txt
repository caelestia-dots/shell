add_subdirectory(components)
add_subdirectory(services)
add_subdirectory(config)
add_subdirectory(utils)
add_subdirectory(modules)

configure_file(shell.qml "${CMAKE_BINARY_DIR}/Shell.qml" COPYONLY)
_fix_imports("${CMAKE_BINARY_DIR}/Shell.qml")
set_source_files_properties("${CMAKE_BINARY_DIR}/Shell.qml" PROPERTIES QT_RESOURCE_ALIAS "Shell.qml")
qml_module(caelestia-qml
    URI Caelestia.Qml
    QML_FILES
        "${CMAKE_BINARY_DIR}/Shell.qml"
    DEPENDENCIES
        Quickshell
)

file(STRINGS shell.qml shell_qml)
set(pragmas "")
foreach(line IN LISTS shell_qml)
    if("${line}" MATCHES "^//@")
        list(APPEND pragmas "${line}")
    else()
        break()
    endif()
endforeach()

list(JOIN pragmas "\n" pragmas)
file(WRITE "${CMAKE_BINARY_DIR}/shell.qml"
    "${pragmas}\n"
    "import Caelestia.Qml\n"
    "Shell { settings.watchFiles: false }\n"
)
install(FILES "${CMAKE_BINARY_DIR}/shell.qml" DESTINATION "${INSTALL_QSCONFDIR}")
