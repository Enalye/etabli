/**
    Label

    Copyright: (c) Enalye 2017
    License: Zlib
    Authors: Enalye
*/

module atelier.ui.label;

import std.string;

import derelict.sdl2.sdl;
import derelict.sdl2.ttf;

import atelier.core;
import atelier.common;

import atelier.render.texture;
import atelier.render.sprite;
import atelier.render.font;

import atelier.ui.widget;

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