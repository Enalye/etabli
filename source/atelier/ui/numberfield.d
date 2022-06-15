/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module atelier.ui.numberfield;

import std.utf;
import std.conv : to;
import std.string : indexOf;
import atelier.core, atelier.render, atelier.common;
import atelier.ui.gui_element, atelier.ui.label;

/// Editable field.
class NumberField : GuiElement {
    private {
        Label _label;
        Color _borderColor;
        float _caretAlpha = 1f;
        string _text;
        Timer _timer;
        uint _caretIndex = 0U, _selectionIndex = 0u;
        Vec2f _caretPosition = Vec2f.zero, _selectionPosition = Vec2f.zero;
        int _maxValue = int.max;
        bool _isUnsigned;
    }

    @property {
        /// The field value
        int value() const {
            int value_;
            try {
                value_ = to!int(_text);
            }
            catch (Exception e) {
            }
            return value_;
        }
        /// Ditto
        int value(int value_) {
            if (_isUnsigned && value_ < 0)
                value_ = -value_;

            _text = to!string(value_);
            _caretIndex = to!uint(_text.length);
            _selectionIndex = _caretIndex;
            _label.text = _text;
            return value_;
        }

        /// Label font
        Font font() {
            return _label.font;
        }
        /// Ditto
        Font font(Font font_) {
            return _label.font = font_;
        }

        /// Maximum value
        int maxValue() const {
            return _maxValue;
        }
        /// Ditto
        int maxValue(int maxValue_) {
            if (_isUnsigned && maxValue_ < 0)
                maxValue_ = 0;
            _maxValue = maxValue_;

            int currentValue;
            try {
                currentValue = to!int(_text);
            }
            catch (Exception e) {
            }
            if (currentValue > _maxValue) {
                _text = to!string(_maxValue);
                _label.text = _text;
            }
            if (_caretIndex > _text.length)
                _caretIndex = cast(uint) _text.length;
            return _maxValue;
        }

        /// Does the field allow negative values or not ?
        bool isUnsigned() const {
            return _isUnsigned;
        }
        /// Ditto
        bool isUnsigned(bool isUnsigned_) {
            _isUnsigned = isUnsigned_;

            if (_isUnsigned) {
                if (_maxValue < 0)
                    _maxValue = 0;

                int currentValue = value();
                if(currentValue < 0)
                    value = 0;
            }
            return _isUnsigned;
        }
    }

    /// Color of the numberfield's selection area
    Color selectionColor = Color(.23f, .30f, .37f);
    /// Color of the numberfield's cursor
    Color caretColor = Color.white;

    /// The size is used to setup a canvas, avoid resizing too often. \
    /// Set startWithFocus to true if you want the numberfield to accept inputs immediatly.
    this(Vec2f size_, int defaultValue = 0, bool startWithFocus = false) {
        size = size_;
        _text = to!string(defaultValue);
        _label = new Label(_text, new TrueTypeFont(veraMonoFontData));
        _label.setAlign(GuiAlignX.left, GuiAlignY.center);
        appendChild(_label);

        hasFocus = startWithFocus;
        _caretIndex = to!uint(_text.length);
        _selectionIndex = _caretIndex;

        _borderColor = Color.white;
        _caretAlpha = 1f;
        _timer.mode = Timer.Mode.bounce;
        _timer.start(1f);
        hasCanvas(true);
    }

    private void insertText(string textInput_) {
        string textInput;
        foreach (ch; textInput_) {
            if (ch >= '0' && ch <= '9') {
                textInput ~= ch;
            }
            else if (ch == '-' && !_isUnsigned) {
                if (_text.length) {
                    if (_text[0] != '-') {
                        _text = '-' ~ _text;
                        _caretIndex++;
                        _selectionIndex++;
                    }
                }
                else {
                    _text = '-' ~ _text;
                    _caretIndex++;
                    _selectionIndex++;
                }
            }
            else if (ch == '+') {
                if (_text.length) {
                    if (_text[0] == '-') {
                        _text = _text[1 .. $];
                        if (_caretIndex > 0)
                            _caretIndex--;
                        if (_selectionIndex > 0)
                            _selectionIndex--;
                    }
                }
            }
        }
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
        string txt = _label.text;
        if (_selectionIndex == _caretIndex || (txt.length == 0)) {
            return "";
        }
        const int minIndex = min(_selectionIndex, _caretIndex);
        const int maxIndex = max(_selectionIndex, _caretIndex);
        txt = txt[minIndex .. maxIndex];
        return txt;
    }

    override void onEvent(Event event) {
        if (hasFocus) {
            switch (event.type) with (Event.Type) {
            case keyInput:
                if (_caretIndex >= _maxValue)
                    break;
                insertText(event.input.text);
                break;
            case keyDown:
                switch (event.key.button) with (KeyButton) {
                case up:
                    int currentValue = value();
                    if (currentValue < _maxValue) {
                        value = currentValue + 1;
                        triggerCallback();
                    }
                    break;
                case down:
                    int currentValue = value();
                    if (!_isUnsigned || currentValue > 0) {
                        value = currentValue - 1;
                        triggerCallback();
                    }
                    break;
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
                            insertText(getClipboard());
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
}
