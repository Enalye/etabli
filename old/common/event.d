/**
    Event

    Copyright: (c) Enalye 2017
    License: Zlib
    Authors: Enalye
*/

module etabli.common.event;

import std.path;
import std.string;
import std.conv;
import std.utf;

version (linux) {
    import core.sys.posix.unistd;
    import core.sys.posix.signal;
}
version (Windows) {
    import core.stdc.signal;
}

import bindbc.sdl;

import etabli.render;
import etabli.ui;
import etabli.core;

import etabli.common.settings;
import etabli.common.controller;

static private {
    bool[KeyButton.max + 1] _keys1, _keys2;
    bool[MouseButton.max + 1] _buttons1, _buttons2;
    Vec2f _mousePosition;
    Event[] _globalEvents;
}

private shared bool _isRunning = false;

/// List of mouse buttons.
enum MouseButton : ubyte {
    left = SDL_BUTTON_LEFT,
    middle = SDL_BUTTON_MIDDLE,
    right = SDL_BUTTON_RIGHT,
    x1 = SDL_BUTTON_X1,
    x2 = SDL_BUTTON_X2,
}

/// List of keyboard buttons.
enum KeyButton {
    unknown = SDL_SCANCODE_UNKNOWN,
    a = SDL_SCANCODE_A,
    b = SDL_SCANCODE_B,
    c = SDL_SCANCODE_C,
    d = SDL_SCANCODE_D,
    e = SDL_SCANCODE_E,
    f = SDL_SCANCODE_F,
    g = SDL_SCANCODE_G,
    h = SDL_SCANCODE_H,
    i = SDL_SCANCODE_I,
    j = SDL_SCANCODE_J,
    k = SDL_SCANCODE_K,
    l = SDL_SCANCODE_L,
    m = SDL_SCANCODE_M,
    n = SDL_SCANCODE_N,
    o = SDL_SCANCODE_O,
    p = SDL_SCANCODE_P,
    q = SDL_SCANCODE_Q,
    r = SDL_SCANCODE_R,
    s = SDL_SCANCODE_S,
    t = SDL_SCANCODE_T,
    u = SDL_SCANCODE_U,
    v = SDL_SCANCODE_V,
    w = SDL_SCANCODE_W,
    x = SDL_SCANCODE_X,
    y = SDL_SCANCODE_Y,
    z = SDL_SCANCODE_Z,
    alpha1 = SDL_SCANCODE_1,
    alpha2 = SDL_SCANCODE_2,
    alpha3 = SDL_SCANCODE_3,
    alpha4 = SDL_SCANCODE_4,
    alpha5 = SDL_SCANCODE_5,
    alpha6 = SDL_SCANCODE_6,
    alpha7 = SDL_SCANCODE_7,
    alpha8 = SDL_SCANCODE_8,
    alpha9 = SDL_SCANCODE_9,
    alpha0 = SDL_SCANCODE_0,
    enter = SDL_SCANCODE_RETURN,
    escape = SDL_SCANCODE_ESCAPE,
    backspace = SDL_SCANCODE_BACKSPACE,
    tab = SDL_SCANCODE_TAB,
    space = SDL_SCANCODE_SPACE,
    minus = SDL_SCANCODE_MINUS,
    equals = SDL_SCANCODE_EQUALS,
    leftBracket = SDL_SCANCODE_LEFTBRACKET,
    rightBracket = SDL_SCANCODE_RIGHTBRACKET,
    backslash = SDL_SCANCODE_BACKSLASH,
    nonushash = SDL_SCANCODE_NONUSHASH,
    semicolon = SDL_SCANCODE_SEMICOLON,
    apostrophe = SDL_SCANCODE_APOSTROPHE,
    grave = SDL_SCANCODE_GRAVE,
    comma = SDL_SCANCODE_COMMA,
    period = SDL_SCANCODE_PERIOD,
    slash = SDL_SCANCODE_SLASH,
    capslock = SDL_SCANCODE_CAPSLOCK,
    f1 = SDL_SCANCODE_F1,
    f2 = SDL_SCANCODE_F2,
    f3 = SDL_SCANCODE_F3,
    f4 = SDL_SCANCODE_F4,
    f5 = SDL_SCANCODE_F5,
    f6 = SDL_SCANCODE_F6,
    f7 = SDL_SCANCODE_F7,
    f8 = SDL_SCANCODE_F8,
    f9 = SDL_SCANCODE_F9,
    f10 = SDL_SCANCODE_F10,
    f11 = SDL_SCANCODE_F11,
    f12 = SDL_SCANCODE_F12,
    printScreen = SDL_SCANCODE_PRINTSCREEN,
    scrollLock = SDL_SCANCODE_SCROLLLOCK,
    pause = SDL_SCANCODE_PAUSE,
    insert = SDL_SCANCODE_INSERT,
    home = SDL_SCANCODE_HOME,
    pageup = SDL_SCANCODE_PAGEUP,
    remove = SDL_SCANCODE_DELETE,
    end = SDL_SCANCODE_END,
    pagedown = SDL_SCANCODE_PAGEDOWN,
    right = SDL_SCANCODE_RIGHT,
    left = SDL_SCANCODE_LEFT,
    down = SDL_SCANCODE_DOWN,
    up = SDL_SCANCODE_UP,
    numLockclear = SDL_SCANCODE_NUMLOCKCLEAR,
    numDivide = SDL_SCANCODE_KP_DIVIDE,
    numMultiply = SDL_SCANCODE_KP_MULTIPLY,
    numMinus = SDL_SCANCODE_KP_MINUS,
    numPlus = SDL_SCANCODE_KP_PLUS,
    numEnter = SDL_SCANCODE_KP_ENTER,
    num1 = SDL_SCANCODE_KP_1,
    num2 = SDL_SCANCODE_KP_2,
    num3 = SDL_SCANCODE_KP_3,
    num4 = SDL_SCANCODE_KP_4,
    num5 = SDL_SCANCODE_KP_5,
    num6 = SDL_SCANCODE_KP_6,
    num7 = SDL_SCANCODE_KP_7,
    num8 = SDL_SCANCODE_KP_8,
    num9 = SDL_SCANCODE_KP_9,
    num0 = SDL_SCANCODE_KP_0,
    numPeriod = SDL_SCANCODE_KP_PERIOD,
    nonusBackslash = SDL_SCANCODE_NONUSBACKSLASH,
    application = SDL_SCANCODE_APPLICATION,
    power = SDL_SCANCODE_POWER,
    numEquals = SDL_SCANCODE_KP_EQUALS,
    f13 = SDL_SCANCODE_F13,
    f14 = SDL_SCANCODE_F14,
    f15 = SDL_SCANCODE_F15,
    f16 = SDL_SCANCODE_F16,
    f17 = SDL_SCANCODE_F17,
    f18 = SDL_SCANCODE_F18,
    f19 = SDL_SCANCODE_F19,
    f20 = SDL_SCANCODE_F20,
    f21 = SDL_SCANCODE_F21,
    f22 = SDL_SCANCODE_F22,
    f23 = SDL_SCANCODE_F23,
    f24 = SDL_SCANCODE_F24,
    execute = SDL_SCANCODE_EXECUTE,
    help = SDL_SCANCODE_HELP,
    menu = SDL_SCANCODE_MENU,
    select = SDL_SCANCODE_SELECT,
    stop = SDL_SCANCODE_STOP,
    again = SDL_SCANCODE_AGAIN,
    undo = SDL_SCANCODE_UNDO,
    cut = SDL_SCANCODE_CUT,
    copy = SDL_SCANCODE_COPY,
    paste = SDL_SCANCODE_PASTE,
    find = SDL_SCANCODE_FIND,
    mute = SDL_SCANCODE_MUTE,
    volumeUp = SDL_SCANCODE_VOLUMEUP,
    volumeDown = SDL_SCANCODE_VOLUMEDOWN,
    numComma = SDL_SCANCODE_KP_COMMA,
    numEqualsAs400 = SDL_SCANCODE_KP_EQUALSAS400,
    international1 = SDL_SCANCODE_INTERNATIONAL1,
    international2 = SDL_SCANCODE_INTERNATIONAL2,
    international3 = SDL_SCANCODE_INTERNATIONAL3,
    international4 = SDL_SCANCODE_INTERNATIONAL4,
    international5 = SDL_SCANCODE_INTERNATIONAL5,
    international6 = SDL_SCANCODE_INTERNATIONAL6,
    international7 = SDL_SCANCODE_INTERNATIONAL7,
    international8 = SDL_SCANCODE_INTERNATIONAL8,
    international9 = SDL_SCANCODE_INTERNATIONAL9,
    lang1 = SDL_SCANCODE_LANG1,
    lang2 = SDL_SCANCODE_LANG2,
    lang3 = SDL_SCANCODE_LANG3,
    lang4 = SDL_SCANCODE_LANG4,
    lang5 = SDL_SCANCODE_LANG5,
    lang6 = SDL_SCANCODE_LANG6,
    lang7 = SDL_SCANCODE_LANG7,
    lang8 = SDL_SCANCODE_LANG8,
    lang9 = SDL_SCANCODE_LANG9,
    alterase = SDL_SCANCODE_ALTERASE,
    sysreq = SDL_SCANCODE_SYSREQ,
    cancel = SDL_SCANCODE_CANCEL,
    clear = SDL_SCANCODE_CLEAR,
    prior = SDL_SCANCODE_PRIOR,
    enter2 = SDL_SCANCODE_RETURN2,
    separator = SDL_SCANCODE_SEPARATOR,
    out_ = SDL_SCANCODE_OUT,
    oper = SDL_SCANCODE_OPER,
    clearAgain = SDL_SCANCODE_CLEARAGAIN,
    crsel = SDL_SCANCODE_CRSEL,
    exsel = SDL_SCANCODE_EXSEL,
    num00 = SDL_SCANCODE_KP_00,
    num000 = SDL_SCANCODE_KP_000,
    thousandSeparator = SDL_SCANCODE_THOUSANDSSEPARATOR,
    decimalSeparator = SDL_SCANCODE_DECIMALSEPARATOR,
    currencyUnit = SDL_SCANCODE_CURRENCYUNIT,
    currencySubunit = SDL_SCANCODE_CURRENCYSUBUNIT,
    numLeftParenthesis = SDL_SCANCODE_KP_LEFTPAREN,
    numRightParenthesis = SDL_SCANCODE_KP_RIGHTPAREN,
    numLeftBrace = SDL_SCANCODE_KP_LEFTBRACE,
    numRightBrace = SDL_SCANCODE_KP_RIGHTBRACE,
    numTab = SDL_SCANCODE_KP_TAB,
    numBackspace = SDL_SCANCODE_KP_BACKSPACE,
    numA = SDL_SCANCODE_KP_A,
    numB = SDL_SCANCODE_KP_B,
    numC = SDL_SCANCODE_KP_C,
    numD = SDL_SCANCODE_KP_D,
    numE = SDL_SCANCODE_KP_E,
    numF = SDL_SCANCODE_KP_F,
    numXor = SDL_SCANCODE_KP_XOR,
    numPower = SDL_SCANCODE_KP_POWER,
    numPercent = SDL_SCANCODE_KP_PERCENT,
    numLess = SDL_SCANCODE_KP_LESS,
    numGreater = SDL_SCANCODE_KP_GREATER,
    numAmpersand = SDL_SCANCODE_KP_AMPERSAND,
    numDblAmpersand = SDL_SCANCODE_KP_DBLAMPERSAND,
    numVerticalBar = SDL_SCANCODE_KP_VERTICALBAR,
    numDblVerticalBar = SDL_SCANCODE_KP_DBLVERTICALBAR,
    numColon = SDL_SCANCODE_KP_COLON,
    numHash = SDL_SCANCODE_KP_HASH,
    numSpace = SDL_SCANCODE_KP_SPACE,
    numAt = SDL_SCANCODE_KP_AT,
    numExclam = SDL_SCANCODE_KP_EXCLAM,
    numMemStore = SDL_SCANCODE_KP_MEMSTORE,
    numMemRecall = SDL_SCANCODE_KP_MEMRECALL,
    numMemClear = SDL_SCANCODE_KP_MEMCLEAR,
    numMemAdd = SDL_SCANCODE_KP_MEMADD,
    numMemSubtract = SDL_SCANCODE_KP_MEMSUBTRACT,
    numMemMultiply = SDL_SCANCODE_KP_MEMMULTIPLY,
    numMemDivide = SDL_SCANCODE_KP_MEMDIVIDE,
    numPlusMinus = SDL_SCANCODE_KP_PLUSMINUS,
    numClear = SDL_SCANCODE_KP_CLEAR,
    numClearEntry = SDL_SCANCODE_KP_CLEARENTRY,
    numBinary = SDL_SCANCODE_KP_BINARY,
    numOctal = SDL_SCANCODE_KP_OCTAL,
    numDecimal = SDL_SCANCODE_KP_DECIMAL,
    numHexadecimal = SDL_SCANCODE_KP_HEXADECIMAL,
    leftControl = SDL_SCANCODE_LCTRL,
    leftShift = SDL_SCANCODE_LSHIFT,
    leftAlt = SDL_SCANCODE_LALT,
    leftGUI = SDL_SCANCODE_LGUI,
    rightControl = SDL_SCANCODE_RCTRL,
    rightShift = SDL_SCANCODE_RSHIFT,
    rightAlt = SDL_SCANCODE_RALT,
    rightGUI = SDL_SCANCODE_RGUI,
    mode = SDL_SCANCODE_MODE,
    audioNext = SDL_SCANCODE_AUDIONEXT,
    audioPrev = SDL_SCANCODE_AUDIOPREV,
    audioStop = SDL_SCANCODE_AUDIOSTOP,
    audioPlay = SDL_SCANCODE_AUDIOPLAY,
    audioMute = SDL_SCANCODE_AUDIOMUTE,
    mediaSelect = SDL_SCANCODE_MEDIASELECT,
    www = SDL_SCANCODE_WWW,
    mail = SDL_SCANCODE_MAIL,
    calculator = SDL_SCANCODE_CALCULATOR,
    computer = SDL_SCANCODE_COMPUTER,
    acSearch = SDL_SCANCODE_AC_SEARCH,
    acHome = SDL_SCANCODE_AC_HOME,
    acBack = SDL_SCANCODE_AC_BACK,
    acForward = SDL_SCANCODE_AC_FORWARD,
    acStop = SDL_SCANCODE_AC_STOP,
    acRefresh = SDL_SCANCODE_AC_REFRESH,
    acBookmarks = SDL_SCANCODE_AC_BOOKMARKS,
    brightnessDown = SDL_SCANCODE_BRIGHTNESSDOWN,
    brightnessUp = SDL_SCANCODE_BRIGHTNESSUP,
    displaysWitch = SDL_SCANCODE_DISPLAYSWITCH,
    kbdIllumToggle = SDL_SCANCODE_KBDILLUMTOGGLE,
    kbdIllumDown = SDL_SCANCODE_KBDILLUMDOWN,
    kbdIllumUp = SDL_SCANCODE_KBDILLUMUP,
    eject = SDL_SCANCODE_EJECT,
    sleep = SDL_SCANCODE_SLEEP,
    app1 = SDL_SCANCODE_APP1,
    app2 = SDL_SCANCODE_APP2
}

/// Event structure passed on onEvent() methods.
struct Event {
    /// Type of event
    enum Type : uint {
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
        callback,
        custom
    }

    /// Ctor from basic type.
    this(Type type_) {
        type = type_;
    }

    /// Base type.
    Event.Type type;
    union {
        /// For base type `keyDown` and `keyUp`.
        KeyEvent key;
        /// For base type `mouseDown`, `mouseUp` and `mouseUpdate`.
        MouseEvent mouse;
        /// For base type `mouseWheel`.
        MouseWheelEvent scroll;
        /// For base type `keyInput`.
        TextInputEvent input;
        /// For base type `dropFile`.
        DropFileEvent drop;
        /// For base type `keyDelete`.
        TextDeleteEvent textDelete;
        /// For base type `keyDir`.
        KeyMoveEvent keyMove;
        /// For base type `resize`.
        WindowEvent window;
        /// For base type `custom`.
        CustomEvent custom;
    }

    /// For base type `keyDown` and `keyUp`.
    struct KeyEvent {
        /// Which button was active
        KeyButton button;
        /// Was it repeated
        bool isRepeated;
    }

    /// For base type `mouseDown`, `mouseUp` and `mouseUpdate`.
    struct MouseEvent {
        /// Mouse position relative to its canvas. (Not an absolute position)
        Vec2f position;
        /// Button pressed or not.
        MouseButton button;
        /// How many time the button was pressed.
        uint clicks;
    }

    /// For base type `mouseWheel`.
    struct MouseWheelEvent {
        /// Direction of scrolling.
        Vec2f delta;
    }

    /// For base type `dropFile`.
    struct DropFileEvent {
        /// Full path of the file dropped.
        string filePath;
    }

    /// For base type `keyInput`.
    struct TextInputEvent {
        /// Text written by the user.
        string text;
    }

    /// For base type `keyDelete`.
    struct TextDeleteEvent {
        /// 1 = delete right char, \
        /// -1 = delete left char.
        int direction;
    }

    /// For base type `keyDir`.
    struct KeyMoveEvent {
        /// Arrow keys movement.
        Vec2f direction;
    }

    /// For base type `resize`.
    struct WindowEvent {
        /// New size of the window.
        Vec2i size;
    }

    /// Custom event
    struct CustomEvent {
        /// Identifier
        string id;
        /// User defined data
        void* data;
    }
}

/// Check whether the key associated with the ID is pressed. \
/// Do not reset the value.
bool isButtonDown(KeyButton button) {
    return _keys1[button];
}

/// Check whether the key associated with the ID is pressed. \
/// This function resets the value to false.
bool getButtonDown(KeyButton button) {
    const bool value = _keys2[button];
    _keys2[button] = false;
    return value;
}

/// Check whether the mouse button associated with the ID is pressed. \
/// Do not reset the value.
bool isButtonDown(MouseButton button) {
    return _buttons1[button];
}

/// Check whether the mouse button associated with the ID is pressed. \
/// This function resets the value to false.
bool getButtonDown(MouseButton button) {
    const bool value = _buttons2[button];
    _buttons2[button] = false;
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
void sendEvent(Event.Type eventType) {
    Event event = Event(eventType);
    _globalEvents ~= event;
}

/// Dispatch an event to GUIs.
void sendEvent(Event event) {
    _globalEvents ~= event;
}

/// Send a custom event.
void sendCustomEvent(string id, void* data = null) {
    Event event;
    event.type = Event.Type.custom;
    event.custom.id = id;
    event.custom.data = data;
    _globalEvents ~= event;
}

/// Capture interruptions.
extern (C) void signalHandler(int sig) nothrow @nogc @system {
    cast(void) sig;
    _isRunning = false;
}

/// Initialize everything mouse, keyboard or controller related.
void initializeEvents() {
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

    if (!_isRunning) {
        event.type = Event.Type.quit;
        handleElementEvent(event);
        destroyWindow();
        return false;
    }

    //Used to start receiving SDL_TEXTINPUT events
    //SDL_StartTextInput();

    while (SDL_PollEvent(&sdlEvent)) {
        switch (sdlEvent.type) {
        case SDL_QUIT:
            _isRunning = false;
            event.type = Event.Type.quit;
            handleElementEvent(event);
            destroyWindow();
            //No operation involving the SDL after this.
            return false;
        case SDL_KEYDOWN:
            if (sdlEvent.key.keysym.scancode >= _keys1.length)
                break;
            if (!sdlEvent.key.repeat) {
                _keys1[sdlEvent.key.keysym.scancode] = true;
                _keys2[sdlEvent.key.keysym.scancode] = true;
            }

            { // KeyDown Event
                event.type = Event.Type.keyDown;
                event.key.button = cast(KeyButton) sdlEvent.key.keysym.scancode;
                event.key.isRepeated = sdlEvent.key.repeat > 0;
                handleElementEvent(event);
            }
            switch (sdlEvent.key.keysym.scancode) {
            case SDL_SCANCODE_DELETE:
                event.type = Event.Type.keyDelete;
                event.textDelete.direction = 1;
                handleElementEvent(event);
                break;
            case SDL_SCANCODE_BACKSPACE:
                event.type = Event.Type.keyDelete;
                event.textDelete.direction = -1;
                handleElementEvent(event);
                break;
            case SDL_SCANCODE_RETURN:
                event.type = Event.Type.keyEnter;
                handleElementEvent(event);
                break;
            case SDL_SCANCODE_UP:
                event.type = Event.Type.keyDir;
                event.keyMove.direction = Vec2f(0f, -1f);
                handleElementEvent(event);
                break;
            case SDL_SCANCODE_DOWN:
                event.type = Event.Type.keyDir;
                event.keyMove.direction = Vec2f(0f, 1f);
                handleElementEvent(event);
                break;
            case SDL_SCANCODE_LEFT:
                event.type = Event.Type.keyDir;
                event.keyMove.direction = Vec2f(-1f, 0f);
                handleElementEvent(event);
                break;
            case SDL_SCANCODE_RIGHT:
                event.type = Event.Type.keyDir;
                event.keyMove.direction = Vec2f(1f, 0f);
                handleElementEvent(event);
                break;
            default:
                break;
            }
            break;
        case SDL_KEYUP:
            if (sdlEvent.key.keysym.scancode >= _keys1.length)
                break;
            _keys1[sdlEvent.key.keysym.scancode] = false;
            _keys2[sdlEvent.key.keysym.scancode] = false;

            { // KeyUp Event
                event.type = Event.Type.keyUp;
                event.key.button = cast(KeyButton) sdlEvent.key.keysym.scancode;
                event.key.isRepeated = sdlEvent.key.repeat > 0;
                handleElementEvent(event);
            }
            break;
        case SDL_TEXTINPUT:
            string text = to!string(sdlEvent.text.text);
            text.length = stride(text);
            event.type = Event.Type.keyInput;
            event.input.text = text;
            handleElementEvent(event);
            break;
        case SDL_MOUSEMOTION:
            _mousePosition.set(cast(float) sdlEvent.motion.x, cast(float) sdlEvent.motion.y);
            _mousePosition = transformCanvasSpace(_mousePosition);

            event.type = Event.Type.mouseUpdate;
            event.mouse.position = _mousePosition;

            handleElementEvent(event);
            break;
        case SDL_MOUSEBUTTONDOWN:
            _mousePosition.set(cast(float) sdlEvent.motion.x, cast(float) sdlEvent.motion.y);
            _mousePosition = transformCanvasSpace(_mousePosition);
            if (sdlEvent.button.button >= _buttons1.length)
                break;
            _buttons1[sdlEvent.button.button] = true;
            _buttons2[sdlEvent.button.button] = true;

            event.type = Event.Type.mouseDown;
            event.mouse.position = _mousePosition;
            event.mouse.button = cast(MouseButton) sdlEvent.button.button;
            event.mouse.clicks = sdlEvent.button.clicks;

            handleElementEvent(event);
            break;
        case SDL_MOUSEBUTTONUP:
            _mousePosition.set(cast(float) sdlEvent.motion.x, cast(float) sdlEvent.motion.y);
            _mousePosition = transformCanvasSpace(_mousePosition);
            if (sdlEvent.button.button >= _buttons1.length)
                break;
            _buttons1[sdlEvent.button.button] = false;
            _buttons2[sdlEvent.button.button] = false;

            event.type = Event.Type.mouseUp;
            event.mouse.position = _mousePosition;
            event.mouse.button = cast(MouseButton) sdlEvent.button.button;
            event.mouse.clicks = sdlEvent.button.clicks;

            handleElementEvent(event);
            break;
        case SDL_MOUSEWHEEL:
            event.type = Event.Type.mouseWheel;
            event.scroll.delta = Vec2f(sdlEvent.wheel.x, sdlEvent.wheel.y);
            handleElementEvent(event);
            break;
        case SDL_WINDOWEVENT:
            switch (sdlEvent.window.event) {
            case SDL_WINDOWEVENT_RESIZED:
                if (!isWindowLogicalSize()) {
                    event.type = Event.Type.resize;
                    event.window.size = Vec2i(sdlEvent.window.data1, sdlEvent.window.data2);
                    resizeWindow(event.window.size);
                    handleElementEvent(event);
                }
                break;
            case SDL_WINDOWEVENT_SIZE_CHANGED:
                break;
            default:
                break;
            }
            break;
        case SDL_DROPFILE:
            string path = to!string(fromStringz(sdlEvent.drop.file));
            size_t index;
            while (-1 != (index = path.indexOfAny("%"))) {
                if ((index + 3) > path.length)
                    break;
                string str = path[index + 1 .. index + 3];
                const int utfValue = parse!int(str, 16);
                const char utfChar = to!char(utfValue);

                if (index == 0)
                    path = utfChar ~ path[3 .. $];
                else if ((index + 3) == path.length)
                    path = path[0 .. index] ~ utfChar;
                else
                    path = path[0 .. index] ~ utfChar ~ path[index + 3 .. $];
            }

            event.type = Event.Type.dropFile;
            event.drop.filePath = path;
            handleElementEvent(event);

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
            setControllerAxis(cast(SDL_GameControllerAxis) sdlEvent.caxis.axis,
                sdlEvent.caxis.value);
            break;
        case SDL_CONTROLLERBUTTONDOWN:
            setControllerButton(cast(SDL_GameControllerButton) sdlEvent.cbutton.button, true);
            break;
        case SDL_CONTROLLERBUTTONUP:
            setControllerButton(cast(SDL_GameControllerButton) sdlEvent.cbutton.button, false);
            break;
        default:
            break;
        }
    }

    foreach (Event globalEvent; _globalEvents) {
        switch (globalEvent.type) with (Event.Type) {
        case quit:
            _isRunning = false;
            handleElementEvent(globalEvent);
            destroyWindow();
            return false;
        default:
            handleElementEvent(globalEvent);
            break;
        }
    }
    _globalEvents.length = 0;

    return true;
}

/// Check if the clipboard isn't empty
bool hasClipboard() {
    return cast(bool) SDL_HasClipboardText();
}

/// Returns the content of the clipboard
string getClipboard() {
    auto clipboard = SDL_GetClipboardText();
    if (clipboard) {
        string text = to!string(fromStringz(clipboard));
        SDL_free(clipboard);
        return text;
    }
    return "";
}

/// Fill the clipboard
void setClipboard(string text) {
    SDL_SetClipboardText(toStringz(text));
}
