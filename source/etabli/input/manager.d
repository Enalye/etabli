/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module etabli.input.manager;

version (linux) {
    import core.sys.posix.unistd;
    import core.sys.posix.signal;
}
version (Windows) {
    import core.stdc.signal;
}

import std.file : exists;
import std.conv : to, parse;
import std.math : abs;
import std.path, std.string, std.utf;
import std.stdio;

import bindbc.sdl;

import etabli.common;
import etabli.runtime;
import etabli.render;
import etabli.window;

import etabli.input.event;
import etabli.input.map;
import etabli.input.data;

private shared {
    bool _hasQuit;
}

/// Gère les entrés et notifications de l’application
final class InputManager {
    private {
        final class Controller {
            SDL_GameController* sdlController;
            SDL_Joystick* sdlJoystick;
            int index, joystickId;
        }

        // Input handlers
        InputMap _map;
        Controller[] _controllers;

        Vec2f _mousePosition = Vec2f.zero, _deltaMousePosition = Vec2f.zero;
        Vec2i _mouseWheel;

        KeyState[InputEvent.KeyButton.Button.max + 1] _keyButtonStates;
        KeyState[InputEvent.MouseButton.Button.max + 1] _mouseButtonStates;
        KeyState[InputEvent.ControllerButton.Button.max + 1] _controllerButtonStates;
        double[InputEvent.ControllerAxis.Axis.max + 1] _controllerAxisValues = .0;

        struct ActionState {
            string id;
            bool activated = false;
            double strength = 0.0;

            this(string id_) {
                id = id_;
            }
        }

        ActionState[string] _actionStates;
    }

    @property {
        /// Notifie d’une demande pour quitter l’application
        bool hasQuit() const {
            return _hasQuit;
        }

        /// Vérifie si le presse papier contient quelque chose
        bool hasClipboard() const {
            return cast(bool) SDL_HasClipboardText();
        }
    }

    /// Init
    this() {
        signal(SIGINT, &_signalHandler);
        _mousePosition = Vec2f.zero;
        _deltaMousePosition = Vec2f.zero;

        // Ouvre la base de donnée des manettes
        foreach (string line; _gameControllerDb.splitLines()) {
            if (!line.length || line[0] == '#')
                continue;

            _addControllerMapping(line);
        }

        // Initialise toutes les manettes connectées
        foreach (index; 0 .. SDL_NumJoysticks())
            _addController(index);
        SDL_GameControllerEventState(SDL_ENABLE);

        //SDL_SetRelativeMouseMode(SDL_TRUE);
        //SDL_ShowCursor(SDL_DISABLE);

        _map = new InputMap;
    }

    /// Récupère le contenu du presse-papier
    string getClipboard() const {
        auto clipboard = SDL_GetClipboardText();

        if (!clipboard)
            return "";

        string text = to!string(fromStringz(clipboard));
        SDL_free(clipboard);
        return text;
    }

    /// Renseigne le presse-papier
    void setClipboard(string text) {
        SDL_SetClipboardText(toStringz(text));
    }

    /// Récupère les événements (clavier/souris/manette/etc)
    /// et les événements de la fenêtre (redimmensionnement/glisser-déposer/etc)
    /// et les redistribue sous forme d’InputEvent
    InputEvent[] pollEvents() {
        InputEvent[] events;
        SDL_Event sdlEvent;

        // Reset mouse wheel
        _mouseWheel = Vec2i.zero;

        // Update key states FSM
        _updateKeyStates();

        while (SDL_PollEvent(&sdlEvent)) {
            switch (sdlEvent.type) {
            case SDL_QUIT:
                _hasQuit = true;
                break;
            case SDL_KEYDOWN:
                InputEvent.KeyButton.Button button = cast(
                    InputEvent.KeyButton.Button) sdlEvent.key.keysym.scancode;

                if (button > InputEvent.KeyButton.Button.max)
                    break;

                if (_keyButtonStates[button] == KeyState.none) {
                    _keyButtonStates[button] = KeyState.down;
                }

                InputState state = InputState(_keyButtonStates[button]);
                events ~= InputEvent.keyButton(button, state, sdlEvent.key.repeat > 0);
                break;
            case SDL_KEYUP:
                InputEvent.KeyButton.Button button = cast(
                    InputEvent.KeyButton.Button) sdlEvent.key.keysym.scancode;

                if (button > InputEvent.KeyButton.Button.max)
                    break;

                _keyButtonStates[button] = KeyState.up;

                InputState state = InputState(_keyButtonStates[button]);
                events ~= InputEvent.keyButton(button, state, sdlEvent.key.repeat > 0);
                break;
            case SDL_TEXTINPUT:
                string text = to!string(sdlEvent.text.text);
                text.length = stride(text);
                InputEvent event = InputEvent.textInput(text);

                events ~= event;
                break;
            case SDL_MOUSEMOTION:
                _mousePosition = Vec2f(sdlEvent.motion.x, sdlEvent.motion.y);
                _deltaMousePosition = Vec2f(sdlEvent.motion.xrel, sdlEvent.motion.yrel);
                InputEvent event = InputEvent.mouseMotion( //
                    _mousePosition, //
                    _deltaMousePosition);

                events ~= event;
                break;
            case SDL_MOUSEBUTTONDOWN:
                InputEvent.MouseButton.Button button = cast(
                    InputEvent.MouseButton.Button) sdlEvent.button.button;

                if (button > InputEvent.MouseButton.Button.max)
                    break;

                _mousePosition = Vec2f(sdlEvent.button.x, sdlEvent.button.y);

                if (_mouseButtonStates[button] == KeyState.none) {
                    _mouseButtonStates[button] = KeyState.down;
                }

                InputState state = InputState(_mouseButtonStates[button]);
                events ~= InputEvent.mouseButton(button, state,
                    sdlEvent.button.clicks, _mousePosition, _deltaMousePosition);
                break;
            case SDL_MOUSEBUTTONUP:
                InputEvent.MouseButton.Button button = cast(
                    InputEvent.MouseButton.Button) sdlEvent.button.button;

                if (button > InputEvent.MouseButton.Button.max)
                    break;

                _mousePosition = Vec2f(sdlEvent.button.x, sdlEvent.button.y);
                _mouseButtonStates[button] = KeyState.up;

                InputState state = InputState(_mouseButtonStates[button]);
                events ~= InputEvent.mouseButton(button, state,
                    sdlEvent.button.clicks, _mousePosition, _deltaMousePosition);
                break;
            case SDL_MOUSEWHEEL:
                _mouseWheel = Vec2i(sdlEvent.wheel.x, sdlEvent.wheel.y);
                InputEvent event = InputEvent.mouseWheel(_mouseWheel);
                events ~= event;
                break;
            case SDL_CONTROLLERDEVICEADDED:
                _addController(sdlEvent.cdevice.which);
                break;
            case SDL_CONTROLLERDEVICEREMOVED:
                _removeController(sdlEvent.cdevice.which);
                break;
            case SDL_CONTROLLERDEVICEREMAPPED:
                break;
            case SDL_CONTROLLERAXISMOTION:
                InputEvent.ControllerAxis.Axis axis = cast(
                    InputEvent.ControllerAxis.Axis) sdlEvent.caxis.axis;

                if (axis > InputEvent.ControllerAxis.Axis.max)
                    break;

                const double value = rlerp(-32_768, 32_767, cast(double) sdlEvent.caxis.value) *
                    2f - 1f;
                _controllerAxisValues[axis] = value;

                events ~= InputEvent.controllerAxis(axis, value);
                break;
            case SDL_CONTROLLERBUTTONDOWN:
                InputEvent.ControllerButton.Button button = cast(
                    InputEvent.ControllerButton.Button) sdlEvent.cbutton.button;

                if (button > InputEvent.ControllerButton.Button.max)
                    break;

                if (_controllerButtonStates[button] == KeyState.none) {
                    _controllerButtonStates[button] = KeyState.down;
                }

                InputState state = InputState(_controllerButtonStates[button]);
                events ~= InputEvent.controllerButton(button, state);
                break;
            case SDL_CONTROLLERBUTTONUP:
                InputEvent.ControllerButton.Button button = cast(
                    InputEvent.ControllerButton.Button) sdlEvent.cbutton.button;

                if (button > InputEvent.ControllerButton.Button.max)
                    break;

                _controllerButtonStates[button] = KeyState.up;

                InputState state = InputState(_controllerButtonStates[button]);
                events ~= InputEvent.controllerButton(button, state);
                break;
            case SDL_WINDOWEVENT:
                import std.stdio;

                switch (sdlEvent.window.event) {
                case SDL_WINDOWEVENT_RESIZED:
                case SDL_WINDOWEVENT_SIZE_CHANGED:
                    Etabli.window.onSize(sdlEvent.window.data1, sdlEvent.window.data2);
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
                SDL_free(sdlEvent.drop.file);

                InputEvent event = InputEvent.dropFile(path);
                events ~= event;
                break;
            default:
                break;
            }
        }

        _updateActionStates();

        return events;
    }

    /// Enregistre toutes les définitions de manettes depuis un fichier valide
    private void _addControllerMappingsFromFile(string filePath) {
        if (!exists(filePath))
            throw new Exception("could not find `" ~ filePath ~ "`");
        if (-1 == SDL_GameControllerAddMappingsFromFile(toStringz(filePath)))
            throw new Exception("invalid mapping file `" ~ filePath ~ "`");
    }

    /// Enregistre une définition de manette
    private void _addControllerMapping(string mapping) {
        if (-1 == SDL_GameControllerAddMapping(toStringz(mapping)))
            throw new Exception("invalid mapping");
    }

    /// Ajoute une manette connectée
    private void _addController(int index) {
        //writeln("Detected device at index ", index, ".");

        auto c = SDL_JoystickNameForIndex(index);
        auto d = fromStringz(c);
        //writeln("Device name: ", d);

        if (!SDL_IsGameController(index)) {
            //writeln("The device is not recognised as a game controller.");
            auto stick = SDL_JoystickOpen(index);
            auto guid = SDL_JoystickGetGUID(stick);
            //writeln("The device guid is: ");
            //foreach (i; 0 .. 16)
            //    printf("%02x", guid.data[i]);
            //writeln("");
            return;
        }
        //writeln("The device has been detected as a game controller.");
        foreach (controller; _controllers) {
            if (controller.index == index) {
                //writeln("The controller is already open, aborted.");
                return;
            }
        }

        auto sdlController = SDL_GameControllerOpen(index);
        if (!sdlController) {
            //writeln("Could not connect the game controller.");
            return;
        }

        Controller controller = new Controller;
        controller.sdlController = sdlController;
        controller.index = index;
        controller.sdlJoystick = SDL_GameControllerGetJoystick(controller.sdlController);
        controller.joystickId = SDL_JoystickInstanceID(controller.sdlJoystick);
        _controllers ~= controller;

        //writeln("The game controller is now connected.");
    }

    /// Retire une manette déconnectée
    private void _removeController(int joystickId) {
        //writeln("Controller disconnected: ", joystickId);

        int index;
        bool isControllerPresent;
        foreach (ref controller; _controllers) {
            if (controller.joystickId == joystickId) {
                isControllerPresent = true;
                break;
            }
            index++;
        }

        if (!isControllerPresent)
            return;

        SDL_GameControllerClose(_controllers[index].sdlController);

        //Remove from list
        if (index + 1 == _controllers.length)
            _controllers.length--;
        else if (index == 0)
            _controllers = _controllers[1 .. $];
        else
            _controllers = _controllers[0 .. index] ~ _controllers[(index + 1) .. $];
    }

    // Mise à jour des états de chaque touche naturelle
    private void _updateKeyStates() {
        foreach (ref KeyState keyState; _keyButtonStates) {
            _updateKeyState(keyState);
        }

        foreach (ref KeyState keyState; _mouseButtonStates) {
            _updateKeyState(keyState);
        }

        foreach (ref KeyState keyState; _controllerButtonStates) {
            _updateKeyState(keyState);
        }
    }

    // Mise à jour des états d'une touche naturelle
    private void _updateKeyState(ref KeyState keyState) {
        if (keyState == KeyState.down) {
            keyState = KeyState.held;
        }
        else if (keyState == KeyState.up) {
            keyState = KeyState.none;
        }
    }

    // Mise à jour des états des actions
    private void _updateActionStates() {
        foreach (ref ActionState actionState; _actionStates) {
            InputMap.Action action = _map.getAction(actionState.id);
            bool actionActivated = false;
            double actionStrength = 0.0;

            foreach (InputEvent event; action.events) {
                double eventStrength = 0.0;

                /// Skip inputs not triggered
                if (!matchManagedInput(event)) {
                    continue;
                }

                switch (event.type) with (InputEvent.Type) {
                case keyButton:
                case mouseButton:
                case mouseWheel:
                case controllerButton:
                    eventStrength = event.value;
                    break;
                case controllerAxis:
                    const InputEvent.ControllerAxis controllerAxis = event.asControllerAxis();
                    double strength = getAxis(controllerAxis.axis);
                    strength = clamp(abs(strength), 0.0, 1.0);
                    eventStrength = rlerp(controllerAxis.deadzone, 1.0, strength);
                    break;
                default:
                    break;
                }

                actionActivated = true;
                actionStrength += eventStrength;
            }

            actionState.activated = actionActivated;
            actionState.strength = clamp(actionStrength, 0.0, 1.0);
        }
    }

    /// Est-ce qu'un evenement attendu associe a une action matche un veritable input ?
    private bool matchManagedInput(InputEvent event) {
        switch (event.type) with (InputEvent.Type) {
        case keyButton:
            return event.matchExpectedState(_keyButtonStates[event.asKeyButton.button]);
        case mouseButton:
            return event.matchExpectedState(_mouseButtonStates[event.asMouseButton.button]);
        case controllerButton:
            return event.matchExpectedState(
                _controllerButtonStates[event.asControllerButton.button]);
        case controllerAxis:
            return event.matchAxisValue(_controllerAxisValues[event.asControllerAxis.axis]);
        default:
            return false;
        }
    }

    /// Est-ce que la touche est appuyée ?
    bool isPressed(InputEvent.KeyButton.Button button) const {
        return _keyButtonStates[button].pressed();
    }

    /// Ditto
    bool isPressed(InputEvent.MouseButton.Button button) const {
        return _mouseButtonStates[button].pressed();
    }

    /// Ditto
    bool isPressed(InputEvent.ControllerButton.Button button) const {
        return _controllerButtonStates[button].pressed();
    }

    /// Retourne la valeur de l’axe
    double getAxis(InputEvent.ControllerAxis.Axis axis) const {
        return _controllerAxisValues[axis];
    }

    /// Ajoute une nouvelle action
    void addAction(string id) {
        _map.addAction(id);
        _actionStates[id] = ActionState(id);
    }

    /// Retire une action existante
    void removeAction(string id) {
        _map.removeAction(id);
    }

    /// Vérifie si une action existe
    bool hasAction(string id) const {
        return _map.hasAction(id);
    }

    /// Cet événement correspond-t’il a une action ?
    bool isAction(string id, InputEvent event) {
        InputMap.Action action = _map.getAction(id);
        return action ? action.match(event) : false;
    }

    /// Associe un événement à une action existante
    void addActionEvent(string id, InputEvent event) {
        _map.addActionEvent(id, event);
    }

    /// Supprime tous les événements associés à une action
    void removeActionEvents(string id) {
        _map.removeActionEvents(id);
    }

    /// L’action est-t’elle activée ?
    bool activated(string id) const {
        auto action = id in _actionStates;
        return action ? (*action).activated : false;
    }

    double getActionStrength(string id) const {
        auto action = id in _actionStates;
        return action ? (*action).strength : 0.0;
    }

    double getActionAxis(string negativeId, string positiveId) {
        return getActionStrength(positiveId) - getActionStrength(negativeId);
    }

    /*
    vec2f getVector(string leftAction, string rightAction, string upAction, string downAction) {

    }*/
}

/// Capture les interruptions
private extern (C) void _signalHandler(int sig) nothrow @nogc @system {
    cast(void) sig;
    _hasQuit = true;
}
