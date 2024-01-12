/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module etabli.window;

import std.exception : enforce;
import std.string : toStringz, fromStringz;

import bindbc.sdl;

import etabli.common;
import etabli.render;
import etabli.runtime;

final class Window {
    enum Display {
        fullscreen,
        desktop,
        windowed
    }

    private {
        SDL_Window* _sdlWindow;
        SDL_Surface* _icon;
        string _title;
        int _width, _height;
    }

    @property {
        SDL_Window* sdlWindow() {
            return _sdlWindow;
        }

        /// Titre de la fenêtre
        string title() const {
            return _title;
        }
        /// Ditto
        string title(string title_) {
            _title = title_;
            SDL_SetWindowTitle(_sdlWindow, toStringz(_title));
            return _title;
        }

        int width() const {
            return _width;
        }

        int height() const {
            return _height;
        }
    }

    this(int width_, int height_, string title_) {
        _width = width_;
        _height = height_;
        _title = title_;

        enforce(SDL_Init(SDL_INIT_EVERYTHING) == 0,
            "SDL initialisation failure: " ~ fromStringz(SDL_GetError()));

        enforce(TTF_Init() != -1, "SDL ttf initialisation failure");

        _sdlWindow = SDL_CreateWindow(toStringz(_title), SDL_WINDOWPOS_CENTERED,
            SDL_WINDOWPOS_CENTERED, _width, _height, SDL_WINDOW_RESIZABLE);
        enforce(_sdlWindow, "window initialisation failure");
    }

    void update() {
        SDL_GetWindowSize(_sdlWindow, &_width, &_height);
    }

    void close() {
        if (_sdlWindow)
            SDL_DestroyWindow(_sdlWindow);
    }

    void setIcon(string path) {
        if (_icon) {
            SDL_FreeSurface(_icon);
            _icon = null;
        }
        _icon = IMG_Load(toStringz(path));

        SDL_SetWindowIcon(_sdlWindow, _icon);
    }

    void onSize(int width_, int height_) {
        if (_width == width_ && _height == height_)
            return;

        _width = width_;
        _height = height_;
    }
}
