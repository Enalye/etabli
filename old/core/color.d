/**
    Color

    Copyright: (c) Enalye 2017
    License: Zlib
    Authors: Enalye
*/

module etabli.core.color;

import std.math;
import std.typecons;
import std.random;
public import std.algorithm.comparison : clamp;

import bindbc.sdl;

import etabli.core.stream;
import etabli.core.vec3;

/// An RGB color structure.
struct Color {
    /// Basic color.
    static const Color red = Color(1f, 0f, 0f);
    /// Ditto
    static const Color lime = Color(0f, 1f, 0f);
    /// Ditto
    static const Color blue = Color(0f, 0f, 1f);
    /// Ditto
    static const Color white = Color(1f, 1f, 1f);
    /// Ditto
    static const Color black = Color(0f, 0f, 0f);
    /// Ditto
    static const Color yellow = Color(1f, 1f, 0f);
    /// Ditto
    static const Color cyan = Color(0f, 1f, 1f);
    /// Ditto
    static const Color magenta = Color(1f, 0f, 1f);
    /// Ditto
    static const Color silver = Color(.75f, .75f, .75f);
    /// Ditto
    static const Color gray = Color(.5f, .5f, .5f);
    /// Ditto
    static const Color grey = Color(.5f, .5f, .5f);
    /// Ditto
    static const Color maroon = Color(.5f, 0f, 0f);
    /// Ditto
    static const Color olive = Color(.5f, .5f, 0f);
    /// Ditto
    static const Color green = Color(0f, .5f, 0f);
    /// Ditto
    static const Color purple = Color(.5f, 0f, .5f);
    /// Ditto
    static const Color teal = Color(.5f, 0f, .5f);
    /// Ditto
    static const Color navy = Color(0f, 0f, .5f);
    /// Ditto
    static const Color pink = Color(1f, .75f, .8f);
    /// Ditto
    static const Color orange = Color(1f, .65f, 0f);

    static @property {
        /// Random RGB color.
        Color random() {
            return Color(uniform01(), uniform01(), uniform01());
        }
    }

    static {
        /// Take a 0xFFFFFF color format.
        Color fromHex(int rgbValue) {
            return Color((rgbValue >> 16) & 0xFF, (rgbValue >> 8) & 0xFF, rgbValue & 0xFF);
        }
    }

    @property {
        /// Red component, between 0 and 1.
        float r() const {
            return _r;
        }
        /// Ditto
        float r(float red) {
            return _r = clamp(red, 0f, 1f);
        }

        /// Green component, between 0 and 1.
        float g() const {
            return _g;
        }
        /// Ditto
        float g(float green) {
            return _g = clamp(green, 0f, 1f);
        }

        /// Blue component, between 0 and 1.
        float b() const {
            return _b;
        }
        /// Ditto
        float b(float blue) {
            return _b = clamp(blue, 0f, 1f);
        }

        /// Convert to Vec3
        Vec3f rgb() const {
            return Vec3f(_r, _g, _b);
        }
        /// Convert from Vec3
        Vec3f rgb(Vec3f v) {
            set(v.x, v.y, v.z);
            return v;
        }
    }

    private {
        float _r = 0f, _g = 0f, _b = 0f;
    }

    /// Sets the RGB values, between 0 and 1.
    this(float red, float green, float blue) {
        _r = clamp(red, 0f, 1f);
        _g = clamp(green, 0f, 1f);
        _b = clamp(blue, 0f, 1f);
    }

    /// Sets the RGB values, between 0 and 1.
    this(Vec3f v) {
        _r = clamp(v.x, 0f, 1f);
        _g = clamp(v.y, 0f, 1f);
        _b = clamp(v.z, 0f, 1f);
    }

    /// Sets the RGB values, between 0 and 255.
    this(int red, int green, int blue) {
        _r = clamp(red, 0, 255) / 255f;
        _g = clamp(green, 0, 255) / 255f;
        _b = clamp(blue, 0, 255) / 255f;
    }

    /// Sets the RGB values, between 0 and 1.
    void set(float red, float green, float blue) {
        _r = clamp(red, 0f, 1f);
        _g = clamp(green, 0f, 1f);
        _b = clamp(blue, 0f, 1f);
    }

    /// Sets the RGB values, between 0 and 255.
    void set(int red, int green, int blue) {
        _r = clamp(red, 0, 255) / 255f;
        _g = clamp(green, 0, 255) / 255f;
        _b = clamp(blue, 0, 255) / 255f;
    }

    /// Binary operations
    Color opBinary(string op)(const Color c) const {
        return mixin("Color(_r " ~ op ~ " c._r, _g " ~ op ~ " c._g, _b " ~ op ~ " c._b)");
    }

    /// Binary operations
    Color opBinary(string op)(float s) const {
        return mixin("Color(_r " ~ op ~ " s, _g " ~ op ~ " s, _b " ~ op ~ " s)");
    }

    /// Binary operations
    Color opBinaryRight(string op)(float s) const {
        return mixin("Color(s " ~ op ~ " _r, s " ~ op ~ " _g, s " ~ op ~ " _b)");
    }

    /// Binary operations
    Color opOpAssign(string op)(const Color c) {
        mixin("
			_r = clamp(_r "
                ~ op ~ "c._r, 0f, 1f);
			_g = clamp(_g "
                ~ op
                ~ "c._g, 0f, 1f);
			_b = clamp(_b "
                ~ op ~ "c._b, 0f, 1f);
			");
        return this;
    }

    /// Assignment
    Color opOpAssign(string op)(float s) {
        mixin("s = clamp(s, 0f, 1f);_r = _r" ~ op ~ "s;_g = _g" ~ op ~ "s;_b = _b" ~ op ~ "s;");
        return this;
    }

    /// Read from an InStream.
    void load(InStream stream) {
        _r = stream.read!float;
        _g = stream.read!float;
        _b = stream.read!float;
    }

    /// Write to an OutStream.
    void save(OutStream stream) {
        stream.write!float(_r);
        stream.write!float(_g);
        stream.write!float(_b);
    }

    /// Get the SDL struct format for colors.
    SDL_Color toSDL() const {
        SDL_Color sdlColor = {
            cast(ubyte)(_r * 255f), cast(ubyte)(_g * 255f), cast(ubyte)(_b * 255f)
        };
        return sdlColor;
    }

    /// Return a 0xFFFFFF color format.
    int toHex() const {
        SDL_Color color = toSDL();
        return (color.r << 16) | (color.g << 8) | color.b;
    }
}

/// Mix 50% of one color with 50% of another.
Color mix(Color c1, Color c2) {
    return Color((c1._r + c2._r) / 2f, (c1._g + c2._g) / 2f, (c1._b + c2._b) / 2f);
}
