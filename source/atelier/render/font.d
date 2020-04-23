/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module atelier.render.font;

import std.string;

import bindbc.sdl, bindbc.sdl.ttf;

import atelier.core;
import atelier.render.texture;

private {
    Font _defaultFont;
}

void setDefaultFont(Font font) {
    _defaultFont = font;
}

Font getDefaultFont() {
    return _defaultFont;
}

/// Information about a single character
struct GlyphMetrics {
	@property {
		/// Is the character defined ?
		bool exists() const { return _exists; }
		/// Width to advance cursor from previous position.
		int advance() const { return _advance; }
		/// Offset
		int offsetX() const { return _offsetX; }
		/// Ditto
		int offsetY() const { return _offsetY; }
		/// Character size
		int width() const { return _width; }
		/// Ditto
		int height() const { return _height; }
	}

	private {
		bool _exists;
		/// Width to advance cursor from previous position.
		int _advance;
		/// Offset
		int _offsetX, _offsetY;
		/// Character size
		int _width, _height;
		/// Coordinates in texture
		int _packX, _packY;
		/// Texture
		Texture _texture;
	}

	/// Render glyph
	void draw(Vec2f position, int scale, Color color) {
		_texture.setColorMod(color, Blend.alpha);
		_texture.draw(position, Vec2f(_width, _height) * scale, Vec4i(_packX, _packY, _width, _height), Vec2f.zero);
	}
}

/// Font that renders text to texture.
interface Font {
	@property {
		/// Is the font loaded ?
		bool isLoaded() const;
	}
	/// Renders the given text to a texture.
	Texture render(string text);
}

/// Font from a texture atlas.
final class PixelFont {
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
    this(PixelFont font) {
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

    GlyphMetrics getMetrics(dchar character) {
        for(int i; i < _charCount; ++ i) {
			if(_chars[i] == character) {
				GlyphMetrics metrics;
				metrics._exists = true;
				metrics._advance = _advance[i];
				metrics._offsetX = _offsetX[i];
				metrics._offsetY = _offsetY[i];
				metrics._width = _width[i];
				metrics._height = _height[i];
				metrics._packX = _packX[i];
				metrics._packY = _packY[i];
				metrics._texture = _texture;
				return metrics;
			}
		}
		return GlyphMetrics();
    }
}

/// Font that load a TTF file.
final class TrueTypeFont: Font {
	private {
		TTF_Font* _trueTypeFont;
		bool _isLoaded, _ownData;
		int _size;
	}

	@property {
		//TTF_Font* font() const { return cast(TTF_Font*)_trueTypeFont; }
		/// Is the font loaded ?
		bool isLoaded() const { return _isLoaded; }
	}

	/// Default ctor
	this() {}

	/// Copy ctor
    this(TrueTypeFont font) {
        _trueTypeFont = font._trueTypeFont;
		_isLoaded = font._isLoaded;
		_size = font._size;
        _ownData = false;
	}

	/// Ctor
	this(const string path, int newSize = 16u) {
		load(path, newSize);
	}

	~this() {
		unload();
	}

	/// Load
	void load(string path, int newSize = 16u) {
		if (null != _trueTypeFont)
			TTF_CloseFont(_trueTypeFont);

		if(newSize == 0u)
			throw new Exception("Cannot render a font of size 0");

		_size = newSize;
		_trueTypeFont = TTF_OpenFont(toStringz(path), _size);

		if (null == _trueTypeFont)
			throw new Exception("Cannot load \'" ~ path ~ "\' font.");

		_isLoaded = true;
        _ownData = true;
	}

	/// Unload
	void unload() {
        if(!_ownData)
            return;
		if (null != _trueTypeFont)
			TTF_CloseFont(_trueTypeFont);

		_isLoaded = false;
	}

	/// Renders the given text to a texture.
	Texture render(string text) {
		if(!text.length)
			return null;
		SDL_Surface* surface = TTF_RenderUTF8_Blended(_trueTypeFont, toStringz(text), Color.white.toSDL());
		Texture texture = new Texture(surface);
		SDL_FreeSurface(surface);
		return texture;
	}
}