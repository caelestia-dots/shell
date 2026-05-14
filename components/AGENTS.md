# Components — Agent Guide

Reusable UI primitives shared across all modules. These are the building blocks — modules compose them, never duplicate them.

## Directory structure

| Directory | Purpose |
|-----------|---------|
| `components/` (root) | Core styled wrappers, animation types, layout helpers |
| `controls/` | Interactive widgets (buttons, sliders, switches, menus, text fields) |
| `containers/` | Scrollable/windowed containers (StyledFlickable, StyledListView, StyledWindow) |
| `effects/` | Visual effects (ColouredIcon, Colouriser, Elevation, InnerBorder, OpacityMask) |
| `filedialog/` | File picker components |
| `images/` | Cached image loading (CachingImage, CachingIconImage) |
| `misc/` | Utilities (CustomShortcut, Ref) |
| `widgets/` | Composite widgets (ExtraIndicator) |

## Styled wrappers

All visual elements should use styled wrappers instead of raw Qt types:

| Use this | Instead of | What it adds |
|----------|-----------|--------------|
| `StyledRect` | `Rectangle` | Animated `color` transitions via `CAnim` |
| `StyledText` | `Text` | Theme font family/size from `Tokens`, color from `Colours` |
| `StyledClippingRect` | `ClippingRectangle` | Animated color with clipping support |

## Animation system

Three animation types, all reading durations and easing curves from `Tokens.anim`:

| Type | Base | Use for |
|------|------|---------|
| `Anim` | `NumberAnimation` | Sizes, positions, opacity, scale |
| `CAnim` | `ColorAnimation` | Color transitions |
| `AnchorAnim` | `AnchorAnimation` | Anchor changes |

Each has an `Anim.Type` enum controlling duration/easing:

```
StandardSmall, Standard, StandardLarge, StandardExtraLarge
EmphasizedSmall, Emphasized, EmphasizedLarge, EmphasizedExtraLarge
FastSpatial, DefaultSpatial, SlowSpatial
```

Usage:
```qml
Behavior on width {
    Anim { type: Anim.DefaultSpatial }
}
```

## StateLayer

Provides hover/press/focus visual feedback on interactive elements. Attach to any clickable component:

```qml
StyledRect {
    StateLayer {
        // Automatically handles hover/press states
    }
}
```

## Controls conventions

- All controls read colors from `Colours.palette.*`
- All sizing from `Tokens.padding.*`, `Tokens.spacing.*`, `Tokens.rounding.*`
- Interactive controls expose `onClicked`, `onMoved`, `onToggled` signals as appropriate
- Use `CustomMouseArea` for scroll/wheel handling with `onWheel` signal

## Adding a new component

1. Create a PascalCase `.qml` file in the appropriate subdirectory
2. Use `StyledRect`/`StyledText` as base types where possible
3. Read all visual constants from `Tokens` and `Colours` — never hardcode
4. Use `Anim` types for transitions — never hardcode durations
5. The component is auto-discovered via Quickshell's implicit import system
