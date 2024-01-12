/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module etabli.input.event;

import std.array : join;
import std.conv : to;
import std.math : abs;
import std.stdio;
import std.typecons;

import bindbc.sdl;

import etabli.common;

/// État d'un bouton
enum KeyState {
    none = 0,
    down = 1 << 0,
    held = 1 << 1,
    up = 1 << 2,
    pressed = down | held
}

pragma(inline) {
    /// Dans le cas d’une touche ou d’un bouton, est-il appuyé ?
    bool pressed(KeyState state) {
        return cast(bool)(state & KeyState.pressed);
    }

    /// Dans le cas d’une touche ou d’un bouton, est-il maintenu enfoncé ?
    bool held(KeyState state) {
        return cast(bool)(state & KeyState.held);
    }

    /// Dans le cas d'une touche ou d'un bouton, a-t-il été appuyé cette frame ?
    bool down(KeyState state) {
        return cast(bool)(state & KeyState.down);
    }

    /// Dans le cas d'une touche ou d'un bouton, a-t-on arreté d'appuyer dessus cette frame ?
    bool up(KeyState state) {
        return cast(bool)(state & KeyState.up);
    }
}

alias InputState = BitFlags!(KeyState, Yes.unsafe);

/// Événement utilisateur
final class InputEvent {
    /// Type d’événement
    enum Type {
        none,
        keyButton,
        mouseButton,
        mouseMotion,
        mouseWheel,
        controllerButton,
        controllerAxis,
        textInput,
        dropFile
    }

    /// Touche du clavier
    final class KeyButton {
        /// Touches du clavier
        enum Button {
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

        /// Touche du clavier
        Button button;

        /// État du bouton ou états possibles attendus du bouton
        InputState state;

        /// Est-ce une répétition de touche automatique ?
        bool echo;

        /// Init
        this(Button button_, InputState state_, bool echo_) {
            button = button_;
            state = state_;
            echo = echo_;
        }

        /// Copie
        this(const KeyButton event) {
            button = event.button;
            state = event.state;
            echo = event.echo;
        }
    }

    /// Touche de la souris
    final class MouseButton {
        /// Touches de la souris
        enum Button {
            left = SDL_BUTTON_LEFT,
            middle = SDL_BUTTON_MIDDLE,
            right = SDL_BUTTON_RIGHT,
            x1 = SDL_BUTTON_X1,
            x2 = SDL_BUTTON_X2,
        }

        /// Touche de la souris
        Button button;

        /// État du bouton ou états possibles attendus du bouton
        InputState state;

        /// Combien de fois cette touche a été appuyé ?
        uint clicks;

        /// Position du curseur
        Vec2f position;

        /// Position par rapport à la dernière position
        Vec2f deltaPosition;

        /// Init
        this(Button button_, InputState state_, uint clicks_,
            Vec2f position_, Vec2f deltaPosition_) {
            button = button_;
            state = state_;
            clicks = clicks_;
            position = position_;
            deltaPosition = deltaPosition_;
        }

        /// Copie
        this(const MouseButton event) {
            button = event.button;
            state = event.state;
            clicks = event.clicks;
            position = event.position;
            deltaPosition = event.deltaPosition;
        }
    }

    /// Déplacement de la souris
    final class MouseMotion {
        /// Position du curseur
        Vec2f position;

        /// Position par rapport à la dernière position
        Vec2f deltaPosition;

        /// Init
        this(Vec2f position_, Vec2f deltaPosition_) {
            position = position_;
            deltaPosition = deltaPosition_;
        }

        /// Copie
        this(const MouseMotion event) {
            position = event.position;
            deltaPosition = event.deltaPosition;
        }
    }

    /// Molette de la souris
    final class MouseWheel {
        /// Molette
        Vec2i wheel;

        /// Init
        this(Vec2i wheel_) {
            wheel = wheel_;
        }

        /// Copie
        this(const MouseWheel event) {
            wheel = event.wheel;
        }
    }

    /// Bouton de la manette
    final class ControllerButton {
        /// Boutons de la manette
        enum Button {
            unknown = SDL_CONTROLLER_BUTTON_INVALID,
            a = SDL_CONTROLLER_BUTTON_A,
            b = SDL_CONTROLLER_BUTTON_B,
            x = SDL_CONTROLLER_BUTTON_X,
            y = SDL_CONTROLLER_BUTTON_Y,
            back = SDL_CONTROLLER_BUTTON_BACK,
            guide = SDL_CONTROLLER_BUTTON_GUIDE,
            start = SDL_CONTROLLER_BUTTON_START,
            leftStick = SDL_CONTROLLER_BUTTON_LEFTSTICK,
            rightStick = SDL_CONTROLLER_BUTTON_RIGHTSTICK,
            leftShoulder = SDL_CONTROLLER_BUTTON_LEFTSHOULDER,
            rightShoulder = SDL_CONTROLLER_BUTTON_RIGHTSHOULDER,
            up = SDL_CONTROLLER_BUTTON_DPAD_UP,
            down = SDL_CONTROLLER_BUTTON_DPAD_DOWN,
            left = SDL_CONTROLLER_BUTTON_DPAD_LEFT,
            right = SDL_CONTROLLER_BUTTON_DPAD_RIGHT
        }

        /// Bouton de la manette
        Button button;

        /// État du bouton ou états possibles attendus du bouton
        InputState state;

        /// Init
        this(Button button_, InputState state_) {
            button = button_;
            state = state_;
        }

        /// Copie
        this(const ControllerButton event) {
            button = event.button;
            state = event.state;
        }
    }

    /// Axe de la manette
    final class ControllerAxis {
        /// Axes de la manette
        enum Axis {
            unknown = SDL_CONTROLLER_AXIS_INVALID,
            leftX = SDL_CONTROLLER_AXIS_LEFTX,
            leftY = SDL_CONTROLLER_AXIS_LEFTY,
            rightX = SDL_CONTROLLER_AXIS_RIGHTX,
            rightY = SDL_CONTROLLER_AXIS_RIGHTY,
            leftTrigger = SDL_CONTROLLER_AXIS_TRIGGERLEFT,
            rightTrigger = SDL_CONTROLLER_AXIS_TRIGGERRIGHT
        }

        /// Axe de la manette
        Axis axis;

        /// La valeur de l’axe
        double value;

        /// Le seuil de l'axe
        double deadzone;

        /// Init
        this(Axis axis_, double value_, double deadzone_ = 0.2) {
            axis = axis_;
            value = value_;
            deadzone = deadzone_;
        }

        /// Copie
        this(const ControllerAxis event) {
            axis = event.axis;
            value = event.value;
            deadzone = event.deadzone;
        }
    }

    /// Texte entré par l’utilisateur
    final class TextInput {
        /// Texte
        string text;

        /// Init
        this(string text_) {
            text = text_;
        }

        /// Copie
        this(const TextInput event) {
            text = event.text;
        }
    }

    /// Fichier glissé/déposé dans la fenêtre de l’application
    final class DropFile {
        /// Chemin du fichier
        string path;

        /// Init
        this(string path_) {
            path = path_;
        }

        /// Copie
        this(const DropFile event) {
            path = event.path;
        }
    }

    private {
        Type _type;
        bool _isAccepted;

        union {
            KeyButton _keyButton;
            MouseButton _mouseButton;
            MouseMotion _mouseMotion;
            MouseWheel _mouseWheel;
            ControllerButton _controllerButton;
            ControllerAxis _controllerAxis;
            TextInput _textInput;
            DropFile _dropFile;
        }
    }

    @property {
        /// Type de l’événement
        Type type() const {
            return _type;
        }

        /// Si l’événement est de type KeyButton, le retourne, sinon retourne null
        KeyButton asKeyButton() {
            if (_type != Type.keyButton)
                return null;
            return _keyButton;
        }

        /// Si l’événement est de type MouseButton, le retourne, sinon retourne null
        MouseButton asMouseButton() {
            if (_type != Type.mouseButton)
                return null;
            return _mouseButton;
        }

        /// Si l’événement est de type MouseMotion, le retourne, sinon retourne null
        MouseMotion asMouseMotion() {
            if (_type != Type.mouseMotion)
                return null;
            return _mouseMotion;
        }

        /// Si l’événement est de type MouseWheel, le retourne, sinon retourne null
        MouseWheel asMouseWheel() {
            if (_type != Type.mouseWheel)
                return null;
            return _mouseWheel;
        }

        /// Si l’événement est de type ControllerButton, le retourne, sinon retourne null
        ControllerButton asControllerButton() {
            if (_type != Type.controllerButton)
                return null;
            return _controllerButton;
        }

        /// Si l’événement est de type ControllerAxis, le retourne, sinon retourne null
        ControllerAxis asControllerAxis() {
            if (_type != Type.controllerAxis)
                return null;
            return _controllerAxis;
        }

        /// Si l’événement est de type TextInput, le retourne, sinon retourne null
        TextInput asTextInput() {
            if (_type != Type.textInput)
                return null;
            return _textInput;
        }

        /// Si l’événement est de type DropFile, le retourne, sinon retourne null
        DropFile asDropFile() {
            if (_type != Type.dropFile)
                return null;
            return _dropFile;
        }

        InputState state() const {
            switch (_type) with (Type) {
            case keyButton:
                return _keyButton.state;
            case mouseButton:
                return _mouseButton.state;
            case controllerButton:
                return _controllerButton.state;
            default:
                return InputState();
            }
        }

        /// Dans le cas d’une touche ou d’un bouton, est-il appuyé ?
        bool pressed() const {
            return state.pressed();
        }

        /// Dans le cas d’une touche ou d’un bouton, est-il maintenu enfoncé ?
        bool held() const {
            return state.held();
        }

        /// Dans le cas d'une touche ou d'un bouton, a-t-il été appuyé cette frame ?
        bool down() const {
            return state.down();
        }

        /// Dans le cas d'une touche ou d'un bouton, a-t-on arreté d'appuyer dessus cette frame ?
        bool up() const {
            return state.held();
        }

        /// L’événement est-il un écho ?
        bool echo() const {
            switch (_type) with (Type) {
            case keyButton:
                return _keyButton.echo;
            default:
                return false;
            }
        }

        /// Valeur analogique du bouton ou de l’axe
        double value() const {
            switch (_type) with (Type) {
            case keyButton:
            case mouseButton:
            case controllerButton:
                return pressed ? 1.0 : .0;
            case controllerAxis:
                return _controllerAxis.value;
            default:
                return .0;
            }
        }

        /// Formate l'etat
        string infoState() const {
            if (down) {
                return "down";
            }
            else if (held) {
                return "held";
            }
            else if (up) {
                return "up";
            }
            else {
                return "none";
            }
        }

        /// Formate l’événement
        string prettify() const {
            string txt = __traits(identifier, typeof(this));
            string[] info;
            txt ~= "{ ";
            info ~= to!string(_type);

            final switch (_type) with (Type) {
            case none:
                break;
            case keyButton:
                info ~= "button: " ~ to!string(_keyButton.button);
                info ~= infoState;
                if (_keyButton.echo)
                    info ~= "echo";
                break;
            case mouseButton:
                info ~= "button: " ~ to!string(_mouseButton.button);
                info ~= infoState;
                info ~= "clicks: " ~ to!string(_mouseButton.clicks);
                info ~= "position: " ~ to!string(_mouseButton.position);
                info ~= "deltaPosition: " ~ to!string(_mouseButton.deltaPosition);
                break;
            case mouseMotion:
                info ~= "position: " ~ to!string(_mouseMotion.position);
                info ~= "deltaPosition: " ~ to!string(_mouseMotion.deltaPosition);
                break;
            case mouseWheel:
                info ~= "wheel: " ~ to!string(_mouseWheel.wheel);
                break;
            case controllerButton:
                info ~= "button: " ~ to!string(_controllerButton.button);
                info ~= infoState;
                break;
            case controllerAxis:
                info ~= "axis: " ~ to!string(_controllerAxis.axis);
                info ~= "value: " ~ to!string(_controllerAxis.value);
                break;
            case textInput:
                info ~= "text: " ~ to!string(_textInput.text);
                break;
            case dropFile:
                info ~= "path: " ~ to!string(_dropFile.path);
                break;
            }
            txt ~= info.join(", ");
            txt ~= " }";
            return txt;
        }

        /// L’événement a-t’il été consommé ?
        final isAccepted() const {
            return _isAccepted;
        }
    }

    private this() {
    }

    /// Copie
    this(const InputEvent event) {
        _type = event._type;
        _isAccepted = event._isAccepted;

        final switch (_type) with (Type) {
        case none:
            break;
        case keyButton:
            _keyButton = new KeyButton(event._keyButton);
            break;
        case mouseButton:
            _mouseButton = new MouseButton(event._mouseButton);
            break;
        case mouseMotion:
            _mouseMotion = new MouseMotion(event._mouseMotion);
            break;
        case mouseWheel:
            _mouseWheel = new MouseWheel(event._mouseWheel);
            break;
        case controllerButton:
            _controllerButton = new ControllerButton(event._controllerButton);
            break;
        case controllerAxis:
            _controllerAxis = new ControllerAxis(event._controllerAxis);
            break;
        case textInput:
            _textInput = new TextInput(event._textInput);
            break;
        case dropFile:
            _dropFile = new DropFile(event._dropFile);
            break;
        }
    }

    private {
        void _makeKeyButton(KeyButton.Button button, InputState state, bool echo) {
            _keyButton = new KeyButton(button, state, echo);
        }

        void _makeMouseButton(MouseButton.Button button, InputState state,
            uint clicks, Vec2f position, Vec2f deltaPosition) {
            _mouseButton = new MouseButton(button, state, clicks,
                position, deltaPosition);
        }

        void _makeMouseMotion(Vec2f position, Vec2f deltaPosition) {
            _mouseMotion = new MouseMotion(position, deltaPosition);
        }

        void _makeMouseWheel(Vec2i wheel) {
            _mouseWheel = new MouseWheel(wheel);
        }

        void _makeControllerButton(ControllerButton.Button button, InputState state) {
            _controllerButton = new ControllerButton(button, state);
        }

        void _makeControllerAxis(ControllerAxis.Axis axis, double value) {
            _controllerAxis = new ControllerAxis(axis, value);
        }

        void _makeTextInput(string text) {
            _textInput = new TextInput(text);
        }

        void _makeDropFile(string path) {
            _dropFile = new DropFile(path);
        }
    }

    /// Touche du clavier
    static {
        /// Retourne un événement correspondant à une touche du clavier
        InputEvent keyButton(KeyButton.Button button, InputState state, bool echo = false) {
            InputEvent event = new InputEvent;
            event._type = Type.keyButton;
            event._isAccepted = false;
            event._makeKeyButton(button, state, echo);
            return event;
        }

        /// Retourne un événement correspondant à une touche de la souris
        InputEvent mouseButton(MouseButton.Button button, InputState state,
            uint clicks, Vec2f position, Vec2f deltaPosition) {
            InputEvent event = new InputEvent;
            event._type = Type.mouseButton;
            event._isAccepted = false;
            event._makeMouseButton(button, state, clicks, position, deltaPosition);
            return event;
        }

        /// Retourne un événement correspondant à un déplacement de la souris
        InputEvent mouseMotion(Vec2f position, Vec2f deltaPosition) {
            InputEvent event = new InputEvent;
            event._type = Type.mouseMotion;
            event._isAccepted = false;
            event._makeMouseMotion(position, deltaPosition);
            return event;
        }

        /// Retourne un événement correspondant à un mouvement de la molette de la souris
        InputEvent mouseWheel(Vec2i wheel) {
            InputEvent event = new InputEvent;
            event._type = Type.mouseWheel;
            event._isAccepted = false;
            event._makeMouseWheel(wheel);
            return event;
        }

        /// Retourne un événement correspondant à un bouton de la manette
        InputEvent controllerButton(ControllerButton.Button button, InputState state) {
            InputEvent event = new InputEvent;
            event._type = Type.controllerButton;
            event._isAccepted = false;
            event._makeControllerButton(button, state);
            return event;
        }

        /// Retourne un événement correspondant à un bouton de la manette
        InputEvent controllerAxis(ControllerAxis.Axis axis, double value) {
            InputEvent event = new InputEvent;
            event._type = Type.controllerAxis;
            event._isAccepted = false;
            event._makeControllerAxis(axis, value);
            return event;
        }

        /// Retourne un événement correspondant à un mouvement de la molette de la souris
        InputEvent textInput(string text) {
            InputEvent event = new InputEvent;
            event._type = Type.textInput;
            event._isAccepted = false;
            event._makeTextInput(text);
            return event;
        }

        /// Retourne un événement correspondant à un mouvement de la molette de la souris
        InputEvent dropFile(string path) {
            InputEvent event = new InputEvent;
            event._type = Type.dropFile;
            event._isAccepted = false;
            event._makeDropFile(path);
            return event;
        }
    }

    /// L'événement correspond-il a un input donné?
    bool matchExpectedState(const KeyState inputState) const {
        switch (_type) with (Type) {
        case keyButton:
            return cast(bool)(_keyButton.state & inputState);
        case mouseButton:
            return cast(bool)(_mouseButton.state & inputState);
        case controllerButton:
            return cast(bool)(_controllerButton.state & inputState);
        default:
            return false;
        }
    }

    /// L'événement correspond-il a une limite d'axe donnée?
    /// Précondition: l'événement est pour un axe de manette
    bool matchAxisValue(const double value) {
        const double strength = _controllerAxis.value;
        const double deadzone = _controllerAxis.deadzone;

        if ((value < 0.0) == (strength < 0.0) && (value > 0.0) == (strength > 0.0)) {
            return abs(value) > deadzone;
        }

        return false;
    }

    /// L’événement a-t-il le meme input que l'autre ?
    bool matchInput(const InputEvent event) const {
        switch (_type) with (Type) {
        case keyButton:
            return _keyButton.button == event._keyButton.button;
        case mouseButton:
            return _mouseButton.button == event._mouseButton.button;
        case controllerButton:
            return _controllerButton.button == event._controllerButton.button;
        case controllerAxis:
            return _controllerAxis.axis == event._controllerAxis.axis &&
                (event._controllerAxis.value < 0.0) == (_controllerAxis.value < 0.0) &&
                (event._controllerAxis.value > 0.0) == (_controllerAxis.value > 0.0);
        default:
            return false;
        }
    }

    /// Consomme l’événement et empêche sa propagation
    void accept() {
        _isAccepted = true;
    }
}
