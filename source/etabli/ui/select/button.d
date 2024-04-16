/** 
 * Droits d’auteur: Enalye
 * Licence: Zlib
 * Auteur: Enalye
 */
module etabli.ui.select.button;

import std.algorithm.searching : canFind;
import etabli.common;
import etabli.core;
import etabli.render;
import etabli.ui.button;
import etabli.ui.core;
import etabli.ui.select.list;

final class SelectButton : Button!RoundedRectangle {
    private {
        RoundedRectangle _background;
        SelectList _list;
        bool _isDisplayed;
        string[] _items;
        string _value;
        Label _label;
        Color _buttonColor;
    }

    @property {
        string value() const {
            return _value;
        }

        string value(string value_) {
            if (_value == value_)
                return _value;

            if (_items.canFind(value_)) {
                _value = value_;
                _label.text = _value;
                dispatchEvent("value", false);
            }
            return _value;
        }
    }

    this(string[] items, string defaultItem, bool isAccent = false) {
        _items = items;
        _buttonColor = isAccent ? Etabli.theme.accent : Etabli.theme.neutral;

        Vec2f size = Vec2f.zero;

        _label = new Label("", Etabli.theme.font);
        _label.setAlign(UIAlignX.center, UIAlignY.center);
        _label.color = Etabli.theme.onAccent;
        addUI(_label);

        _list = new SelectList(this);
        foreach (item; _items) {
            _list.add(item);
            _label.text = item;
            size = size.max(_label.getSize());
        }

        setSize(size + Vec2f(24f, 8f));

        if (_items.length)
            _value = _items[0];
        value(defaultItem);

        setFxColor(_buttonColor);

        _background = RoundedRectangle.fill(getSize(), Etabli.theme.corner);
        _background.color = _buttonColor;
        _background.anchor = Vec2f.zero;
        addImage(_background);

        addEventListener("mouseenter", {
            Color rgb = _buttonColor;
            HSLColor hsl = HSLColor.fromColor(rgb);
            hsl.l = hsl.l * .8f;
            _background.color = hsl.toColor();
        });
        addEventListener("mouseleave", { _background.color = _buttonColor; });
        addEventListener("click", &_onClick);
    }

    private void _onClick() {
        if (_isDisplayed) {
            removeMenu();
        }
        else {
            displayMenu();
        }
    }

    package void removeMenu() {
        _list.startRemove();
    }

    package void displayMenu() {
        _list.runState("visible");
        Etabli.ui.addUI(_list);
    }
}
