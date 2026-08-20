'use strict';
import GObject from 'gi://GObject';
import St from 'gi://St';
import Clutter from 'gi://Clutter';
import Cairo from 'gi://cairo';

import {
    hexToColor, setSourceColor, getInkBounds, addVectorImage, loadFileToCairoSurface
} from './colorHelpers.js';
import {VectorImages} from './circularBatteryVectorImages.js';

// Credits: to https://github.com/Deminder for this
// https://github.com/Deminder/battery-indicator-icon/blob/main/src/modules/drawicon.js

export const CircleBatteryIcon = GObject.registerClass({
    GTypeName: 'BluetoothBatteryMeter_CircleBatteryIcon',
}, class CircleBatteryIcon extends St.DrawingArea {
    _init(canvasSize, deviceIcon, widgetInfo) {
        super._init({x_align: Clutter.ActorAlign.CENTER, y_align: Clutter.ActorAlign.CENTER});
        this.width = canvasSize;
        this.height = canvasSize;
        this._canvasSize = canvasSize;
        this._deviceIcon = deviceIcon;
        this._widgetInfo = widgetInfo;
        this._extPath = widgetInfo.extPath;
        this._loadDeviceIcon();
    }

    _loadDeviceIcon() {
        this._cairoCacheSurface = null;
        this._transform = {};

        const intendedIconSize = 15.2;
        const svgSize = 16;
        const unscaledCanvasSize = 34;

        const iconFolder = `${this._extPath}/icons/hicolor/scalable/actions`;
        const filePath = `${iconFolder}/bbm-${this._deviceIcon}-symbolic.svg`;

        const inkRect =  getInkBounds(filePath, svgSize);
        if (!inkRect)
            return;

        const intendedScale = intendedIconSize / svgSize;
        const displayScale = this._canvasSize / unscaledCanvasSize;
        const maxTextureScale = 3;
        const scale = displayScale * intendedScale / maxTextureScale;
        const unscaledOffsetXY = (unscaledCanvasSize - intendedIconSize) / 2;
        const offsetXY = unscaledOffsetXY * maxTextureScale / intendedScale;

        this._transform.scale = scale;
        this._transform.offsetXY = offsetXY;
        this._transform.chargingStatusScale = displayScale;

        this._cairoCacheSurface = loadFileToCairoSurface(filePath, maxTextureScale);
    }

    _assignWidgetColor() {
        const themeColors = this.get_theme_node().get_icon_colors();
        const foregroundColor = themeColors.foreground;
        const successColor =  themeColors.success;
        const warningColor =  themeColors.warning;
        const errorColor =  themeColors.error;
        const baseLevelColor = foregroundColor.copy();
        baseLevelColor.alpha *= 0.5;

        let fillLevelColor;
        let chargingIconColor = foregroundColor;
        const disconnectedIconColor = errorColor;
        if (this._widgetInfo.circleWidgetColor === 0) {
            fillLevelColor = this._percentage > 20 ? foregroundColor : warningColor;
            chargingIconColor = successColor;
        } else if (this._widgetInfo.circleWidgetColor === 1) {
            fillLevelColor = this._percentage > 20 ? successColor : warningColor;
        } else {
            const idx = Math.ceil(this._percentage / 10) - 1;
            const fallbackColor = this._percentage > 20 ? successColor : warningColor;
            const hex = this._widgetInfo.circleWidgetCustomColors[idx] ?? fallbackColor;
            fillLevelColor = hexToColor(hex);
        }
        return {
            foregroundColor, fillLevelColor, baseLevelColor,
            chargingIconColor, disconnectedIconColor,
        };
    }

    updateValues(percentage, status) {
        this._status = status;
        this._percentage = percentage;
        if (this.has_allocation())
            this.queue_repaint();
    }

    _drawIcon(cr) {
        cr.save();
        cr.scale(this._transform.scale, this._transform.scale);
        cr.translate(this._transform.offsetXY, this._transform.offsetXY);
        setSourceColor(cr, this._colors.foregroundColor);
        cr.maskSurface(this._cairoCacheSurface, 0, 0);
        cr.restore();
    }

    _setRadialStrokeSource(cr, cx, cy, radius, strokeWidth, scale, color) {
        let fade = 0.2 - 0.091 * Math.log(scale);
        fade = Math.max(0.10, Math.min(0.20, fade));

        const inner = radius - strokeWidth / 2;
        const outer = radius + strokeWidth / 2;

        const gradient = new Cairo.RadialGradient(cx, cy, inner, cx, cy, outer);

        const r = color.red / 255;
        const g = color.green / 255;
        const b = color.blue / 255;
        const a = color.alpha / 255;

        gradient.addColorStopRGBA(0.0, r, g, b, 0.0);
        gradient.addColorStopRGBA(fade, r, g, b, a);
        gradient.addColorStopRGBA(1.0 - fade, r, g, b, a);
        gradient.addColorStopRGBA(1.0, r, g, b, 0.0);

        cr.setSource(gradient);
    }

    _drawCircle(cr) {
        const size = this._canvasSize;
        const scale = size / 32;
        const strokeWidth = 4.8 * Math.pow(scale, 0.85);

        const p = Math.max(0, Math.min(1, this._percentage / 100));
        const radius = (size - strokeWidth) / 2;
        const cx = size / 2;
        const cy = size / 2;
        const angleOffset = -0.5 * Math.PI;
        const endAngle = angleOffset + p * 2 * Math.PI;

        cr.save();
        cr.setLineWidth(strokeWidth);

        if (p > 0) {
            this._setRadialStrokeSource(cr, cx, cy, radius, strokeWidth,
                scale, this._colors.fillLevelColor);
            cr.arc(cx, cy, radius, angleOffset, endAngle);
            cr.stroke();
        }

        if (p < 1) {
            this._setRadialStrokeSource(cr, cx, cy, radius, strokeWidth,
                scale, this._colors.baseLevelColor);
            cr.arc(cx, cy, radius, endAngle, angleOffset + 2 * Math.PI);
            cr.stroke();
        }

        cr.restore();
    }

    _drawChargingStatusVectors(cr) {
        if (this._status !== 'disconnected' && this._status !== 'charging')
            return;

        cr.scale(this._transform.chargingStatusScale, this._transform.chargingStatusScale);

        const modelPath = VectorImages[this._deviceIcon];
        const chargingPath = VectorImages['charging-bolt'];
        const disconnectedPath = VectorImages['disconnected'];

        addVectorImage(cr, modelPath, this._colors.foregroundColor);

        if (this._status === 'disconnected') {
            cr.fill();
            addVectorImage(cr, disconnectedPath, this._colors.disconnectedIconColor);
        } else if (this._status === 'charging') {
            addVectorImage(cr, chargingPath, this._colors.chargingIconColor);
        }
        cr.fill();
    }

    vfunc_repaint() {
        if (!this._cairoCacheSurface)
            return;

        const [w, h] = this.get_surface_size();
        if (w === 0 || h === 0)
            return;

        if (this._transform.scale === undefined || this._transform.offsetXY === undefined ||
                this._transform.chargingStatusScale === undefined)
            return;

        this._colors = this._assignWidgetColor();
        const cr = this.get_context();
        this._drawIcon(cr);
        this._drawCircle(cr);
        cr.$dispose();
    }
}
);


