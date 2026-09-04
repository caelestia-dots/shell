set(po_files
    # All .po files should go here
)

find_program(MSGFMT_EXECUTABLE msgfmt REQUIRED)

# Compile .po -> .mo and alias each one to <lang>.mo in the module's resources
set(mo_files)
file(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/trs")

function(compile_po po)
    cmake_path(GET po STEM lang)
    set(mo "${CMAKE_CURRENT_BINARY_DIR}/trs/${lang}.mo")

    add_custom_command(
        OUTPUT "${mo}"
        COMMAND "${MSGFMT_EXECUTABLE}" --check-format -o "${mo}" "${po}"
        DEPENDS "${po}"
        COMMENT "Compiling translations for ${lang}"
        VERBATIM
    )

    set_source_files_properties("${mo}" PROPERTIES QT_RESOURCE_ALIAS "${lang}.mo")
    set(mo_files "${mo_files};${mo}" PARENT_SCOPE)
endfunction()

foreach(po IN LISTS po_files)
    compile_po("${CMAKE_CURRENT_SOURCE_DIR}/${po}")
endforeach()

if(CAELESTIA_TEST_TRS)
    add_custom_command(
        OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/trs/test.po"
        COMMAND "${CMAKE_SOURCE_DIR}/scripts/trs.fish" test "${CMAKE_CURRENT_BINARY_DIR}/trs/test.po"
        COMMENT "Generating test translations"
        VERBATIM
    )
    compile_po("${CMAKE_CURRENT_BINARY_DIR}/trs/test.po")
endif()

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
