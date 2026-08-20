'use strict';
import Clutter from 'gi://Clutter';
import GObject from 'gi://GObject';
import St from 'gi://St';

import {
    hexToColor, setSourceColor, getInkBounds, addVectorImage,
    loadFileToCairoSurface
} from './colorHelpers.js';
import {VectorImages} from './indicatorVectorImages.js';

// Credits: to https://github.com/Deminder for this
// https://github.com/Deminder/battery-indicator-icon/blob/main/src/modules/drawicon.js

export const IndicatorIconWidget = GObject.registerClass({
    GTypeName: 'BluetoothBatteryMeter_IndicatorIconWidget',
}, class IndicatorIconWidget extends St.DrawingArea {
    _init(settings, indicator, indicatorMode, deviceIcon, widgetInfo) {
        super._init({x_align: Clutter.ActorAlign.CENTER, y_align: Clutter.ActorAlign.CENTER});
        this._settings = settings;
        this._indicator = indicator;
        this._indicatorScale = this._settings.get_int('indicator-size') / 100;
        this._indicatorMode = indicatorMode;
        this._iconSize = null;
        this._extPath = widgetInfo.extPath;
        this._deviceIcon = deviceIcon;
        this._widgetInfo = widgetInfo;
        this._cairoCacheSurface = null;

        this._settings.connectObject(
            'changed::indicator-size', () => {
                this._indicatorScale = this._settings.get_int('indicator-size') / 100;
                this._loadDeviceIcon();
            },
            this
        );
    }

    setIconSize(iconSize) {
        this._iconSize = iconSize;
        this._loadDeviceIcon();
    }

    _loadDeviceIcon() {
        if (!this._iconSize)
            return;

        this._cairoCacheSurface = null;
        this._transform = {};
        const svgSize = 16;
        const iconFolder = `${this._extPath}/icons/hicolor/scalable/actions`;
        const filePath = `${iconFolder}/bbm-${this._deviceIcon}-symbolic.svg`;

        const inkRect =  getInkBounds(filePath, svgSize);
        if (!inkRect)
            return;

        if (this._widgetInfo.levelIndicatorType === 1 || this._widgetInfo.levelBarPosition === 2)
            this._setSquaredWidth(filePath, svgSize, inkRect);
        else
            this._setAdjustedWidth(filePath, svgSize, inkRect);
    }

    _setSquaredWidth(filePath, svgSize, inkRect) {
        const binWidth = this._iconSize;
        const binHeight = this._iconSize;
        const displayScale = binHeight / svgSize;
        const maxTextureScale = 3;
        const maxHeight = 12;
        const maxWidth = 14.5;
        let scaleSvg = maxHeight / inkRect.height;
        const targetWidth = inkRect.width * scaleSvg;

        if (targetWidth >= maxWidth)
            scaleSvg = maxWidth / inkRect.width;

        const textureSize = svgSize * maxTextureScale;
        const correctedFactor = binHeight / textureSize;
        const finalScale = scaleSvg * correctedFactor * this._indicatorScale;
        const inkWidthSurface = inkRect.width * maxTextureScale;
        const inkHeightSurface = inkRect.height * maxTextureScale;
        const inkRectXSurface = inkRect.x * maxTextureScale;
        const inkRectYSurface = inkRect.y * maxTextureScale;
        const inkWidthDevice = inkWidthSurface * finalScale;
        const inkHeightDevice = inkHeightSurface * finalScale;
        const desiredInkLeftDevice = (binHeight - inkWidthDevice) / 2;
        const maxHeightDevice = maxHeight * displayScale;
        const desiredInkTopDevice = maxHeightDevice - inkHeightDevice;
        const offsetX = desiredInkLeftDevice / finalScale - inkRectXSurface;
        const offsetY = desiredInkTopDevice  / finalScale - inkRectYSurface;
        const batteryScale = displayScale;

        this.width = binWidth;
        this.height = binHeight;

        this._transform = {
            scale: finalScale,
            offsetX,
            offsetY,
            batteryScale,
        };

        const batteryWidth = 15;
        const batteryHeight = 2.6;
        const batteryX = (svgSize - batteryWidth) / 2;
        const batteryY = svgSize - batteryHeight;

        if (this._widgetInfo.levelIndicatorType === 0)
            this._precomputeBarLayouts(batteryX, batteryY, batteryWidth, batteryHeight, false);
        else
            this._precomputeDotLayouts(batteryX, batteryY, batteryWidth, batteryHeight);

        this._cairoCacheSurface = loadFileToCairoSurface(filePath, maxTextureScale);

        this.queue_repaint();
    }

    _setAdjustedWidth(filePath, svgSize, inkRect) {
        const binHeight = this._iconSize;
        const spacer = this._indicatorMode ===  1 ? 2 : 3;
        const batBoxWidth = this._indicatorMode ===  1 ? 6.5 : 4;
        const batteryHeight = 15;
        const svgHeight = svgSize;
        const displayScale = binHeight / svgSize;
        const maxTextureScale = 3;
        const textureSize = svgSize * maxTextureScale;
        const correctedFactor = binHeight / textureSize;
        const icon2Right = this._widgetInfo.levelBarPosition === 0;
        const initialOffset = icon2Right ? spacer + batBoxWidth : 0;
        const offsetX = (initialOffset - inkRect.x) * maxTextureScale;
        const offsetY = (0 - inkRect.y + (svgHeight - inkRect.height) / 2) * maxTextureScale;
        const totalBinWidth = (inkRect.width + spacer + batBoxWidth) * displayScale;
        const batteryScale = displayScale;

        this.width = totalBinWidth;
        this.height = binHeight;

        this._transform = {
            scale: correctedFactor,
            offsetX,
            offsetY,
            batteryScale,
        };

        const batteryX = icon2Right ? 0 : inkRect.width + spacer;
        const batteryY = (svgHeight - batteryHeight) / 2;

        this._precomputeBarLayouts(batteryX, batteryY, batBoxWidth, batteryHeight, true);

        this._cairoCacheSurface = loadFileToCairoSurface(filePath, maxTextureScale);

        this.queue_repaint();
    }

    _assignWidgetColor() {
        const themeColors = this.get_theme_node().get_icon_colors();
        const foregroundColor = themeColors.foreground;
        const successColor =  themeColors.success;
        const warningColor =  themeColors.warning;
        const baseLevelColor = foregroundColor.copy();
        baseLevelColor.alpha *= 0.5;

        let fillLevelColor;
        if (this._widgetInfo.levelIndicatorColor === 0) {
            fillLevelColor = this._percentage > 20 ? foregroundColor : warningColor;
        } else if (this._widgetInfo.levelIndicatorColor === 1) {
            fillLevelColor = this._percentage > 20 ? successColor : warningColor;
        } else {
            const idx = Math.ceil(this._percentage / 10) - 1;
            const fallbackColor = this._percentage > 20 ? successColor : warningColor;
            const hex = this._widgetInfo.levelIndicatorCustomColors[idx] ?? fallbackColor;
            fillLevelColor = hexToColor(hex);
        }
        return {foregroundColor, fillLevelColor, baseLevelColor};
    }

    _precomputeBarLayouts(x, y, width, height, vertical = false) {
        this._batteryBounds = {};
        const thickness = vertical ? width : height;
        const notchLength = thickness * 0.40;
        const notchDepth  = thickness * 0.60;
        const radius = thickness * 0.06;

        let barX, barY, barW, barH;
        let notchX, notchY, notchW, notchH;

        if (vertical) {
            barX = x;
            barY = y + notchLength;
            barW = width;
            barH = height - notchLength;
            notchX = x + (width - notchDepth) / 2;
            notchY = y;
            notchW = notchDepth;
            notchH = notchLength;
        } else {
            barX = x;
            barY = y;
            barW = width - notchLength;
            barH = height;
            notchX = x + barW;
            notchY = y + (height - notchDepth) / 2;
            notchW = notchLength;
            notchH = notchDepth;
        }

        this._batteryBounds = {
            vertical,
            barX, barY, barW, barH,
            notchX, notchY, notchW, notchH,
            radius,
        };
    }

    _drawBatteryBarLevel(cr) {
        const {
            vertical,
            barX, barY, barW, barH,
            notchX, notchY, notchW, notchH,
            radius,
        } = this._batteryBounds;

        const drawRoundedRect = (ctx, x, y, w, h, r) => {
            ctx.newPath();
            ctx.arc(x + w - r, y + r, r, -Math.PI / 2, 0);
            ctx.arc(x + w - r, y + h - r, r, 0, Math.PI / 2);
            ctx.arc(x + r, y + h - r, r, Math.PI / 2, Math.PI);
            ctx.arc(x + r, y + r, r, Math.PI, 1.5 * Math.PI);
            ctx.closePath();
            ctx.fill();
        };

        setSourceColor(cr, this._colors.baseLevelColor);
        drawRoundedRect(cr, barX, barY, barW, barH, radius);

        if (this._percentage >= 100)
            setSourceColor(cr, this._colors.fillLevelColor);
        drawRoundedRect(cr, notchX, notchY, notchW, notchH, radius);

        setSourceColor(cr, this._colors.fillLevelColor);
        if (vertical) {
            const fillH = barH * this._percentage / 100;
            const fillY = barY + (barH - fillH);
            drawRoundedRect(cr, barX, fillY, barW, fillH, radius);
        } else {
            const fillW = barW * this._percentage / 100;
            drawRoundedRect(cr, barX, barY, fillW, barH, radius);
        }
    }

    _precomputeDotLayouts(x, y, width, height) {
        this._dotLayouts = [];
        const r = height / 2;
        const d = height;
        const boxCenter = x + width / 2;
        const cy = y + r;
        this._dotLayouts = {radius: r};
        this._dotLayouts[1] = [{cx: boxCenter, cy}];

        let spacer = d;
        this._dotLayouts[2] = [
            {cx: boxCenter - (spacer / 2 + r), cy},
            {cx: boxCenter + (spacer / 2 + r), cy},
        ];

        this._dotLayouts[3] = [
            {cx: boxCenter - (spacer + r), cy},
            {cx: boxCenter, cy},
            {cx: boxCenter + (spacer + r), cy},
        ];

        spacer = (width - 4 * d) / 3;
        const startX = x + (width - (4 * d + 3 * spacer)) / 2;
        this._dotLayouts[4] = [
            {cx: startX + r, cy},
            {cx: startX + (d + spacer) + r, cy},
            {cx: startX + 2 * (d + spacer) + r, cy},
            {cx: startX + 3 * (d + spacer) + r, cy},
        ];

        this._batteryBounds = this._batteryBounds || {};
        this._batteryBounds.barX = x;
    }

    _drawDotLevel(cr) {
        let fillCount = 0;
        const percentage = this._percentage;

        if (percentage > 75)
            fillCount = 4;
        else if (percentage > 50)
            fillCount = 3;
        else if (percentage > 25)
            fillCount = 2;
        else
            fillCount = 1;

        const centers = this._dotLayouts[fillCount];
        const radius = this._dotLayouts.radius;

        setSourceColor(cr, this._colors.fillLevelColor);

        for (const {cx, cy} of centers) {
            cr.newPath();
            cr.arc(cx, cy, radius, 0, 2 * Math.PI);
            cr.fill();
        }
    }

    _drawWidget(cr) {
        cr.save();
        cr.scale(this._transform.scale, this._transform.scale);
        cr.translate(this._transform.offsetX, this._transform.offsetY);
        setSourceColor(cr, this._colors.foregroundColor);
        cr.maskSurface(this._cairoCacheSurface, 0, 0);
        cr.restore();
        cr.scale(this._transform.batteryScale, this._transform.batteryScale);

        if (this._indicatorMode === 2) {
            if (this._widgetInfo.levelIndicatorType === 0)
                this._drawBatteryBarLevel(cr);
            else
                this._drawDotLevel(cr);
        } else if (this._indicatorMode === 1) {
            const barX = this._batteryBounds?.barX ?? 0;
            cr.translate(barX, 0);
            const placeImageBelowDeviceIcon = this._widgetInfo.levelIndicatorType === 1 ||
                    this._widgetInfo.levelBarPosition === 2;
            const vectorImage = placeImageBelowDeviceIcon ? 'h-non-battery' : 'v-non-battery';
            addVectorImage(cr, VectorImages[vectorImage], this._colors.foregroundColor);
        }
    }

    vfunc_repaint() {
        if (!this._cairoCacheSurface)
            return;

        const [w, h] = this.get_surface_size();
        if (w === 0 || h === 0)
            return;

        if (this._transform.scale === undefined || this._transform.offsetX === undefined ||
                    this._transform.offsetY === undefined ||
                    this._transform.batteryScale === undefined)
            return;

        this._colors = this._assignWidgetColor();
        const cr = this.get_context();
        this._drawWidget(cr);
        cr.$dispose();
    }

    updateValues(percentage) {
        this._percentage = percentage;
        if (this.has_allocation())
            this.queue_repaint();
    }

    updateProperties(indicatorMode, deviceIcon) {
        if (this._indicatorMode !== indicatorMode || this._deviceIcon !== deviceIcon) {
            this._indicatorMode = indicatorMode;
            this._deviceIcon = deviceIcon;
            this._loadDeviceIcon();
        }
    }
}
);


