find_package(Qt6 REQUIRED COMPONENTS LinguistTools)

# --- lrelease: compile .ts -> .qm ---

find_program(LRELEASE_PROGRAM lrelease6 lrelease
    PATHS /usr/lib/qt6/bin
)

if(NOT LRELEASE_PROGRAM)
    message(FATAL_ERROR "lrelease not found")
endif()

file(GLOB TS_FILES "${CMAKE_CURRENT_SOURCE_DIR}/*.ts")

if(TS_FILES)
    foreach(ts_file ${TS_FILES})
        get_filename_component(basename ${ts_file} NAME_WE)
        set(qm_file "${CMAKE_CURRENT_BINARY_DIR}/${basename}.qm")

        add_custom_command(
            OUTPUT ${qm_file}
            DEPENDS ${ts_file}
            COMMAND ${LRELEASE_PROGRAM} ${ts_file} -qm ${qm_file}
            COMMENT "Compiling ${basename} translations..."
        )

        list(APPEND QM_FILES ${qm_file})
    endforeach()

    add_custom_target(caelestia-shell-translations ALL
        DEPENDS ${QM_FILES}
    )

    install(FILES ${QM_FILES}
        DESTINATION ${INSTALL_TRANSLATIONSDIR}
    )
else()
    message(WARNING "No translation files (*.ts) found; creating a template with lupdate")
endif()

# --- lupdate: extract translatable strings from source into .ts ---

find_program(LUPDATE_PROGRAM lupdate6 lupdate
    PATHS /usr/lib/qt6/bin
)

if(LUPDATE_PROGRAM)
    file(GLOB_RECURSE QML_SOURCES
        "${CMAKE_SOURCE_DIR}/*.qml"
    )

    file(GLOB_RECURSE CPP_SOURCES
        "${CMAKE_SOURCE_DIR}/plugin/src/*.cpp"
        "${CMAKE_SOURCE_DIR}/plugin/src/*.hpp"
    )

    set(SOURCES_FOR_LUPDATE ${QML_SOURCES} ${CPP_SOURCES})

    add_custom_target(update-translations
        COMMAND ${LUPDATE_PROGRAM}
            ${SOURCES_FOR_LUPDATE}
            -ts ${TS_FILES}
        COMMENT "Updating translation files from source..."
        WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
    )
endif()
