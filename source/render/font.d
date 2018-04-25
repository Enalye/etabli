/**
Grimoire
Copyright (c) 2017 Enalye

This software is provided 'as-is', without any express or implied warranty.
In no event will the authors be held liable for any damages arising
from the use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute
it freely, subject to the following restrictions:

	1. The origin of this software must not be misrepresented;
	   you must not claim that you wrote the original software.
	   If you use this software in a product, an acknowledgment
	   in the product documentation would be appreciated but
	   is not required.

	2. Altered source versions must be plainly marked as such,
	   and must not be misrepresented as being the original software.

	3. This notice may not be removed or altered from any source distribution.
*/

module render.font;

import std.string;

import derelict.sdl2.sdl;
import derelict.sdl2.ttf;

class Font {
	private {
		TTF_Font* _font;
		bool _isLoaded;
		uint _size;
	}

	@property {
		TTF_Font* font() const { return cast(TTF_Font*)_font; }
		bool isLoaded() const { return _isLoaded; }
		float scale() const { return 16f / _size;}
	}

	this() {
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
	}

	void unload() {
		if (null != _font)
			TTF_CloseFont(_font);

		_isLoaded = false;
	}
}