/**
    Controller

    Copyright: (c) Enalye 2017
    License: Zlib
    Authors: Enalye
*/

module atelier.common.controller;

import bindbc.sdl;
import atelier.core;
import atelier.common.resource;

import std.string;
import std.file : exists;
import std.stdio : writeln, printf;
import std.path;

/// List of controller buttons.
enum ControllerButton {
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

/// List of controller axis.
enum ControllerAxis {
    unknown = SDL_CONTROLLER_AXIS_INVALID,
    leftX = SDL_CONTROLLER_AXIS_LEFTX,
    leftY = SDL_CONTROLLER_AXIS_LEFTY,
    rightX = SDL_CONTROLLER_AXIS_RIGHTX,
    rightY = SDL_CONTROLLER_AXIS_RIGHTY,
    leftTrigger = SDL_CONTROLLER_AXIS_TRIGGERLEFT,
    rightTrigger = SDL_CONTROLLER_AXIS_TRIGGERRIGHT
}

private struct Controller {
    SDL_GameController* sdlController;
    SDL_Joystick* sdlJoystick;
    int index, joystickId;
}

private {
    Controller[] _controllers;
    Timer[6] _analogTimers, _analogTimeoutTimers;
    bool[ControllerButton.max + 1] _buttons1, _buttons2;
    float[ControllerAxis.max + 1] _axis = 0f;
}

/// Open all the connected controllers
void initializeControllers() {
    foreach (index; 0 .. SDL_NumJoysticks())
        addController(index);
    SDL_GameControllerEventState(SDL_ENABLE);
}

/// Close all the connected controllers
void destroyControllers() {
    foreach (ref controller; _controllers)
        SDL_GameControllerClose(controller.sdlController);
}

/// Register all controller definitions in a file, must be a valid format.
void addControllerMappingsFromFile(string filePath) {
    if (!exists(filePath))
        throw new Exception("Could not find \'" ~ filePath ~ "\'.");
    if (-1 == SDL_GameControllerAddMappingsFromFile(toStringz(filePath)))
        throw new Exception("Invalid mapping file \'" ~ filePath ~ "\'.");
}

/// Register a controller definition, must be a valid format.
void addControllerMapping(string mapping) {
    if (-1 == SDL_GameControllerAddMapping(toStringz(mapping)))
        throw new Exception("Invalid mapping.");
}

/// Update the state of the controllers
void updateControllers(float deltaTime) {
    foreach (axisIndex; 0 .. 4) {
        _analogTimers[axisIndex].update(deltaTime);
        _analogTimeoutTimers[axisIndex].update(deltaTime);
    }
}

/// Attempt to connect a new controller
void addController(int index) {
    writeln("Detected device at index ", index, ".");

    auto c = SDL_JoystickNameForIndex(index);
    auto d = fromStringz(c);
    writeln("Device name: ", d);

    if (!SDL_IsGameController(index)) {
        writeln("The device is not recognised as a game controller.");
        auto stick = SDL_JoystickOpen(index);
        auto guid = SDL_JoystickGetGUID(stick);
        writeln("The device guid is: ");
        foreach (i; 0 .. 16)
            printf("%02x", guid.data[i]);
        writeln("");
        return;
    }
    writeln("The device has been detected as a game controller.");
    foreach (ref controller; _controllers) {
        if (controller.index == index) {
            writeln("The controller is already open, aborted.");
            return;
        }
    }

    auto sdlController = SDL_GameControllerOpen(index);
    if (!sdlController) {
        writeln("Could not connect the game controller.");
        return;
    }

    Controller controller;
    controller.sdlController = sdlController;
    controller.index = index;
    controller.sdlJoystick = SDL_GameControllerGetJoystick(controller.sdlController);
    controller.joystickId = SDL_JoystickInstanceID(controller.sdlJoystick);
    _controllers ~= controller;

    writeln("The game controller is now connected.");
}

/// Remove a connected controller
void removeController(int joystickId) {
    writeln("Controller disconnected: ", joystickId);

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

/// Called upon remapping
void remapController(int joystickId) {
    writeln("Controller remapped: ", joystickId);
}

/// Change the value of a controller axis.
void setControllerAxis(SDL_GameControllerAxis axis, short value) {
    if (axis > ControllerAxis.max)
        return;
    const auto v = rlerp(-32_768, 32_767, cast(float) value) * 2f - 1f;
    _axis[axis] = v;
}

/// Handle the timing of the axis
private bool updateAnalogTimer(int axisIndex, float x, float y) {
    if (axisIndex == -1)
        return false;

    enum deadzone = .5f;
    if ((x < deadzone && x > -deadzone) && (y < deadzone && y > -deadzone)) {
        _analogTimeoutTimers[axisIndex].stop();
        return false;
    }
    else {
        if (_analogTimers[axisIndex].isRunning)
            return false;
        _analogTimers[axisIndex].start(_analogTimeoutTimers[axisIndex].isRunning ? .15f : .35f);
        _analogTimeoutTimers[axisIndex].start(5f);
    }
    return true;
}

/// Change the value of a controller button.
void setControllerButton(SDL_GameControllerButton button, bool state) {
    if (button > ControllerButton.max)
        return;
    _buttons1[button] = state;
    _buttons2[button] = state;
}

/// Check whether the button associated with the ID is pressed. \
/// Do not reset the value.
bool isButtonDown(ControllerButton button) {
    return _buttons1[button];
}

/// Check whether the button associated with the ID is pressed. \
/// This function resets the value to false.
bool getButtonDown(ControllerButton button) {
    const bool value = _buttons2[button];
    _buttons2[button] = false;
    return value;
}

/// Return the current state of the axis.
float getAxis(ControllerAxis axis) {
    return _axis[axis];
}
/+
/// Returns the left stick x-axis as a button.
bool getControllerInputSingleLeftX() {
    return updateAnalogTimer(0, _left.x, 0f);
}

/// Returns the left stick y-axis as a button.
bool getControllerInputSingleLeftY() {
    return updateAnalogTimer(1, 0f, _left.y);
}

/// Returns the left stick x and y axis as a button.
bool getControllerInputSingleLeftXY() {
    return updateAnalogTimer(2, _left.x, _left.y);
}

/// Returns the right stick x-axis as a button.
bool getControllerInputSingleRightX() {
    return updateAnalogTimer(3, _right.x, 0f);
}

/// Returns the right stick y-axis as a button.
bool getControllerInputSingleRightY() {
    return updateAnalogTimer(4, 0f, _right.y);
}

/// Returns the right stick x and y axis as a button.
bool getControllerInputSingleRightXY() {
    return updateAnalogTimer(5, _right.x, _right.y);
}+/
