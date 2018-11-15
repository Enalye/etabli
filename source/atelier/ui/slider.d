/**
Grimoire
Copyright (c) 2017 Enalye

This software is provided 'as-is', without any express or implied warranty.
In no event will the authors be held liable for any damages arising
from the use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute
it freely, subject to the following restrictions:

	1. The origin of this software must not be misrepresented;
	   you must not claim that you wrote the original software.
	   If you use this software in a product, an acknowledgment
	   in the product documentation would be appreciated but
	   is not required.

	2. Altered source versions must be plainly marked as such,
	   and must not be misrepresented as being the original software.

	3. This notice may not be removed or altered from any source distribution.
*/

module atelier.ui.slider;

import std.math;
import std.algorithm.comparison;
import std.conv: to;
import atelier.core, atelier.render, atelier.common;
import atelier.ui.button, atelier.ui.gui_element;

class Slider: GuiElement {
	protected {	
		float _value = 0f, _offset = 0f, _step = 1f, _min = 0f, _max = 1f, _length = 1f, _minimalSliderSize = 25f, _scrollAngle = 0f;
		bool _isGrabbed = false;
	}

	@property {
		float value01() const { return _value; }
		float value01(float newValue) { return _value = _offset = newValue; }

		int ivalue() const { return cast(int)lerp(_min, _max, _value); }
		int ivalue(int newValue) { return cast(int)(_value = _offset = rlerp(_min, _max, newValue)); }
		float fvalue() const { return lerp(_min, _max, _value); }
		float fvalue(float newValue) { return _value = _offset = rlerp(_min, _max, newValue); }
		float offset() const { return _offset; }

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

		float length() const { return _length; }
		float length(float newLength) { return _length = newLength; }
	}

	this() {}

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
		case MouseWheel:
			_offset -= event.position.y * _step;
			_offset = (_offset < -_step) ? -_step : ((_offset > 1f + _step) ? 1f + _step : _offset);	//Clamp the value.
			break;
		case MouseDown:
		case MouseUp:
			if(isSelected)
				break;
			relocateSlider(event);
			break;
		default:
			break;
		}
		/+if(!_hasFocus) {
			if(getKeyDown("left"))
				_offset = clamp(_offset - _step, 0f, 1f);
			if(getKeyDown("right"))
				_offset = clamp(_offset + _step, 0f, 1f);
		}+/
		if(isSelected)
			relocateSlider(event);
	}

	protected void relocateSlider(Event event) {
		if(_step == 0f) {
			_offset = 0f;
			_value = 0f;
			return;
		}
		Vec2f direction = Vec2f.angled(_scrollAngle);
		Vec2f origin = center - direction * 0.5f * _length;
		float coef = direction.y / direction.x;
		float b = origin.y - (coef * origin.x);

		Vec2f closestPoint = Vec2f(
			(coef * event.position.y + event.position.x - coef * b) / (coef * coef + 1f),
			(coef * coef * event.position.y + coef * event.position.x + b) / (coef * coef + 1f));

		_offset = ((closestPoint.x - origin.x) + (closestPoint.y - origin.y)) / _length;	
		_offset = (_offset < 0f) ? 0f : ((_offset > 1f) ? 1f : _offset);	//Clamp the value.
	}

	protected Vec2f getSliderPosition() {
		if(_step == 0f)
			return center;
		Vec2f direction = Vec2f.angled(_scrollAngle);
		return center + direction * (_length * (_offset - 0.5f));
	}
}

class VScrollbar: Slider {
	private {
		Sprite _circleSprite, _barSprite;
	}

	Color backColor, frontColor;

	this() {
		_scrollAngle = 90f;
		_circleSprite = fetch!Sprite("gui_circle");
		_barSprite = fetch!Sprite("gui_texel");

		backColor = Color.white * .25f;
		backColor.a = 1f;
		frontColor = Color.white * .45f;
		frontColor.a = 1f;
	}
	
	override void draw() {
		Vec2f sliderPosition = getSliderPosition();
		float sliderLength = std.algorithm.max((_step > 0f ? _step : 1f) * _length, _minimalSliderSize);

		//Resize the slider to fit in the rail.
		if(sliderPosition.y - sliderLength / 2f < center.y - _length / 2f) {
			float origin = center.y - _length / 2f;
			float destination = sliderPosition.y + sliderLength / 2f;
			sliderLength = destination - origin;
			sliderPosition.y = origin + sliderLength / 2f;
		}
		else if(sliderPosition.y + sliderLength / 2f > center.y + _length / 2f) {
			float origin = sliderPosition.y - sliderLength / 2f;
			float destination = center.y + _length / 2f;
			sliderLength = destination - origin;
			sliderPosition.y = origin + sliderLength / 2f;
		}

		sliderPosition.y = clamp(sliderPosition.y, center.y - _length / 2f, center.y + _length / 2f);
		if(sliderLength < 0f)
			sliderLength = 0f;

		_circleSprite.size = Vec2f(size.x, size.x);
		_circleSprite.color = backColor;
		_circleSprite.draw(center - Vec2f(0f, _length / 2f));
		_circleSprite.draw(center + Vec2f(0f, _length / 2f));

		_barSprite.color = backColor;
		_barSprite.size = Vec2f(size.x, _length);
		_barSprite.draw(center);

		_circleSprite.color = frontColor;
		_circleSprite.draw(sliderPosition - Vec2f(0f, sliderLength / 2f));
		_circleSprite.draw(sliderPosition + Vec2f(0f, sliderLength / 2f));

		_barSprite.color = frontColor;
		_barSprite.size = Vec2f(size.x, sliderLength);
		_barSprite.draw(sliderPosition);

		_circleSprite.size = Vec2f.one;
		_barSprite.size = Vec2f.one;
	}

    override void onSize() {
        _length = size.y - size.x;
    }
}

class HScrollbar: Slider {
	private {
		Sprite _circleSprite, _barSprite;
	}

	Color backColor, frontColor;

	this() {
		_scrollAngle = 0f;
		_circleSprite = fetch!Sprite("gui_circle");
		_barSprite = fetch!Sprite("gui_texel");

		backColor = Color.white * .25f;
		backColor.a = 1f;
		frontColor = Color.white * .45f;
		frontColor.a = 1f;
	}
	
	override void draw() {
		Vec2f sliderPosition = getSliderPosition();
		float sliderLength = std.algorithm.max((_step > 0f ? _step : 1f) * _length, _minimalSliderSize);

		//Resize the slider to fit in the rail.
		if(sliderPosition.x - sliderLength / 2f < center.x - _length / 2f) {
			float origin = center.x - _length / 2f;
			float destination = sliderPosition.x + sliderLength / 2f;
			sliderLength = destination - origin;
			sliderPosition.x = origin + sliderLength / 2f;
		}
		else if(sliderPosition.x + sliderLength / 2f > center.x + _length / 2f) {
			float origin = sliderPosition.x - sliderLength / 2f;
			float destination = center.x + _length / 2f;
			sliderLength = destination - origin;
			sliderPosition.x = origin + sliderLength / 2f;
		}

		sliderPosition.x = clamp(sliderPosition.x, center.x - _length / 2f, center.x + _length / 2f);
		if(sliderLength < 0f)
			sliderLength = 0f;

		_circleSprite.size = Vec2f(size.y, size.y);
		_circleSprite.color = backColor;
		_circleSprite.draw(center - Vec2f(_length / 2f, 0f));
		_circleSprite.draw(center + Vec2f(_length / 2f, 0f));

		_barSprite.color = backColor;
		_barSprite.size = Vec2f(_length, size.y);
		_barSprite.draw(center);

		_circleSprite.color = frontColor;
		_circleSprite.draw(sliderPosition - Vec2f(sliderLength / 2f, 0f));
		_circleSprite.draw(sliderPosition + Vec2f(sliderLength / 2f, 0f));

		_barSprite.color = frontColor;
		_barSprite.size = Vec2f(sliderLength, size.y);
		_barSprite.draw(sliderPosition);

		_circleSprite.size = Vec2f.one;
		_barSprite.size = Vec2f.one;
	}

    override void onSize() {
        _length = size.x - size.y;
    }
}

class VGauge: Slider {
	private {
		Sprite _barSprite, _endSprite;
		int _clipSizeY, _clipSizeH;
	}

	this() {
		_scrollAngle = 90f;
		_barSprite = fetch!Sprite("gui_bar");
		_endSprite = fetch!Sprite("gui_bar_end");
		_clipSizeY = _endSprite.clip.y;
		_clipSizeH = _endSprite.clip.w;
	}
	
	override void draw() {
		Vec2f sliderPosition = getSliderPosition();

		//Base
		_barSprite.size = size - Vec2f(0f, 16f);
		_endSprite.clip.y = _clipSizeY;
		_endSprite.clip.w = _clipSizeH;
		_endSprite.size = Vec2f(size.x, _clipSizeH);

		_barSprite.color = Color.white * .25f;
		_endSprite.color = Color.white * .25f;

		_barSprite.draw(center);
		_endSprite.flip = Flip.NoFlip;
		_endSprite.draw(center - Vec2f(0f, _length / 2f - _endSprite.size.y / 2f));
		_endSprite.flip = Flip.VerticalFlip;
		_endSprite.draw(center + Vec2f(0f, _length / 2f - _endSprite.size.y / 2f));

		//Gauge
		_barSprite.color = Color.white;
		_endSprite.color = Color.white;
		if(sliderPosition.y > (center.y +_length / 2f - _endSprite.size.y)) {
			_endSprite.size.y = _clipSizeH + (((center.y +_length / 2f - _endSprite.size.y) - sliderPosition.y) * 2f);
			_endSprite.clip.w = to!int(_endSprite.size.y);
			_endSprite.flip = Flip.VerticalFlip;
			_endSprite.draw(center + Vec2f(0f, _length / 2f - _endSprite.size.y / 2f));
		}
		else if(sliderPosition.y < (center.y - _length / 2f + _endSprite.size.y)) {
			_endSprite.flip = Flip.VerticalFlip;
			_endSprite.draw(center + Vec2f(0f, _length / 2f - _endSprite.size.y / 2f));

			_barSprite.size = size - Vec2f(0f, 16f);
			_barSprite.draw(center);	

			_endSprite.size.y = (((center.y - _length / 2f + _endSprite.size.y) - sliderPosition.y) * 2f);
			_endSprite.clip.y = to!int(_clipSizeY + _clipSizeH - _endSprite.size.y / 2f);
			_endSprite.clip.w = to!int(_endSprite.size.y);
			_endSprite.flip = Flip.NoFlip;
			_endSprite.draw(center - Vec2f(0f, _length / 2f - _clipSizeH / 2f - _clipSizeH / 2f));
		}
		else {
			_endSprite.flip = Flip.VerticalFlip;
			_endSprite.draw(center + Vec2f(0f, _length / 2f - _endSprite.size.y / 2f));

			float origin = sliderPosition.y;
			float dest = center.y + _barSprite.size.y / 2f;
			_barSprite.size = Vec2f(size.x, dest - origin + 1f);
			_barSprite.draw(Vec2f(center.x, origin + _barSprite.size.y / 2f));
		}

		_endSprite.size = Vec2f.one;
		_barSprite.size = Vec2f.one;
	}

    override void onSize() {
        _length = size.y;
    }
}

class HGauge: Slider {
	private {
		Sprite _barSprite, _endSprite;
		int _clipSizeY, _clipSizeH;
	}

	this() {
		_scrollAngle = 0f;
		_barSprite = fetch!Sprite("gui_bar");
		_endSprite = fetch!Sprite("gui_bar_end");
		_endSprite.angle = 90f;
		_clipSizeY = _endSprite.clip.y;
		_clipSizeH = _endSprite.clip.w;
	}
	
	override void draw() {
		Vec2f sliderPosition = getSliderPosition();
		Vec2f leftAnchor = center - Vec2f(_length / 2f - _clipSizeH, 0f);
		Vec2f rightAnchor = center + Vec2f(_length / 2f - _clipSizeH, 0f);
		Vec2f leftEnd = center - Vec2f(_length / 2f - _clipSizeH / 2f, 0f);
		Vec2f rightEnd = center + Vec2f(_length / 2f - _clipSizeH / 2f, 0f);

		//Base
		_barSprite.anchor = Vec2f(0f, .5f);
		_barSprite.size = Vec2f((rightAnchor.x - leftAnchor.x), size.y);
		_barSprite.color = Color.white * .25f;
		_barSprite.draw(leftAnchor);

		_endSprite.clip.y = _clipSizeY;
		_endSprite.clip.w = _clipSizeH;
		_endSprite.size = Vec2f(size.y, _clipSizeH);
		_endSprite.color = Color.white * .25f;

		_endSprite.flip = Flip.VerticalFlip;
		_endSprite.draw(leftEnd);
		_endSprite.flip = Flip.HorizontalFlip;
		_endSprite.draw(rightEnd);

		//Gauge
		_barSprite.color = Color.white;
		_endSprite.color = Color.white;

		if(sliderPosition.x > rightAnchor.x) {
			//Static left end
			_endSprite.flip = Flip.VerticalFlip;
			_endSprite.draw(leftEnd);

			//Static bar
			_barSprite.draw(leftAnchor);

			//Resized right end
			_endSprite.size.y = sliderPosition.x - rightAnchor.x;
			_endSprite.clip.y = to!int(_clipSizeY + _clipSizeH - _endSprite.size.y);
			_endSprite.clip.w = to!int(_endSprite.size.y);
			_endSprite.flip = Flip.HorizontalFlip;
			_endSprite.draw(rightAnchor + Vec2f(_endSprite.size.y / 2f, 0f));
		}
		else if(sliderPosition.x < leftAnchor.x) {
			//Resized left end
			_endSprite.size.y = _clipSizeH - (leftAnchor.x - sliderPosition.x);
			_endSprite.clip.w = to!int(_endSprite.size.y);
			_endSprite.flip = Flip.VerticalFlip;
			_endSprite.draw(leftAnchor + Vec2f(_endSprite.size.y / 2f - _clipSizeH, 0f));
		}
		else {
			//Static left end
			_endSprite.flip = Flip.VerticalFlip;
			_endSprite.draw(leftEnd);

			//Resized bar
			_barSprite.size = Vec2f(sliderPosition.x - leftAnchor.x, size.y);
			_barSprite.draw(leftAnchor);
		}

		_endSprite.size = Vec2f.one;
		_barSprite.size = Vec2f.one;
	}

    override void onSize() {
        _length = size.x;
    }
}


class VSlider: Slider {
	private Sprite _circleSprite, _barSprite;

	Color backColor, frontColor;

	this() {
		_scrollAngle = 90f;
		_barSprite = fetch!Sprite("gui_bar");
		_circleSprite = fetch!Sprite("gui_circle");

		backColor = Color.white * .25f;
		backColor.a = 1f;
		frontColor = Color.cyan * .8f;
		frontColor.a = 1f;
	}
	
	override void draw() {
		Vec2f sliderPosition = getSliderPosition();

		Vec2f upPos = center - Vec2f(0f, _length / 2f);
		Vec2f downPos = center + Vec2f(0f, _length / 2f);

		_circleSprite.size = Vec2f(size.x, size.x);
		_circleSprite.color = backColor;
		_circleSprite.draw(upPos);

		_barSprite.color = backColor;
		_barSprite.size = Vec2f(size.x, _length);
		_barSprite.draw(center);

		_circleSprite.color = frontColor;
		_circleSprite.draw(downPos);
		_circleSprite.draw(sliderPosition);

		_barSprite.color = frontColor;
		_barSprite.size = Vec2f(size.x, downPos.y - sliderPosition.y);
		_barSprite.draw(sliderPosition + Vec2f(0f, (downPos.y - sliderPosition.y) / 2f));

		_circleSprite.size = Vec2f.one;
		_barSprite.size = Vec2f.one;
	}

    override void onSize() {
        _length = size.y - size.x;
    }
}

class HSlider: Slider {
	private Sprite _circleSprite, _barSprite;

	Color backColor, frontColor;

	this() {
		_scrollAngle = 0f;
		_barSprite = fetch!Sprite("gui_bar");
		_circleSprite = fetch!Sprite("gui_circle");

		backColor = Color.white * .25f;
		backColor.a = 1f;
		frontColor = Color.cyan * .8f;
		frontColor.a = 1f;
	}
	
	override void draw() {
		Vec2f sliderPosition = getSliderPosition();

		Vec2f leftPos = center - Vec2f(_length / 2f, 0f);
		Vec2f rightPos = center + Vec2f(_length / 2f, 0f);

		_circleSprite.size = Vec2f(size.y, size.y);
		_circleSprite.color = backColor;
		_circleSprite.draw(rightPos);

		_barSprite.color = backColor;
		_barSprite.size = Vec2f(_length, size.y);
		_barSprite.draw(center);

		_circleSprite.color = frontColor;
		_circleSprite.draw(leftPos);
		_circleSprite.draw(sliderPosition);

		_barSprite.color = frontColor;
		_barSprite.size = Vec2f(sliderPosition.x - leftPos.x, size.y);
		_barSprite.draw(leftPos + Vec2f((sliderPosition.x - leftPos.x) / 2f, 0f));

		_circleSprite.size = Vec2f.one;
		_barSprite.size = Vec2f.one;
	}

    override void onSize() {
        _length = size.x - size.y;
    }
}