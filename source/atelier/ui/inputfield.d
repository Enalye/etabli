/**
    Input field

    Copyright: (c) Enalye 2017
    License: Zlib
    Authors: Enalye
*/

module atelier.ui.inputfield;

import std.utf;
import std.conv: to;
import std.string: indexOf;
import atelier.core, atelier.render, atelier.common;
import atelier.ui.gui_element, atelier.ui.label;

/// Editable field.
class InputField: GuiElement {
	private {
		Label _label;
		Color _borderColor, _caretColor;
		dstring _text, _allowedCharacters;
		Timer _timer;
		uint _caretIndex = 0U;
		Vec2f _caretPosition = Vec2f.zero;
		uint _limit = 80u;
	}

	@property {
		/// The displayed text.
		string text() const { return to!string(_text); }
		/// Ditto
		string text(string newText) {
			_text = to!dstring(newText);
			_caretIndex = to!uint(_text.length);
			_label.text = newText;
			return newText;
		}

		/// Max number of characters.
		uint limit() const { return _limit; }
		/// Ditto
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

	/// The size is used to setup a canvas, avoid resizing too often. \
	/// Set startWithFocus to true if you want the inputfield to accept inputs immediatly.
	this(Vec2f size_, string defaultText = "", bool startWithFocus = false) {
		size = size_;
		super(GuiElement.Flags.canvas);
		_label = new Label;
        _label.setAlign(GuiAlignX.left, GuiAlignY.center);
        addChildGui(_label);
		hasFocus = startWithFocus;
		_text = to!dstring(defaultText);
		_caretIndex = to!uint(_text.length);
		_label.text = to!string(_text);

		_borderColor = Color.white;
		_caretColor = Color.white;
		_timer.mode = Timer.Mode.bounce;
		_timer.start(1f);
	}

	override void onEvent(Event event) {
		if(hasFocus) {
			switch(event.type) with(EventType) {
			case keyInput:
				if(_caretIndex >= _limit)
					break;
                const auto textInput = to!dstring(event.input.text);
                if(_allowedCharacters.length) {
                    if(indexOf(_allowedCharacters, textInput) == -1)
                        break;
                }
				if(_caretIndex == _text.length)
					_text ~= textInput;
				else if(_caretIndex == 0U)
					_text = textInput ~ _text;
				else
					_text = _text[0U.._caretIndex] ~ textInput ~ _text[_caretIndex..$];
				_caretIndex ++;
				_label.text = to!string(_text);
				break;
			case keyDelete:
				if(_text.length) {
					if(event.textDelete.direction > 0) {
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
			case keyDir:
				if(event.keyMove.direction.x > 0f && _caretIndex < _text.length)
					_caretIndex ++;
				if(event.keyMove.direction.x < 0f && _caretIndex > 0U)
					_caretIndex --;
				break;
			case keyEnter:
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

		_timer.update(deltaTime);
		_caretColor = lerp(Color.white, Color.white * .21f, _timer.value01);
	}

	override void draw() {
		if(_text.length && hasFocus)
			drawFilledRect(_caretPosition, Vec2f(2f, _label.size.y), _caretColor);
	}

    override void drawOverlay() {
		drawRect(origin, size, _borderColor);
    }

	/// Resets the text.
	void clear() {
		_text.length = 0L;
		_caretIndex = 0u;
		_label.text = "";
	}

	/// It will discard any characters from keyboard that aren't in this list.
    void setAllowedCharacters(dstring allowedCharacters) {
        _allowedCharacters = allowedCharacters;
    }
}