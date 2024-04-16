/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module etabli.ui.panel.modal;

import etabli.common;
import etabli.core;
import etabli.render;
import etabli.ui.core;

class Modal : UIElement {
    private {
        RoundedRectangle _background, _outline;
    }

    this() {
        movable = true;

        _background = RoundedRectangle.fill(getSize(), Etabli.theme.corner);
        _background.anchor = Vec2f.zero;
        _background.color = Etabli.theme.surface;
        addImage(_background);

        _outline = RoundedRectangle.outline(getSize(), Etabli.theme.corner, 1f);
        _outline.anchor = Vec2f.zero;
        _outline.color = Etabli.theme.neutral;
        addImage(_outline);

        addEventListener("size", &_onSizeChange);
    }

    private void _onSizeChange() {
        _background.size = getSize();
        _outline.size = getSize();
    }
}
