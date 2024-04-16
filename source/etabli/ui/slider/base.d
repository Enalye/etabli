/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module etabli.ui.slider.base;

import std.math;
import etabli.common;
import etabli.ui.core;

/// Base abstract class for any vertical or horizontal slider/scrollbar.
abstract class Slider : UIElement {
    private {
        float _value = 0f, _lastOffset = 0f, _offset = 0f, _step = 1f, _minValue = 0f,
            _maxValue = 1f, _scrollLength = 1f, _minimalSliderSize = 25f, _scrollAngle = 0f;
        bool _isGrabbed = false;
    }

    @property {
        /// Slider's value between 0 and 1.
        float value01() const {
            return _value;
        }
        /// Ditto
        float value01(float value_) {
            return _value = _offset = value_;
        }

        /// Rounded value between the min and max values specified.
        int ivalue() const {
            return cast(int) lerp(_minValue, _maxValue, _value);
        }
        /// Ditto
        int ivalue(int value_) {
            return cast(int)(_value = _offset = rlerp(_minValue, _maxValue, value_));
        }

        /// Value between the min and max values specified.
        float fvalue() const {
            return lerp(_minValue, _maxValue, _value);
        }
        /// Ditto
        float fvalue(float value_) {
            return _value = _offset = rlerp(_minValue, _maxValue, value_);
        }

        /// Value (from 0 to 1) before being processed/clamped/etc. \
        /// Useful for rendering, not for getting its value as data.
        float offset() const {
            return _offset;
        }

        /// The number of steps of the slider. \
        /// 1 = The slider jumps directly from start to finish. \
        /// More = The slider has more intermediate values.
        uint steps() const {
            return (_step > 0f) ? cast(uint)(1f / _step) : 0u;
        }
        /// Ditto
        uint steps(uint steps_) {
            if (steps_ < 1u)
                _step = 0f;
            else
                _step = 1f / steps_;
            return steps_;
        }

        /// Minimal value possible for the slider. \
        /// Used by ivalue() and fvalue().
        float minValue() const {
            return _minValue;
        }
        /// Ditto
        float minValue(float newMin) {
            return _minValue = newMin;
        }

        /// Maximal value possible for the slider. \
        /// Used by ivalue() and fvalue().
        float maxValue() const {
            return _maxValue;
        }
        /// Ditto
        float maxValue(float newMax) {
            return _maxValue = newMax;
        }

        float scrollAngle() const {
            return _scrollAngle;
        }

        float scrollAngle(float scrollAngle_) {
            return _scrollAngle = scrollAngle_;
        }

        float scrollLength() const {
            return _scrollLength;
        }

        float scrollLength(float scrollLength_) {
            return _scrollLength = scrollLength_;
        }
    }

    /// Ctor
    this() {
        addEventListener("mouseup", &relocateSlider);
        addEventListener("mousedown", &relocateSlider);
        addEventListener("mousemove", {
            if (isPressed)
                relocateSlider();
        });
        addEventListener("update", &_onUpdate);
    }

    private void _onUpdate() {
        _value = (_offset < 0f) ? 0f : ((_offset > 1f) ? 1f : _offset); //Clamp the value.
        if (_step > 0f)
            _value = std.math.round(_value / _step) * _step; //Snap the value.
        if (!isPressed) {
            _offset = lerp(_offset, _value, 0.25f);

            if (_lastOffset != _offset) {
                _lastOffset = _offset;
                dispatchEvent("value", false);
            }
        }
    }

    /// Process the slider position.
    protected void relocateSlider() {
        if (_step == 0f) {
            _offset = 0f;
            _value = 0f;
            return;
        }

        const Vec2f direction = Vec2f.angled(degToRad(_scrollAngle));
        const Vec2f startPos = getCenter() - direction * 0.5f * _scrollLength;
        const float coef = direction.y / direction.x;
        const float b = startPos.y - (coef * startPos.x);

        const Vec2f closestPoint = Vec2f((coef * getMousePosition()
                .y + getMousePosition().x - coef * b) / (coef * coef + 1f),
            (coef * coef * getMousePosition().y + coef * getMousePosition().x + b) / (
                coef * coef + 1f));

        _offset = ((closestPoint.x - startPos.x) + (closestPoint.y - startPos.y)) / _scrollLength;
        if (_scrollAngle <= -90f || _scrollAngle > 90f) {
            _offset = -_offset;
        }
        _offset = (_offset < 0f) ? 0f : ((_offset > 1f) ? 1f : _offset);

        if (_lastOffset != _offset) {
            _lastOffset = _offset;
            dispatchEvent("value", false);
        }
    }

    /// Current coordinate of the slider.
    protected Vec2f getSliderPosition() {
        if (_step == 0f)
            return getCenter();
        Vec2f direction = Vec2f.angled(degToRad(_scrollAngle));
        return getCenter() + direction * (_scrollLength * (_offset - 0.5f));
    }
}
