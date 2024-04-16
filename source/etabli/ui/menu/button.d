/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module etabli.ui.menu.button;

import etabli.common;
import etabli.core;
import etabli.render;
import etabli.ui.button;
import etabli.ui.core;
import etabli.ui.menu.bar;

final class MenuButton : TextButton!RoundedRectangle {
    private {
        RoundedRectangle _background;
        MenuBar _bar;
        Label _label;
        uint _id;
    }

    this(MenuBar bar, uint id, string text) {
        super(text);
        _bar = bar;
        _id = id;

        setFxColor(Etabli.theme.neutral);
        setTextColor(Etabli.theme.onNeutral);

        _background = RoundedRectangle.fill(getSize(), Etabli.theme.corner);
        _background.color = Etabli.theme.neutral;
        _background.anchor = Vec2f.zero;
        _background.alpha = .5f;
        _background.isVisible = false;
        addImage(_background);

        addEventListener("mouseenter", {
            _background.isVisible = true;
            _bar.switchMenu(_id);
        });
        addEventListener("mouseleave", {
            _background.isVisible = false;
            _bar.leaveMenu(_id);
        });
        addEventListener("click", { _bar.toggleMenu(_id); });
    }
}
