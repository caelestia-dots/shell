// ===== wp_fade.frag =====
#version 450

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(binding = 1) uniform sampler2D source1;
layout(binding = 2) uniform sampler2D source2;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float progress;
    
    // Fill mode parameters
    float fillMode;      // 0=no(center), 1=crop(fill), 2=fit(contain), 3=stretch
    float imageWidth1;   // Width of source1 image
    float imageHeight1;  // Height of source1 image
    float imageWidth2;   // Width of source2 image
    float imageHeight2;  // Height of source2 image
    float screenWidth;   // Screen width
    float screenHeight;  // Screen height
    vec4 fillColor;      // Fill color for empty areas (default: black)
} ubuf;

// Calculate UV coordinates based on fill mode
vec2 calculateUV(vec2 uv, float imgWidth, float imgHeight) {
    float imageAspect = imgWidth / imgHeight;
    float screenAspect = ubuf.screenWidth / ubuf.screenHeight;
    vec2 transformedUV = uv;
    
    if (ubuf.fillMode < 0.5) {
        // Mode 0: no (center) - No resize, center image at original size
        // Convert UV to pixel coordinates, offset, then back to UV in image space
        vec2 screenPixel = uv * vec2(ubuf.screenWidth, ubuf.screenHeight);
        vec2 imageOffset = (vec2(ubuf.screenWidth, ubuf.screenHeight) - vec2(imgWidth, imgHeight)) * 0.5;
        vec2 imagePixel = screenPixel - imageOffset;
        transformedUV = imagePixel / vec2(imgWidth, imgHeight);
    } 
    else if (ubuf.fillMode < 1.5) {
        // Mode 1: crop (fill/cover) - Fill screen, crop excess (default)
        float scale = max(ubuf.screenWidth / imgWidth, ubuf.screenHeight / imgHeight);
        vec2 scaledImageSize = vec2(imgWidth, imgHeight) * scale;
        vec2 offset = (scaledImageSize - vec2(ubuf.screenWidth, ubuf.screenHeight)) / scaledImageSize;
        transformedUV = uv * (vec2(1.0) - offset) + offset * 0.5;
    }
    else if (ubuf.fillMode < 2.5) {
        // Mode 2: fit (contain) - Fit inside screen, maintain aspect ratio
        float scale = min(ubuf.screenWidth / imgWidth, ubuf.screenHeight / imgHeight);
        vec2 scaledImageSize = vec2(imgWidth, imgHeight) * scale;
        vec2 offset = (vec2(ubuf.screenWidth, ubuf.screenHeight) - scaledImageSize) * 0.5;
        
        // Convert screen UV to pixel coordinates
        vec2 screenPixel = uv * vec2(ubuf.screenWidth, ubuf.screenHeight);
        // Adjust for offset and scale
        vec2 imagePixel = (screenPixel - offset) / scale;
        // Convert back to UV coordinates in image space
        transformedUV = imagePixel / vec2(imgWidth, imgHeight);
    }
    // Mode 3: stretch - Use original UV (stretches to fit)
    // No transformation needed for stretch mode
    
    return transformedUV;
}

// Sample texture with fill mode and handle out-of-bounds
vec4 sampleWithFillMode(sampler2D tex, vec2 uv, float imgWidth, float imgHeight) {
    vec2 transformedUV = calculateUV(uv, imgWidth, imgHeight);
    
    // Check if UV is out of bounds
    if (transformedUV.x < 0.0 || transformedUV.x > 1.0 || 
        transformedUV.y < 0.0 || transformedUV.y > 1.0) {
        return ubuf.fillColor;
    }
    
    return texture(tex, transformedUV);
}

void main() {
    vec2 uv = qt_TexCoord0;
    
    // Sample textures with fill mode
    vec4 color1 = sampleWithFillMode(source1, uv, ubuf.imageWidth1, ubuf.imageHeight1);
    vec4 color2 = sampleWithFillMode(source2, uv, ubuf.imageWidth2, ubuf.imageHeight2);
    
    // Mix the two textures based on progress value
    fragColor = mix(color1, color2, ubuf.progress) * ubuf.qt_Opacity;
}