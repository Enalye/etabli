/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module etabli.ui.menu.separator;

import etabli.common;
import etabli.core;
import etabli.render;
import etabli.ui.button;
import etabli.ui.core;
import etabli.ui.menu.bar;

final class MenuSeparator : UIElement {
    private {
        Rectangle _line;
    }

    this() {
        _line = new Rectangle(Vec2f(getWidth(), 2f), true, 2f);
        _line.color = Etabli.theme.neutral;
        _line.anchor = Vec2f(0f, 0.5f);
        _line.alpha = 1f;
        addImage(_line);

        addEventListener("size", { _line.size = Vec2f(getWidth(), 2f); });
    }
}
