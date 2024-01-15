/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module etabli.ciel.button.button;

import etabli.ui;

import etabli.common;
import etabli.runtime;
import etabli.render;
import etabli.ciel.theme;
import etabli.ciel.button.fx;

final class FilledButton : UIElement {
    private {
        RoundedRectangle _background;
        ButtonFx _fx;
        Label _text;
    }

    this(string text_) {
        _text = new Label(text_);
        addElement(_text);

        setSize(Vec2f(_text.getSize().x + 48f, 40f));

        _fx = new ButtonFx(this);

        _background = new RoundedRectangle(getSize(), 8f, true, 0f);
        _background.anchor = Vec2f.zero;
        addImage(_background);

        addEventListener("enable", &onEnable);
        addEventListener("disable", &onDisable);
        addEventListener("mousedown", { _fx.onClick(getMousePosition()); });
        addEventListener("mouseup", { _fx.onUnclick(); });
        addEventListener("mousemove", { _fx.onUpdate(getMousePosition()); });
        addEventListener("update", { _fx.update(); });
        addEventListener("draw", { _fx.draw(); });

        onEnable();
    }

    void onEnable() {
        _background.color = getTheme(ThemeKey.primary);
        _text.color = getTheme(ThemeKey.onPrimary);
        _fx.color = getTheme(ThemeKey.surface);

        _background.alpha = 1f;
        _text.alpha = 1f;
    }

    void onDisable() {
        _background.color = getTheme(ThemeKey.onSurface);
        _text.color = getTheme(ThemeKey.onSurface);

        _background.alpha = 0.12f;
        _text.alpha = 0.38f;
    }
}

final class OutlinedButton : UIElement {
    private {
        RoundedRectangle _background;
        ButtonFx _fx;
        Label _text;
    }

    this(string text_) {
        _text = new Label(text_);
        addElement(_text);

        setSize(Vec2f(_text.getSize().x + 48f, 40f));

        _fx = new ButtonFx(this);

        _background = new RoundedRectangle(getSize(), 8f, false, 1f);
        _background.anchor = Vec2f.zero;
        addImage(_background);

        addEventListener("enable", &onEnable);
        addEventListener("disable", &onDisable);
        addEventListener("mousedown", { _fx.onClick(getMousePosition()); });
        addEventListener("mouseup", { _fx.onUnclick(); });
        addEventListener("mousemove", { _fx.onUpdate(getMousePosition()); });
        addEventListener("update", { _fx.update(); });
        addEventListener("draw", { _fx.draw(); });

        onEnable();
    }

    void onEnable() {
        _background.color = getTheme(ThemeKey.background);
        _text.color = getTheme(ThemeKey.primary);
        _fx.color = getTheme(ThemeKey.primary);

        _background.alpha = 1f;
        _text.alpha = 1f;
    }

    void onDisable() {
        _background.color = getTheme(ThemeKey.onSurface);
        _text.color = getTheme(ThemeKey.onSurface);

        _background.alpha = 0.12f;
        _text.alpha = 0.38f;
    }
}

final class TextButton : UIElement {
    private {
        ButtonFx _fx;
        Label _text;
    }

    this(string text_) {
        _text = new Label(text_);
        addElement(_text);

        setSize(Vec2f(_text.getSize().x + 48f, 40f));

        _fx = new ButtonFx(this);

        addEventListener("enable", &onEnable);
        addEventListener("disable", &onDisable);
        addEventListener("mousedown", { _fx.onClick(getMousePosition()); });
        addEventListener("mouseup", { _fx.onUnclick(); });
        addEventListener("mousemove", { _fx.onUpdate(getMousePosition()); });
        addEventListener("update", { _fx.update(); });
        addEventListener("draw", { _fx.draw(); });

        onEnable();
    }

    void onEnable() {
        _text.color = getTheme(ThemeKey.primary);
        _fx.color = getTheme(ThemeKey.primary);

        _text.alpha = 1f;
    }

    void onDisable() {
        _text.color = getTheme(ThemeKey.onSurface);

        _text.alpha = 0.38f;
    }
}
