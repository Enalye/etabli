/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module etabli.ui.button.icon;

import etabli.common;
import etabli.core;
import etabli.render;
import etabli.ui.core;
import etabli.ui.button.button;

final class IconButton : Button!RoundedRectangle {
    private {
        RoundedRectangle _background;
        Icon _icon;
    }

    this(string icon) {
        setFxColor(Etabli.theme.neutral);

        _icon = new Icon(icon);
        _icon.setAlign(UIAlignX.center, UIAlignY.center);
        addUI(_icon);

        setSize(_icon.getSize() + Vec2f(8f, 8f));

        _background = RoundedRectangle.fill(getSize(), Etabli.theme.corner);
        _background.color = Etabli.theme.neutral;
        _background.anchor = Vec2f.zero;
        _background.alpha = .5f;
        _background.isVisible = false;
        addImage(_background);

        addEventListener("mouseenter", &_onMouseEnter);
        addEventListener("mouseleave", &_onMouseLeave);

        addEventListener("enable", &_onEnable);
        addEventListener("disable", &_onDisable);
    }

    void setIcon(string icon) {
        _icon.setIcon(icon);
        setSize(_icon.getSize() + Vec2f(8f, 8f));
    }

    private void _onEnable() {
        addEventListener("mouseenter", &_onMouseEnter);
        addEventListener("mouseleave", &_onMouseLeave);
    }

    private void _onDisable() {
        _background.isVisible = false;
        removeEventListener("mouseenter", &_onMouseEnter);
        removeEventListener("mouseleave", &_onMouseLeave);
    }

    private void _onMouseEnter() {
        _background.isVisible = true;
    }

    private void _onMouseLeave() {
        _background.isVisible = false;
    }
}
