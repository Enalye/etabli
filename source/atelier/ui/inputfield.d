/**
    Input field

    Copyright: (c) Enalye 2017
    License: Zlib
    Authors: Enalye
*/

module atelier.ui.inputfield;

import std.utf;
import std.conv: to;

import atelier.core;
import atelier.render;
import atelier.common;

import atelier.ui.widget;
import atelier.ui.label;

class InputField: Widget {
	private {
		Label _label;
		View _view;
		Color _borderColor, _caretColor;
		dstring _text;
		Timer _time;
		uint _caretIndex = 0U;
		Vec2f _caretPosition = Vec2f.zero;
		uint _limit = 80u;
	}

	@property {
		string text() const { return to!string(_text); }
		string text(string newText) {
			_text = to!dstring(newText);
			_caretIndex = to!uint(_text.length);
			_label.text = newText;
			return newText;
		}

		uint limit() const { return _limit; }
		uint limit(uint newLimit) {
			_limit = newLimit;
			if(_text.length > _limit) {
				_text.length = _limit;
				_label.text = to!string(_text);
			}
			if(_caretIndex > _limit)
				_caretIndex = _limit;
			return _limit;
		}
	}

	this(Vec2f newSize, string defaultText = "", bool startWithFocus = false) {
		_size = newSize;
		_view = new View(newSize);
		_view.position = Vec2f.zero;
		_view.setColorMod(Color.white, Blend.AlphaBlending);
		_label = new Label;
		_hasFocus = startWithFocus;
		_text = to!dstring(defaultText);
		_caretIndex = to!uint(_text.length);
		_label.text = to!string(_text);

		_borderColor = Color.white;
		_caretColor = Color.white;
		_time.start(1f, TimeMode.Bounce);
	}

	override void onEvent(Event event) {
		pushView(_view, false);
		if(_hasFocus) {
			switch(event.type) with(EventType) {
			case MouseDown:
				hasFocus = true;
				break;
			case KeyInput:
				if(_caretIndex >= _limit)
					break;
				if(_caretIndex == _text.length)
					_text ~= to!dstring(event.str);
				else if(_caretIndex == 0U)
					_text = to!dstring(event.str) ~ _text;
				else
					_text = _text[0U.._caretIndex] ~ to!dstring(event.str) ~ _text[_caretIndex..$];
				_caretIndex ++;
				_label.text = to!string(_text);
				break;
			case KeyDelete:
				if(_text.length) {
					if(event.ivalue > 0) {
						if(_caretIndex == 0U)
							_text = _text[1U..$];
						else if(_caretIndex != _text.length) {
							_text = _text[0U.._caretIndex] ~ _text[_caretIndex + 1..$];
						}
					}
					else {
						if(_caretIndex == _text.length) {
							_text.length --;
							_caretIndex --;
						}
						else if(_caretIndex != 0U) {
							_text = _text[0U.._caretIndex - 1] ~ _text[_caretIndex..$];
							_caretIndex --;
						}
					}
					_label.text = to!string(_text);
				}
				break;
			case KeyDir:
				if(event.position.x > 0f && _caretIndex < _text.length)
					_caretIndex ++;
				if(event.position.x < 0f && _caretIndex > 0U)
					_caretIndex --;
				break;
			case KeyEnter:
				triggerCallback();
				break;
			default:
				break;
			}	
		}
		popView();
	}

	override void update(float deltaTime) {
		_caretPosition = Vec2f(_label.position.x - _label.size.x / 2f + (_label.size.x / _text.length) * _caretIndex, _label.position.y - _label.size.y / 2f);
		_label.position = Vec2f(10f + (_label.size.x - _view.size.x) / 2f, 0f);

		if(_caretPosition.x > _view.position.x + _view.size.x / 2f - 10f)
			_view.position.x = _caretPosition.x - _view.size.x / 2f + 10f;
		else if(_caretPosition.x < _view.position.x - _view.size.x / 2f + 10f)
			_view.position.x = _caretPosition.x + _view.size.x / 2f - 10f;

		if(_caretIndex == 0U)
			_view.position.x = 0f;

		if(_hasFocus)
			_borderColor = lerp(_borderColor, Color.white, deltaTime * .25f);
		else
			_borderColor = lerp(_borderColor, Color.white * .21f, deltaTime * .1f);

		_time.update(deltaTime);
		_caretColor = lerp(Color.white, Color.white * .21f, _time.time);
	}

	override void draw() {
		pushView(_view, true);
		_label.draw();
		if(_text.length && _hasFocus)
			drawFilledRect(_caretPosition, Vec2f(2f, _label.size.y), _caretColor);
		popView();
		_view.draw(_position);
		drawRect(_position - _size / 2f, _size, _borderColor);
	}

	void clear() {
		_text.length = 0L;
		_caretIndex = 0u;
		_label.text = "";
	}
}