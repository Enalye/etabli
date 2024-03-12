module etabli.ui.label;

import std.algorithm.comparison : min;
import std.conv : to;
import std.math : abs;
import std.stdio;

import etabli.common, etabli.render;
import etabli.ui.element;

/// Label
final class Label : UIElement {
    private {
        dstring _text;
        Font _font;
        float _charScale = 1f, _charSpacing = 0f;
    }

    @property {
        /// Texte affiché
        string text() const {
            return to!string(_text);
        }
        /// Ditto
        string text(string text_) {
            _text = to!dstring(text_);
            _reload();
            return text_;
        }

        /// La police de caractère utilisée
        Font font() const {
            return cast(Font) _font;
        }
        /// Ditto
        Font font(Font font_) {
            _font = font_;
            _reload();
            return _font;
        }

        /// Espacement additionnel entre chaque lettre
        float charSpacing() const {
            return _charSpacing;
        }
        /// Ditto
        float charSpacing(float charSpacing_) {
            return _charSpacing = charSpacing_;
        }
    }

    /// Constructor
    this(string text_ = "", Font font_ = getDefaultFont()) {
        _text = to!dstring(text_);
        _font = font_;
        _reload();
        isEnabled = false;

        addEventListener("draw", &_onDraw);
    }

    private void _onDraw() {
        Vec2f pos = Vec2f.zero;
        dchar prevChar;
        foreach (dchar ch; _text) {
            if (ch == '\n') {
                pos.x = 0f;
                pos.y += _font.lineSkip * _charScale;
                prevChar = 0;
            }
            else {
                Glyph metrics = _font.getMetrics(ch);
                if (!metrics.exists)
                    continue;
                pos.x += _font.getKerning(prevChar, ch) * _charScale;

                float x = pos.x + metrics.offsetX * _charScale;
                float y = pos.y - metrics.offsetY * _charScale;

                metrics.draw(Vec2f(x, y), _charScale, Color.white, 1f);
                pos.x += (metrics.advance + _charSpacing) * _charScale;
                prevChar = ch;
            }
        }
    }

    size_t getIndexOf(Vec2f position_) {
        size_t index;
        Vec2f currentPosition = Vec2f(0f, _font.ascent - _font.descent) * _charScale / 2f;
        Vec2f nearestDelta = Vec2f.zero;
        size_t nearestIndex = 0;
        bool isInit = true;

        dchar prevChar;
        float advance = 0f;
        for (; index < _text.length; ++index) {
            dchar ch = _text[index];

            if (ch == '\n') {
                currentPosition.y += _font.lineSkip * _charScale;
                if (!isInit && abs(position_.y - currentPosition.y) > nearestDelta.y) {
                    break;
                }
                currentPosition.x = 0f;
            }
            else {
                const Glyph metrics = _font.getMetrics(ch);
                bool half;
                if (currentPosition.x == 0f) {
                    half = true;
                }
                advance = 0f;
                advance += _font.getKerning(prevChar, ch) * _charScale;
                advance += metrics.advance * _charScale;
                currentPosition.x += advance;
                if (half) {
                    currentPosition.x /= 2f;
                }

                Vec2f delta = Vec2f(abs(position_.y - currentPosition.y),
                    abs(position_.x - currentPosition.x));

                if (isInit) {
                    isInit = false;
                    nearestDelta = delta;
                }

                if (delta.x <= nearestDelta.x && delta.y <= nearestDelta.y) {
                    nearestDelta = delta;
                    nearestIndex = index;
                }
                prevChar = ch;
            }
        }

        if (_text.length && position_.x > (currentPosition.x + advance / 2f)) {
            nearestIndex ++;
        }

        return nearestIndex;
    }

    Vec2f getTextSize(size_t start = 0, size_t end = size_t.max) {
        start = min(start, _text.length);
        end = min(end, _text.length);

        Vec2f totalSize_ = Vec2f(0f, _font.ascent - _font.descent) * _charScale;
        float lineWidth = 0f;

        dchar prevChar;
        for (; start < end; ++start) {
            dchar ch = _text[start];

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

        return totalSize_;
    }

    private void _reload() {
        setSize(getTextSize());
    }
}
