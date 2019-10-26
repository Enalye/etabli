/**
    Slider

    Copyright: (c) Enalye 2017
    License: Zlib
    Authors: Enalye
*/

module atelier.ui.slider;

import std.math;
import std.algorithm.comparison;
import std.conv: to;
import atelier.core, atelier.render, atelier.common;
import atelier.ui.button, atelier.ui.gui_element;

/// Base abstract class for any vertical or horizontal slider/scrollbar.
abstract class Slider: GuiElement {
	protected {	
		float _value = 0f, _offset = 0f, _step = 1f, _min = 0f, _max = 1f,
			_scrollLength = 1f, _minimalSliderSize = 25f, _scrollAngle = 0f;
		bool _isGrabbed = false;
	}

	@property {
		/// Slider's value between 0 and 1.
		float value01() const { return _value; }
		/// Ditto
		float value01(float newValue) { return _value = _offset = newValue; }

		/// Rounded value between the min and max values specified.
		int ivalue() const { return cast(int)lerp(_min, _max, _value); }
		/// Ditto
		int ivalue(int newValue) { return cast(int)(_value = _offset = rlerp(_min, _max, newValue)); }

		/// Value between the min and max values specified.
		float fvalue() const { return lerp(_min, _max, _value); }
		/// Ditto
		float fvalue(float newValue) { return _value = _offset = rlerp(_min, _max, newValue); }

		/// Value (from 0 to 1) before being processed/clamped/etc. \
		/// Useful for rendering, not for getting its value as data.
		float offset() const { return _offset; }

		/// The number of steps of the slider. \
		/// 1 = The slider jumps directly from start to finish. \
		/// More = The slider has more intermediate values.
		uint step() const { return (_step > 0f) ? cast(uint)(1f / _step) : 0u; }
		/// Ditto
		uint step(uint newStep) {
			if(newStep < 1u)
				_step = 0f;
			else
				_step = 1f / newStep;
			return newStep;
		}

		/// Minimal value possible for the slider. \
		/// Used by ivalue() and fvalue().
		float min() const { return _min; }
		/// Ditto
		float min(float newMin) { return _min = newMin; }

		/// Maximal value possible for the slider. \
		/// Used by ivalue() and fvalue().
		float max() const { return _max; }
		/// Ditto
		float max(float newMax) { return _max = newMax; }
	}

	/// Sets the angle of the slider. \
	/// 90 = Vertical. \
	/// 0 = Horizontal.
	this(float scrollAngle) {
		_scrollAngle = scrollAngle;
	}

	override void update(float deltaTime) {
		if(!isSelected) {
			_value = (_offset < 0f) ? 0f : ((_offset > 1f) ? 1f : _offset);	//Clamp the value.
			if(_step > 0f)
				_value = std.math.round(_value / _step) * _step;	//Snap the value.
			_offset = lerp(_offset, _value, deltaTime * 0.25f);
			triggerCallback();
		}
	}
	
	override void onEvent(Event event) {
		if(_step == 0f)
			return;

		switch(event.type) with(EventType) {
		case mouseWheel:
			_offset -= event.position.y * _step;
			_offset = (_offset < -_step) ? -_step : ((_offset > 1f + _step) ? 1f + _step : _offset);	//Clamp the value.
			break;
		case mouseUpdate:
			if(!isClicked)
				break;
			relocateSlider(event);
			break;
		case mouseDown:
			relocateSlider(event);
			break;
		case mouseUp:
			relocateSlider(event);
			break;
		default:
			break;
		}
		if(isSelected)
			relocateSlider(event);
	}

	/// Process the slider position.
	protected void relocateSlider(Event event) {
		if(_step == 0f) {
			_offset = 0f;
			_value = 0f;
			return;
		}
		const Vec2f direction = Vec2f.angled(_scrollAngle);
		const Vec2f startPos = center - direction * 0.5f * _scrollLength;
		const float coef = direction.y / direction.x;
		const float b = startPos.y - (coef * startPos.x);

		const Vec2f closestPoint = Vec2f(
			(coef * event.position.y + event.position.x - coef * b) / (coef * coef + 1f),
			(coef * coef * event.position.y + coef * event.position.x + b) / (coef * coef + 1f));

		_offset = ((closestPoint.x - startPos.x) + (closestPoint.y - startPos.y)) / _scrollLength;	
		_offset = (_offset < 0f) ? 0f : ((_offset > 1f) ? 1f : _offset);	//Clamp the value.
	}

	/// Current coordinate of the slider.
	protected Vec2f getSliderPosition() {
		if(_step == 0f)
			return center;
		Vec2f direction = Vec2f.angled(_scrollAngle);
		return center + direction * (_scrollLength * (_offset - 0.5f));
	}
}

/// Simple vertical scrollbar with basic rendering.
class VScrollbar: Slider {
	/// Ctor
	this() {
		super(90f);
	}
	
	override void draw() {
		Vec2f sliderPosition = getSliderPosition();
		float sliderLength = std.algorithm.max((_step > 0f ? _step : 1f) * _scrollLength, _minimalSliderSize);

		//Resize the slider to fit in the rail.
		if(sliderPosition.y - sliderLength / 2f < center.y - _scrollLength / 2f) {
			const float startPos = center.y - _scrollLength / 2f;
			const float destination = sliderPosition.y + sliderLength / 2f;
			sliderLength = destination - startPos;
			sliderPosition.y = startPos + sliderLength / 2f;
		}
		else if(sliderPosition.y + sliderLength / 2f > center.y + _scrollLength / 2f) {
			const float startPos = sliderPosition.y - sliderLength / 2f;
			const float destination = center.y + _scrollLength / 2f;
			sliderLength = destination - startPos;
			sliderPosition.y = startPos + sliderLength / 2f;
		}

		sliderPosition.y = clamp(sliderPosition.y, center.y - _scrollLength / 2f, center.y + _scrollLength / 2f);
		if(sliderLength < 0f)
			sliderLength = 0f;

		drawFilledRect(origin, size, Color.white * .25f);
		const Vec2f sliderSize = Vec2f(size.x, sliderLength);
		drawFilledRect(sliderPosition - sliderSize / 2f, sliderSize, Color.white);
	}

    override void onSize() {
        _scrollLength = size.y;
    }
}

/// Simple horizontal scrollbar with basic rendering.
class HScrollbar: Slider {
	/// Ctor
	this() {
		super(0f);
	}
	
	override void draw() {
		Vec2f sliderPosition = getSliderPosition();
		float sliderLength = std.algorithm.max((_step > 0f ? _step : 1f) * _scrollLength, _minimalSliderSize);

		//Resize the slider to fit in the rail.
		if(sliderPosition.x - sliderLength / 2f < center.x - _scrollLength / 2f) {
			const float startPos = center.x - _scrollLength / 2f;
			const float destination = sliderPosition.x + sliderLength / 2f;
			sliderLength = destination - startPos;
			sliderPosition.x = startPos + sliderLength / 2f;
		}
		else if(sliderPosition.x + sliderLength / 2f > center.x + _scrollLength / 2f) {
			const float startPos = sliderPosition.x - sliderLength / 2f;
			const float destination = center.x + _scrollLength / 2f;
			sliderLength = destination - startPos;
			sliderPosition.x = startPos + sliderLength / 2f;
		}

		sliderPosition.x = clamp(sliderPosition.x, center.x - _scrollLength / 2f, center.x + _scrollLength / 2f);
		if(sliderLength < 0f)
			sliderLength = 0f;

		drawFilledRect(origin, size, Color.white * .25f);
		const Vec2f sliderSize = Vec2f(sliderLength, size.y);
		drawFilledRect(sliderPosition - sliderSize / 2f, sliderSize, Color.white);
	}

    override void onSize() {
        _scrollLength = size.x;
    }
}

/// Simple vertical slider with basic rendering.
class VSlider: Slider {
	/// Ctor
	this() {
		super(90f);
	}
	
	override void draw() {
		//Background
		drawFilledRect(origin, size, Color.white * .25f);

		//Gauge
		const float sliderHeight = clamp(getSliderPosition().y - origin.y, 0f, size.y);
		const Vec2f sliderSize = Vec2f(size.x, sliderHeight);
		drawFilledRect(origin + Vec2f(0f, size.y - sliderHeight), sliderSize, Color.white);
	}

    override void onSize() {
        _scrollLength = size.y;
    }
}

/// Simple horizontal slider with basic rendering.
class HSlider: Slider {
	/// Ctor
	this() {
		super(0f);
	}
	
	override void draw() {
		//Background
		drawFilledRect(origin, size, Color.white * .25f);

		//Gauge
		const float sliderWidth = clamp(getSliderPosition().x - origin.x, 0f, size.x);
		const Vec2f sliderSize = Vec2f(sliderWidth, size.y);
		drawFilledRect(origin, sliderSize, Color.white);
	}

    override void onSize() {
        _scrollLength = size.x;
    }
}