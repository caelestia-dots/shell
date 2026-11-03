add_library(rgbcx STATIC rgbcx.cpp)
target_include_directories(rgbcx SYSTEM PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}")
target_compile_options(rgbcx PRIVATE -w)
set_target_properties(rgbcx PROPERTIES
    POSITION_INDEPENDENT_CODE ON
    EXPORT_COMPILE_COMMANDS OFF
)
