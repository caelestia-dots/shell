find_package(Qt6 REQUIRED COMPONENTS Test Core Qml Quick Network Sql Concurrent DBus)
find_package(PkgConfig REQUIRED)
pkg_check_modules(Pipewire IMPORTED_TARGET libpipewire-0.3 REQUIRED)

# Each test is one tst_<name>.cpp linked against the plugin libraries it exercises
function(caelestia_test name)
    cmake_parse_arguments(PARSE_ARGV 1 arg "" "" "LIBRARIES")

    add_executable(${name} ${name}.cpp)
    set_target_properties(${name} PROPERTIES AUTOMOC ON)
    target_include_directories(${name} PRIVATE "${CMAKE_SOURCE_DIR}/plugin/src/Caelestia")
    target_link_libraries(${name} PRIVATE Qt::Test ${arg_LIBRARIES})

    add_test(NAME ${name} COMMAND ${name})
    set_tests_properties(${name} PROPERTIES ENVIRONMENT
        "QT_QPA_PLATFORM=offscreen;TSAN_OPTIONS=suppressions=${CMAKE_CURRENT_SOURCE_DIR}/tsan.supp:halt_on_error=1:report_thread_leaks=0")
endfunction()

caelestia_test(tst_pluralrules LIBRARIES caelestia-i18n)
caelestia_test(tst_settingscodecs LIBRARIES caelestia-settings Qt::Qml)
caelestia_test(tst_audiocollector LIBRARIES caelestia-services caelestia-util caelestia-config PkgConfig::Pipewire Qt::Qml)
caelestia_test(tst_lyrics LIBRARIES caelestia-services caelestia-util caelestia-config Qt::Qml Qt::Network)
caelestia_test(tst_appdb LIBRARIES caelestia-models Qt::Qml Qt::Sql)
caelestia_test(tst_qalculator LIBRARIES caelestia-core Qt::Qml)
caelestia_test(tst_ddc LIBRARIES caelestia-services caelestia-config Qt::Qml Qt::Concurrent)
caelestia_test(tst_networkdbus LIBRARIES caelestia-services caelestia-config Qt::Qml Qt::DBus)
caelestia_test(tst_material LIBRARIES caelestia-material)
caelestia_test(tst_blobs LIBRARIES caelestia-blobs Qt::Quick)
caelestia_test(tst_cutils LIBRARIES caelestia-core Qt::Quick)
caelestia_test(tst_listnode LIBRARIES caelestia-settings Qt::Qml)
