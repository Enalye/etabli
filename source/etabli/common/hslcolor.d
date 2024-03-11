/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module etabli.common.hslcolor;

import std.math;
import std.typecons;
import std.random;
import std.algorithm.comparison : clamp, min, max;

import etabli.common.color;
import etabli.common.stream;
import etabli.common.vec3;

/// Couleur dans un espace TSL
struct HSLColor {
    private {
        float _h = 0f, _s = 0f, _l = 0f;
    }

    static {
        HSLColor fromColor(Color color) {
            return fromColor(color.r, color.g, color.b);
        }

        HSLColor fromColor(float r, float g, float b) {
            float cmin = min(r, g, b);
            float cmax = max(r, g, b);
            float delta = cmax - cmin;
            float h = 0f, s = 0f, l = 0f;

            if (delta == 0f)
                h = 0f;
            else if (cmax == r)
                h = ((g - b) / delta) % 6f;
            else if (cmax == g)
                h = (b - r) / delta + 2f;
            else
                h = (r - g) / delta + 4f;

            h *= 60f;

            if (h < 0f)
                h += 360f;

            l = (cmax + cmin) / 2f;

            s = delta == 0f ? 0f : delta / (1f - abs(2f * l - 1f));

            return HSLColor(h, s, l);
        }
    }

    @property {
        /// Teinte
        float h() const {
            return _h;
        }
        /// Ditto
        float h(float hue) {
            if (hue < 0f)
                hue += 360f;
            return _h = clamp(hue, 0f, 360f);
        }

        /// Saturation
        float s() const {
            return _s;
        }
        /// Ditto
        float s(float saturation) {
            return _s = clamp(saturation, 0f, 1f);
        }

        /// Luminosité
        float l() const {
            return _l;
        }
        /// Ditto
        float l(float light) {
            return _l = clamp(light, 0f, 1f);
        }

        /// Converti en vecteur
        Vec3f hsl() const {
            return Vec3f(_h, _s, _l);
        }
        /// Converti depuis un vecteur
        Vec3f hsl(Vec3f v) {
            set(v.x, v.y, v.z);
            return v;
        }
    }

    this(float hue, float saturation, float light) {
        set(hue, saturation, light);
    }

    /// Assigne les valeurs
    void set(float hue, float saturation, float light) {
        _h = clamp(hue, 0f, 360f);
        _s = clamp(saturation, 0f, 1f);
        _l = clamp(light, 0f, 1f);
    }

    /// Binary operations
    HSLColor opBinary(string op)(const HSLColor c) const {
        return mixin("HSLColor(_h ", op, " c._h, _s ", op, " c._s, _l ", op, " c._l)");
    }

    /// Binary operations
    HSLColor opBinary(string op)(float v) const {
        return mixin("HSLColor(_h ", op, " v, _s ", op, " v, _l ", op, " v)");
    }

    /// Binary operations
    HSLColor opBinaryRight(string op)(float v) const {
        return mixin("HSLColor(v ", op, " _h, v ", op, " _s, v ", op, " _l)");
    }

    /// Binary operations
    HSLColor opOpAssign(string op)(const HSLColor c) {
        mixin("
			_h = clamp(_h ", op, "c._h, 0f, 360f);
			_s = clamp(_s " ~ op ~ "c._s, 0f, 1f);
			_l = clamp(_l ", op, "c._l, 0f, 1f);
			");
        return this;
    }

    HSLColor lerp(HSLColor end, float t) const {
        return (this * (1f - t)) + (end * t);
    }

    Color toColor() const {
        float c = (1f - abs(2f * _l - 1f)) * _s;
        float x = c * (1 - abs((_h / 60f) % 2f - 1f));
        float m = _l - c / 2f;
        float r = 0f, g = 0f, b = 0f;

        if (0f <= _h && _h < 60f) {
            r = c;
            g = x;
            b = 0f;
        }
        else if (60f <= _h && _h < 120f) {
            r = x;
            g = c;
            b = 0f;
        }
        else if (120f <= _h && _h < 180f) {
            r = 0f;
            g = c;
            b = x;
        }
        else if (180f <= _h && _h < 240f) {
            r = 0f;
            g = x;
            b = c;
        }
        else if (240f <= _h && _h < 300f) {
            r = x;
            g = 0f;
            b = c;
        }
        else if (300f <= _h && _h < 360f) {
            r = c;
            g = 0f;
            b = x;
        }

        r += m;
        g += m;
        b += m;

        return Color(r, g, b);
    }

    /// Désérialise
    void load(InStream stream) {
        _h = stream.read!float;
        _s = stream.read!float;
        _l = stream.read!float;
    }

    /// Sérialise
    void save(OutStream stream) {
        stream.write!float(_h);
        stream.write!float(_s);
        stream.write!float(_l);
    }
}
