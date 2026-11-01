# Material You colours, as the caelestia CLI makes them (materialyoucolor 3.0.2 ported to C++).
# material-color-utilities supplies HCT, CAM16 and the quantizer; the palettes, colour roles and
# schemes are ported here so they match the Python library to the last bit.

set(MCU_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../../../../third_party/material-color-utilities")
set(STB_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../../../../third_party/stb")

# The parts of material-color-utilities the port uses (the scheme and dynamic colour code is ported
# here instead, as materialyoucolor's version of it differs from the upstream C++ one)
add_library(caelestia-mcu STATIC
    ${MCU_DIR}/cpp/cam/cam.cc
    ${MCU_DIR}/cpp/cam/hct.cc
    ${MCU_DIR}/cpp/cam/hct_solver.cc
    ${MCU_DIR}/cpp/cam/viewing_conditions.cc
    ${MCU_DIR}/cpp/quantize/celebi.cc
    ${MCU_DIR}/cpp/quantize/lab.cc
    ${MCU_DIR}/cpp/quantize/wsmeans.cc
    ${MCU_DIR}/cpp/quantize/wu.cc
    ${MCU_DIR}/cpp/utils/utils.cc
)
target_include_directories(caelestia-mcu SYSTEM PUBLIC "${MCU_DIR}")
target_compile_options(caelestia-mcu PRIVATE -w)
set_target_properties(caelestia-mcu PROPERTIES POSITION_INDEPENDENT_CODE ON)

add_library(caelestia-material STATIC
    color_utils.cpp
    dynamic.cpp
    generator.cpp
    preview.cpp
    roles.cpp
    stb_decode.cc
    temperature.cpp
    thumbnail.cpp
)
target_include_directories(caelestia-material PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}")
target_include_directories(caelestia-material SYSTEM PRIVATE "${STB_DIR}")
target_link_libraries(caelestia-material PUBLIC caelestia-mcu Qt::Core Qt::Gui)
set_target_properties(caelestia-material PROPERTIES POSITION_INDEPENDENT_CODE ON)
