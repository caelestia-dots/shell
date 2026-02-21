#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float fadeMargin;
};

layout(binding = 1) uniform sampler2D source;

void main() {
    vec4 tex = texture(source, qt_TexCoord0);
    float factor = 1.0;
    float margin = 0.1;

    if (qt_TexCoord0.y < margin) {
        factor = qt_TexCoord0.y / margin;
    } else if (qt_TexCoord0.y > (1.0 - margin)) {
        factor = (1.0 - qt_TexCoord0.y) / margin;
    }

    fragColor = tex * factor * qt_Opacity;
}
