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
import atelier.render.window, atelier.render.drawable;

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
final class Texture : Drawable {
    private {
        bool _isLoaded = false, _ownData, _isSmooth;
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

        /// underlaying surface
        package SDL_Surface* surface() const {
            return cast(SDL_Surface*) _surface;
        }
    }

    /// Ctor
    this(const Texture texture) {
        _isLoaded = texture._isLoaded;
        _texture = cast(SDL_Texture*) texture._texture;
        _surface = cast(SDL_Surface*) texture._surface;
        _width = texture._width;
        _height = texture._height;
        _isSmooth = texture._isSmooth;
        _blend = texture._blend;
        _color = texture._color;
        _alpha = texture._alpha;
        _ownData = false;
    }

    /// Ctor
    this(SDL_Surface* surface_, bool preload_ = false, bool isSmooth_ = false) {
        _isSmooth = isSmooth_;
        if (preload_) {
            _surface = surface_;
            _width = _surface.w;
            _height = _surface.h;
        }
        else
            load(surface_);
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
        enforce(null != _surface, "invalid surface");
        enforce(null != _sdlRenderer, "the renderer does not exist");

        if (null != _texture)
            SDL_DestroyTexture(_texture);
        if (_isSmooth)
            SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "1");
        _texture = SDL_CreateTextureFromSurface(_sdlRenderer, _surface);
        enforce(null != _texture, "error occurred while converting a surface to a texture format");
        if (_isSmooth)
            SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "0");
        updateSettings();
        _isLoaded = true;
    }

    package void load(SDL_Surface* surface_) {
        if (_surface && _ownData)
            SDL_FreeSurface(_surface);
        _surface = surface_;

        enforce(null != _surface, "invalid surface");
        enforce(null != _sdlRenderer, "the renderer does not exist");

        if (null != _texture)
            SDL_DestroyTexture(_texture);

        if (_isSmooth)
            SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "1");
        _texture = SDL_CreateTextureFromSurface(_sdlRenderer, _surface);
        if (_isSmooth)
            SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "0");

        enforce(null != _texture, "error occurred while converting a surface to a texture format.");
        updateSettings();

        _width = _surface.w;
        _height = _surface.h;

        _isLoaded = true;
        _ownData = true;
    }

    /// Load from file
    void load(string path) {
        if (_surface && _ownData)
            SDL_FreeSurface(_surface);
        _surface = IMG_Load(toStringz(path));

        enforce(null != _surface, "can't load image file `" ~ path ~ "`");
        enforce(null != _sdlRenderer, "the renderer does not exist");

        if (_isSmooth)
            SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "1");
        _texture = SDL_CreateTextureFromSurface(_sdlRenderer, _surface);
        if (_isSmooth)
            SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "0");

        if (null == _texture)
            throw new Exception(
                "Error occurred while converting `" ~ path ~ "` to a texture format.");
        updateSettings();

        _width = _surface.w;
        _height = _surface.h;

        _isLoaded = true;
        _ownData = true;
    }

    /// Free image data
    void unload() {
        if (!_ownData)
            return;
        if (_surface)
            SDL_FreeSurface(_surface);
        if (_texture)
            SDL_DestroyTexture(_texture);
        _isLoaded = false;
    }

    private void updateSettings() {
        auto sdlColor = _color.toSDL();
        SDL_SetTextureBlendMode(_texture, getSDLBlend(_blend));
        SDL_SetTextureColorMod(_texture, sdlColor.r, sdlColor.g, sdlColor.b);
        SDL_SetTextureAlphaMod(_texture, cast(ubyte)(clamp(_alpha, 0f, 1f) * 255f));
    }

    /// Render the whole texture here
    void draw(Vec2f pos, Vec2f anchor = Vec2f.half) const {
        assert(_isLoaded, "can't render the texture: asset not loaded");
        pos -= anchor * Vec2f(_width, _height);

        SDL_Rect destRect = {cast(uint) pos.x, cast(uint) pos.y, _width, _height};

        SDL_RenderCopy(cast(SDL_Renderer*) _sdlRenderer,
            cast(SDL_Texture*) _texture, null, &destRect);
    }

    /// Render a section of the texture here
    void draw(Vec2f pos, Vec4i srcRect, Vec2f anchor = Vec2f.half) const {
        assert(_isLoaded, "can't render the texture: asset not loaded");
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
        assert(_isLoaded, "can't render the texture: asset not loaded");
        pos -= anchor * size;

        SDL_Rect destSdlRect = {
            cast(uint) pos.x, cast(uint) pos.y, cast(uint) size.x, cast(uint) size.y
        };

        SDL_RenderCopy(cast(SDL_Renderer*) _sdlRenderer,
            cast(SDL_Texture*) _texture, null, &destSdlRect);
    }

    /// Render a section of the texture here
    void draw(Vec2f pos, Vec2f size, Vec4i srcRect, Vec2f anchor = Vec2f.half) const {
        enforce(_isLoaded, "can't render the texture: asset not loaded");
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
        assert(_isLoaded, "can't render the texture: asset not loaded");
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
