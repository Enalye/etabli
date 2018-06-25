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

module common.event;

import std.path;
import std.string;
import std.conv;
import std.utf;

version(linux) {
	import core.sys.posix.unistd;
	import core.sys.posix.signal;
}

import derelict.sdl2.sdl;

import render.window;
import ui.widget;
import core.vec2;

import common.settings;
import common.controller;

static private {
	bool[512] _keys;
	bool[8] _buttons;
	Vec2f _mousePosition;
	Event[] _globalEvents;
	int[string] _keysMap;
}

private bool _isRunning = false;

enum EventType: uint {
	KeyUp,
	KeyDown,
	KeyInput,
	KeyDelete,
	KeyEnter,
	KeyDir,
	MouseUp,
	MouseDown,
	MouseUpdate,
	MouseWheel,
	Quit,
	DropFile,
	Resize,
	ModalOpen,
	ModalClose,
	ModalApply,
	ModalCancel,
	Callback
}

struct Event {
	this(EventType _type) {
		type = _type;
	}

	EventType type;
	string id;
	union {
		Vec2f position;
		Vec2i coord;
		string str;
		int ivalue;
		string[] sarray;
		Widget widget;
	}
}

struct WidgetCallback {
	Widget widget;
	string id;

	void trigger(Widget w) {
		Event event;
		event.type = EventType.Callback;
		event.id = id;
		event.widget = w;
		widget.onEvent(event);
	}

	void trigger(string[] array) {
		Event event;
		event.type = EventType.Callback;
		event.id = id;
		event.sarray = array;
		widget.onEvent(event);
	}

	void trigger(int value) {
		Event event;
		event.type = EventType.Callback;
		event.id = id;
		event.ivalue = value;
		widget.onEvent(event);
	}
}

void bindKey(string keyName, uint keyId) {
	_keysMap[keyName] = keyId;
}

bool isKeyDown(string keyName) {
	auto keyPtr = keyName in _keysMap;

	if(keyPtr is null)
		throw new Exception("Undefined key: " ~ keyName);

	return _keys[*keyPtr];
}

bool getKeyDown(string keyName) {
	auto keyPtr = keyName in _keysMap;

	if(keyPtr is null)
		throw new Exception("Undefined key: " ~ keyName);

	auto value = _keys[*keyPtr];
	_keys[*keyPtr] = false;
	return value;
}

bool isButtonDown(ubyte button) {
	return _buttons[button];
}

Vec2f getMousePos() {
	return _mousePosition;
}

void stopApplication() {
	_isRunning = false;
}

bool isRunning() {
	return _isRunning;
}

void sendEvent(EventType eventType) {
	Event event = Event(eventType);
	_globalEvents ~= event;
}

void sendEvent(Event event) {
	_globalEvents ~= event;
}

version(linux)
extern(C) void signalHandler(int sig) nothrow @nogc @system {
	_isRunning = false;
}

void initializeEvents() {
	version(linux)
		signal(SIGINT, &signalHandler);
	_isRunning = true;
	_mousePosition = Vec2f.zero;
    initializeControllers();
}

void destroyEvents() {
    destroyControllers();
}

void updateEvents(float deltaTime) {
    updateControllers(deltaTime);
}

bool processEvents(IMainWidget mainWidget) {
	Event event;
	SDL_Event sdlEvent;

	if(!_isRunning) {
		event.type = EventType.Quit;
		mainWidget.onEvent(event);
        destroyWindow();
		return false;
	}

	//Used to start receiving SDL_TEXTINPUT events
	SDL_StartTextInput();
	
	while (SDL_PollEvent(&sdlEvent)) {
		switch (sdlEvent.type) {
		case SDL_QUIT:
			_isRunning = false;
			event.type = EventType.Quit;
			mainWidget.onEvent(event);
			destroyWindow();
			//No operation involving the SDL after this.
			return false;
		case SDL_KEYDOWN:
			if (!_keys[sdlEvent.key.keysym.scancode])
				_keys[sdlEvent.key.keysym.scancode] = true;
			switch(sdlEvent.key.keysym.scancode) {
			case SDL_SCANCODE_DELETE:
				event.type = EventType.KeyDelete;
				event.ivalue = 1;
				mainWidget.onEvent(event);
				break;
			case SDL_SCANCODE_BACKSPACE:
				event.type = EventType.KeyDelete;
				event.ivalue = -1;
				mainWidget.onEvent(event);
				break;
			case SDL_SCANCODE_RETURN:
				event.type = EventType.KeyEnter;
				mainWidget.onEvent(event);
				break;
			case SDL_SCANCODE_UP:
				event.type = EventType.KeyDir;
				event.position = Vec2f(0f, -1f);
				mainWidget.onEvent(event);
				break;
			case SDL_SCANCODE_DOWN:
				event.type = EventType.KeyDir;
				event.position = Vec2f(0f, 1f);
				mainWidget.onEvent(event);
				break;
			case SDL_SCANCODE_LEFT:
				event.type = EventType.KeyDir;
				event.position = Vec2f(-1f, 0f);
				mainWidget.onEvent(event);
				break;
			case SDL_SCANCODE_RIGHT:
				event.type = EventType.KeyDir;
				event.position = Vec2f(1f, 0f);
				mainWidget.onEvent(event);
				break;
			default:
				break;
			}
			break;
		case SDL_KEYUP:
			if (_keys[sdlEvent.key.keysym.scancode])
				_keys[sdlEvent.key.keysym.scancode] = false;
			break;
		case SDL_TEXTINPUT:
			string text = to!string(sdlEvent.text.text);
			text.length = stride(text);
			event.type = EventType.KeyInput;
			event.str = text;
			mainWidget.onEvent(event);
			break;
		case SDL_MOUSEMOTION:
			_mousePosition.set(cast(float)sdlEvent.motion.x, cast(float)sdlEvent.motion.y);
			_mousePosition = getViewVirtualPos(_mousePosition);

			event.type = EventType.MouseUpdate;
			event.position = _mousePosition;

			mainWidget.onEvent(event);
			break;
		case SDL_MOUSEBUTTONDOWN:
			_mousePosition.set(cast(float)sdlEvent.motion.x, cast(float)sdlEvent.motion.y);
			_mousePosition = getViewVirtualPos(_mousePosition);
			_buttons[sdlEvent.button.button] = true;
			
			event.type = EventType.MouseDown;
			event.position = _mousePosition;

			mainWidget.onEvent(event);
			break;
		case SDL_MOUSEBUTTONUP:
			_mousePosition.set(cast(float)sdlEvent.motion.x, cast(float)sdlEvent.motion.y);
			_mousePosition = getViewVirtualPos(_mousePosition);
			_buttons[sdlEvent.button.button] = false;

			event.type = EventType.MouseUp;
			event.position = _mousePosition;

			mainWidget.onEvent(event);
			break;
		case SDL_MOUSEWHEEL:
			event.type = EventType.MouseWheel;
			event.position = Vec2f(sdlEvent.wheel.x, sdlEvent.wheel.y);
			mainWidget.onEvent(event);
			break;
		case SDL_WINDOWEVENT:
			switch (sdlEvent.window.event) {
				case SDL_WINDOWEVENT_RESIZED:
					setWindowSize(Vec2u(sdlEvent.window.data1, sdlEvent.window.data2));
					break;
				default:
					break;
			}
			break;
		case SDL_DROPFILE:
			string path = to!string(fromStringz(sdlEvent.drop.file));
			size_t index;
			while(-1 != (index = path.indexOfAny("%"))) {
				if((index + 3) > path.length)
					break;
				string str = path[index + 1 .. index + 3];
				int utfValue = parse!int(str, 16);
				char utfChar = to!char(utfValue);

				if(index == 0)
					path = utfChar ~ path[3 .. $];
				else if((index + 3) == path.length)
					path = path[0 .. index] ~ utfChar;
				else
					path = path[0 .. index] ~ utfChar ~ path[index + 3 .. $];		
			}

			event.type = EventType.DropFile;
			event.str = path;
			mainWidget.onEvent(event);

			SDL_free(sdlEvent.drop.file);
			break;
        case SDL_CONTROLLERDEVICEADDED:
            addController(sdlEvent.cdevice.which);
            break;
        case SDL_CONTROLLERDEVICEREMOVED:
            removeController(sdlEvent.cdevice.which);
            break;
        case SDL_CONTROLLERDEVICEREMAPPED:
            remapController(sdlEvent.cdevice.which);
            break;
        case SDL_CONTROLLERAXISMOTION:
            setControllerAxis(sdlEvent.caxis.axis, sdlEvent.caxis.value);
            break;
        case SDL_CONTROLLERBUTTONDOWN:
            setControllerButton(sdlEvent.cbutton.button, true);
            break;
        case SDL_CONTROLLERBUTTONUP:
            setControllerButton(sdlEvent.cbutton.button, false);
            break;
		default:
			break;
		}
	}

	foreach(Event globalEvent; _globalEvents) {
		switch(globalEvent.type) with(EventType) {
			case Quit:
				_isRunning = false;
				mainWidget.onEvent(globalEvent);
                destroyWindow();
				return false;
			default:
				mainWidget.onEvent(globalEvent);
				break;
		}
	}
	_globalEvents.length = 0;

	return true;
}
