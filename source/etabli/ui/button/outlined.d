/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module etabli.ui.button.outlined;

import etabli.common;
import etabli.core;
import etabli.render;
import etabli.ui.button.button;

final class OutlinedButton : TextButton!RoundedRectangle {
    private {
        RoundedRectangle _background;
    }

    this(string text_) {
        super(text_);

        setFxColor(Etabli.theme.accent);
        setTextColor(Etabli.theme.accent);

        _background = RoundedRectangle.outline(getSize(), Etabli.theme.corner, 2f);
        _background.color = Etabli.theme.accent;
        _background.anchor = Vec2f.zero;
        _background.thickness = 2f;
        addImage(_background);

        addEventListener("mouseenter", &_onMouseEnter);
        addEventListener("mouseleave", &_onMouseLeave);

        addEventListener("enable", &_onEnable);
        addEventListener("disable", &_onDisable);
    }

    private void _onEnable() {
        _background.alpha = Etabli.theme.activeOpacity;
        _background.color = Etabli.theme.accent;
        setTextColor(Etabli.theme.accent);

        addEventListener("mouseenter", &_onMouseEnter);
        addEventListener("mouseleave", &_onMouseLeave);
    }

    private void _onDisable() {
        _background.filled = false;
        _background.alpha = Etabli.theme.inactiveOpacity;
        _background.color = Etabli.theme.neutral;
        setTextColor(Etabli.theme.neutral);

        removeEventListener("mouseenter", &_onMouseEnter);
        removeEventListener("mouseleave", &_onMouseLeave);
    }

    private void _onMouseEnter() {
        setTextColor(Etabli.theme.onAccent);
        _background.filled = true;
    }

    private void _onMouseLeave() {
        setTextColor(Etabli.theme.accent);
        _background.filled = false;
    }
}
