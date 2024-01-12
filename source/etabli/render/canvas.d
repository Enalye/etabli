/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module etabli.render.canvas;

import std.conv : to;
import std.exception : enforce;

import bindbc.sdl;

import etabli.common;
import etabli.runtime;
import etabli.render.imagedata;
import etabli.render.renderer;
import etabli.render.texture;
import etabli.render.util;

/// Behave like Texture but you can render onto it.
/// Use pushCanvas/popCanvasAndDraw to start the drawing region on it.
final class Canvas : ImageData {
    private {
        SDL_Texture* _texture;
        uint _width, _height;
        bool _isSmooth = false;
        Color _color = Color.white;
        float _alpha = 1f;
        Blend _blend = Blend.alpha;
    }

    package(etabli.render) {
        bool _isTargetOnStack;
    }

    @property {
        package(etabli) SDL_Texture* target() {
            return _texture;
        }

        /// loaded ?
        bool isLoaded() const {
            return true;
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
    }

    /// Ctor
    this(uint width_, uint height_, bool isSmooth_ = false) {
        _isSmooth = isSmooth_;
        _width = width_;
        _height = height_;

        enforce(_width > 0 && _height > 0, "canvas render size too small");

        if (_isSmooth)
            SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "1");

        _texture = SDL_CreateTexture(Etabli.renderer.sdlRenderer,
            SDL_PIXELFORMAT_RGBA8888, SDL_TEXTUREACCESS_TARGET, _width, _height);

        if (_isSmooth)
            SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "0");

        updateCanvasSettings();
    }

    /// Ctor
    this(const Canvas canvas) {
        _width = canvas._width;
        _height = canvas._height;
        _isSmooth = canvas._isSmooth;
        _blend = canvas._blend;
        _color = canvas._color;
        _alpha = canvas._alpha;

        if (_isSmooth)
            SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "1");

        _texture = SDL_CreateTexture(Etabli.renderer.sdlRenderer,
            SDL_PIXELFORMAT_RGBA8888, SDL_TEXTUREACCESS_TARGET, _width, _height);

        if (_isSmooth)
            SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "0");

        updateCanvasSettings();
    }

    ~this() {
        if (_texture !is null)
            SDL_DestroyTexture(_texture);
    }

    /// Copy
    Canvas copy(const Canvas canvas) {
        _width = canvas._width;
        _height = canvas._height;
        _isSmooth = canvas._isSmooth;
        _blend = canvas._blend;
        _color = canvas._color;
        _alpha = canvas._alpha;

        if (_texture !is null)
            SDL_DestroyTexture(_texture);

        if (_isSmooth)
            SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "1");

        _texture = SDL_CreateTexture(Etabli.renderer.sdlRenderer,
            SDL_PIXELFORMAT_RGBA8888, SDL_TEXTUREACCESS_TARGET, _width, _height);

        if (_isSmooth)
            SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "0");

        updateCanvasSettings();
        return this;
    }

    /// The size (in texels) of the surface to be rendered on.
    /// Changing that value allocate a new texture, so don't do it everytime.
    void setSize(uint width_, uint height_) {
        //if (_isTargetOnStack)
        //    throw new Exception("attempt to resize canvas while being rendered");

        _width = width_;
        _height = height_;

        enforce(_width > 0 && _height > 0, "canvas render size too small");

        if (_texture !is null)
            SDL_DestroyTexture(_texture);

        if (_isSmooth)
            SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "1");

        _texture = SDL_CreateTexture(Etabli.renderer.sdlRenderer,
            SDL_PIXELFORMAT_RGBA8888, SDL_TEXTUREACCESS_TARGET, _width, _height);

        if (_isSmooth)
            SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "0");

        updateCanvasSettings();
    }

    private void updateCanvasSettings() {
        auto sdlColor = _color.toSDL();
        SDL_SetTextureBlendMode(_texture, getSDLBlend(_blend));
        SDL_SetTextureColorMod(_texture, sdlColor.r, sdlColor.g, sdlColor.b);
        SDL_SetTextureAlphaMod(_texture, cast(ubyte)(clamp(_alpha, 0f, 1f) * 255f));
    }

    /// Toggle the canvas smoothing
    void setSmooth(bool isSmooth_) {
        if (isSmooth_ != _isSmooth) {
            _isSmooth = isSmooth_;
            setSize(_width, _height);
        }
    }

    /// Dessine le canvas
    override void draw(Vec2f position, Vec2f size, Vec4i clip, double angle,
        Vec2f pivot = Vec2f.zero, bool flipX = false, bool flipY = false) {
        SDL_Rect sdlSrc = clip.toSdlRect();
        SDL_FRect sdlDest = {position.x, position.y, size.x, size.y};
        SDL_FPoint sdlPivot = {pivot.x, pivot.y};

        SDL_RenderCopyExF(Etabli.renderer.sdlRenderer, _texture, &sdlSrc, //
            &sdlDest, angle, &sdlPivot, //
            (flipX ? SDL_FLIP_HORIZONTAL
                : SDL_FLIP_NONE) | //
            (flipY ? SDL_FLIP_VERTICAL : SDL_FLIP_NONE));
    }
}
