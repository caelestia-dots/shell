import "../components/controls"
import QtQuick
import QtQuick.Templates
import QtTest

Item {
    id: scene

    property real brightness: 0.65

    property int taps: 0

    property int drags: 0

    property int starts: 0

    property int dragStarts: 0

    width: 240
    height: 400

    Slider {
        id: control

        x: 95
        y: 50
        width: 30
        height: 240
        from: 0
        to: 1
        orientation: Qt.Vertical
        value: scene.brightness
        onMoved: {
            scene.brightness = value;
            scene.drags++;
        }
        handle: Rectangle {
            id: knob

            implicitWidth: 30
            implicitHeight: 30
            y: control.visualPosition * (control.availableHeight - height)
            radius: 15
            color: "#202126"
            scale: area.pressed && !area.dragging ? .94 : 1
        }

        ThumbInputArea {
            id: area

            x: knob.x - 6
            y: knob.y - 6
            width: knob.width + 12
            height: knob.height + 12
            z: 1
            slider: control
            onInteractionStarted: scene.starts++
            onTapped: scene.taps++
            onDragStarted: scene.dragStarts++
            onDragMoved: next => {
                scene.brightness = next;
                scene.drags++;
            }
        }
    }

    TestCase {
        function position(dx, dy) {
            return [control.x + knob.x + dx, control.y + knob.y + dy];
        }

        function init() {
            scene.brightness = .65;
            scene.taps = 0;
            scene.drags = 0;
            scene.starts = 0;
            scene.dragStarts = 0;
            wait(40);
        }

        function test_edges_and_corners_do_not_move_slider() {
            const points = [[15, 15], [1, 15], [29, 15], [15, 1], [15, 29], [15, 30], [15, 31], [15, 33], [15, 35], [1, 1], [29, 29], [0, 0]];
            for (let i = 0; i < points.length; i++) {
                const [x, y] = position(points[i][0], points[i][1]);
                const value = scene.brightness;
                mouseClick(scene, x, y, Qt.LeftButton);
                compare(scene.taps, i + 1, "Edge " + i);
                compare(scene.brightness, value, "Click modified brightness at " + i);
                compare(scene.drags, 0);
            }
        }

        function test_drag_still_adjusts() {
            const [x, y] = position(15, 15);
            const old = scene.brightness;
            mousePress(scene, x, y, Qt.LeftButton);
            mouseMove(scene, x, y - 70, 50, Qt.LeftButton);
            mouseRelease(scene, x, y - 70, Qt.LeftButton);
            compare(scene.taps, 0);
            verify(scene.dragStarts > 0);
            verify(scene.drags > 0);
            verify(scene.brightness > old);
        }

        function test_mouse_pressed_scale() {
            const [x, y] = position(15, 15);
            compare(knob.scale, 1);
            mousePress(scene, x, y, Qt.LeftButton);
            compare(knob.scale, .94);
            mouseRelease(scene, x, y, Qt.LeftButton);
            compare(knob.scale, 1);
            compare(scene.taps, 1);
        }

        function test_horizontal_motion_does_not_change_brightness() {
            const [x, y] = position(15, 15);
            const old = scene.brightness;
            mousePress(scene, x, y, Qt.LeftButton);
            mouseMove(scene, x + 65, y + 4, 50, Qt.LeftButton);
            mouseRelease(scene, x + 65, y + 4, Qt.LeftButton);
            compare(scene.drags, 0);
            compare(scene.taps, 0);
            compare(scene.brightness, old);
        }

        function test_track_click_still_works() {
            const [x, y] = position(15, 15);
            const old = control.value;
            mouseClick(scene, control.x + 15, control.y + 12, Qt.LeftButton);
            compare(scene.taps, 0);
            verify(Math.abs(control.value - old) > 0.05);
        }

        name: "ThumbInput"
        when: windowShown
    }
}
