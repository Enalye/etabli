/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module etabli.ui.button.neutral;

import etabli.common;
import etabli.core;
import etabli.render;
import etabli.ui.button.button;

final class NeutralButton : TextButton!RoundedRectangle {
    private {
        RoundedRectangle _background;
    }

    this(string text_) {
        super(text_);

        setFxColor(Etabli.theme.neutral);
        setTextColor(Etabli.theme.onNeutral);

        _background = RoundedRectangle.fill(getSize(), Etabli.theme.corner);
        _background.color = Etabli.theme.neutral;
        _background.anchor = Vec2f.zero;
        addImage(_background);

        addEventListener("mouseenter", &_onMouseEnter);
        addEventListener("mouseleave", &_onMouseLeave);

        addEventListener("enable", &_onEnable);
        addEventListener("disable", &_onDisable);
    }

    private void _onEnable() {
        _background.alpha = Etabli.theme.activeOpacity;
        _background.color = Etabli.theme.neutral;
        setTextColor(Etabli.theme.onNeutral);

        addEventListener("mouseenter", &_onMouseEnter);
        addEventListener("mouseleave", &_onMouseLeave);
    }

    private void _onDisable() {
        _background.alpha = Etabli.theme.inactiveOpacity;
        _background.color = Etabli.theme.neutral;
        setTextColor(Etabli.theme.neutral);

        removeEventListener("mouseenter", &_onMouseEnter);
        removeEventListener("mouseleave", &_onMouseLeave);
    }

    private void _onMouseEnter() {
        Color rgb = Etabli.theme.neutral;
        HSLColor hsl = HSLColor.fromColor(rgb);
        hsl.l = hsl.l * .8f;
        _background.color = hsl.toColor();
    }

    private void _onMouseLeave() {
        _background.color = Etabli.theme.neutral;
    }
}
