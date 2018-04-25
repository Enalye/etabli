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

module ui.slider;

import std.math;
import std.algorithm.comparison;
import std.conv: to;

import core.all;
import render.all;
import common.all;

import ui.button;
import ui.widget;

class Slider: Widget {
	protected {	
		float _value = 0f, _offset = 0f, _step = 1f, _min = 0f, _max = 1f, _length = 1f, _minimalSliderSize = 25f;
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
		if(!_isSelected) {
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
			if(_isSelected)
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
		if(_isSelected)
			relocateSlider(event);
	}

	protected void relocateSlider(Event event) {
		if(_step == 0f) {
			_offset = 0f;
			_value = 0f;
			return;
		}
		Vec2f direction = Vec2f.angled(_angle);
		Vec2f origin = _position - direction * 0.5f * _length;
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
			return _position;
		Vec2f direction = Vec2f.angled(_angle);
		return _position + direction * (_length * (_offset - 0.5f));
	}
}

class VScrollbar: Slider {
	private {
		Sprite _circleSprite, _barSprite;
	}

	@property {
		alias size = super.size;
		override Vec2f size(Vec2f newSize) {
			super.size = newSize;
			_length = newSize.y - newSize.x;
			return _size;
		}
	}

	this() {
		_angle = 90f;
		_circleSprite = fetch!Sprite("gui_circle");
		_barSprite = fetch!Sprite("gui_texel");
	}
	
	override void draw() {
		Vec2f sliderPosition = getSliderPosition();
		float sliderLength = std.algorithm.max((_step > 0f ? _step : 1f) * _length, _minimalSliderSize);

		//Resize the slider to fit in the rail.
		if(sliderPosition.y - sliderLength / 2f < _position.y - _length / 2f) {
			float origin = _position.y - _length / 2f;
			float destination = sliderPosition.y + sliderLength / 2f;
			sliderLength = destination - origin;
			sliderPosition.y = origin + sliderLength / 2f;
		}
		else if(sliderPosition.y + sliderLength / 2f > _position.y + _length / 2f) {
			float origin = sliderPosition.y - sliderLength / 2f;
			float destination = _position.y + _length / 2f;
			sliderLength = destination - origin;
			sliderPosition.y = origin + sliderLength / 2f;
		}

		sliderPosition.y = clamp(sliderPosition.y, _position.y - _length / 2f, _position.y + _length / 2f);
		if(sliderLength < 0f)
			sliderLength = 0f;

		Color backColor = Color.white * .25f,
			frontColor = Color.white * .45f;
		backColor.a = 1f;
		frontColor.a = 1f;

		_circleSprite.size = Vec2f(_size.x, _size.x);
		_circleSprite.texture.setColorMod(backColor);
		_circleSprite.draw(_position - Vec2f(0f, _length / 2f));
		_circleSprite.draw(_position + Vec2f(0f, _length / 2f));

		_barSprite.texture.setColorMod(backColor);
		_barSprite.size = Vec2f(_size.x, _length);
		_barSprite.draw(_position);

		_circleSprite.texture.setColorMod(frontColor);
		_circleSprite.draw(sliderPosition - Vec2f(0f, sliderLength / 2f));
		_circleSprite.draw(sliderPosition + Vec2f(0f, sliderLength / 2f));

		_barSprite.texture.setColorMod(frontColor);
		_barSprite.size = Vec2f(_size.x, sliderLength);
		_barSprite.draw(sliderPosition);

		_circleSprite.texture.setColorMod(Color.white);
		_barSprite.texture.setColorMod(Color.white);

		_circleSprite.size = Vec2f.one;
		_barSprite.size = Vec2f.one;
	}
}

class HScrollbar: Slider {
	private {
		Sprite _circleSprite, _barSprite;
	}

	@property {
		alias size = super.size;
		override Vec2f size(Vec2f newSize) {
			super.size = newSize;
			_length = newSize.x - newSize.y;
			return _size;
		}
	}

	this() {
		_angle = 0f;
		_circleSprite = fetch!Sprite("gui_circle");
		_barSprite = fetch!Sprite("gui_texel");
	}
	
	override void draw() {
		Vec2f sliderPosition = getSliderPosition();
		float sliderLength = std.algorithm.max((_step > 0f ? _step : 1f) * _length, _minimalSliderSize);

		//Resize the slider to fit in the rail.
		if(sliderPosition.x - sliderLength / 2f < _position.x - _length / 2f) {
			float origin = _position.x - _length / 2f;
			float destination = sliderPosition.x + sliderLength / 2f;
			sliderLength = destination - origin;
			sliderPosition.x = origin + sliderLength / 2f;
		}
		else if(sliderPosition.x + sliderLength / 2f > _position.x + _length / 2f) {
			float origin = sliderPosition.x - sliderLength / 2f;
			float destination = _position.x + _length / 2f;
			sliderLength = destination - origin;
			sliderPosition.x = origin + sliderLength / 2f;
		}

		sliderPosition.x = clamp(sliderPosition.x, _position.x - _length / 2f, _position.x + _length / 2f);
		if(sliderLength < 0f)
			sliderLength = 0f;

		Color backColor = Color.white * .25f,
			frontColor = Color.white * .45f;
		backColor.a = 1f;
		frontColor.a = 1f;

		_circleSprite.size = Vec2f(_size.y, _size.y);
		_circleSprite.texture.setColorMod(backColor);
		_circleSprite.draw(_position - Vec2f(_length / 2f, 0f));
		_circleSprite.draw(_position + Vec2f(_length / 2f, 0f));

		_barSprite.texture.setColorMod(backColor);
		_barSprite.size = Vec2f(_length, _size.y);
		_barSprite.draw(_position);

		_circleSprite.texture.setColorMod(frontColor);
		_circleSprite.draw(sliderPosition - Vec2f(sliderLength / 2f, 0f));
		_circleSprite.draw(sliderPosition + Vec2f(sliderLength / 2f, 0f));

		_barSprite.texture.setColorMod(frontColor);
		_barSprite.size = Vec2f(sliderLength, _size.y);
		_barSprite.draw(sliderPosition);

		_circleSprite.texture.setColorMod(Color.white);
		_barSprite.texture.setColorMod(Color.white);

		_circleSprite.size = Vec2f.one;
		_barSprite.size = Vec2f.one;
	}
}

class VGauge: Slider {
	private {
		Sprite _barSprite, _endSprite;
		int _clipSizeY, _clipSizeH;
	}

	@property {
		alias size = super.size;
		override Vec2f size(Vec2f newSize) {
			super.size = newSize;
			_length = newSize.y;
			return _size;
		}
	}

	this() {
		_angle = 90f;
		_barSprite = fetch!Sprite("gui_bar");
		_endSprite = fetch!Sprite("gui_bar_end");
		_clipSizeY = _endSprite.clip.y;
		_clipSizeH = _endSprite.clip.w;
	}
	
	override void draw() {
		Vec2f sliderPosition = getSliderPosition();

		//Base
		_barSprite.size = _size - Vec2f(0f, 16f);
		_endSprite.clip.y = _clipSizeY;
		_endSprite.clip.w = _clipSizeH;
		_endSprite.size = Vec2f(_size.x, _clipSizeH);

		_barSprite.texture.setColorMod(Color.white * .25f);
		_endSprite.texture.setColorMod(Color.white * .25f);

		_barSprite.draw(_position);
		_endSprite.flip = Flip.NoFlip;
		_endSprite.draw(_position - Vec2f(0f, _length / 2f - _endSprite.size.y / 2f));
		_endSprite.flip = Flip.VerticalFlip;
		_endSprite.draw(_position + Vec2f(0f, _length / 2f - _endSprite.size.y / 2f));

		//Gauge
		_barSprite.texture.setColorMod(Color.white);
		_endSprite.texture.setColorMod(Color.white);
		if(sliderPosition.y > (_position.y +_length / 2f - _endSprite.size.y)) {
			_endSprite.size.y = _clipSizeH + (((_position.y +_length / 2f - _endSprite.size.y) - sliderPosition.y) * 2f);
			_endSprite.clip.w = to!int(_endSprite.size.y);
			_endSprite.flip = Flip.VerticalFlip;
			_endSprite.draw(_position + Vec2f(0f, _length / 2f - _endSprite.size.y / 2f));
		}
		else if(sliderPosition.y < (_position.y - _length / 2f + _endSprite.size.y)) {
			_endSprite.flip = Flip.VerticalFlip;
			_endSprite.draw(_position + Vec2f(0f, _length / 2f - _endSprite.size.y / 2f));

			_barSprite.size = _size - Vec2f(0f, 16f);
			_barSprite.draw(_position);	

			_endSprite.size.y = (((_position.y - _length / 2f + _endSprite.size.y) - sliderPosition.y) * 2f);
			_endSprite.clip.y = to!int(_clipSizeY + _clipSizeH - _endSprite.size.y / 2f);
			_endSprite.clip.w = to!int(_endSprite.size.y);
			_endSprite.flip = Flip.NoFlip;
			_endSprite.draw(_position - Vec2f(0f, _length / 2f - _clipSizeH / 2f - _clipSizeH / 2f));
		}
		else {
			_endSprite.flip = Flip.VerticalFlip;
			_endSprite.draw(_position + Vec2f(0f, _length / 2f - _endSprite.size.y / 2f));

			float origin = sliderPosition.y;
			float dest = _position.y + _barSprite.size.y / 2f;
			_barSprite.size = Vec2f(_size.x, dest - origin + 1f);
			_barSprite.draw(Vec2f(_position.x, origin + _barSprite.size.y / 2f));
		}

		_endSprite.size = Vec2f.one;
		_barSprite.size = Vec2f.one;
	}
}

class HGauge: Slider {
	private {
		Sprite _barSprite, _endSprite;
		int _clipSizeY, _clipSizeH;
	}

	@property {
		alias size = super.size;
		override Vec2f size(Vec2f newSize) {
			super.size = newSize;
			_length = newSize.x;
			return _size;
		}
	}

	this() {
		_angle = 0f;
		_barSprite = fetch!Sprite("gui_bar");
		_endSprite = fetch!Sprite("gui_bar_end");
		_endSprite.angle = 90f;
		_clipSizeY = _endSprite.clip.y;
		_clipSizeH = _endSprite.clip.w;
	}
	
	override void draw() {
		Vec2f sliderPosition = getSliderPosition();
		Vec2f leftAnchor = _position - Vec2f(_length / 2f - _clipSizeH, 0f);
		Vec2f rightAnchor = _position + Vec2f(_length / 2f - _clipSizeH, 0f);
		Vec2f leftEnd = _position - Vec2f(_length / 2f - _clipSizeH / 2f, 0f);
		Vec2f rightEnd = _position + Vec2f(_length / 2f - _clipSizeH / 2f, 0f);

		//Base
		_barSprite.anchor = Vec2f(0f, .5f);
		_barSprite.size = Vec2f((rightAnchor.x - leftAnchor.x), _size.y);
		_barSprite.texture.setColorMod(Color.white * .25f);
		_barSprite.draw(leftAnchor);

		_endSprite.clip.y = _clipSizeY;
		_endSprite.clip.w = _clipSizeH;
		_endSprite.size = Vec2f(_size.y, _clipSizeH);
		_endSprite.texture.setColorMod(Color.white * .25f);

		_endSprite.flip = Flip.VerticalFlip;
		_endSprite.draw(leftEnd);
		_endSprite.flip = Flip.HorizontalFlip;
		_endSprite.draw(rightEnd);

		//Gauge
		_barSprite.texture.setColorMod(Color.white);
		_endSprite.texture.setColorMod(Color.white);

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
			_barSprite.size = Vec2f(sliderPosition.x - leftAnchor.x, _size.y);
			_barSprite.draw(leftAnchor);
		}

		_endSprite.size = Vec2f.one;
		_barSprite.size = Vec2f.one;
	}
}


class VSlider: Slider {
	private Sprite _circleSprite, _barSprite;

	@property {
		alias size = super.size;
		override Vec2f size(Vec2f newSize) {
			super.size = newSize;
			_length = newSize.y - newSize.x;
			return _size;
		}
	}

	this() {
		_angle = 90f;
		_barSprite = fetch!Sprite("gui_bar");
		_circleSprite = fetch!Sprite("gui_circle");
	}
	
	override void draw() {
		Vec2f sliderPosition = getSliderPosition();

		Vec2f upPos = _position - Vec2f(0f, _length / 2f);
		Vec2f downPos = _position + Vec2f(0f, _length / 2f);

		Color backColor = Color.white * .25f,
			frontColor = Color.cyan * .8f;
		backColor.a = 1f;
		frontColor.a = 1f;

		_circleSprite.size = Vec2f(_size.x, _size.x);
		_circleSprite.texture.setColorMod(backColor);
		_circleSprite.draw(upPos);

		_barSprite.texture.setColorMod(backColor);
		_barSprite.size = Vec2f(_size.x, _length);
		_barSprite.draw(_position);

		_circleSprite.texture.setColorMod(frontColor);
		_circleSprite.draw(downPos);
		_circleSprite.draw(sliderPosition);

		_barSprite.texture.setColorMod(frontColor);
		_barSprite.size = Vec2f(_size.x, downPos.y - sliderPosition.y);
		_barSprite.draw(sliderPosition + Vec2f(0f, (downPos.y - sliderPosition.y) / 2f));

		_circleSprite.texture.setColorMod(Color.white);
		_barSprite.texture.setColorMod(Color.white);

		_circleSprite.size = Vec2f.one;
		_barSprite.size = Vec2f.one;
	}
}

class HSlider: Slider {
	private Sprite _circleSprite, _barSprite;

	@property {
		alias size = super.size;
		override Vec2f size(Vec2f newSize) {
			super.size = newSize;
			_length = newSize.x - newSize.y;
			return _size;
		}
	}

	this() {
		_angle = 0f;
		_barSprite = fetch!Sprite("gui_bar");
		_circleSprite = fetch!Sprite("gui_circle");
	}
	
	override void draw() {
		Vec2f sliderPosition = getSliderPosition();

		Vec2f leftPos = _position - Vec2f(_length / 2f, 0f);
		Vec2f rightPos = _position + Vec2f(_length / 2f, 0f);

		Color backColor = Color.white * .25f,
			frontColor = Color.cyan * .8f;
		backColor.a = 1f;
		frontColor.a = 1f;

		_circleSprite.size = Vec2f(_size.y, _size.y);
		_circleSprite.texture.setColorMod(backColor);
		_circleSprite.draw(rightPos);

		_barSprite.texture.setColorMod(backColor);
		_barSprite.size = Vec2f(_length, _size.y);
		_barSprite.draw(_position);

		_circleSprite.texture.setColorMod(frontColor);
		_circleSprite.draw(leftPos);
		_circleSprite.draw(sliderPosition);

		_barSprite.texture.setColorMod(frontColor);
		_barSprite.size = Vec2f(sliderPosition.x - leftPos.x, _size.y);
		_barSprite.draw(leftPos + Vec2f((sliderPosition.x - leftPos.x) / 2f, 0f));

		_circleSprite.texture.setColorMod(Color.white);
		_barSprite.texture.setColorMod(Color.white);

		_circleSprite.size = Vec2f.one;
		_barSprite.size = Vec2f.one;
	}
}