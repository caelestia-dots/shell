# Dashboard Animation Improvements - MVP

## Current Problem

The Quickshell dashboard animations are getting "cut off" or clipped instead of smoothly overlaying on top of other content. This creates a jarring experience where widgets appear to slide under the screen boundaries rather than expanding gracefully over the desktop.

## Root Cause Analysis

### Current Issues:
1. **Z-Index/Layer Problems** - Dashboard might be rendering below other layers
2. **Clipping Boundaries** - Parent containers are clipping child animations  
3. **Window Positioning** - Dashboard window constraints preventing proper overflow
4. **Animation Anchoring** - Widgets animating relative to wrong anchor points

### Key Files to Investigate:
```
modules/dashboard/
├── Wrapper.qml          # Main dashboard container and positioning
├── Content.qml          # Dashboard content with animation logic  
├── Dash.qml            # Grid layout we've been working on
└── Background.qml      # Background handling
```

## MVP Implementation Plan

### Phase 1: Understand Current Animation System

**1. Analyze Animation Flow:**
- Dashboard trigger → Wrapper visibility → Content loading → Animation start
- Current animation properties: `implicitHeight`, `implicitWidth` changes
- Parent-child clipping relationships

**2. Identify Clipping Sources:**
```qml
// Look for these properties in Wrapper.qml and Content.qml:
clip: true                    // Prevents overflow
anchors.fill: parent         // Constrains to parent bounds  
implicitWidth/Height         // May be limiting animation space
```

### Phase 2: Fix Layer and Positioning Issues

**1. Ensure Proper Z-Order:**
```qml
// In modules/dashboard/Wrapper.qml
Item {
    z: 999  // Ensure dashboard renders on top
    // Or use proper layer management
}
```

**2. Fix Window Layer Assignment:**
```qml
// Check in modules/drawers/Drawers.qml for:
WlrLayershell.layer: WlrLayer.Top     // Should be on top layer
WlrLayershell.exclusionMode: ExclusionMode.Ignore  // Don't push other windows
```

**3. Remove Clipping Constraints:**
```qml
// In Content.qml and Wrapper.qml:
clip: false  // Allow content to overflow smoothly
```

### Phase 3: Improve Animation Anchoring

**1. Center-Based Animations:**
Instead of expanding from edges, animate from center:
```qml
// Current (likely edge-anchored):
anchors.bottom: parent.bottom
anchors.horizontalCenter: parent.horizontalCenter

// Better (center-anchored):
anchors.centerIn: parent
transformOrigin: Item.Center
```

**2. Scale-Based Animations:**
Replace size-based animations with scale transforms:
```qml
// Instead of changing implicitWidth/Height:
transform: Scale {
    id: scaleTransform
    xScale: dashboardVisible ? 1.0 : 0.8
    yScale: dashboardVisible ? 1.0 : 0.8
    
    Behavior on xScale {
        NumberAnimation { 
            duration: 300
            easing.type: Easing.OutCubic 
        }
    }
}
```

### Phase 4: Implement Overlay Behavior

**1. Background Overlay:**
```qml
// Add semi-transparent overlay behind dashboard
Rectangle {
    anchors.fill: parent
    color: "#80000000"  // Semi-transparent black
    opacity: dashboardVisible ? 1.0 : 0.0
    
    Behavior on opacity {
        NumberAnimation { duration: 200 }
    }
    
    MouseArea {
        anchors.fill: parent
        onClicked: closeDashboard()  // Click outside to close
    }
}
```

**2. Smooth Slide Animation:**
```qml
// Dashboard content with proper slide-in
Item {
    id: dashboardContent
    
    y: dashboardVisible ? 0 : parent.height
    opacity: dashboardVisible ? 1.0 : 0.0
    
    Behavior on y {
        NumberAnimation {
            duration: 400
            easing.type: Easing.OutQuart
        }
    }
    
    Behavior on opacity {
        NumberAnimation { duration: 300 }
    }
}
```

## Implementation Steps

### Step 1: Backup and Analyze
```bash
# Backup current working config
cp -r ~/.config/quickshell/caelestia ~/.config/quickshell/caelestia-backup

# Test current animation behavior
# Note: Which direction dashboard slides, where it gets cut off
```

### Step 2: Modify Wrapper.qml
```qml
// Changes needed in modules/dashboard/Wrapper.qml:

Item {
    id: root
    
    // Remove clipping
    clip: false
    
    // Ensure proper layering
    z: 1000
    
    // Center the dashboard instead of bottom-anchoring
    anchors.centerIn: parent  // Instead of bottom anchoring
    
    // Use transform-based scaling
    transform: Scale {
        origin.x: width / 2
        origin.y: height / 2
        xScale: shouldBeVisible ? 1.0 : 0.9
        yScale: shouldBeVisible ? 1.0 : 0.9
    }
}
```

### Step 3: Improve Content.qml Animations
```qml
// In modules/dashboard/Content.qml:

Item {
    // Remove size-based animations, use transform instead
    transform: [
        Scale {
            xScale: isVisible ? 1.0 : 0.8
            yScale: isVisible ? 1.0 : 0.8
            origin.x: width / 2
            origin.y: height / 2
        },
        Translate {
            y: isVisible ? 0 : 50  // Slide up effect
        }
    ]
    
    opacity: isVisible ? 1.0 : 0.0
}
```

### Step 4: Fix Layer Configuration
```qml
// In modules/drawers/Drawers.qml, ensure:
StyledWindow {
    WlrLayershell.layer: WlrLayer.Overlay  // Top-most layer
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    
    // Remove any mask/clipping that might interfere
    mask: Region { /* simplified or removed */ }
}
```

## Testing and Refinement

### Test Cases:
1. **Dashboard Open/Close** - Should slide smoothly without clipping
2. **Multi-Monitor** - Should work correctly on ultrawide displays  
3. **Other Overlays** - Shouldn't conflict with notifications, popups
4. **Performance** - Smooth 60fps animations

### Common Fixes:
```qml
// If animations still clip:
parent.clip: false

// If dashboard appears behind other elements:
z: 9999

// If animations feel choppy:
layer.enabled: true  // Enable GPU acceleration

// If positioning is wrong on ultrawide:
anchors.horizontalCenter: parent.horizontalCenter
```

## Advanced Improvements (Future)

### 1. Physics-Based Animations
```qml
SpringAnimation {
    spring: 3.0
    damping: 0.4
    velocity: 0
}
```

### 2. Gesture Support
```qml
// Swipe up to open dashboard
PinchArea {
    // Handle swipe gestures
}
```

### 3. Multiple Animation States
```qml
states: [
    State { name: "hidden" },
    State { name: "peek" },      // Partially visible
    State { name: "expanded" }   // Fully visible
]
```

### 4. Blur Effects
```qml
// Background blur when dashboard is open
MultiEffect {
    blurEnabled: true
    blurMax: 32
}
```

## Success Criteria

✅ **Dashboard slides smoothly from bottom/center**  
✅ **No clipping at screen edges**  
✅ **Proper overlay behavior (appears on top)**  
✅ **Smooth 60fps animations**  
✅ **Works correctly on ultrawide monitors**  
✅ **Click outside to close functionality**  

## Files to Modify

**Primary:**
- `modules/dashboard/Wrapper.qml` - Main positioning and visibility
- `modules/dashboard/Content.qml` - Animation implementation
- `modules/drawers/Drawers.qml` - Layer configuration

**Secondary:**
- `modules/dashboard/Background.qml` - Overlay background
- `config/DashboardConfig.qml` - Animation settings

**Testing:**
- Use Super+D or hover trigger to test animations
- Test on multiple wallpapers to ensure consistent behavior
- Check interaction with other Quickshell elements