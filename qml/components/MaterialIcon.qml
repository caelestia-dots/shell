import QtQuick
import Caelestia.Config
import qs.services

StyledText {
    property real fill
    property int grade: Colours.light ? 0 : -25
    property font fontStyle: Tokens.font.icon.small

    font: Tokens.font.icon.size(fontStyle.pointSize).weight(fontStyle.weight).vaxes(fontStyle.variableAxes).fill(fill.toFixed(1)).grade(grade).build()
}
