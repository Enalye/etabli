/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module etabli.ui.menu.item;

import etabli.common;
import etabli.core;
import etabli.render;
import etabli.ui.button;
import etabli.ui.core;
import etabli.ui.menu.bar;

final class MenuItem : TextButton!RoundedRectangle {
    private {
        RoundedRectangle _background;
        Label _label;
        MenuBar _bar;
        uint _id;
    }

    this(MenuBar bar, uint id, string text) {
        super(text);
        _bar = bar;
        _id = id;

        setAlign(UIAlignX.left, UIAlignY.top);
        setFxColor(Etabli.theme.neutral);
        setTextColor(Etabli.theme.onNeutral);
        setPadding(Vec2f(48f, 8f));
        setTextAlign(UIAlignX.left, 16f);

        _background = RoundedRectangle.fill(getSize(), Etabli.theme.corner);
        _background.color = Etabli.theme.accent;
        _background.anchor = Vec2f.zero;
        _background.alpha = 1f;
        _background.isVisible = false;
        addImage(_background);

        addEventListener("mouseenter", { _background.isVisible = true; });
        addEventListener("mouseleave", { _background.isVisible = false; });
        addEventListener("click", { _bar.toggleMenu(_id); });
        addEventListener("size", { _background.size = getSize(); });
    }
}
