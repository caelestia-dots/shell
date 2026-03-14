#version 440
layout(location = 0) in vec4 qt_Vertex;
layout(location = 1) in vec2 qt_MultiTexCoord0;

layout(location = 0) out vec2 vUv;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;

    vec2 sizePx;
    vec4 menuRectPx;
    vec4 subRectPx;
    float radiusPx;
    float smoothPxTop;
    float smoothPxBottom;

    vec4 fillColor;
    vec4 shadowColor;
    vec2 shadowOffsetPx;
    float shadowSoftPx;
} ubuf;

void main() {
    vUv = qt_MultiTexCoord0;
    gl_Position = ubuf.qt_Matrix * qt_Vertex;
}
