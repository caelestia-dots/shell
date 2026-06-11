pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import M3Shapes
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.effects
import qs.services

CustomMouseArea {
    id: root

    required property DashboardState dashState

    readonly property int realCurrMonth: dashState.currentDate.getMonth()
    readonly property int realCurrYear: dashState.currentDate.getFullYear()

    property int activeGrid: 1
    property int month1
    property int year1
    property int month2
    property int year2

    function handleDateChange() {
        const currM = activeGrid === 1 ? month1 : month2;
        const currY = activeGrid === 1 ? year1 : year2;
        if (realCurrMonth !== currM || realCurrYear !== currY) {
            monthChangeAnim.direction = (realCurrYear > currY || (realCurrYear === currY && realCurrMonth > currM)) ? -1 : 1;

            if (activeGrid === 1) {
                month2 = realCurrMonth;
                year2 = realCurrYear;
                activeGrid = 2;
            } else {
                month1 = realCurrMonth;
                year1 = realCurrYear;
                activeGrid = 1;
            }
            monthChangeAnim.restart();
        }
    }

    function onWheel(event: WheelEvent): void {
        if (event.angleDelta.y > 0)
            root.dashState.currentDate = new Date(root.realCurrYear, root.realCurrMonth - 1, 1);
        else if (event.angleDelta.y < 0)
            root.dashState.currentDate = new Date(root.realCurrYear, root.realCurrMonth + 1, 1);
    }

    anchors.left: parent.left
    anchors.right: parent.right
    implicitHeight: inner.implicitHeight + inner.anchors.margins * 2

    acceptedButtons: Qt.MiddleButton

    Component.onCompleted: {
        month1 = realCurrMonth;
        year1 = realCurrYear;
        month2 = realCurrMonth;
        year2 = realCurrYear;
    }

    onRealCurrMonthChanged: handleDateChange()
    onRealCurrYearChanged: handleDateChange()

    onClicked: root.dashState.currentDate = new Date()

    SequentialAnimation {
        id: monthChangeAnim

        property int direction: 0

        ScriptAction {
            script: {
                if (activeGrid === 1) {
                    titleTranslate1.x = -monthChangeAnim.direction * titleClip.width;
                    grid1Translate.x = -monthChangeAnim.direction * gridClip.width;
                    titleTranslate2.x = 0;
                    grid2Translate.x = 0;
                } else {
                    titleTranslate2.x = -monthChangeAnim.direction * titleClip.width;
                    grid2Translate.x = -monthChangeAnim.direction * gridClip.width;
                    titleTranslate1.x = 0;
                    grid1Translate.x = 0;
                }
            }
        }
        ParallelAnimation {
            Anim {
                target: titleTranslate1
                property: "x"
                to: root.activeGrid === 1 ? 0 : monthChangeAnim.direction * titleClip.width
                type: Anim.DefaultSpatial
            }
            Anim {
                target: grid1Translate
                property: "x"
                to: root.activeGrid === 1 ? 0 : monthChangeAnim.direction * gridClip.width
                type: Anim.DefaultSpatial
            }
            Anim {
                target: titleTranslate2
                property: "x"
                to: root.activeGrid === 2 ? 0 : monthChangeAnim.direction * titleClip.width
                type: Anim.DefaultSpatial
            }
            Anim {
                target: grid2Translate
                property: "x"
                to: root.activeGrid === 2 ? 0 : monthChangeAnim.direction * gridClip.width
                type: Anim.DefaultSpatial
            }
        }
    }

    ColumnLayout {
        id: inner

        anchors.fill: parent
        anchors.margins: Tokens.padding.large

        spacing: Tokens.spacing.extraSmall

        RowLayout {
            id: monthNavigationRow

            Layout.fillWidth: true

            spacing: Tokens.spacing.extraSmall

            IconButton {
                icon: "chevron_left"
                type: IconButton.Text
                font: Tokens.font.icon.builders.small.weight(Font.Bold).build()
                padding: Tokens.padding.small

                onClicked: root.dashState.currentDate = new Date(root.realCurrYear, root.realCurrMonth - 1, 1)
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                implicitWidth: monthYearDisplay1.implicitWidth + Tokens.padding.large * 2
                implicitHeight: monthYearDisplay1.implicitHeight + Tokens.padding.extraSmall * 2

                StateLayer {
                    color: Colours.palette.m3primary
                    radius: pressed ? Tokens.rounding.small : Tokens.rounding.large
                    disabled: {
                        const now = new Date();
                        return root.realCurrMonth === now.getMonth() && root.realCurrYear === now.getFullYear();
                    }

                    onClicked: root.dashState.currentDate = new Date()

                    Behavior on radius {
                        Anim {
                            type: Anim.DefaultEffects
                        }
                    }
                }

                Item {
                    id: titleClip

                    anchors.fill: parent

                    clip: true

                    StyledText {
                        id: monthYearDisplay1

                        anchors.centerIn: parent

                        // qmllint disable missing-property
                        text: grid1.item ? grid1.item.title : ""
                        // qmllint enable missing-property
                        color: Colours.palette.m3primary
                        font: Tokens.font.title.builders.small.capitalisation(Font.Capitalize).build()
                        visible: root.activeGrid === 1 || monthChangeAnim.running

                        transform: Translate {
                            id: titleTranslate1
                        }
                    }

                    StyledText {
                        id: monthYearDisplay2

                        anchors.centerIn: parent

                        // qmllint disable missing-property
                        text: grid2.item ? grid2.item.title : ""
                        // qmllint enable missing-property
                        color: Colours.palette.m3primary
                        font: Tokens.font.title.builders.small.capitalisation(Font.Capitalize).build()
                        visible: root.activeGrid === 2 || monthChangeAnim.running

                        transform: Translate {
                            id: titleTranslate2
                        }
                    }
                }
            }

            IconButton {
                icon: "chevron_right"
                type: IconButton.Text
                font: Tokens.font.icon.builders.small.weight(Font.Bold).build()
                padding: Tokens.padding.small

                onClicked: root.dashState.currentDate = new Date(root.realCurrYear, root.realCurrMonth + 1, 1)
            }
        }

        DayOfWeekRow {
            id: daysRow

            Layout.fillWidth: true

            locale: Qt.locale()

            delegate: StyledText {
                required property var model

                horizontalAlignment: Text.AlignHCenter
                text: model.shortName
                font: Tokens.font.body.builders.small.weight(Font.Medium).build()
                color: (model.day === 0 || model.day === 6) ? Colours.palette.m3tertiary : Colours.palette.m3onSurface
            }
        }

        Item {
            id: gridClip

            Layout.fillWidth: true
            implicitHeight: grid1.implicitHeight

            clip: true

            Component {
                id: gridComp

                Item {
                    id: internalGridContainer

                    property alias title: internalGrid.title
                    property int month
                    property int year

                    implicitHeight: internalGrid.implicitHeight

                    MonthGrid {
                        id: internalGrid

                        anchors.fill: parent

                        month: internalGridContainer.month
                        year: internalGridContainer.year
                        spacing: 3
                        locale: Qt.locale()

                        delegate: Item {
                            id: dayItem

                            required property var model

                            implicitWidth: implicitHeight
                            implicitHeight: text.implicitHeight + Tokens.padding.small

                            StyledText {
                                id: text

                                anchors.centerIn: parent

                                horizontalAlignment: Text.AlignHCenter
                                text: internalGrid.locale.toString(dayItem.model.day)
                                color: {
                                    const dayOfWeek = dayItem.model.date.getDay();
                                    if (dayOfWeek === 0 || dayOfWeek === 6)
                                        return Colours.palette.m3tertiary;

                                    return Colours.palette.m3onSurfaceVariant;
                                }
                                opacity: dayItem.model.today || dayItem.model.month === internalGrid.month ? 1 : 0.4
                                font: Tokens.font.body.small
                            }
                        }
                    }

                    MaterialShape {
                        id: todayIndicator

                        readonly property Item todayItem: internalGrid.contentItem.children.find(c => c.model.today) ?? null
                        property Item today

                        x: today ? today.x + (today.width - implicitWidth) / 2 : 0
                        y: today ? today.y - Tokens.padding.extraSmall - 1 : 0

                        implicitSize: today ? Math.max(today.implicitWidth, today.implicitHeight) + Tokens.padding.extraSmall * 2 : 0
                        shape: MaterialShape.Sunny

                        clip: true
                        color: Colours.palette.m3primary
                        opacity: todayItem ? 1 : 0
                        scale: todayItem ? 1 : 0.7

                        onTodayItemChanged: {
                            if (todayItem)
                                today = todayItem;
                        }

                        Colouriser {
                            x: -todayIndicator.x
                            y: -todayIndicator.y

                            implicitWidth: internalGrid.width
                            implicitHeight: internalGrid.height

                            source: internalGrid
                            sourceColor: Colours.palette.m3onSurface
                            colorizationColor: Colours.palette.m3onPrimary
                        }

                        Behavior on opacity {
                            Anim {
                                type: Anim.DefaultEffects
                            }
                        }

                        Behavior on scale {
                            Anim {
                                type: Anim.FastSpatial
                            }
                        }

                        Behavior on x {
                            Anim {}
                        }

                        Behavior on y {
                            Anim {}
                        }
                    }
                }
            }

            Loader {
                id: grid1

                anchors.fill: parent

                sourceComponent: gridComp
                visible: root.activeGrid === 1 || monthChangeAnim.running

                transform: Translate {
                    id: grid1Translate
                }

                Binding {
                    target: grid1.item
                    property: "month"
                    value: root.month1
                }
                Binding {
                    target: grid1.item
                    property: "year"
                    value: root.year1
                }
            }

            Loader {
                id: grid2

                anchors.fill: parent

                sourceComponent: gridComp
                visible: root.activeGrid === 2 || monthChangeAnim.running

                transform: Translate {
                    id: grid2Translate
                }

                Binding {
                    target: grid2.item
                    property: "month"
                    value: root.month2
                }
                Binding {
                    target: grid2.item
                    property: "year"
                    value: root.year2
                }
            }
        }
    }
}
