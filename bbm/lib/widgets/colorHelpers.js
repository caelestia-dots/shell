import Clutter from 'gi://Clutter';
import Cogl from 'gi://Cogl';
import Gio from 'gi://Gio';
import St from 'gi://St';
import Rsvg from 'gi://Rsvg';
import * as Config from 'resource:///org/gnome/shell/misc/config.js';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';

const [major] = Config.PACKAGE_VERSION.split('.');
const shellVersion = Number.parseInt(major);

export function getAccentColor() {
    const tmp = new St.Button({style_class: 'quick-toggle'});
    tmp.hide();
    Main.uiGroup.add_child(tmp);
    tmp.checked = true;
    const color = tmp.get_theme_node().get_background_color();
    tmp.destroy();
    return color;
}

export function rgbToHsl(r, g, b) {
    r /= 255;
    g /= 255;
    b /= 255;
    const max = Math.max(r, g, b);
    const min = Math.min(r, g, b);
    let h, s;
    const l = (max + min) / 2;

    if (max === min) {
        h = s = 0;
    } else {
        const delta = max - min;
        s = l > 0.5 ? delta / (2 - max - min) : delta / (max + min);
        switch (max) {
            case r:
                h = (g - b) / delta + (g < b ? 6 : 0);
                break;
            case g:
                h = (b - r) / delta + 2;
                break;
            case b:
                h = (r - g) / delta + 4;
                break;
        }
        h /= 6;
    }

    return {
        h: h * 360,
        s: s * 100,
        l: l * 100,
    };
}

export function hslToRgb(h, s, l) {
    h /= 360;
    s /= 100;
    l /= 100;
    let r, g, b;

    if (s === 0) {
        r = g = b = l;
    } else {
        const hue2rgb = (p, q, t) => {
            if (t < 0)
                t += 1;
            if (t > 1)
                t -= 1;
            if (t < 1 / 6)
                return p + (q - p) * 6 * t;
            if (t < 1 / 2)
                return q;
            if (t < 2 / 3)
                return p + (q - p) * (2 / 3 - t) * 6;
            return p;
        };
        const q = l < 0.5 ? l * (1 + s) : l + s - l * s;
        const p = 2 * l - q;

        r = hue2rgb(p, q, h + 1 / 3);
        g = hue2rgb(p, q, h);
        b = hue2rgb(p, q, h - 1 / 3);
    }

    return {
        red: Math.round(r * 255),
        green: Math.round(g * 255),
        blue: Math.round(b * 255),
    };
}

export function hslToRgbHexString(h, s, l) {
    const {red, green, blue} = hslToRgb(h, s, l);
    return `#${((1 << 24) + (red << 16) + (green << 8) + blue)
        .toString(16)
        .slice(1)
        .toUpperCase()}`;
}

export function colorToString(color) {
    return color.to_string().substring(0, 7);
}

export function colorToRgba(color) {
    return `rgba(${color.red}, ${color.green}, ${color.blue}, ${color.alpha})`;
}

export function colorToHsl(color) {
    return rgbToHsl(color.red, color.green, color.blue);
}

export function isDarkMode(color) {
    const {l} = rgbToHsl(color.red, color.green, color.blue);
    return l < 40;
}

export function invertColor(color) {
    const ColorClass = shellVersion <= 46 ? Clutter.Color : Cogl.Color;
    return new ColorClass({
        red: 255 - color.red,
        green: 255 - color.green,
        blue: 255 - color.blue,
        alpha: color.alpha,
    });
}

export function adjustOpacityToRgba(color, transparency) {
    const alpha = Math.max(0, Math.min(1, transparency)).toFixed(2);
    return `rgba(${color.red}, ${color.green}, ${color.blue}, ${alpha})`;
}

export function colorGreyOpacity(transparency) {
    const alpha = Math.max(0, Math.min(1, transparency)).toFixed(2);
    return `rgba(${128}, ${128}, ${128}, ${alpha})`;
}

export function adjustColorLuminanceToRgba(color, factor) {
    const {h, s, l} = rgbToHsl(color.red, color.green, color.blue);
    const newL = Math.max(0, Math.min(100, l + factor));
    const {red, green, blue} = hslToRgb(h, s, newL);
    const alpha = (color.alpha / 255).toFixed(2);
    return `rgba(${red}, ${green}, ${blue}, ${alpha})`;
}

export function hexToColor(hexColor) {
    return (shellVersion <= 46 ? Clutter.Color : Cogl.Color).from_string(hexColor)[1];
}

export function setSourceColor(cr, sourceColor) {
    if (Clutter.cairo_set_source_color)
        Clutter.cairo_set_source_color(cr, sourceColor);
    else
        cr.setSourceColor(sourceColor);
}

export function getInkBounds(filePath, svgSize) {
    let handle;

    try {
        handle = Rsvg.Handle.new_from_file(filePath);
    } catch {
        console.error(`Failed to load SVG: ${filePath}`);
        return null;
    }

    const intrinsic = handle.get_intrinsic_size_in_pixels();
    if (!Array.isArray(intrinsic) || intrinsic.length < 3 ||
                intrinsic[1] !== svgSize || intrinsic[2] !== svgSize) {
        console.log('Invalid SVG dimension');
        return null;
    }

    const viewport = new Rsvg.Rectangle({x: 0, y: 0, width: svgSize, height: svgSize});
    const [ok, inkRect] = handle.get_geometry_for_layer(null, viewport);
    if (!ok) {
        console.log('Invalid SVG geometry');
        return null;
    }
    return inkRect;
}

export function loadFileToCairoSurface(filePath, textureScale) {
    try {
        const gFile = Gio.File.new_for_path(filePath);
        return St.TextureCache.get_default().load_file_to_cairo_surface(
            gFile, 1, textureScale);
    } catch (e) {
        console.log(e, `Failed to load Cairo surface from file: ${filePath}`);
        return null;
    }
}

export function addVectorImage(cr, path, color)  {
    setSourceColor(cr, color);
    cr.translate(0, 0);
    let currentX = 0;
    let currentY = 0;
    const vectorPath = path.split(' ');
    for (let i = 0; i < vectorPath.length; i++) {
        if (vectorPath[i] === 'M') {
            currentX = parseFloat(vectorPath[i + 1]);
            currentY = parseFloat(vectorPath[i + 2]);
            cr.moveTo(currentX, currentY);
            i += 2;
        } else if (vectorPath[i] === 'L') {
            currentX = parseFloat(vectorPath[i + 1]);
            currentY = parseFloat(vectorPath[i + 2]);
            cr.lineTo(currentX, currentY);
            i += 2;
        } else if (vectorPath[i] === 'H') {
            currentX = parseFloat(vectorPath[i + 1]);
            cr.lineTo(currentX, currentY);
            i += 1;
        } else if (vectorPath[i] === 'V') {
            currentY = parseFloat(vectorPath[i + 1]);
            cr.lineTo(currentX, currentY);
            i += 1;
        } else if (vectorPath[i] === 'C') {
            const x1 = parseFloat(vectorPath[i + 1]);
            const y1 = parseFloat(vectorPath[i + 2]);
            const x2 = parseFloat(vectorPath[i + 3]);
            const y2 = parseFloat(vectorPath[i + 4]);
            const x3 = parseFloat(vectorPath[i + 5]);
            const y3 = parseFloat(vectorPath[i + 6]);
            cr.curveTo(x1, y1, x2, y2, x3, y3);
            currentX = x3;
            currentY = y3;
            i += 6;
        } else if (vectorPath[i] === 'Z') {
            cr.closePath();
        }
    }
    cr.fill();
}
