import QtQuick
import Caelestia.Config

AnchorAnimation {
    enum Type {
        StandardSmall = 0,
        Standard,
        StandardLarge,
        StandardExtraLarge,
        EmphasizedSmall,
        Emphasized,
        EmphasizedLarge,
        EmphasizedExtraLarge,
        FastSpatial,
        DefaultSpatial,
        SlowSpatial
    }

    property int type: AnchorAnim.DefaultSpatial

    duration: {
        if (type < AnchorAnim.StandardSmall || type > AnchorAnim.SlowSpatial)
            return Tokens.anim.durations.expressiveDefaultSpatial;

        if (type == AnchorAnim.FastSpatial)
            return Tokens.anim.durations.expressiveFastSpatial;
        if (type == AnchorAnim.DefaultSpatial)
            return Tokens.anim.durations.expressiveDefaultSpatial;
        if (type == AnchorAnim.SlowSpatial)
            return Tokens.anim.durations.expressiveSlowSpatial;

        const types = ["small", "normal", "large", "extraLarge"];
        const idx = type % 4; // 0-7 are the 4 standard types
        return Tokens.anim.durations[types[idx]];
    }
    easing: {
        if (type == AnchorAnim.FastSpatial)
            return Tokens.anim.expressiveFastSpatial;
        if (type == AnchorAnim.DefaultSpatial)
            return Tokens.anim.expressiveDefaultSpatial;
        if (type == AnchorAnim.SlowSpatial)
            return Tokens.anim.expressiveSlowSpatial;

        if (type >= AnchorAnim.StandardSmall && type <= AnchorAnim.StandardExtraLarge)
            return Tokens.anim.standard;
        if (type >= AnchorAnim.EmphasizedSmall && type <= AnchorAnim.EmphasizedExtraLarge)
            return Tokens.anim.emphasized;

        return Tokens.anim.expressiveDefaultSpatial;
    }
}
