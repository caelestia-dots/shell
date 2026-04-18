import Caelestia.Config
import qs.services

StyledText {
    property real fill
    property int grade: Colours.light ? 0 : -25

    font.family: Tokens.font.family.material
    font.pointSize: Tokens.font.size.larger
    font.variableAxes: ({
            FILL: fill.toFixed(1),
            GRAD: grade,
            opsz: fontInfo.pixelSize,
            wght: fontInfo.weight
        })
}
