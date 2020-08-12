/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module atelier.ui.label;

import std.algorithm.comparison: min;
import std.string, std.conv;
import bindbc.sdl, bindbc.sdl.ttf;
import atelier.core, atelier.common, atelier.render;
import atelier.ui.gui_element;

/// A single line of text.
final class Label: GuiElement {
	private {
		dstring _text;
		Font _font;
		int _spacing = 0;
	}

	@property {
		/// Text
		string text() const {
			return to!string(_text);
		}
		/// Ditto
		string text(string text_) {
			_text = to!dstring(text_);
			reload();
			return text_;
		}

		/// Font
		Font font() const {
			return cast(Font) _font;
		}
		/// Ditto
		Font font(Font font_) {
			_font = font_;
			reload();
			return _font;
		}

		/// Additionnal spacing between each character
		int spacing() const { return _spacing; }
		/// Ditto
		int spacing(int spacing_) { return _spacing = spacing_; }
	}

	/// Build label
	this(string text_ = "", Font font = getDefaultFont()) {
		super(GuiElement.Flags.notInteractable);
        _font = font;
		_text = to!dstring(text_);
		reload();
	}

	private void reload() {
		int scale_ = min(cast(int) scale.x, cast(int) scale.y);
		Vec2f totalSize_ = Vec2f(0f, _font.ascent - _font.descent);
		float lineWidth = 0f;
		dchar prevChar;
		foreach(dchar ch; _text) {
			if(ch == '\n') {
				lineWidth = 0f;
				totalSize_.y += _font.lineSkip;
			}
			else {
				const Glyph metrics = _font.getMetrics(ch);
				lineWidth += _font.getKerning(prevChar, ch) * scale_;
				lineWidth += metrics.advance * scale_;
				if(lineWidth > totalSize_.x)
					totalSize_.x = lineWidth;
				prevChar = ch;
			}
		}
		size = totalSize_;
	}

	override void draw() {
		int scale_ = min(cast(int) scale.x, cast(int) scale.y);
		Vec2f pos = origin;
		dchar prevChar;
		foreach(dchar ch; _text) {
			if(ch == '\n') {
				pos.x = origin.x;
				pos.y += _font.lineSkip * scale_;
				prevChar = 0;
			}
			else {
				Glyph metrics = _font.getMetrics(ch);
				pos.x += _font.getKerning(prevChar, ch) * scale_;
				Vec2f drawPos = Vec2f(pos.x + metrics.offsetX * scale_, pos.y - metrics.offsetY * scale_);
				metrics.draw(drawPos, scale_, color);
				pos.x += (metrics.advance + _spacing) * scale_;
				prevChar = ch;
			}
		}
	}
}