/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module etabli.ui.input.textfield;

import std.ascii;
import std.math : abs;
import std.conv : to;
import std.string : indexOf;
import std.utf;
import etabli.common;
import etabli.core;
import etabli.input;
import etabli.render;
import etabli.ui.core;

final class TextField : UIElement {
    private {
        RoundedRectangle _background, _outline;
        Rectangle _caret, _selection;
        UIElement _textContainer;
        Label _label;
        dstring _text, _allowedCharacters;
        uint _caretIndex = 0U, _selectionIndex = 0u;
        Timer _timer;
        uint _limit = 80u;
        float _targetOffset = 0f, _currentOffset = 0f;
        bool _updateMouseMove;
        Vec2f _innerMargins = Vec2f(4f, 4f);
    }

    @property {
        string value() const {
            return to!string(_text);
        }

        string value(string text_) {
            dstring newText = to!dstring(text_);
            if (newText == _text)
                return text_;

            _text = newText;
            _caretIndex = to!uint(_text.length);
            _selectionIndex = _caretIndex;
            _label.text = text_;
            dispatchEvent("value", false);
            return text_;
        }

        uint limit() const {
            return _limit;
        }

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

    this() {
        setSize(Vec2f(150f, 32f));
        setSizeLock(false, true);
        focusable = true;
        _timer.mode = Timer.Mode.bounce;

        _background = RoundedRectangle.fill(getSize(), Etabli.theme.corner);
        _background.anchor = Vec2f.zero;
        _background.color = Etabli.theme.background;
        addImage(_background);

        _outline = RoundedRectangle.outline(getSize(), Etabli.theme.corner, 1f);
        _outline.anchor = Vec2f.zero;
        _outline.color = Etabli.theme.neutral;
        addImage(_outline);

        _textContainer = new UIElement;
        _textContainer.setAlign(UIAlignX.left, UIAlignY.center);
        _textContainer.setSize(Vec2f(getWidth() - _innerMargins.sum(), Etabli.theme.font.size()));
        _textContainer.setPosition(Vec2f(_innerMargins.x, 0f));
        _textContainer.isEnabled = false;
        addUI(_textContainer);

        _selection = Rectangle.fill(Vec2f(2f, Etabli.theme.font.size()));
        _selection.anchor = Vec2f(0f, 0.5f);
        _selection.color = Etabli.theme.accent;
        _selection.alpha = 0.5f;
        _selection.isVisible = false;
        _textContainer.addImage(_selection);

        _caret = Rectangle.fill(Vec2f(1f, Etabli.theme.font.size()));
        _caret.anchor = Vec2f.half;
        _caret.color = Etabli.theme.onNeutral;
        _caret.isVisible = false;
        _caret.alpha = 0f;
        _textContainer.addImage(_caret);

        _label = new Label("", Etabli.theme.font);
        _label.color = Etabli.theme.onNeutral;
        _label.setPosition(Vec2f(0f, 0f));
        _label.setAlign(UIAlignX.left, UIAlignY.center);
        _textContainer.addUI(_label);

        addEventListener("mousedown", &_onMouseDown);
        addEventListener("mouserelease", &_onMouseRelease);
        addEventListener("key", &_onKeyButton);
        addEventListener("text", &_onText);
        addEventListener("focus", &_onFocus);
        addEventListener("blur", &_onBlur);
        addEventListener("update", &_onUpdate);
        addEventListener("size", &_onSize);
        addEventListener("enable", &_onEnable);
        addEventListener("disable", &_onDisable);

        _onSelectionChange();
    }

    private void _onEnable() {
        _background.alpha = Etabli.theme.activeOpacity;
        _outline.alpha = Etabli.theme.activeOpacity;
        _label.color = Etabli.theme.onNeutral;
    }

    private void _onDisable() {
        _background.alpha = Etabli.theme.inactiveOpacity;
        _outline.alpha = Etabli.theme.inactiveOpacity;
        _label.color = Etabli.theme.neutral;
    }

    private void _onSize() {
        _background.size = getSize();
        _outline.size = getSize();
        _outline.size = getSize();
        _textContainer.setSize(Vec2f(getWidth() - _innerMargins.sum(), Etabli.theme.font.size()));
        _textContainer.setPosition(Vec2f(_innerMargins.x, 0f));
        _onSelectionChange();
    }

    private uint getCarretPosition() {
        return cast(uint) _label.getIndexOf(getMousePosition() - (
                _textContainer.getPosition() + Vec2f(_targetOffset, 0f)));
    }

    private void _onMouseDown() {
        _caretIndex = getCarretPosition();
        _selectionIndex = _caretIndex;
        _onSelectionChange();
        addEventListener("mousemove", &_onMouseMove);
    }

    private void _onMouseRelease() {
        removeEventListener("mousemove", &_onMouseMove);
        _updateMouseMove = false;
    }

    private void _onMouseMove() {
        if (!hasFocus())
            return;
        _caretIndex = getCarretPosition();
        _onSelectionChange(true);
    }

    private void _onFocus() {
        addEventListener("update", &_onFocusUpdate);
        _timer.start(60);
        _caret.isVisible = true;
        _outline.color = Etabli.theme.accent;
    }

    private void _onBlur() {
        removeEventListener("update", &_onFocusUpdate);
        _timer.stop();
        _caret.isVisible = false;
        _selection.isVisible = false;
        _outline.color = Etabli.theme.neutral;
        _updateMouseMove = false;
        _selectionIndex = _caretIndex;
    }

    private void _onUpdate() {
        Vec2f caretPos = Vec2f(_label.getTextSize(0, _caretIndex).x, _textContainer.getHeight() / 2f);

        _currentOffset = lerp(_currentOffset, _targetOffset, 0.25f);
        _label.setPosition(Vec2f(_currentOffset, 0f));
        _caret.position = caretPos + Vec2f(_currentOffset, 0f);

        if (_caretIndex != _selectionIndex) {
            Vec2f selectionPosition = Vec2f(_label.getPosition().x + _label.getTextSize(0,
                    _selectionIndex).x, _textContainer.getHeight() / 2f);

            const float minPos = min(selectionPosition.x, _caret.position.x);
            const float selectionSize = abs(selectionPosition.x - _caret.position.x);
            _selection.position = Vec2f(minPos, selectionPosition.y);
            _selection.size = Vec2f(selectionSize, _label.getHeight());
        }
    }

    private void _onFocusUpdate() {
        _timer.update();
        _caret.alpha = lerp(0.5f, 1f, easeInOutSine(_timer.value01()));
        if (_updateMouseMove)
            _onMouseMove();
    }

    private void _onSelectionChange(bool byMouse = false) {
        float border = 8f;
        Vec2f caretPos = Vec2f(_label.getTextSize(0, _caretIndex).x, _textContainer.getHeight() / 2f);

        if (caretPos.x + _targetOffset > _textContainer.getWidth() - border) {
            _updateMouseMove = byMouse;
            _targetOffset = _textContainer.getWidth() - (border + caretPos.x);
        }
        else if (caretPos.x + _targetOffset < border) {
            _updateMouseMove = byMouse;
            _targetOffset = border - caretPos.x;
        }

        if (_caretIndex != _selectionIndex) {
            _selection.isVisible = true;

            Vec2f selectionPosition = Vec2f(_label.getPosition().x + _label.getTextSize(0,
                    _selectionIndex).x, _textContainer.getHeight() / 2f);

            const float minPos = min(selectionPosition.x, _caret.position.x);
            const float selectionSize = abs(selectionPosition.x - _caret.position.x);
            _selection.position = Vec2f(minPos, selectionPosition.y);
            _selection.size = Vec2f(selectionSize, _label.getHeight());
        }
        else {
            _selection.isVisible = false;
        }
    }

    private void _onKeyButton() {
        if (!Etabli.ui.input.isPressed())
            return;

        InputEvent.KeyButton ev = Etabli.ui.input.asKeyButton();

        switch (ev.button) with (InputEvent.KeyButton.Button) {
        case right:
            if (_selectionIndex != _caretIndex) {
                if (!Etabli.input.isPressed(InputEvent.KeyButton.Button.leftShift) &&
                    !Etabli.input.isPressed(InputEvent.KeyButton.Button.rightShift)) {
                    uint maxPos = max(_selectionIndex, _caretIndex);
                    _selectionIndex = maxPos;
                    _caretIndex = maxPos;
                }
                else if (_caretIndex < _text.length) {
                    if (Etabli.input.isPressed(InputEvent.KeyButton.Button.leftControl)) {
                        _moveWordBorder(1);
                    }
                    else {
                        _caretIndex++;
                    }
                }
            }
            else {
                if (_caretIndex < _text.length) {
                    if (Etabli.input.isPressed(InputEvent.KeyButton.Button.leftControl)) {
                        _moveWordBorder(1);
                    }
                    else {
                        _caretIndex++;
                    }
                }
                if (!Etabli.input.isPressed(InputEvent.KeyButton.Button.leftShift) &&
                    !Etabli.input.isPressed(InputEvent.KeyButton.Button.rightShift)) {
                    _selectionIndex = _caretIndex;
                }
            }
            _onSelectionChange();
            break;
        case left:
            if (_selectionIndex != _caretIndex) {
                if (!Etabli.input.isPressed(InputEvent.KeyButton.Button.leftShift) &&
                    !Etabli.input.isPressed(InputEvent.KeyButton.Button.rightShift)) {
                    uint minPos = min(_selectionIndex, _caretIndex);
                    _selectionIndex = minPos;
                    _caretIndex = minPos;
                }
                else if (_caretIndex > 0U) {
                    if (Etabli.input.isPressed(InputEvent.KeyButton.Button.leftControl)) {
                        _moveWordBorder(-1);
                    }
                    else {
                        _caretIndex--;
                    }
                }
            }
            else {
                if (_caretIndex > 0U) {
                    if (Etabli.input.isPressed(InputEvent.KeyButton.Button.leftControl)) {
                        _moveWordBorder(-1);
                    }
                    else {
                        _caretIndex--;
                    }
                }
                if (!Etabli.input.isPressed(InputEvent.KeyButton.Button.leftShift) &&
                    !Etabli.input.isPressed(InputEvent.KeyButton.Button.rightShift)) {
                    _selectionIndex = _caretIndex;
                }
            }
            _onSelectionChange();
            break;
        case remove:
            _removeSelection(1);
            break;
        case backspace:
            _removeSelection(-1);
            break;
        case end:
            _caretIndex = cast(uint) _text.length;
            if (!Etabli.input.isPressed(InputEvent.KeyButton.Button.leftShift) &&
                !Etabli.input.isPressed(InputEvent.KeyButton.Button.rightShift)) {
                _selectionIndex = _caretIndex;
            }
            _onSelectionChange();
            break;
        case home:
            _caretIndex = 0;
            if (!Etabli.input.isPressed(InputEvent.KeyButton.Button.leftShift) &&
                !Etabli.input.isPressed(InputEvent.KeyButton.Button.rightShift)) {
                _selectionIndex = _caretIndex;
            }
            _onSelectionChange();
            break;
        case v:
            if (Etabli.input.isPressed(InputEvent.KeyButton.Button.leftControl) ||
                Etabli.input.isPressed(InputEvent.KeyButton.Button.rightControl)) {
                if (Etabli.input.hasClipboard()) {
                    _insertText(to!dstring(Etabli.input.getClipboard()));
                }
            }
            break;
        case c:
            if (Etabli.input.isPressed(InputEvent.KeyButton.Button.leftControl) ||
                Etabli.input.isPressed(InputEvent.KeyButton.Button.rightControl)) {
                Etabli.input.setClipboard(_getSelection());
            }
            break;
        case x:
            if (Etabli.input.isPressed(InputEvent.KeyButton.Button.leftControl) ||
                Etabli.input.isPressed(InputEvent.KeyButton.Button.rightControl)) {
                Etabli.input.setClipboard(_getSelection());
                _removeSelection(0);
            }
            break;
        case q:
            if (Etabli.input.isPressed(InputEvent.KeyButton.Button.leftControl) ||
                Etabli.input.isPressed(InputEvent.KeyButton.Button.rightControl)) {
                _caretIndex = cast(uint) _text.length;
                _selectionIndex = 0U;
                _onSelectionChange();
            }
            break;
        case enter:
        case enter2:
            dispatchEvent("validate", false);
            break;
        default:
            return;
        }
    }

    private void _onText() {
        if (_caretIndex >= _limit)
            return;
        const auto textInput = to!dstring(Etabli.ui.input.asTextInput().text);
        if (_allowedCharacters.length) {
            if (indexOf(_allowedCharacters, textInput) == -1)
                return;
        }
        _insertText(textInput);
    }

    private void _insertText(dstring textInput) {
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
        _onSelectionChange();
        dispatchEvent("value", false);
    }

    private void _moveWordBorder(int direction) {
        int currentIndex = cast(int) _caretIndex;
        if (direction > 0) {
            for (; currentIndex < _text.length; ++currentIndex) {
                if (isPunctuation(_text[currentIndex]) || isWhite(_text[currentIndex])) {
                    if (currentIndex == _caretIndex)
                        currentIndex++;
                    break;
                }
            }
            _caretIndex = currentIndex;
        }
        else {
            currentIndex--;
            for (; currentIndex >= 0; --currentIndex) {
                if (isPunctuation(_text[currentIndex]) || isWhite(_text[currentIndex])) {
                    if (currentIndex + 1 == _caretIndex)
                        currentIndex--;
                    break;
                }
            }
            _caretIndex = currentIndex + 1;
        }
    }

    private void _removeSelection(int direction) {
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
        _onSelectionChange();
        dispatchEvent("value", false);
    }

    private string _getSelection() {
        dstring txt = to!dstring(_label.text);
        if (_selectionIndex == _caretIndex || (txt.length == 0)) {
            return "";
        }
        const int minIndex = min(_selectionIndex, _caretIndex);
        const int maxIndex = max(_selectionIndex, _caretIndex);
        txt = txt[minIndex .. maxIndex];
        return to!string(txt);
    }

    void setAllowedCharacters(dstring allowedCharacters) {
        _allowedCharacters = allowedCharacters;
    }

    void setInnerMargin(float leftMargin, float rightMargin) {
        _innerMargins = Vec2f(leftMargin, rightMargin);
        _textContainer.setSize(Vec2f(getWidth() - _innerMargins.sum(), Etabli.theme.font.size()));
        _textContainer.setPosition(Vec2f(_innerMargins.x, 0f));
    }
}
