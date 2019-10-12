/**
    Event

    Copyright: (c) Enalye 2017
    License: Zlib
    Authors: Enalye
*/

module atelier.common.event;

import std.path;
import std.string;
import std.conv;
import std.utf;

version(linux) {
	import core.sys.posix.unistd;
	import core.sys.posix.signal;
}

import derelict.sdl2.sdl;

import atelier.render;
import atelier.ui;
import atelier.core;

import atelier.common.settings;
import atelier.common.controller;

static private {
	bool[512] _keys;
	bool[8] _buttons;
	Vec2f _mousePosition;
	Event[] _globalEvents;
	int[string] _keysMap;
}

private bool _isRunning = false;

/// Type of event
enum EventType: uint {
	keyUp,
	keyDown,
	keyInput,
	keyDelete,
	keyEnter,
	keyDir,
	mouseUp,
	mouseDown,
	mouseUpdate,
	mouseWheel,
	quit,
	dropFile,
	resize,
	modalOpen,
	modalClose,
	modalApply,
	modalCancel,
	callback
}

/// Event structure passed on onEvent() methods.
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
		GuiElement widget;
	}
}

/// Deprecated, don't use this.
struct GuiElementCallback {
	GuiElement widget;
	string id;

	void trigger(GuiElement w) {
		Event event;
		event.type = EventType.callback;
		event.id = id;
		event.widget = w;
		widget.onEvent(event);
	}

	void trigger(string[] array) {
		Event event;
		event.type = EventType.callback;
		event.id = id;
		event.sarray = array;
		widget.onEvent(event);
	}

	void trigger(int value) {
		Event event;
		event.type = EventType.callback;
		event.id = id;
		event.ivalue = value;
		widget.onEvent(event);
	}
}

/// Associate an ID with a key.
void bindKey(string keyName, uint keyId) {
	_keysMap[keyName] = keyId;
}

/// Check whether the key associated with the ID is pressed. \
/// Do not reset the value.
bool isKeyDown(string keyName) {
	auto keyPtr = keyName in _keysMap;

	if(keyPtr is null)
		throw new Exception("Undefined key: " ~ keyName);

	return _keys[*keyPtr];
}

/// Check whether the key associated with the ID is pressed. \
/// This function resets the value to false.
bool getKeyDown(string keyName) {
	auto keyPtr = keyName in _keysMap;

	if(keyPtr is null)
		throw new Exception("Undefined key: " ~ keyName);

	auto value = _keys[*keyPtr];
	_keys[*keyPtr] = false;
	return value;
}

/// Check whether the mouse button associated with the ID is pressed. \
/// Do not reset the value.
bool isButtonDown(ubyte button) {
	return _buttons[button];
}

/// Check whether the mouse button associated with the ID is pressed. \
/// This function resets the value to false.
bool getButtonDown(ubyte button) {
    bool value = _buttons[button];
    _buttons[button] = false;
	return value;
}

/// Returns the position of the mouse relative to the window.
Vec2f getMousePos() {
	return _mousePosition;
}

/// Tells the application to finish.
void stopApplication() {
	_isRunning = false;
}

/// Check if the application's still running.
bool isRunning() {
	return _isRunning;
}

/// Dispatch an event to GUIs.
void sendEvent(EventType eventType) {
	Event event = Event(eventType);
	_globalEvents ~= event;
}

/// Dispatch an event to GUIs.
void sendEvent(Event event) {
	_globalEvents ~= event;
}

version(linux)
/// Capture interruptions.
extern(C) void signalHandler(int sig) nothrow @nogc @system {
	_isRunning = false;
}

/// Initialize everything mouse, keyboard or controller related.
void initializeEvents() {
	version(linux)
		signal(SIGINT, &signalHandler);
	_isRunning = true;
	_mousePosition = Vec2f.zero;
    initializeControllers();
}

/// Closes everything mouse, keyboard or controller related.
void destroyEvents() {
    destroyControllers();
}

/// Updates everything mouse, keyboard or controller related.
void updateEvents(float deltaTime) {
    updateControllers(deltaTime);
}

/// Process and dispatch window, input, etc events.
bool processEvents() {
	Event event;
	SDL_Event sdlEvent;

	if(!_isRunning) {
		event.type = EventType.quit;
		handleGuiElementEvent(event);
        destroyWindow();
		return false;
	}

	//Used to start receiving SDL_TEXTINPUT events
	SDL_StartTextInput();
	
	while (SDL_PollEvent(&sdlEvent)) {
		switch (sdlEvent.type) {
		case SDL_QUIT:
			_isRunning = false;
			event.type = EventType.quit;
			handleGuiElementEvent(event);
			destroyWindow();
			//No operation involving the SDL after this.
			return false;
		case SDL_KEYDOWN:
			if (!_keys[sdlEvent.key.keysym.scancode])
				_keys[sdlEvent.key.keysym.scancode] = true;
			switch(sdlEvent.key.keysym.scancode) {
			case SDL_SCANCODE_DELETE:
				event.type = EventType.keyDelete;
				event.ivalue = 1;
				handleGuiElementEvent(event);
				break;
			case SDL_SCANCODE_BACKSPACE:
				event.type = EventType.keyDelete;
				event.ivalue = -1;
				handleGuiElementEvent(event);
				break;
			case SDL_SCANCODE_RETURN:
				event.type = EventType.keyEnter;
				handleGuiElementEvent(event);
				break;
			case SDL_SCANCODE_UP:
				event.type = EventType.keyDir;
				event.position = Vec2f(0f, -1f);
				handleGuiElementEvent(event);
				break;
			case SDL_SCANCODE_DOWN:
				event.type = EventType.keyDir;
				event.position = Vec2f(0f, 1f);
				handleGuiElementEvent(event);
				break;
			case SDL_SCANCODE_LEFT:
				event.type = EventType.keyDir;
				event.position = Vec2f(-1f, 0f);
				handleGuiElementEvent(event);
				break;
			case SDL_SCANCODE_RIGHT:
				event.type = EventType.keyDir;
				event.position = Vec2f(1f, 0f);
				handleGuiElementEvent(event);
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
			event.type = EventType.keyInput;
			event.str = text;
			handleGuiElementEvent(event);
			break;
		case SDL_MOUSEMOTION:
			_mousePosition.set(cast(float)sdlEvent.motion.x, cast(float)sdlEvent.motion.y);
			_mousePosition = transformCanvasSpace(_mousePosition);

			event.type = EventType.mouseUpdate;
			event.position = _mousePosition;

			handleGuiElementEvent(event);
			break;
		case SDL_MOUSEBUTTONDOWN:
			_mousePosition.set(cast(float)sdlEvent.motion.x, cast(float)sdlEvent.motion.y);
			_mousePosition = transformCanvasSpace(_mousePosition);
			_buttons[sdlEvent.button.button] = true;
			
			event.type = EventType.mouseDown;
			event.position = _mousePosition;

			handleGuiElementEvent(event);
			break;
		case SDL_MOUSEBUTTONUP:
			_mousePosition.set(cast(float)sdlEvent.motion.x, cast(float)sdlEvent.motion.y);
			_mousePosition = transformCanvasSpace(_mousePosition);
			_buttons[sdlEvent.button.button] = false;

			event.type = EventType.mouseUp;
			event.position = _mousePosition;

			handleGuiElementEvent(event);
			break;
		case SDL_MOUSEWHEEL:
			event.type = EventType.mouseWheel;
			event.position = Vec2f(sdlEvent.wheel.x, sdlEvent.wheel.y);
			handleGuiElementEvent(event);
			break;
		case SDL_WINDOWEVENT:
			switch (sdlEvent.window.event) {
				case SDL_WINDOWEVENT_RESIZED:
					//setWindowSize(Vec2u(sdlEvent.window.data1, sdlEvent.window.data2));
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

			event.type = EventType.dropFile;
			event.str = path;
			handleGuiElementEvent(event);

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
			case quit:
				_isRunning = false;
				handleGuiElementEvent(globalEvent);
                destroyWindow();
				return false;
			default:
				handleGuiElementEvent(globalEvent);
				break;
		}
	}
	_globalEvents.length = 0;

	return true;
}
