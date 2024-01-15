/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module etabli.ciel.slider.vslider;

import etabli.common;
import etabli.render;
import etabli.runtime;
import etabli.ui;
import etabli.ciel.theme;

/// Réglette horizontale
final class VSlider : Slider {
    private {
        Rectangle _backgroundBar, _progressBar;
        Circle _circle, _hoverCircle;
        Timer _hoverTimer, _clickTimer;
    }

    /// Ctor
    this() {
        scrollAngle = 270f;
        setSize(Vec2f(32f, 200f));

        _backgroundBar = new Rectangle(Vec2f(scrollLength, 2f), true, 1f);
        _backgroundBar.color = getTheme(ThemeKey.neutral);
        _backgroundBar.angle = scrollAngle;
        addImage(_backgroundBar);

        _progressBar = new Rectangle(Vec2f(scrollLength, 2f), true, 1f);
        _progressBar.anchor = Vec2f(0f, .5f);
        _progressBar.pivot = Vec2f(0f, .5f);
        _progressBar.angle = scrollAngle;
        _progressBar.color = getTheme(ThemeKey.primary);
        addImage(_progressBar);

        _circle = new Circle(16f, true, 0f);
        _circle.color = getTheme(ThemeKey.primary);
        addImage(_circle);

        _hoverCircle = new Circle(16f, true, 0f);
        _hoverCircle.color = getTheme(ThemeKey.primary);
        _hoverCircle.alpha = 0f;
        addImage(_hoverCircle);

        addEventListener("size", &_onSizeChange);
        addEventListener("value", &_onValueChange);
        addEventListener("mouseenter", &_onMouseEnter);
        addEventListener("mouseleave", &_onMouseLeave);
        addEventListener("mousedown", &_onMouseDown);
        addEventListener("mouseup", &_onMouseUp);
        addEventListener("update", &_onUpdate);

        _onSizeChange();
        _onValueChange();
    }

    private void _onValueChange() {
        _progressBar.size = Vec2f(offset() * scrollLength, 2f);

        _hoverCircle.position = getSliderPosition();
        _circle.position = getSliderPosition();
    }

    private void _onSizeChange() {
        scrollLength = getHeight() - 32f;

        const Vec2f direction = Vec2f.angled(degToRad * scrollAngle);
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
