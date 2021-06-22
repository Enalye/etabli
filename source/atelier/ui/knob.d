/**
    Knob

    Copyright: (c) Enalye 2017
    License: Zlib
    Authors: Enalye
*/

module atelier.ui.knob;

import atelier.core, atelier.render, atelier.common;
import atelier.ui.gui_element;

/// A rotating knob. \
/// Behave a bit like slider.
class Knob : GuiElement {
    protected {
        float _value = 0f, _step = 1f, _min = 0f, _max = 1f, _minAngle = 0f,
            _maxAngle = 360f, _knobAngle = 0f, _lastValue = 0f;
        bool _isGrabbed = false;
        Vec2f _lastCursorPosition = Vec2f.zero;
    }

    @property {
        /// Slider's value between 0 and 1.
        float value01() const {
            return _value;
        }
        /// Ditto
        float value01(float newValue) {
            return _value = newValue;
        }

        /// Rounded value between the min and max values specified.
        int ivalue() const {
            return cast(int) lerp(_min, _max, _value);
        }
        /// Ditto
        int ivalue(int newValue) {
            return cast(int)(_value = rlerp(_min, _max, newValue));
        }

        /// Value between the min and max values specified.
        float fvalue() const {
            return lerp(_min, _max, _value);
        }
        /// Ditto
        float fvalue(float newValue) {
            return _value = rlerp(_min, _max, newValue);
        }

        /// The number of steps of the slider. \
        /// 1 = The slider jumps directly from start to finish. \
        /// More = The slider has more intermediate values.
        uint step() const {
            return (_step > 0f) ? cast(uint)(1f / _step) : 0u;
        }
        /// Ditto
        uint step(uint newStep) {
            if (newStep < 1u)
                _step = 0f;
            else
                _step = 1f / newStep;
            return newStep;
        }

        /// Minimal value possible for the slider. \
        /// Used by ivalue() and fvalue().
        float min() const {
            return _min;
        }
        /// Ditto
        float min(float newMin) {
            return _min = newMin;
        }

        /// Maximal value possible for the slider. \
        /// Used by ivalue() and fvalue().
        float max() const {
            return _max;
        }
        /// Ditto
        float max(float newMax) {
            return _max = newMax;
        }

        /// Angle in degrees in which the rotator currently is.
        float knobAngle() const {
            return _knobAngle;
        }
    }

    /// Ctor
    this() {
        setEventHook(true);
    }

    /// Sets the min and max angles that the knob can rotate.
    void setAngles(float minAngle, float maxAngle) {
        _minAngle = minAngle;
        _maxAngle = maxAngle;
    }

    override void onEvent(Event event) {
        if (_step == 0f)
            return;

        switch (event.type) with (Event.Type) {
        case mouseWheel:
            _value += event.scroll.delta.y * _step;
            _value = clamp(_value, 0f, 1f);
            break;
        case mouseDown:
            _lastCursorPosition = event.mouse.position;
            break;
        case mouseUp:
        case mouseUpdate:
            if (!isSelected)
                break;
            Vec2f delta = event.mouse.position - center;
            Vec2f delta2 = event.mouse.position - _lastCursorPosition;
            if (delta2.lengthSquared() > 0f)
                delta2.normalize();
            else
                break;
            if (delta.lengthSquared() > 0f)
                delta.normalize();
            float direction = delta.rotated(90f).dot(delta2);
            direction = direction > .5f ? 1f : (direction < -.5f ? -1f : 0f);
            _value += direction * _step;
            _value = clamp(_value, 0f, 1f);
            _lastCursorPosition = event.mouse.position;
            break;
        default:
            break;
        }
    }

    override void update(float deltaTime) {
        if (_step == 0f) {
            _value = 0f;
            return;
        }
        _knobAngle = lerp(_minAngle, _maxAngle, _value);

        if (_lastValue != _value) {
            triggerCallback();
            _lastValue = _value;
        }
    }

    override void draw() {
        drawRect(origin, size, Color.white);
        drawLine(center, center + Vec2f(1f, 0f).rotated(_knobAngle) * 10f, Color.white);
    }

    override bool isInside(const Vec2f pos) const {
        const float halfSize = size.x / 2f;
        return (pos - center).lengthSquared() < halfSize * halfSize;
    }
}
