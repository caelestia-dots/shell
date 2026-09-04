set(po_files
    # All .po files should go here
)

if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    list(APPEND po_files trs/test.po)
endif()

find_program(MSGFMT_EXECUTABLE msgfmt REQUIRED)

# Compile .po -> .mo and alias each one to <lang>.mo in the module's resources
set(mo_files)
file(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/trs")
foreach(po IN LISTS po_files)
    cmake_path(GET po STEM lang)
    set(mo "${CMAKE_CURRENT_BINARY_DIR}/trs/${lang}.mo")

    add_custom_command(
        OUTPUT "${mo}"
        COMMAND "${MSGFMT_EXECUTABLE}" --check-format -o "${mo}" "${CMAKE_CURRENT_SOURCE_DIR}/${po}"
        DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/${po}"
        COMMENT "Compiling translations for ${lang}"
        VERBATIM
    )

    set_source_files_properties("${mo}" PROPERTIES QT_RESOURCE_ALIAS "${lang}.mo")
    list(APPEND mo_files "${mo}")
endforeach()

qml_module(caelestia-translations
    URI Caelestia.Translations
    INCLUDE_PREFIX translations
    SOURCES
        translator.cpp
    QML_SINGLETONS
        Tr.qml
    RESOURCES
        ${mo_files}
)
