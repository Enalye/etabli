/**
    Font

    Copyright: (c) Enalye 2017
    License: Zlib
    Authors: Enalye
*/

module atelier.render.font;

import std.string;

import derelict.sdl2.sdl;
import derelict.sdl2.ttf;

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

/// Font that renders text to texture.
interface Font {
	@property {
		/// Is the font loaded ?
		bool isLoaded() const;
	}
	/// Renders the given text to a texture.
	Texture render(string text);
}

/// Font that load a TTF file.
final class TrueTypeFont: Font {
	private {
		TTF_Font* _trueTypeFont;
		bool _isLoaded, _ownData;
		uint _size;
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

	this(const string path, uint newSize = 16u) {
		load(path, newSize);
	}

	~this() {
		unload();
	}

	void load(string path, uint newSize = 16u) {
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