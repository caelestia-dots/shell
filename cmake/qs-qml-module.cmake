function(_fix_imports FILE)
    execute_process(
        COMMAND perl -pi -e "s/import qs\\.([\\w.]+)/'import Caelestia.Qml.' . join('.', map {ucfirst} split(\\/\\.\\/,  $1))/ge" ${FILE}
    )
endfunction()

function(qs_qml_module arg_TARGET)
    cmake_parse_arguments(PARSE_ARGV 1 arg "" "URI" "SOURCES;QML_FILES;QML_SINGLETONS;DEPENDENCIES;IMPORTS;OPTIONAL_IMPORTS;DEFAULT_IMPORTS;LIBRARIES")

    set(proc_qml_files "")
    set(proc_qml_singletons "")
    file(RELATIVE_PATH proc_dir "${CMAKE_SOURCE_DIR}/qml" "${CMAKE_CURRENT_SOURCE_DIR}")
    set(proc_dir "${CMAKE_BINARY_DIR}/proc_qml/${proc_dir}")

    foreach(file IN LISTS arg_QML_FILES)
        set(bin_file "${proc_dir}/${file}")
        list(APPEND proc_qml_files "${bin_file}")

        configure_file("${file}" "${bin_file}" COPYONLY)
        set_source_files_properties("${bin_file}" PROPERTIES QT_RESOURCE_ALIAS "${file}")
        _fix_imports("${bin_file}")
    endforeach()

    foreach(file IN LISTS arg_QML_SINGLETONS)
        set(bin_file "${proc_dir}/${file}")
        list(APPEND proc_qml_singletons "${bin_file}")

        configure_file("${file}" "${bin_file}" COPYONLY)
        set_source_files_properties("${bin_file}" PROPERTIES QT_RESOURCE_ALIAS "${file}")
        _fix_imports("${bin_file}")
    endforeach()

    qml_module(${arg_TARGET}
        URI ${arg_URI}
        SOURCES ${arg_SOURCES}
        QML_FILES ${proc_qml_files}
        QML_SINGLETONS ${proc_qml_singletons}
        DEPENDENCIES ${arg_DEPENDENCIES}
        IMPORTS ${arg_IMPORTS}
        OPTIONAL_IMPORTS ${arg_OPTIONAL_IMPORTS}
        DEFAULT_IMPORTS ${arg_DEFAULT_IMPORTS}
        LIBRARIES ${arg_LIBRARIES}
    )

    target_compile_options(${arg_TARGET} PRIVATE -Wno-implicit-int-float-conversion -Wno-float-conversion -Wno-shorten-64-to-32)

    # Mostly disable clazy warnings (we can't completely disable it, so we just set it to qenums which isn't likely to trigger)
    if(CMAKE_CXX_COMPILER MATCHES ".*clazy")
        set_target_properties(${arg_TARGET} PROPERTIES
            COMPILE_FLAGS "-Xclang -plugin-arg-clazy -Xclang qenums"
        )
    endif()
endfunction()
