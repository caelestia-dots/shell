if(NOT COMMAND qml_module)
    message(FATAL_ERROR "CAELESTIA_AOT_QML requires the plugin module to be enabled")
endif()

find_package(Qt6 REQUIRED COMPONENTS Qml Quick ShaderTools)
qt_standard_project_setup(REQUIRES 6.9)
set(QT_QML_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/qml" CACHE STRING "QML output directory" FORCE)

find_package(Python3 REQUIRED COMPONENTS Interpreter)

set(AOT_QML_DIR "${CMAKE_BINARY_DIR}/aot-qml")
set(AOT_QML_MODULES "${AOT_QML_DIR}/modules.cmake")

execute_process(
    COMMAND "${Python3_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/prepare.py" "${CMAKE_SOURCE_DIR}" "${AOT_QML_DIR}"
    RESULT_VARIABLE AOT_PREPARE_RESULT
    OUTPUT_VARIABLE AOT_PREPARE_OUTPUT
    ERROR_VARIABLE AOT_PREPARE_ERROR
)

if(NOT AOT_PREPARE_RESULT EQUAL 0)
    message(FATAL_ERROR "Failed to prepare AOT QML tree:\n${AOT_PREPARE_OUTPUT}\n${AOT_PREPARE_ERROR}")
endif()

list(APPEND QML_IMPORT_PATH "${CMAKE_BINARY_DIR}/qml")
set(QML_IMPORT_PATH "${QML_IMPORT_PATH}" CACHE STRING "QML import path" FORCE)

include("${AOT_QML_MODULES}")
