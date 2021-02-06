/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module atelier.ui.label;

import std.algorithm.comparison : min;
import std.string, std.conv;
import bindbc.sdl, bindbc.sdl.ttf;
import atelier.core, atelier.common, atelier.render;
import atelier.ui.gui_element;

/// A single line of text.
final class Label : GuiElement {
    private {
        dstring _text;
        Font _font;
        int _charSpacing, _charScale = 1;
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
        int charSpacing() const {
            return _charSpacing;
        }
        /// Ditto
        int charSpacing(int charSpacing_) {
            return _charSpacing = charSpacing_;
        }

        /// Characters scaling
        int charScale() const {
            return _charScale;
        }
        /// Ditto
        int charScale(int charScale_) {
            return _charScale = charScale_;
        }
    }

    /// Build label
    this(string text_ = "", Font font = getDefaultFont()) {
        super(GuiElement.Flags.notInteractable);
        _font = font;
        _text = to!dstring(text_);
        reload();
    }

    private void reload() {
        Vec2f totalSize_ = Vec2f(0f, _font.ascent) * _charScale;
        float lineWidth = 0f;
        dchar prevChar;
        foreach (dchar ch; _text) {
            if (ch == '\n') {
                lineWidth = 0f;
                totalSize_.y += _font.lineSkip * _charScale;
            }
            else {
                const Glyph metrics = _font.getMetrics(ch);
                lineWidth += _font.getKerning(prevChar, ch) * _charScale;
                lineWidth += metrics.advance * _charScale;
                if (lineWidth > totalSize_.x)
                    totalSize_.x = lineWidth;
                prevChar = ch;
            }
        }
        size = totalSize_;
    }

    override void draw() {
        Vec2f pos = origin;
        pos.y += _font.ascent * _charScale;
        dchar prevChar;
        foreach (dchar ch; _text) {
            if (ch == '\n') {
                pos.x = origin.x;
                pos.y += _font.lineSkip * _charScale;
                prevChar = 0;
            }
            else {
                Glyph metrics = _font.getMetrics(ch);
                pos.x += _font.getKerning(prevChar, ch) * _charScale;
                Vec2f drawPos = Vec2f(pos.x + metrics.offsetX * _charScale,
                        pos.y - metrics.offsetY * _charScale);
                metrics.draw(drawPos, _charScale, color, alpha);
                pos.x += (metrics.advance + _charSpacing) * _charScale;
                prevChar = ch;
            }
        }
    }
}
