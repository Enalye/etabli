/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module atelier.render.font.bitmap;

import bindbc.sdl, bindbc.sdl.ttf;
import atelier.core;
import atelier.render.texture;
import atelier.render.font.font, atelier.render.font.glyph;

/// Font from a texture atlas.
final class BitmapFont: Font {
    private {
        string _name;
        Texture _texture;
        int _size, _ascent, _descent, _charCount, _kerningCount;
        int[] _chars, _advance, _offsetX, _offsetY,
            _width, _height, _packX, _packY, _kerning;
    }

    /// Load from config file and texture.
    this(string jsonPath, string texturePath) {
		import std.file: readText;
        JSONValue json = parseJSON(readText(jsonPath));
        _name = getJsonStr(json, "name");
        _size = getJsonInt(json, "size");
        _ascent = getJsonInt(json, "ascent");
        _descent = getJsonInt(json, "descent");
        _charCount = getJsonInt(json, "char_count");
        _kerningCount = getJsonInt(json, "kerning_count");
        _chars = getJsonArrayInt(json, "chars");
        _advance = getJsonArrayInt(json, "advance");
        _offsetX = getJsonArrayInt(json, "offset_x");
        _offsetY = getJsonArrayInt(json, "offset_y");
        _width = getJsonArrayInt(json, "width");
        _height = getJsonArrayInt(json, "height");
        _packX = getJsonArrayInt(json, "pack_x");
        _packY = getJsonArrayInt(json, "pack_y");
        _kerning = getJsonArrayInt(json, "kerning");
        _texture = new Texture(texturePath, true);
    }

    /// Copy ctor
    this(BitmapFont font) {
        _name = font._name;
        _size = font._size;
        _ascent = font._ascent;
        _descent = font._descent;
        _charCount = font._charCount;
        _kerningCount = font._kerningCount;
        _chars = font._chars;
        _advance = font._advance;
        _offsetX = font._offsetX;
        _offsetY = font._offsetY;
        _width = font._width;
        _height = font._height;
        _packX = font._packX;
        _packY = font._packY;
        _kerning = font._kerning;
        _texture = new Texture(font._texture);
    }

    /// Call only after Renderer is created in main thread.
    void postload() {
        _texture.postload();
    }

    @property {
        /// Font name
        string name() const { return _name; }
        /// Default font size
        int size() const { return _size; }
        /// Where the top is above the baseline
        int ascent() const { return _ascent; }
        /// Where the bottom is below the baseline
        int descent() const { return _descent; }
		/// Distance between each baselines
        int lineSkip() const { return (_ascent - _descent) + 1; }
    }

    int getKerning(dchar prevChar, dchar currChar) {
        for(int i; i < _kerningCount; ++ i) {
            const int index = i * 3;
            if(_kerning[index] == prevChar &&
                _kerning[index + 1] == currChar) {
                return _kerning[index + 2];
            }
        }
        return 0;
    }

    Glyph getMetrics(dchar character) {
        for(int i; i < _charCount; ++ i) {
			if(_chars[i] == character) {
				Glyph metrics = Glyph(
                    true,
                    _advance[i],
                    _offsetX[i],
                    _offsetY[i],
                    _width[i],
                    _height[i],
                    _packX[i],
                    _packY[i],
                    _width[i],
                    _height[i],
                    _texture
                    );
				return metrics;
			}
		}
		return Glyph();
    }
}