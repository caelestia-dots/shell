find_package(Qt6 REQUIRED COMPONENTS Qml QuickTest Test)

add_executable(test-lock-config
    test_lockconfig.cpp
)

target_include_directories(test-lock-config PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/..")
target_link_libraries(test-lock-config PRIVATE caelestia-config Qt::Qml Qt::Test)
# Shields only upstream Settings header MOC diagnostics; test source warnings remain enabled.
target_compile_options(test-lock-config PRIVATE
    "SHELL:-Xclang -plugin-arg-clazy -Xclang no-fully-qualified-moc-types"
)

add_test(NAME caelestia-lock-config COMMAND test-lock-config)

add_executable(test-lock-lifecycle-qml
    test_locklifecycleqml.cpp
)

target_compile_definitions(test-lock-lifecycle-qml PRIVATE
    QUICK_TEST_SOURCE_DIR="${CMAKE_CURRENT_SOURCE_DIR}/qml"
)
target_link_libraries(test-lock-lifecycle-qml PRIVATE Qt::QuickTest Qt::Qml)

add_test(NAME caelestia-lock-lifecycle-qml COMMAND test-lock-lifecycle-qml)
get_filename_component(qt_qml_prefix "${Qt6Qml_DIR}/../../.." ABSOLUTE)
set(qt_qml_import_path "${qt_qml_prefix}/${QT6_INSTALL_QML}")
set_tests_properties(caelestia-lock-lifecycle-qml PROPERTIES
    ENVIRONMENT "QT_QPA_PLATFORM=offscreen;QML2_IMPORT_PATH=${qt_qml_import_path}:$ENV{QML2_IMPORT_PATH}"
)
