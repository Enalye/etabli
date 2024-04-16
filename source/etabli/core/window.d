/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module etabli.core.window;

import std.exception : enforce;
import std.string : toStringz, fromStringz;

import bindbc.sdl;

import etabli.common;
import etabli.render;
import etabli.core.runtime;

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
        Vec2i _size;
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
            return _size.x;
        }

        int height() const {
            return _size.y;
        }

        Vec2i size() const {
            return _size;
        }
    }

    this(int width_, int height_, string title_) {
        _size.x = width_;
        _size.y = height_;
        _title = title_;

        enforce(SDL_Init(SDL_INIT_EVERYTHING) == 0,
            "SDL initialisation failure: " ~ fromStringz(SDL_GetError()));

        enforce(TTF_Init() != -1, "SDL ttf initialisation failure");

        _sdlWindow = SDL_CreateWindow(toStringz(_title), SDL_WINDOWPOS_CENTERED,
            SDL_WINDOWPOS_CENTERED, _size.x, _size.y, SDL_WINDOW_RESIZABLE);
        enforce(_sdlWindow, "window initialisation failure");
    }

    void update() {
        SDL_GetWindowSize(_sdlWindow, &_size.x, &_size.y);
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

    void setIconFromMemory(const(ubyte[]) data) {
        if (_icon) {
            SDL_FreeSurface(_icon);
            _icon = null;
        }
        SDL_RWops* rw = SDL_RWFromConstMem(cast(const(void)*) data.ptr, cast(int) data.length);
        _icon = IMG_Load_RW(rw, 1);

        SDL_SetWindowIcon(_sdlWindow, _icon);
        
        if (_icon) {
            SDL_FreeSurface(_icon);
            _icon = null;
        }
        rw = SDL_RWFromConstMem(cast(const(void)*) data.ptr, cast(int) data.length);
        _icon = IMG_Load_RW(rw, 1);

        SDL_SetWindowIcon(_sdlWindow, _icon);
    }

    void onSize(int width_, int height_) {
        if (_size.x == width_ && _size.y == height_)
            return;

        _size.x = width_;
        _size.y = height_;
        Etabli.ui.dispatchEvent("windowSize");
        Etabli.ui.dispatchEvent("parentSize", false);
    }
}
