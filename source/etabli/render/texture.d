/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module etabli.render.texture;

import std.string;
import std.exception;
import std.algorithm.comparison : clamp;

import bindbc.sdl;

import etabli.common;
import etabli.runtime;
import etabli.render.imagedata;
import etabli.render.renderer;
import etabli.render.util;

/// Base rendering class.
final class Texture : ImageData, Resource!Texture {
    private {
        bool _isSmooth;
        SDL_Texture* _texture = null;
        SDL_Surface* _surface = null;
        uint _width, _height;
        Color _color = Color.white;
        float _alpha = 1f;
        Blend _blend = Blend.alpha;
    }

    @property {
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

        /// underlaying surface
        package SDL_Surface* surface() const {
            return cast(SDL_Surface*) _surface;
        }
    }

    /// Ctor
    this(const Texture texture) {
        _texture = cast(SDL_Texture*) texture._texture;
        _surface = cast(SDL_Surface*) texture._surface;
        _width = texture._width;
        _height = texture._height;
        _isSmooth = texture._isSmooth;
        _blend = texture._blend;
        _color = texture._color;
        _alpha = texture._alpha;
    }

    /// Ctor
    this(SDL_Surface* surface_, bool isSmooth_ = false) {
        _isSmooth = isSmooth_;
        load(surface_);
    }

    /// Ctor
    this(const(ubyte)[] data, bool isSmooth_ = false) {
        _isSmooth = isSmooth_;
        load(data);
    }

    ~this() {
        unload();
    }

    /// Accès à la ressource
    Texture fetch() {
        return this;
    }

    package void load(SDL_Surface* surface_) {
        if (_surface)
            SDL_FreeSurface(_surface);

        _surface = surface_;

        enforce(_surface, "invalid surface");
        enforce(Etabli.renderer.sdlRenderer, "le module de rendu n’est pas initialisé");

        if (_texture)
            SDL_DestroyTexture(_texture);

        if (_isSmooth)
            SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "1");

        _texture = SDL_CreateTextureFromSurface(Etabli.renderer.sdlRenderer, _surface);

        if (_isSmooth)
            SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "0");

        enforce(_texture, "erreur lors de la conversion d’une surface en format de texture");
        updateSettings();

        _width = _surface.w;
        _height = _surface.h;
    }

    /// Load from file
    void load(const(ubyte)[] data) {
        if (_surface)
            SDL_FreeSurface(_surface);

        SDL_RWops* rw = SDL_RWFromConstMem(cast(const(void)*) data.ptr, cast(int) data.length);
        _surface = IMG_Load_RW(rw, 1);

        enforce(_surface, "le format de l’image est incorrect");
        enforce(Etabli.renderer.sdlRenderer, "le module de rendu n’est pas initialisé");

        if (_isSmooth)
            SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "1");

        _texture = SDL_CreateTextureFromSurface(Etabli.renderer.sdlRenderer, _surface);

        if (_isSmooth)
            SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "0");

        enforce(_texture, "erreur lors de la conversion de l’image en format de texture");
        updateSettings();

        _width = _surface.w;
        _height = _surface.h;
    }

    /// Free image data
    void unload() {
        if (_surface)
            SDL_FreeSurface(_surface);

        if (_texture)
            SDL_DestroyTexture(_texture);
    }

    private void updateSettings() {
        auto sdlColor = _color.toSDL();
        SDL_SetTextureBlendMode(_texture, getSDLBlend(_blend));
        SDL_SetTextureColorMod(_texture, sdlColor.r, sdlColor.g, sdlColor.b);
        SDL_SetTextureAlphaMod(_texture, cast(ubyte)(clamp(_alpha, 0f, 1f) * 255f));
    }

    /// Dessine la texture
    override void draw(Vec2f position, Vec2f size, Vec4i clip, double angle,
        Vec2f pivot = Vec2f.half, bool flipX = false, bool flipY = false) {

        SDL_Rect sdlSrc = clip.toSdlRect();
        SDL_FRect sdlDest = {position.x, position.y, size.x, size.y};
        SDL_FPoint sdlPivot = {size.x * pivot.x, size.y * pivot.y};

        SDL_RenderCopyExF(Etabli.renderer.sdlRenderer, _texture, &sdlSrc, //
            &sdlDest, angle, &sdlPivot, //
            (flipX ? SDL_FLIP_HORIZONTAL
                : SDL_FLIP_NONE) | //
            (flipY ? SDL_FLIP_VERTICAL : SDL_FLIP_NONE));
    }
}
