find_package(Qt6 REQUIRED COMPONENTS LinguistTools)

find_program(LRELEASE_PROGRAM lrelease6 lrelease
    PATHS /usr/lib/qt6/bin
)

if(NOT LRELEASE_PROGRAM)
    message(FATAL_ERROR "lrelease not found")
endif()

set(TS_FILE ${CMAKE_CURRENT_SOURCE_DIR}/caelestia-shell_zh_TW.ts)
set(QM_FILE ${CMAKE_CURRENT_BINARY_DIR}/caelestia-shell_zh_TW.qm)

add_custom_command(
    OUTPUT ${QM_FILE}
    DEPENDS ${TS_FILE}
    COMMAND ${LRELEASE_PROGRAM} ${TS_FILE} -qm ${QM_FILE}
    COMMENT "Compiling zh_TW translations..."
)

add_custom_target(caelestia-shell-translations ALL
    DEPENDS ${QM_FILE}
)

install(FILES ${QM_FILE}
    DESTINATION ${INSTALL_QSCONFDIR}/translations
)
