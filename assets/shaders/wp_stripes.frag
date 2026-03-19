// ===== wp_stripes.frag =====
#version 450

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(binding = 1) uniform sampler2D source1;  // Current wallpaper
layout(binding = 2) uniform sampler2D source2;  // Next wallpaper

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float progress;      // Transition progress (0.0 to 1.0)
    float stripeCount;   // Number of stripes (default 12.0)
    float angle;         // Angle of stripes in degrees (default 30.0)
    float smoothness;    // Edge smoothness (0.0 to 1.0, 0=sharp, 1=very smooth)
    float aspectRatio;   // Width / Height of the screen
    
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
    
    // Map smoothness from 0.0-1.0 to 0.001-0.3 range
    // Using a non-linear mapping for better control at low values
    float mappedSmoothness = mix(0.001, 0.3, ubuf.smoothness * ubuf.smoothness);
    
    // Use values directly without forcing defaults
    float stripes = (ubuf.stripeCount > 0.0) ? ubuf.stripeCount : 12.0;
    float angleRad = radians(ubuf.angle);
    float edgeSmooth = mappedSmoothness;
    
    // Create a coordinate system for stripes based on angle
    // At 0°: vertical stripes (divide by x)
    // At 45°: diagonal stripes
    // At 90°: horizontal stripes (divide by y)
    
    // Transform coordinates based on angle
    float cosA = cos(angleRad);
    float sinA = sin(angleRad);
    
    // Project the UV position onto the stripe direction
    // This gives us the position along the stripe direction
    float stripeCoord = uv.x * cosA + uv.y * sinA;
    
    // Perpendicular coordinate (for edge movement)
    float perpCoord = -uv.x * sinA + uv.y * cosA;
    
    // Calculate the range of perpCoord based on angle
    // This determines how far edges need to travel to fully cover the screen
    float minPerp = min(min(0.0 * -sinA + 0.0 * cosA, 1.0 * -sinA + 0.0 * cosA),
                       min(0.0 * -sinA + 1.0 * cosA, 1.0 * -sinA + 1.0 * cosA));
    float maxPerp = max(max(0.0 * -sinA + 0.0 * cosA, 1.0 * -sinA + 0.0 * cosA),
                       max(0.0 * -sinA + 1.0 * cosA, 1.0 * -sinA + 1.0 * cosA));
    
    // Determine which stripe we're in
    float stripePos = stripeCoord * stripes;
    int stripeIndex = int(floor(stripePos));
    
    // Determine if this is an odd or even stripe
    bool isOddStripe = mod(float(stripeIndex), 2.0) != 0.0;
    
    // Calculate the progress for this specific stripe with wave delay
    // Use absolute stripe position for consistent delay across all stripes
    float normalizedStripePos = clamp(stripePos / stripes, 0.0, 1.0);
    
    // Increased delay and better distribution
    float maxDelay = 0.1;
    float stripeDelay = normalizedStripePos * maxDelay;
    
    // Better progress mapping that uses the full 0.0-1.0 range
    // Map progress so that:
    // - First stripe starts at progress = 0.0
    // - Last stripe finishes at progress = 1.0
    float stripeProgress;
    if (ubuf.progress <= stripeDelay) {
        stripeProgress = 0.0;
    } else if (ubuf.progress >= (stripeDelay + (1.0 - maxDelay))) {
        stripeProgress = 1.0;
    } else {
        // Scale the progress within the active window for this stripe
        float activeStart = stripeDelay;
        float activeEnd = stripeDelay + (1.0 - maxDelay);
        stripeProgress = (ubuf.progress - activeStart) / (activeEnd - activeStart);
    }
    
    // Use gentler easing curve
    stripeProgress = stripeProgress * stripeProgress * (3.0 - 2.0 * stripeProgress);  // Smootherstep instead of smoothstep
    
    // Use the perpendicular coordinate for edge comparison
    float yPos = perpCoord;
    
    // Calculate edge position for this stripe
    // Use the actual perpendicular coordinate range for this angle
    float perpRange = maxPerp - minPerp;
    float margin = edgeSmooth * 2.0;  // Simplified margin calculation
    float edgePosition;
    if (isOddStripe) {
        // Odd stripes: edge moves from max to min
        edgePosition = maxPerp + margin - stripeProgress * (perpRange + margin * 2.0);
    } else {
        // Even stripes: edge moves from min to max
        edgePosition = minPerp - margin + stripeProgress * (perpRange + margin * 2.0);
    }
    
    // Determine which wallpaper to show based on rotated position
    float mask;
    if (isOddStripe) {
        // Odd stripes reveal new wallpaper from bottom
        mask = smoothstep(edgePosition - edgeSmooth, edgePosition + edgeSmooth, yPos);
    } else {
        // Even stripes reveal new wallpaper from top
        mask = 1.0 - smoothstep(edgePosition - edgeSmooth, edgePosition + edgeSmooth, yPos);
    }
    
    // Mix the wallpapers
    fragColor = mix(color1, color2, mask);
    
    // Force exact values at start and end to prevent any bleed-through
    if (ubuf.progress <= 0.0) {
        fragColor = color1;  // Only show old wallpaper at start
    } else if (ubuf.progress >= 1.0) {
        fragColor = color2;  // Only show new wallpaper at end
    } else {
        // Add manga-style edge shadow only during transition
        float edgeDist = abs(yPos - edgePosition);
        float shadowStrength = 1.0 - smoothstep(0.0, edgeSmooth * 2.5, edgeDist);
        shadowStrength *= 0.2 * (1.0 - abs(stripeProgress - 0.5) * 2.0);
        fragColor.rgb *= (1.0 - shadowStrength);
        
        // Add slight vignette during transition for dramatic effect  
        float vignette = 1.0 - ubuf.progress * 0.1 * (1.0 - abs(stripeProgress - 0.5) * 2.0);
        fragColor.rgb *= vignette;
    }
    
    fragColor *= ubuf.qt_Opacity;
}