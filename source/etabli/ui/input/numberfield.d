/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module etabli.ui.input.numberfield;

import std.algorithm.comparison : clamp;
import std.array : replace;
import std.conv : to;
import etabli.common;
import etabli.core;
import etabli.render;
import etabli.ui.button;
import etabli.ui.core;
import etabli.ui.input.textfield;

final class ControlButton : TextButton!RoundedRectangle {
    private {
        RoundedRectangle _background;
    }

    this(string text_) {
        super(text_);

        setFxColor(Etabli.theme.neutral);
        setTextColor(Etabli.theme.accent);
        setSize(Vec2f(32f, 32f));

        _background = RoundedRectangle.fill(getSize(), Etabli.theme.corner);
        _background.color = Etabli.theme.neutral;
        _background.anchor = Vec2f.zero;
        _background.alpha = .5f;
        _background.isVisible = false;
        addImage(_background);

        addEventListener("mouseenter", { _background.isVisible = true; });
        addEventListener("mouseleave", { _background.isVisible = false; });

        addEventListener("enable", &_onEnable);
        addEventListener("disable", &_onDisable);
    }

    private void _onEnable() {
        setTextColor(Etabli.theme.accent);
    }

    private void _onDisable() {
        setTextColor(Etabli.theme.neutral);
    }
}

final class NumberField : UIElement {
    private {
        TextField _textField;
        ControlButton _decrementBtn, _incrementBtn;
        float _value = 0f;
        float _step = 1f;
        float _minValue = float.nan;
        float _maxValue = float.nan;
    }

    @property {
        float value() const {
            return _value;
        }

        float value(float value_) {
            _value = clamp(value_, _minValue, _maxValue);
            _textField.value = to!string(_value);
            return _value;
        }
    }

    this() {
        setSize(Vec2f(150f, 32f));

        _textField = new TextField();
        _textField.value = "0";
        _textField.setAllowedCharacters("0123456789+-.,");
        _textField.setSize(getSize());
        _textField.setInnerMargin(4f, 70f);
        addUI(_textField);

        HBox box = new HBox;
        box.setAlign(UIAlignX.right, UIAlignY.center);
        box.setChildAlign(UIAlignY.center);
        //box.setPosition(Vec2f(2f, 0f));
        //box.setSpacing(2f);
        addUI(box);

        _decrementBtn = new ControlButton("-");
        box.addUI(_decrementBtn);

        _incrementBtn = new ControlButton("+");
        box.addUI(_incrementBtn);

        _incrementBtn.addEventListener("click", { value(_value + _step); });
        _decrementBtn.addEventListener("click", { value(_value - _step); });
        _textField.addEventListener("value", &_onValue);

        addEventListener("enable", &_onEnableChange);
        addEventListener("disable", &_onEnableChange);
    }

    private void _onEnableChange() {
        _textField.isEnabled = isEnabled;
        _decrementBtn.isEnabled = isEnabled;
        _incrementBtn.isEnabled = isEnabled;
    }

    void setRange(float minValue, float maxValue) {
        _minValue = minValue;
        _maxValue = maxValue;
        value(_value);
    }

    private void _onValue() {
        try {
            string text = _textField.value;
            text = text.replace(',', '.');
            _value = clamp(to!float(text), _minValue, _maxValue);
        }
        catch (Exception e) {
            value(0f);
        }
    }
}

final class IntegerField : UIElement {
    private {
        TextField _textField;
        ControlButton _decrementBtn, _incrementBtn;
        int _value = 0;
        int _step = 1;
        int _minValue = int.min;
        int _maxValue = int.max;
    }

    @property {
        int value() const {
            return _value;
        }

        int value(int value_) {
            _value = clamp(value_, _minValue, _maxValue);
            _textField.value = to!string(_value);
            return _value;
        }
    }

    this() {
        setSize(Vec2f(150f, 32f));

        _textField = new TextField();
        _textField.value = "0";
        _textField.setAllowedCharacters("0123456789+-");
        _textField.setSize(getSize());
        _textField.setInnerMargin(4f, 70f);
        addUI(_textField);

        HBox box = new HBox;
        box.setAlign(UIAlignX.right, UIAlignY.center);
        box.setChildAlign(UIAlignY.center);
        addUI(box);

        _decrementBtn = new ControlButton("-");
        box.addUI(_decrementBtn);

        _incrementBtn = new ControlButton("+");
        box.addUI(_incrementBtn);

        _incrementBtn.addEventListener("click", { value(_value + _step); });
        _decrementBtn.addEventListener("click", { value(_value - _step); });
        _textField.addEventListener("value", &_onValue);

        addEventListener("enable", &_onEnableChange);
        addEventListener("disable", &_onEnableChange);
    }

    private void _onEnableChange() {
        _textField.isEnabled = isEnabled;
        _decrementBtn.isEnabled = isEnabled;
        _incrementBtn.isEnabled = isEnabled;
    }

    void setRange(int minValue, int maxValue) {
        _minValue = minValue;
        _maxValue = maxValue;
        value(_value);
    }

    private void _onValue() {
        try {
            string text = _textField.value;
            _value = clamp(to!int(text), _minValue, _maxValue);
        }
        catch (Exception e) {
            value(0);
        }
    }
}
