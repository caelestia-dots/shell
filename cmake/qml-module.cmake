function(qml_module arg_TARGET)
    cmake_parse_arguments(PARSE_ARGV 1 arg "" "URI" "SOURCES;QML_FILES;QML_SINGLETONS;DEPENDENCIES;IMPORTS;OPTIONAL_IMPORTS;DEFAULT_IMPORTS;LIBRARIES")

    set_source_files_properties(${arg_QML_SINGLETONS} PROPERTIES QT_QML_SINGLETON_TYPE TRUE)

    qt_add_qml_module(${arg_TARGET}
        URI ${arg_URI}
        SOURCES ${arg_SOURCES}
        QML_FILES ${arg_QML_FILES} ${arg_QML_SINGLETONS}
        DEPENDENCIES ${arg_DEPENDENCIES}
        IMPORTS ${arg_IMPORTS}
        OPTIONAL_IMPORTS ${arg_OPTIONAL_IMPORTS}
        DEFAULT_IMPORTS ${arg_DEFAULT_IMPORTS}
    )

    qt_query_qml_module(${arg_TARGET}
        URI module_uri
        PLUGIN_TARGET module_plugin_target
        TARGET_PATH module_target_path
        QMLDIR module_qmldir
        TYPEINFO module_typeinfo
    )

    message(STATUS "Created QML module: ${module_uri}")

    set(module_dir "${INSTALL_QMLDIR}/${module_target_path}")
    install(TARGETS ${arg_TARGET} LIBRARY DESTINATION "${module_dir}" RUNTIME DESTINATION "${module_dir}")
    install(TARGETS "${module_plugin_target}" LIBRARY DESTINATION "${module_dir}" RUNTIME DESTINATION "${module_dir}")
    install(FILES "${module_qmldir}" DESTINATION "${module_dir}")
    install(FILES "${module_typeinfo}" DESTINATION "${module_dir}")

    target_link_libraries(${arg_TARGET} PRIVATE Qt::Core Qt::Qml ${arg_LIBRARIES})
endfunction()
