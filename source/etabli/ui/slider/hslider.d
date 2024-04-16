/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module etabli.ui.slider.hslider;

import etabli.common;
import etabli.core;
import etabli.render;
import etabli.ui.slider.base;

/// Réglette horizontale
final class HSlider : Slider {
    private {
        Rectangle _backgroundBar, _progressBar;
        Circle _circle, _hoverCircle;
        Timer _hoverTimer, _clickTimer;
    }

    /// Ctor
    this() {
        scrollAngle = 0f;
        setSize(Vec2f(150f, 32f));

        _backgroundBar = new Rectangle(Vec2f(scrollLength, 2f), true, 1f);
        _backgroundBar.color = Etabli.theme.neutral;
        addImage(_backgroundBar);

        _progressBar = new Rectangle(Vec2f(scrollLength, 2f), true, 1f);
        _progressBar.anchor = Vec2f(0f, .5f);
        _progressBar.pivot = Vec2f(0f, .5f);
        _progressBar.color = Etabli.theme.accent;
        addImage(_progressBar);

        _hoverCircle = new Circle(16f, true, 0f);
        _hoverCircle.color = Etabli.theme.accent;
        _hoverCircle.alpha = 0f;
        addImage(_hoverCircle);

        _circle = new Circle(16f, true, 0f);
        _circle.color = Etabli.theme.accent;
        addImage(_circle);

        addEventListener("size", &_onSizeChange);
        addEventListener("value", &_onValueChange);
        addEventListener("mouseenter", &_onMouseEnter);
        addEventListener("mouseleave", &_onMouseLeave);
        addEventListener("mousedown", &_onMouseDown);
        addEventListener("mouseup", &_onMouseUp);
        addEventListener("update", &_onUpdate);

        addEventListener("enable", &_onEnable);
        addEventListener("disable", &_onDisable);

        _onSizeChange();
        _onValueChange();
    }

    private void _onEnable() {
        _backgroundBar.alpha = Etabli.theme.activeOpacity;
        _progressBar.alpha = Etabli.theme.activeOpacity;
        _progressBar.color = Etabli.theme.accent;
        _circle.color = Etabli.theme.accent;
    }

    private void _onDisable() {
        _backgroundBar.alpha = Etabli.theme.inactiveOpacity;
        _progressBar.alpha = Etabli.theme.inactiveOpacity;
        _progressBar.color = Etabli.theme.neutral;
        _circle.color = Etabli.theme.neutral;
    }

    private void _onValueChange() {
        _progressBar.size = Vec2f(offset() * scrollLength, 2f);

        _hoverCircle.position = getSliderPosition();
        _circle.position = getSliderPosition();
    }

    private void _onSizeChange() {
        scrollLength = getWidth() - 32f;

        const Vec2f direction = Vec2f.angled(degToRad(scrollAngle));
        const Vec2f startPos = getCenter() - direction * 0.5f * scrollLength;

        _backgroundBar.size = Vec2f(scrollLength, 2f);
        _backgroundBar.position = getCenter();
        _progressBar.position = startPos;
    }

    private void _onMouseEnter() {
        _hoverTimer.mode = Timer.Mode.once;

        if (!_hoverTimer.isRunning)
            _hoverTimer.start(12);
    }

    private void _onMouseLeave() {
        _hoverTimer.mode = Timer.Mode.reverse;

        if (!_hoverTimer.isRunning)
            _hoverTimer.start(6);

        if (isPressed)
            _onMouseUp();
    }

    private void _onMouseDown() {
        _clickTimer.mode = Timer.Mode.once;

        if (!_clickTimer.isRunning)
            _clickTimer.start(12);
    }

    private void _onMouseUp() {
        _clickTimer.mode = Timer.Mode.reverse;

        if (!_clickTimer.isRunning)
            _clickTimer.start(6);
    }

    private void _onUpdate() {
        if (_hoverTimer.isRunning) {
            _hoverTimer.update();
            float t = easeInOutSine(_hoverTimer.value01);

            _hoverCircle.radius = lerp(16f, 32f, t);
            _hoverCircle.alpha = lerp(0f, 0.4f, t);
        }

        if (_clickTimer.isRunning) {
            _clickTimer.update();

            float t = easeInOutSine(_clickTimer.value01);

            _circle.radius = lerp(16f, 24f, t);

            if (!_clickTimer.isRunning) {
                _hoverTimer.stop();

                if (isHovered && t == 0f) {
                    _hoverTimer.start(12);
                }
            }
            else {
                float t2 = easeInOutSine(_hoverTimer.value01);
                _hoverCircle.radius = lerp(lerp(16f, 32f, t2), _circle.radius, t);
                _hoverCircle.alpha = lerp(0f, 0.4f, t2);
            }
        }
    }
}
