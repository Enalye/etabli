/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module atelier.render.texture;

import std.string;
import std.exception;
import std.algorithm.comparison : clamp;

import bindbc.sdl, bindbc.sdl.image;

import atelier.core;
import atelier.render.window;

/// Indicate if something is mirrored.
enum Flip {
    none,
    horizontal,
    vertical,
    both
}

package SDL_RendererFlip getSDLFlip(Flip flip) {
    final switch (flip) with (Flip) {
    case both:
        return cast(SDL_RendererFlip)(SDL_FLIP_HORIZONTAL | SDL_FLIP_VERTICAL);
    case horizontal:
        return SDL_FLIP_HORIZONTAL;
    case vertical:
        return SDL_FLIP_VERTICAL;
    case none:
        return SDL_FLIP_NONE;
    }
}

/// Blending algorithm \
/// none: Paste everything without transparency \
/// modular: Multiply color value with the destination \
/// additive: Add color value with the destination \
/// alpha: Paste everything with transparency (Default one)
enum Blend {
    none,
    modular,
    additive,
    alpha
}

/// Returns the SDL blend flag.
package SDL_BlendMode getSDLBlend(Blend blend) {
    final switch (blend) with (Blend) {
    case alpha:
        return SDL_BLENDMODE_BLEND;
    case additive:
        return SDL_BLENDMODE_ADD;
    case modular:
        return SDL_BLENDMODE_MOD;
    case none:
        return SDL_BLENDMODE_NONE;
    }
}

/// Base rendering class.
final class Texture {
    private {
        bool _isLoaded = false, _ownData, _isSmooth;
        SDL_Texture* _texture = null;
        SDL_Surface* _surface = null;
        uint _width, _height;
    }

    @property {
        /// loaded ?
        bool isLoaded() const {
            return _isLoaded;
        }

        /// Width in texels.
        uint width() const {
            return _width;
        }
        /// Height in texels.
        uint height() const {
            return _height;
        }
    }

    /// Ctor
    this(const Texture texture) {
        _isLoaded = texture._isLoaded;
        _texture = cast(SDL_Texture*) texture._texture;
        _width = texture._width;
        _height = texture._height;
        _isSmooth = texture._isSmooth;
        _ownData = false;
    }

    /// Ctor
    this(SDL_Surface* surface, bool preload_ = false, bool isSmooth_ = false) {
        _isSmooth = isSmooth_;
        if (preload_) {
            _surface = surface;
            _width = _surface.w;
            _height = _surface.h;
        }
        else
            load(surface);
    }

    /// Ctor
    this(string path, bool preload_ = false, bool isSmooth_ = false) {
        _isSmooth = isSmooth_;
        if (preload_) {
            _surface = IMG_Load(toStringz(path));
            _width = _surface.w;
            _height = _surface.h;
            _ownData = true;
        }
        else
            load(path);
    }

    ~this() {
        unload();
    }

    /// Call it if you set the preload flag on ctor.
    void postload() {
        enforce(null != _surface, "Invalid surface.");
        enforce(null != _sdlRenderer, "The renderer does not exist.");

        if (null != _texture)
            SDL_DestroyTexture(_texture);
        if (_isSmooth)
            SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "1");
        _texture = SDL_CreateTextureFromSurface(_sdlRenderer, _surface);
        enforce(null != _texture, "Error occurred while converting a surface to a texture format.");
        if (_isSmooth)
            SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "0");

        if (_ownData)
            SDL_FreeSurface(_surface);
        _surface = null;
        _isLoaded = true;
    }

    void setColorMod(Color color, Blend blend = Blend.alpha) {
        SDL_SetTextureBlendMode(_texture, getSDLBlend(blend));

        auto sdlColor = color.toSDL();
        SDL_SetTextureColorMod(_texture, sdlColor.r, sdlColor.g, sdlColor.b);
    }

    void setAlpha(float alpha) {
        SDL_SetTextureAlphaMod(_texture, cast(ubyte)(clamp(alpha, 0f, 1f) * 255f));
    }

    package void load(SDL_Surface* surface) {
        enforce(null != surface, "Invalid surface.");
        enforce(null != _sdlRenderer, "The renderer does not exist.");

        if (null != _texture)
            SDL_DestroyTexture(_texture);

        if (_isSmooth)
            SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "1");
        _texture = SDL_CreateTextureFromSurface(_sdlRenderer, surface);
        if (_isSmooth)
            SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "0");

        enforce(null != _texture, "Error occurred while converting a surface to a texture format.");

        _width = surface.w;
        _height = surface.h;

        _isLoaded = true;
        _ownData = true;
    }

    /// Load from file
    void load(string path) {
        SDL_Surface* surface = IMG_Load(toStringz(path));

        enforce(null != surface, "Cannot load image file \'" ~ path ~ "\'.");
        enforce(null != _sdlRenderer, "The renderer does not exist.");

        if (_isSmooth)
            SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "1");
        _texture = SDL_CreateTextureFromSurface(_sdlRenderer, surface);
        if (_isSmooth)
            SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "0");

        if (null == _texture)
            throw new Exception(
                    "Error occurred while converting \'" ~ path ~ "\' to a texture format.");

        _width = surface.w;
        _height = surface.h;
        SDL_FreeSurface(surface);

        _isLoaded = true;
        _ownData = true;
    }

    /// Free image data
    void unload() {
        if (!_ownData)
            return;
        if (null != _texture)
            SDL_DestroyTexture(_texture);
        _isLoaded = false;
    }

    /// Render the whole texture here
    void draw(Vec2f pos, Vec2f anchor = Vec2f.half) const {
        assert(_isLoaded, "Cannot render the texture: Asset not loaded.");
        pos -= anchor * Vec2f(_width, _height);

        SDL_Rect destRect = {cast(uint) pos.x, cast(uint) pos.y, _width, _height};

        SDL_RenderCopy(cast(SDL_Renderer*) _sdlRenderer,
                cast(SDL_Texture*) _texture, null, &destRect);
    }

    /// Render a section of the texture here
    void draw(Vec2f pos, Vec4i srcRect, Vec2f anchor = Vec2f.half) const {
        assert(_isLoaded, "Cannot render the texture: Asset not loaded.");
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
        assert(_isLoaded, "Cannot render the texture: Asset not loaded.");
        pos -= anchor * size;

        SDL_Rect destSdlRect = {
            cast(uint) pos.x, cast(uint) pos.y, cast(uint) size.x, cast(uint) size.y
        };

        SDL_RenderCopy(cast(SDL_Renderer*) _sdlRenderer,
                cast(SDL_Texture*) _texture, null, &destSdlRect);
    }

    /// Render a section of the texture here
    void draw(Vec2f pos, Vec2f size, Vec4i srcRect, Vec2f anchor = Vec2f.half) const {
        enforce(_isLoaded, "Cannot render the texture: Asset not loaded.");
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
        assert(_isLoaded, "Cannot render the texture: Asset not loaded.");
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
