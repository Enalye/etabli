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

class Font {
	private {
		TTF_Font* _font;
		bool _isLoaded, _ownData;
		uint _size;
	}

	@property {
		TTF_Font* font() const { return cast(TTF_Font*)_font; }
		bool isLoaded() const { return _isLoaded; }
		float scale() const { return 16f / _size;}
	}

	this() {}

    this(Font font) {
        _font = font._font;
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
		if (null != _font)
			TTF_CloseFont(_font);

		if(newSize == 0u)
			throw new Exception("Cannot render a font of size 0");

		_size = newSize;
		_font = TTF_OpenFont(toStringz(path), _size);

		if (null == _font)
			throw new Exception("Cannot load \'" ~ path ~ "\' font.");

		_isLoaded = true;
        _ownData = true;
	}

	void unload() {
        if(!_ownData)
            return;
		if (null != _font)
			TTF_CloseFont(_font);

		_isLoaded = false;
	}
}