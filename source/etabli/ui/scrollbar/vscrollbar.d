/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module etabli.ui.scrollbar.vscrollbar;

import etabli.common;
import etabli.core;
import etabli.render;
import etabli.ui.scrollbar.base;

final class VScrollbar : Scrollbar {
    private {
        Capsule _background, _handle;
        Color _grabColor;
    }

    this() {
        setSize(Vec2f(9f, 0f));

        _background = Capsule.fill(getSize());
        _background.anchor = Vec2f.zero;
        _background.color = Etabli.theme.foreground;
        addImage(_background);

        _handle = Capsule.fill(getSize());
        _handle.anchor = Vec2f.zero;
        _handle.color = Etabli.theme.neutral;
        addImage(_handle);

        HSLColor color = HSLColor.fromColor(Etabli.theme.accent);
        color.l = color.l * 0.8f;
        _grabColor = color.toColor();

        addEventListener("size", &_onSize);
        addEventListener("handlePosition", &_onHandlePosition);
        addEventListener("handleSize", &_onHandleSize);
        addEventListener("update", &_onUpdate);
    }

    protected override float _getScrollLength() const {
        return getHeight();
    }

    protected override float _getScrollMousePosition() const {
        return getMousePosition().y;
    }

    private void _onHandlePosition() {
        _handle.position.y = getHandlePosition();
    }

    private void _onHandleSize() {
        _handle.size = Vec2f(getWidth(), getHandleSize());
    }

    private void _onSize() {
        _background.size = getSize();
        _handle.size = Vec2f(getWidth(), getHandleSize());
    }

    private void _onUpdate() {
        if (isHandleGrabbed()) {
            _handle.color = _grabColor;
            return;
        }

        if (isHandleHovered()) {
            _handle.color = Etabli.theme.accent;
        }
        else {
            _handle.color = Etabli.theme.neutral;
        }
    }
}
