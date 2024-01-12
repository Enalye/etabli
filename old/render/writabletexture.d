/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module etabli.render.writabletexture;

import std.conv : to;
import std.string;
import std.exception;
import std.algorithm.comparison : clamp;

import bindbc.sdl;

import etabli.core;
import etabli.render.window, etabli.render.drawable, etabli.render.texture;

/// Base rendering class.
final class WritableTexture : Drawable {
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
        uint width() const {
            return _width;
        }
        /// Height in texels.
        uint height() const {
            return _height;
        }

        /// Color added to the canvas.
        Color color() const {
            return _color;
        }
        /// Ditto
        Color color(Color color_) {
            _color = color_;
            auto sdlColor = _color.toSDL();
            SDL_SetTextureColorMod(_texture, sdlColor.r, sdlColor.g, sdlColor.b);
            return _color;
        }

        /// Alpha
        float alpha() const {
            return _alpha;
        }
        /// Ditto
        float alpha(float alpha_) {
            _alpha = alpha_;
            SDL_SetTextureAlphaMod(_texture, cast(ubyte)(clamp(_alpha, 0f, 1f) * 255f));
            return _alpha;
        }

        /// Blending algorithm.
        Blend blend() const {
            return _blend;
        }
        /// Ditto
        Blend blend(Blend blend_) {
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
        enforce(null != _sdlRenderer, "the renderer does not exist");

        _width = width_;
        _height = height_;

        if (null != _texture)
            SDL_DestroyTexture(_texture);
        _texture = SDL_CreateTexture(_sdlRenderer, SDL_PIXELFORMAT_RGBA8888,
            SDL_TEXTUREACCESS_STREAMING, _width, _height);
        enforce(null != _texture, "error occurred while converting a surface to a texture format.");

        updateSettings();
    }

    ~this() {
        unload();
    }

    package void load(SDL_Surface* surface) {
        enforce(null != _sdlRenderer, "the renderer does not exist");
        enforce(null != surface, "invalid surface");

        _surface = SDL_ConvertSurfaceFormat(surface, SDL_PIXELFORMAT_RGBA8888, 0);
        enforce(null != _surface, "can't format surface");

        _width = _surface.w;
        _height = _surface.h;

        if (null != _texture)
            SDL_DestroyTexture(_texture);
        _texture = SDL_CreateTexture(_sdlRenderer, SDL_PIXELFORMAT_RGBA8888,
            SDL_TEXTUREACCESS_STREAMING, _width, _height);
        enforce(null != _texture, "error occurred while converting a surface to a texture format.");

        updateSettings();
    }

    /// Load from file
    void load(string path) {
        enforce(null != _sdlRenderer, "the renderer does not exist.");

        SDL_Surface* surface = IMG_Load(toStringz(path));
        enforce(null != surface, "can't load image file `" ~ path ~ "`");

        _surface = SDL_ConvertSurfaceFormat(surface, SDL_PIXELFORMAT_RGBA8888, 0);
        enforce(null != _surface, "can't format image file `" ~ path ~ "`");

        _width = _surface.w;
        _height = _surface.h;

        _texture = SDL_CreateTexture(_sdlRenderer, SDL_PIXELFORMAT_RGBA8888,
            SDL_TEXTUREACCESS_STREAMING, _width, _height);

        if (null == _texture)
            throw new Exception(
                "Error occurred while converting \'" ~ path ~ "\' to a texture format.");

        updateSettings();
        SDL_FreeSurface(surface);
    }

    /// Free image data
    void unload() {
        if (null != _texture)
            SDL_DestroyTexture(_texture);
    }

    void write(void function(uint*, uint*, uint, uint, void*) writeFunc, void* data = null) {
        uint* pixels;
        int pitch;
        if (SDL_LockTexture(_texture, null, cast(void**)&pixels, &pitch) == 0) {
            writeFunc(pixels, _surface ? (cast(uint*) _surface.pixels) : null, _width, _height, data);
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

    /// Render the whole texture here
    void draw(Vec2f pos, Vec2f anchor = Vec2f.half) const {
        pos -= anchor * Vec2f(_width, _height);

        SDL_Rect destRect = {cast(uint) pos.x, cast(uint) pos.y, _width, _height};

        SDL_RenderCopy(cast(SDL_Renderer*) _sdlRenderer,
            cast(SDL_Texture*) _texture, null, &destRect);
    }

    /// Render a section of the texture here
    void draw(Vec2f pos, Vec4i srcRect, Vec2f anchor = Vec2f.half) const {
        pos -= anchor * cast(Vec2f) srcRect.zw;

        SDL_Rect srcSdlRect = srcRect.toSdlRect();
        SDL_Rect destSdlRect = {
            cast(uint) pos.x, cast(uint) pos.y, srcSdlRect.w, srcSdlRect.h
        };

        SDL_RenderCopy(cast(SDL_Renderer*) _sdlRenderer,
            cast(SDL_Texture*) _texture, &srcSdlRect, &destSdlRect);
    }

    /// Render the whole texture here
    void draw(Vec2f pos, Vec2f size, Vec2f anchor = Vec2f.half) const {
        pos -= anchor * size;

        SDL_Rect destSdlRect = {
            cast(uint) pos.x, cast(uint) pos.y, cast(uint) size.x, cast(uint) size.y
        };

        SDL_RenderCopy(cast(SDL_Renderer*) _sdlRenderer,
            cast(SDL_Texture*) _texture, null, &destSdlRect);
    }

    /// Render a section of the texture here
    void draw(Vec2f pos, Vec2f size, Vec4i srcRect, Vec2f anchor = Vec2f.half) const {
        pos -= anchor * size;

        SDL_Rect srcSdlRect = srcRect.toSdlRect();
        SDL_Rect destSdlRect = {
            cast(uint) pos.x, cast(uint) pos.y, cast(uint) size.x, cast(uint) size.y
        };

        SDL_RenderCopy(cast(SDL_Renderer*) _sdlRenderer,
            cast(SDL_Texture*) _texture, &srcSdlRect, &destSdlRect);
    }

    /// Render a section of the texture here
    void draw(Vec2f pos, Vec2f size, Vec4i srcRect, float angle,
        Flip flip = Flip.none, Vec2f anchor = Vec2f.half) const {
        pos -= anchor * size;

        SDL_Rect srcSdlRect = srcRect.toSdlRect();
        SDL_Rect destSdlRect = {
            cast(uint) pos.x, cast(uint) pos.y, cast(uint) size.x, cast(uint) size.y
        };

        const SDL_RendererFlip rendererFlip = getSDLFlip(flip);
        SDL_RenderCopyEx(cast(SDL_Renderer*) _sdlRenderer, cast(SDL_Texture*) _texture,
            &srcSdlRect, &destSdlRect, angle, null, rendererFlip);
    }
}
