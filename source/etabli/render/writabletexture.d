/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module etabli.render.writabletexture;

import std.conv : to;
import std.string;
import std.exception : enforce;
import std.algorithm.comparison : clamp;

import bindbc.sdl;

import etabli.common;
import etabli.runtime;
import etabli.render.imagedata;
import etabli.render.renderer;
import etabli.render.texture;
import etabli.render.util;

/// Texture éditable
final class WritableTexture : ImageData {
    private {
        SDL_Texture* _texture = null;
        SDL_Surface* _surface = null;
        uint _width, _height;
        Color _color = Color.white;
        float _alpha = 1f;
        Blend _blend = Blend.alpha;
    }

    @property {
        /// loaded ?
        bool isLoaded() const {
            return _texture !is null;
        }

        /// Width in texels.
        pragma(inline) override uint width() const {
            return _width;
        }
        /// Height in texels.
        pragma(inline) override uint height() const {
            return _height;
        }

        /// Color added to the canvas.
        override Color color() const {
            return _color;
        }
        /// Ditto
        override Color color(Color color_) {
            _color = color_;
            auto sdlColor = _color.toSDL();
            SDL_SetTextureColorMod(_texture, sdlColor.r, sdlColor.g, sdlColor.b);
            return _color;
        }

        /// Alpha
        override float alpha() const {
            return _alpha;
        }
        /// Ditto
        override float alpha(float alpha_) {
            _alpha = alpha_;
            SDL_SetTextureAlphaMod(_texture, cast(ubyte)(clamp(_alpha, 0f, 1f) * 255f));
            return _alpha;
        }

        /// Blending algorithm.
        override Blend blend() const {
            return _blend;
        }
        /// Ditto
        override Blend blend(Blend blend_) {
            _blend = blend_;
            SDL_SetTextureBlendMode(_texture, getSDLBlend(_blend));
            return _blend;
        }

        uint* pixels() {
            return cast(uint*) _surface.pixels;
        }
    }

    /// Ctor
    this(const Texture texture) {
        load(texture.surface);
    }

    /// Ctor
    this(SDL_Surface* surface) {
        load(surface);
    }

    /// Ctor
    this(string path) {
        load(path);
    }

    /// Ctor
    this(uint width_, uint height_) {
        enforce(Etabli.renderer.sdlRenderer, "the renderer does not exist");

        _width = width_;
        _height = height_;

        if (_texture)
            SDL_DestroyTexture(_texture);
        _texture = SDL_CreateTexture(Etabli.renderer.sdlRenderer,
            SDL_PIXELFORMAT_RGBA8888, SDL_TEXTUREACCESS_STREAMING, _width, _height);
        enforce(_texture, "error occurred while converting a surface to a texture format.");

        updateSettings();
    }

    ~this() {
        unload();
    }

    package void load(SDL_Surface* surface) {
        enforce(Etabli.renderer.sdlRenderer, "the renderer does not exist");
        enforce(surface, "invalid surface");

        _surface = SDL_ConvertSurfaceFormat(surface, SDL_PIXELFORMAT_RGBA8888, 0);
        enforce(_surface, "can't format surface");

        _width = _surface.w;
        _height = _surface.h;

        if (_texture)
            SDL_DestroyTexture(_texture);

        _texture = SDL_CreateTexture(Etabli.renderer.sdlRenderer,
            SDL_PIXELFORMAT_RGBA8888, SDL_TEXTUREACCESS_STREAMING, _width, _height);

        enforce(_texture, "error occurred while converting a surface to a texture format.");

        updateSettings();
    }

    /// Load from file
    void load(string path) {
        enforce(Etabli.renderer.sdlRenderer, "the renderer does not exist.");

        SDL_Surface* surface = IMG_Load(toStringz(path));
        enforce(surface, "can't load image file `" ~ path ~ "`");

        _surface = SDL_ConvertSurfaceFormat(surface, SDL_PIXELFORMAT_RGBA8888, 0);
        enforce(_surface, "can't format image file `" ~ path ~ "`");

        _width = _surface.w;
        _height = _surface.h;

        _texture = SDL_CreateTexture(Etabli.renderer.sdlRenderer,
            SDL_PIXELFORMAT_RGBA8888, SDL_TEXTUREACCESS_STREAMING, _width, _height);

        enforce(_texture, "error occurred while converting `" ~ path ~ "` to a texture format.");

        updateSettings();
        SDL_FreeSurface(surface);
    }

    /// Free image data
    void unload() {
        if (_surface)
            SDL_FreeSurface(_surface);

        if (_texture)
            SDL_DestroyTexture(_texture);
    }

    void write(void function(uint*, uint*, uint, uint, void*) writeFunc, void* data = null) {
        uint* pixels;
        int pitch;
        if (SDL_LockTexture(_texture, null, cast(void**)&pixels, &pitch) == 0) {
            writeFunc(pixels, _surface ? (cast(uint*) _surface.pixels) : null,
                _width, _height, data);
            SDL_UnlockTexture(_texture);
        }
        else {
            throw new Exception("error while locking texture: " ~ to!string(
                    fromStringz(SDL_GetError())));
        }
    }

    /*void write(void function(uint*, uint*, uint, uint) writeFunc) {
        uint* pixels;
        int pitch;
        if (SDL_LockTexture(_texture, null, cast(void**)&pixels, &pitch) == 0) {
            writeFunc(pixels, _surface ? (cast(uint*) _surface.pixels) : null, _width, _height);
            SDL_UnlockTexture(_texture);
        }
        else {
            throw new Exception("error while locking texture: " ~ to!string(
                    fromStringz(SDL_GetError())));
        }
    }*/

    private void updateSettings() {
        auto sdlColor = _color.toSDL();
        SDL_SetTextureBlendMode(_texture, getSDLBlend(_blend));
        SDL_SetTextureColorMod(_texture, sdlColor.r, sdlColor.g, sdlColor.b);
        SDL_SetTextureAlphaMod(_texture, cast(ubyte)(clamp(_alpha, 0f, 1f) * 255f));
    }

    /// Render a section of the texture here
    override void draw(Vec2f position, Vec2f size, Vec4i clip, double angle,
        Vec2f pivot = Vec2f.zero, bool flipX = false, bool flipY = false) {

        SDL_Rect sdlSrc = clip.toSdlRect();
        SDL_FRect sdlDest = {position.x, position.y, size.x, size.y};
        SDL_FPoint sdlPivot = {pivot.x, pivot.y};

        SDL_RenderCopyExF(Etabli.renderer.sdlRenderer, _texture, &sdlSrc, &sdlDest, angle, null,
            (flipX ? SDL_FLIP_HORIZONTAL : SDL_FLIP_NONE) | (flipY ?
    SDL_FLIP_VERTICAL : SDL_FLIP_NONE));
    }
}
