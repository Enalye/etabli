/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module etabli.ui.select.item;

import etabli.common;
import etabli.core;
import etabli.render;
import etabli.ui.button;
import etabli.ui.core;
import etabli.ui.select.button;

final class SelectItem : TextButton!RoundedRectangle {
    private {
        RoundedRectangle _background;
        Label _label;
        SelectButton _button;
    }

    this(SelectButton button, string text) {
        super(text);
        _button = button;

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
        addEventListener("click", { _button.value = text; _button.removeMenu(); });
        addEventListener("size", { _background.size = getSize(); });
    }
}
