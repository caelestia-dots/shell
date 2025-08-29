cmake_minimum_required(VERSION 3.19)
find_package(Qt6 REQUIRED COMPONENTS Core Qml)

if(QT_KNOWN_POLICY_QTP0001)
    qt_policy(SET QTP0001 NEW)
endif()

set(QT_QML_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/qml")
qt_standard_project_setup()
add_subdirectory(src/Caelestia)
