/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module etabli.ui.button.button;

import etabli.common;
import etabli.core;
import etabli.ui.core;
import etabli.ui.button.fx;

abstract class Button(ImageType) : UIElement {
    private {
        ButtonFx!ImageType _fx;
    }

    this() {
        focusable = true;

        _fx = new ButtonFx!ImageType(this);

        addEventListener("press", { _fx.onClick(getMousePosition()); });
        addEventListener("unpress", { _fx.onUnclick(); });
        addEventListener("mousemove", { _fx.onUpdate(getMousePosition()); });
        addEventListener("update", { _fx.update(); });
        addEventListener("draw", { _fx.draw(); });
        addEventListener("size", { _fx.onSize(); });
    }

    final void setFxColor(Color color) {
        _fx.setColor(color);
    }
}

abstract class TextButton(ImageType) : Button!ImageType {
    private {
        Vec2f _padding = Vec2f(24f, 8f);
        Label _label;
    }

    this(string text_) {
        _label = new Label(text_, Etabli.theme.font);
        _label.color = Etabli.theme.onNeutral;
        addUI(_label);

        setSize(_label.getSize() + _padding);
    }

    final Vec2f getPadding() const {
        return _padding;
    }

    final void setPadding(Vec2f padding) {
        _padding = padding;
        setSize(_label.getSize() + _padding);
    }

    void setText(string text_) {
        _label.text = text_;
        setSize(_label.getSize() + _padding);
    }

    void setTextAlign(UIAlignX alignX, float offset = 0f) {
        _label.setAlign(alignX, UIAlignY.center);
        _label.setPosition(Vec2f(offset, 0f));
    }

    void setTextColor(Color color) {
        _label.color = color;
    }
}
