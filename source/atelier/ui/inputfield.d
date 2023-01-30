/**
    Input field

    Copyright: (c) Enalye 2017
    License: Zlib
    Authors: Enalye
*/

module atelier.ui.inputfield;

import std.utf;
import std.conv : to;
import std.string : indexOf;
import atelier.core, atelier.render, atelier.common;
import atelier.ui.gui_element, atelier.ui.label;

/// Editable field.
class InputField : GuiElement {
    private {
        Label _label;
        Color _borderColor;
        float _caretAlpha = 1f;
        dstring _text, _allowedCharacters;
        Timer _timer;
        uint _caretIndex = 0U, _selectionIndex = 0u;
        Vec2f _caretPosition = Vec2f.zero, _selectionPosition = Vec2f.zero;
        uint _limit = 80u;
    }

    @property {
        /// The displayed text.
        string text() const {
            return to!string(_text);
        }
        /// Ditto
        string text(string text_) {
            _text = to!dstring(text_);
            _caretIndex = to!uint(_text.length);
            _selectionIndex = _caretIndex;
            _label.text = text_;
            return text_;
        }

        /// Label font
        Font font() {
            return _label.font;
        }
        /// Ditto
        Font font(Font font_) {
            return _label.font = font_;
        }

        /// Max number of characters.
        uint limit() const {
            return _limit;
        }
        /// Ditto
        uint limit(uint newLimit) {
            _limit = newLimit;
            if (_text.length > _limit) {
                _text.length = _limit;
                _label.text = to!string(_text);
            }
            if (_caretIndex > _limit)
                _caretIndex = _limit;
            return _limit;
        }
    }

    /// Color of the inputfield's selection area
    Color selectionColor = Color(.23f, .30f, .37f);
    /// Color of the inputfield's cursor
    Color caretColor = Color.white;

    /// The size is used to setup a canvas, avoid resizing too often. \
    /// Set startWithFocus to true if you want the inputfield to accept inputs immediatly.
    this(Vec2f size_, string defaultText = "", bool startWithFocus = false) {
        size = size_;
        _label = new Label(defaultText, new TrueTypeFont(veraMonoFontData));
        _label.setAlign(GuiAlignX.left, GuiAlignY.center);
        appendChild(_label);
        hasFocus = startWithFocus;
        _text = to!dstring(defaultText);
        _caretIndex = to!uint(_text.length);
        _selectionIndex = _caretIndex;

        _borderColor = Color.white;
        _caretAlpha = 1f;
        _timer.mode = Timer.Mode.bounce;
        _timer.start(1f);
        hasCanvas(true);
    }

    private void insertText(dstring textInput) {
        if (_caretIndex == _selectionIndex) {
            if (_caretIndex == _text.length)
                _text ~= textInput;
            else if (_caretIndex == 0U)
                _text = textInput ~ _text;
            else
                _text = _text[0U .. _caretIndex] ~ textInput ~ _text[_caretIndex .. $];
            _caretIndex += textInput.length;
        }
        else {
            const int minSelect = min(_caretIndex, _selectionIndex);
            const int maxSelect = max(_caretIndex, _selectionIndex);
            if (minSelect == 0U && maxSelect == _text.length) {
                _text = textInput;
                _caretIndex = cast(uint) _text.length;
            }
            else if (minSelect == 0U) {
                _text = textInput ~ _text[maxSelect .. $];
                _caretIndex = cast(uint) textInput.length;
            }
            else if (maxSelect == _text.length) {
                _text = _text[0U .. minSelect] ~ textInput;
                _caretIndex = cast(uint) _text.length;
            }
            else {
                _text = _text[0U .. minSelect] ~ textInput ~ _text[maxSelect .. $];
                _caretIndex = minSelect + cast(uint) textInput.length;
            }
        }
        _label.text = to!string(_text);
        _selectionIndex = _caretIndex;
        triggerCallback();
    }

    private void removeSelection(int direction) {
        if (_text.length) {
            if (_caretIndex == _selectionIndex) {
                if (direction > 0) {
                    if (_caretIndex == 0U)
                        _text = _text[1U .. $];
                    else if (_caretIndex != _text.length) {
                        _text = _text[0U .. _caretIndex] ~ _text[_caretIndex + 1 .. $];
                    }
                }
                else {
                    if (_caretIndex == _text.length) {
                        _text.length--;
                        _caretIndex--;
                    }
                    else if (_caretIndex != 0U) {
                        _text = _text[0U .. _caretIndex - 1] ~ _text[_caretIndex .. $];
                        _caretIndex--;
                    }
                }
            }
            else {
                const int minSelect = min(_caretIndex, _selectionIndex);
                const int maxSelect = max(_caretIndex, _selectionIndex);
                if (minSelect == 0 && maxSelect == _text.length) {
                    _text.length = 0;
                    _caretIndex = 0;
                }
                else if (minSelect == 0) {
                    _text = _text[maxSelect .. $];
                    _caretIndex = 0;
                }
                else if (maxSelect == _text.length) {
                    _text = _text[0 .. minSelect];
                    _caretIndex = minSelect;
                }
                else {
                    _text = _text[0 .. minSelect] ~ _text[maxSelect .. $];
                    _caretIndex = minSelect;
                }
            }
            _label.text = to!string(_text);
            _selectionIndex = _caretIndex;
        }
        triggerCallback();
    }

    private string getSelection() {
        dstring txt = to!dstring(_label.text);
        if (_selectionIndex == _caretIndex || (txt.length == 0)) {
            return "";
        }
        const int minIndex = min(_selectionIndex, _caretIndex);
        const int maxIndex = max(_selectionIndex, _caretIndex);
        txt = txt[minIndex .. maxIndex];
        return to!string(txt);
    }

    override void onEvent(Event event) {
        if (isLocked)
            return;

        if (hasFocus) {
            switch (event.type) with (Event.Type) {
            case keyInput:
                if (_caretIndex >= _limit)
                    break;
                const auto textInput = to!dstring(event.input.text);
                if (_allowedCharacters.length) {
                    if (indexOf(_allowedCharacters, textInput) == -1)
                        break;
                }
                insertText(textInput);
                break;
            case keyDown:
                switch (event.key.button) with (KeyButton) {
                case right:
                    if (_caretIndex < _text.length)
                        _caretIndex++;
                    if (!isButtonDown(KeyButton.leftShift) && !isButtonDown(KeyButton.rightShift)) {
                        _selectionIndex = _caretIndex;
                    }
                    break;
                case left:
                    if (_caretIndex > 0U)
                        _caretIndex--;
                    if (!isButtonDown(KeyButton.leftShift) && !isButtonDown(KeyButton.rightShift)) {
                        _selectionIndex = _caretIndex;
                    }
                    break;
                case remove:
                    removeSelection(1);
                    break;
                case backspace:
                    removeSelection(-1);
                    break;
                case end:
                    _caretIndex = cast(uint) _text.length;
                    if (!isButtonDown(KeyButton.leftShift) && !isButtonDown(KeyButton.rightShift)) {
                        _selectionIndex = _caretIndex;
                    }
                    break;
                case home:
                    _caretIndex = 0;
                    if (!isButtonDown(KeyButton.leftShift) && !isButtonDown(KeyButton.rightShift)) {
                        _selectionIndex = _caretIndex;
                    }
                    break;
                case v:
                    if (isButtonDown(KeyButton.leftControl) || isButtonDown(KeyButton.rightControl)) {
                        if (hasClipboard()) {
                            insertText(to!dstring(getClipboard()));
                        }
                    }
                    break;
                case c:
                    if (isButtonDown(KeyButton.leftControl) || isButtonDown(KeyButton.rightControl)) {
                        setClipboard(getSelection());
                    }
                    break;
                case x:
                    if (isButtonDown(KeyButton.leftControl) || isButtonDown(KeyButton.rightControl)) {
                        setClipboard(getSelection());
                        removeSelection(0);
                    }
                    break;
                case a:
                    if (isButtonDown(KeyButton.leftControl) || isButtonDown(KeyButton.rightControl)) {
                        _caretIndex = cast(uint) _text.length;
                        _selectionIndex = 0U;
                    }
                    break;
                default:
                    break;
                }
                break;
            default:
                break;
            }
        }
    }

    override void update(float deltaTime) {
        _caretPosition = Vec2f(_label.position.x + (_label.size.x / _text.length) * _caretIndex,
            _label.origin.y);
        _selectionPosition = Vec2f(_label.position.x + (
                _label.size.x / _text.length) * _selectionIndex, _label.origin.y);
        _label.position = Vec2f(10f, 0f);

        if (_caretPosition.x > canvas.position.x + canvas.size.x / 2f - 10f)
            canvas.position.x = _caretPosition.x - canvas.size.x / 2f + 10f;
        else if (_caretPosition.x < canvas.position.x - canvas.size.x / 2f + 10f)
            canvas.position.x = _caretPosition.x + canvas.size.x / 2f - 10f;

        if (hasFocus)
            _borderColor = lerp(_borderColor, Color.white, deltaTime * .25f);
        else
            _borderColor = lerp(_borderColor, Color.white * .21f, deltaTime * .1f);

        _timer.update(deltaTime);
        _caretAlpha = lerp(1f, .21f, _timer.value01);
    }

    override void draw() {
        if (_text.length && hasFocus) {
            if (_caretIndex != _selectionIndex) {
                const float minPos = min(_selectionPosition.x, _caretPosition.x);
                const float selectionSize = abs(_selectionPosition.x - _caretPosition.x);
                drawFilledRect(Vec2f(minPos, _selectionPosition.y),
                    Vec2f(selectionSize, _label.size.y), selectionColor, .7f);
            }
            drawFilledRect(_caretPosition, Vec2f(2f, _label.size.y), caretColor, _caretAlpha);
        }
    }

    override void drawOverlay() {
        drawRect(origin, size, _borderColor);
    }

    /// Resets the text.
    void clear() {
        _text.length = 0L;
        _caretIndex = 0u;
        _selectionIndex = 0u;
        _label.text = "";
    }

    /// It will discard any characters from keyboard that aren't in this list.
    void setAllowedCharacters(dstring allowedCharacters) {
        _allowedCharacters = allowedCharacters;
    }
}
