/**
    Knob

    Copyright: (c) Enalye 2017
    License: Zlib
    Authors: Enalye
*/

module atelier.ui.knob;

import atelier.core;
import atelier.render;
import atelier.common;

import atelier.ui.widget;

class Knob: Widget {
	protected {
		float _value = 0f, _step = 1f, _min = 0f, _max = 1f, _minAngle = 0f, _maxAngle = 360f, _angle = 0f, _lastValue = 0f;
		Sprite _baseSprite, _btnSprite;
		bool _isGrabbed = false;
		Vec2f _lastCursorPosition = Vec2f.zero;
	}

	@property {
		float value01() const { return _value; }
		float value01(float newValue) { return _value = newValue; }

		int ivalue() const { return cast(int)lerp(_min, _max, _value); }
		int ivalue(int newValue) { return cast(int)(_value = rlerp(_min, _max, newValue)); }
		float fvalue() const { return lerp(_min, _max, _value); }
		float fvalue(float newValue) { return _value = rlerp(_min, _max, newValue); }

		uint step() const { return (_step > 0f) ? cast(uint)(1f / _step) : 0u; }
		uint step(uint newStep) {
			if(newStep < 1u)
				_step = 0f;
			else
				_step = 1f / newStep;
			return newStep;
		}

		float min() const { return _min; }
		float min(float newMin) { return _min = newMin; }

		float max() const { return _max; }
		float max(float newMax) { return _max = newMax; }
	}

	this() {
		_btnSprite = fetch!Sprite("knob_btn");
		_size = _btnSprite.size;
	}

	void setAngles(float minAngle, float maxAngle) {
		_minAngle = minAngle;
		_maxAngle = maxAngle;
	}

	override void onEvent(Event event) {
		if(_step == 0f)
			return;

		switch(event.type) with(EventType) {
		case MouseWheel:
			_value += event.position.y * _step;
			_value = clamp(_value, 0f, 1f);
			break;
		case MouseDown:
			_lastCursorPosition = event.position;
			break;
		case MouseUp:
		case MouseUpdate:
			if(!_isSelected)
				break;
			Vec2f delta = event.position - _position;
			Vec2f delta2 = event.position - _lastCursorPosition;
			if(delta2.lengthSquared() > 0f)
				delta2.normalize();
			else
				break;
			if(delta.lengthSquared() > 0f)
				delta.normalize();
			float direction = delta.rotated(90f).dot(delta2);
			direction = direction > .5f ? 1f : (direction < -.5f ? -1f : 0f);
			_value += direction * _step;
			_value = clamp(_value, 0f, 1f);
			_lastCursorPosition = event.position;
			break;
		default:
			break;
		}
	}

	override void update(float deltaTime) {
		if(_step == 0f) {
			_value = 0f;
			return;
		}
		_angle = lerp(_minAngle, _maxAngle, _value);
		_btnSprite.angle = lerp(_btnSprite.angle, _angle, deltaTime * .5f);

		if(_lastValue != _value) {
			triggerCallback();
			_lastValue = _value;
		}
	}

	override void draw() {
		_btnSprite.draw(_position);
	}

	override bool isInside(const Vec2f pos) const {
		float halfSize = _size.x / 2f;
		return (_position - pos).lengthSquared() < halfSize * halfSize;
	}
}