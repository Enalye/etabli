/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module etabli.runtime;

import core.thread;
import std.stdio : writeln;
import std.path, std.file, std.exception;
import std.datetime, std.conv;

import etabli.common;
import etabli.input;
import etabli.render;
import etabli.ui;

import etabli.window;

final class Etabli {
    static private {
        // IPS
        float _currentFps;
        long _tickStartFrame;
        int _nominalFPS = 60;

        // Modules
        Window _window;
        Renderer _renderer;
        UIManager _uiManager;
        InputManager _inputManager;
    }

    static @property pragma(inline) {
        Window window() {
            return _window;
        }

        Renderer renderer() {
            return _renderer;
        }

        /// Le gestionnaire d’interfaces
        UIManager ui() {
            return _uiManager;
        }

        /// Le gestionnaire d’entrés
        InputManager input() {
            return _inputManager;
        }
    }

    /// Ctor
    this(uint windowWidth, uint windowHeight, string windowTitle = "Établi") {
        // Initialisation des modules
        _window = new Window(windowWidth, windowHeight, windowTitle);
        _renderer = new Renderer(_window);
        _uiManager = new UIManager();
        _inputManager = new InputManager();

        initFont();
    }

    void run() {
        _tickStartFrame = Clock.currStdTime();
        float accumulator = 0f;

        while (!_inputManager.hasQuit()) {
            long deltaTicks = Clock.currStdTime() - _tickStartFrame;
            double deltatime = (cast(float)(deltaTicks) / 10_000_000f) * _nominalFPS;
            _currentFps = (deltatime == .0f) ? .0f : (10_000_000f / cast(float)(deltaTicks));
            _tickStartFrame = Clock.currStdTime();

            accumulator += deltatime;

            // Màj
            while (accumulator >= 1f) {
                InputEvent[] inputEvents = _inputManager.pollEvents();

                _window.update();
                _uiManager.dispatch(inputEvents);
                _uiManager.update();

                accumulator -= 1f;
            }

            // Rendu
            _uiManager.draw();
            _renderer.draw();
        }
    }
}
