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

module ui.label;

import std.string;

import derelict.sdl2.sdl;
import derelict.sdl2.ttf;

import core.all;
import common.all;

import render.texture;
import render.sprite;
import render.font;

import ui.widget;

class Label: Widget {
	private {
		string _text;
		Font _font;
		Texture _texture;
		Sprite _sprite;
		Color _color = Color.white;
	}

	@property {
		Vec2f scale() const {
			return _sprite.scale;
		}
		Vec2f scale(Vec2f s) {
			_sprite.scale = s;
			return _sprite.scale;
		}

		string text() const {
			return _text;
		}
		string text(string newText) {
			_text = newText;
			reload();
			return _text;
		}

		Font font() const {
			return cast(Font)_font;
		}
		Font font(Font newFont) {
			_font = newFont;
			reload();
			return _font;
		}

		Sprite sprite() {
			return _sprite;
		}

		Color color() const { return _color; }
		Color color(Color newColor) {
			_color = newColor;
			reload();
			return _color;
		}

		bool isLoaded() const {
			return _sprite.texture !is null;
		}
	}

	this(string newText) {
		this();
		_isInteractable = false;
		_text = newText;
		reload();
	}


	this() {
		_texture = new Texture;
		_sprite = _texture;
		_font = fetch!Font("VeraMoBd");
	}

	override void onEvent(Event event) {}
	override void update(float deltaTime) {}

	override void draw() {
		if(_text.length > 0)
			_sprite.draw(_position);
	}

	void reload() {
		if(_font is null)
			return;

		if ((_text.length > 0)  && _font.isLoaded) {
			_texture.loadFromSurface(TTF_RenderUTF8_Blended(_font.font, toStringz(_text), _color.toSDL()));

			version(Windows) {
			//Hack: On windows, TTF_Render functions for UTF8 strings
			//will randomly fail and create a 0x0 texture,
			//So we make sure that the texture is created again.
				if(_texture.width == 0)
					_texture.loadFromSurface(TTF_RenderUTF8_Blended(_font.font, toStringz(_text), _color.toSDL()));
			}
		}
		_sprite = _texture;
		_sprite.size *= _font.scale;
		_size = _sprite.size;
	}
}