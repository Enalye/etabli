/**
    Label

    Copyright: (c) Enalye 2017
    License: Zlib
    Authors: Enalye
*/

module atelier.ui.label;

import std.string;
import derelict.sdl2.sdl, derelict.sdl2.ttf;
import atelier.core, atelier.common, atelier.render;
import atelier.ui.gui_element;

/// A single line of text.
final class Label: GuiElement {
	private {
		string _text;
		Font _font;
		Texture _texture;
		Sprite _sprite;
		Color _color = Color.white;
	}

	@property {
		Vec2f spriteScale() const {
			return _sprite.scale;
		}
		Vec2f spriteScale(Vec2f s) {
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

		bool isLoaded() const {
			return _sprite.texture !is null;
		}
	}

	this(Font font, string newText) {
        _font = font;
		_text = newText;
		isInteractable = false;
		_texture = new Texture;
		_sprite = new Sprite(_texture);
		reload();
	}

    this(string newText) {
        _font = getDefaultFont();
		_text = newText;
		isInteractable = false;
		_texture = new Texture;
		_sprite = new Sprite(_texture);
		reload();
	}

	this() {
		_font = getDefaultFont();
		_text = "";
		isInteractable = false;
		_texture = new Texture;
		_sprite = new Sprite(_texture);
		reload();
	}

	override void draw() {
		if(_text.length > 0 && _texture.isLoaded) {
			_sprite.color = color;
			_sprite.scale = scale;
			_sprite.draw(center);
		}
	}

	void reload() {
		if(_font is null)
			return;

		if ((_text.length > 0)  && _font.isLoaded) {
			_texture.loadFromSurface(TTF_RenderUTF8_Blended(_font.font, toStringz(_text), Color.white.toSDL()));
		}
		_sprite = _texture;
		_sprite.size *= _font.scale;
		size = _sprite.size;
	}
}