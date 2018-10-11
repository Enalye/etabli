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

module atelier.ui.console.console;

import atelier.common;
import atelier.core;
import atelier.render;

import atelier.ui.list;
import atelier.ui.widget;
import atelier.ui.layout;
import atelier.ui.inputfield;
import atelier.ui.overlay;
import atelier.ui.text;

private {
	Console _console;
	ConsoleHandler _consoleHandler;

	alias FunctionCallback = void function(string[]);
}

void setupConsole(string invokeKey) {
	_consoleHandler = new ConsoleHandler(invokeKey);
	_console = new Console;
	addWidget(_consoleHandler);
}

void addConsoleCmd(string cmd, WidgetCallback callback) {
	if(!_console)
		return;
	_console.addCmd(cmd, callback);
}

void addConsoleCmd(string cmd, FunctionCallback callback) {
	if(!_console)
		return;
	_console.addCmd(cmd, callback);
}

void removeConsoleCmd(string cmd) {
	if(!_console)
		return;
	_console.removeCmd(cmd);
}

void logConsole(string log) {
	if(!_console)
		return;
	_console.addMessage(log);
}

private class ConsoleHandler: Widget {
	private {
		bool _isToggled = false;
		string _invokeKey;
		Timer _timer;
	}

	this(string invokeKey) {
		_invokeKey = invokeKey;
	}

	override void onEvent(Event event) {}

	override void update(float deltaTime) {
		if(_invokeKey.length && getKeyDown(_invokeKey))
			toggleConsole();

		if(_timer.isRunning) {
			_timer.update(deltaTime);
			_console.position = lerp(
				Vec2f(_console.size.x /2f, -_console.size.y / 2f),
				_console.size / 2f,
				easeInOutSine(_timer.time));

			if(!_timer.isRunning && !_isToggled)
				stopOverlay();
		}
	}

	override void draw() {}

	void toggleConsole() {
		_isToggled = !_isToggled;
		if(_isToggled) {
			_console.setup();
			if(!_timer.isRunning) {
				setOverlay(_console);
				_timer.start(.25f);
			}
			else
				_timer.isReversed = false;
		}
		else {
			if(!_timer.isRunning)
				_timer.startReverse(.25f);
			else
				_timer.isReversed = true;
		}
	}
}

private class Console: AnchoredLayout {
	private {
		LogList _log;
		InputField _inputField;
		WidgetCallback[string] _widgetCallbacks;
		FunctionCallback[string] _functionCallbacks;
		Sprite _background;
	}

	this() {
		_size = Vec2f(screenWidth, screenHeight / 2f);

		float inputFieldRatio = 25f / _size.y;
		float inputFieldHeight = _size.y * inputFieldRatio;

		_inputField = new InputField(Vec2f(_size.x, inputFieldHeight));
		_log = new LogList(_size - Vec2f(0f, inputFieldHeight));
		
		_background = fetch!Sprite("gui_texel");
		_background.size = _size;

		addChild(_log, Vec2f(.5f, .5f - inputFieldRatio / 2f), Vec2f(1f, 1f - inputFieldRatio));
		addChild(_inputField, Vec2f(.5f, 1f - inputFieldRatio / 2f), Vec2f(1f, inputFieldRatio));
	}

	override void onEvent(Event event) {
		super.onEvent(event);

		switch(event.type) with(EventType) {
		case KeyEnter:
			if(_inputField.hasFocus) {
				string text = _inputField.text;
				if(text.length) {
					parse(text);
					_inputField.clear();
				}
			}
			break;
		default:
			break;
		}
	}

	override void draw() {
		_background.texture.setColorMod(Color.black * .25f);
		_background.draw(_position);
		super.draw();
	}

	void setup() {
		_inputField.hasFocus = true;
	}

	void addCmd(string cmd, WidgetCallback callback) {
		_widgetCallbacks[cmd] = callback;
	}

	void addCmd(string cmd, FunctionCallback callback) {
		_functionCallbacks[cmd] = callback;
	}

	void removeCmd(string cmd) {
		_widgetCallbacks.remove(cmd);
		_functionCallbacks.remove(cmd);
	}

	void addMessage(string message) {
		//The bold tag is temporary since the font in LogList is not properly rendered.
		_log.addChild(new Text("{b}" ~ message));
	}

	protected void parse(string text) {
		import std.array: split;
		auto parameters = text.split;
		if(!parameters.length)
			return;
		auto widgetCallback = parameters[0] in _widgetCallbacks;
		if(widgetCallback) {
			Event event;
			event.type = EventType.Callback;
			event.id = (*widgetCallback).id;
			event.sarray = parameters[1..$];
			(*widgetCallback).widget.onEvent(event);
			return;
		}
		auto functionCallback = parameters[0] in _functionCallbacks;
		if(functionCallback) {
			(*functionCallback)(parameters[1..$]);
			return;
		}		
		addMessage("Invalid command \'" ~ parameters[0] ~ "\'.");
	}
}