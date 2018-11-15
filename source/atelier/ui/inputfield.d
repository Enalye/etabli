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

module atelier.ui.inputfield;

import std.utf;
import std.conv: to;
import atelier.core, atelier.render, atelier.common;
import atelier.ui.gui_element, atelier.ui.label;

class InputField: GuiElementCanvas {
	private {
		Label _label;
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
		size = newSize;
		_label = new Label;
        _label.setAlign(GuiAlignX.Left, GuiAlignY.Center);
        addChildGui(_label);
		hasFocus = startWithFocus;
		_text = to!dstring(defaultText);
		_caretIndex = to!uint(_text.length);
		_label.text = to!string(_text);

		_borderColor = Color.white;
		_caretColor = Color.white;
		_time.start(1f, TimeMode.Bounce);
	}

	override void onEvent(Event event) {
		if(hasFocus) {
			switch(event.type) with(EventType) {
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
	}

	override void update(float deltaTime) {
		_caretPosition = Vec2f(_label.position.x + (_label.size.x / _text.length) * _caretIndex, _label.origin.y);
		_label.position = Vec2f(10f, 0f);

		if(_caretPosition.x > canvas.position.x + canvas.size.x / 2f - 10f)
			canvas.position.x = _caretPosition.x - canvas.size.x / 2f + 10f;
		else if(_caretPosition.x < canvas.position.x - canvas.size.x / 2f + 10f)
			canvas.position.x = _caretPosition.x + canvas.size.x / 2f - 10f;

		if(hasFocus)
			_borderColor = lerp(_borderColor, Color.white, deltaTime * .25f);
		else
			_borderColor = lerp(_borderColor, Color.white * .21f, deltaTime * .1f);

		_time.update(deltaTime);
		_caretColor = lerp(Color.white, Color.white * .21f, _time.time);
	}

	override void draw() {
		if(_text.length && hasFocus)
			drawFilledRect(_caretPosition, Vec2f(2f, _label.size.y), _caretColor);
	}

    override void drawOverlay() {
		drawRect(origin, size, _borderColor);
    }

	void clear() {
		_text.length = 0L;
		_caretIndex = 0u;
		_label.text = "";
	}
}