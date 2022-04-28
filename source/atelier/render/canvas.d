/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module atelier.render.canvas;

import std.conv : to;

import bindbc.sdl;

import atelier.core;
import atelier.render.window;
import atelier.render.texture;
import atelier.render.drawable;

/// Behave like Texture but you can render onto it.
/// Use pushCanvas/popCanvas to start the drawing region on it.
final class Canvas : Drawable {
    private {
        SDL_Texture* _texture;
        Vec2i _renderSize;
        bool _isSmooth = false;
        Color _color = Color.white;
        float _alpha = 1f;
        Blend _blend = Blend.alpha;
    }

    package(atelier.render) {
        bool _isTargetOnStack;
    }

    @property {
        package(atelier) const(SDL_Texture*) target() const {
            return _texture;
        }

        /// loaded ?
        bool isLoaded() const {
            return true;
        }

        /// Width in texels.
        uint width() const {
            return _renderSize.x;
        }
        /// Height in texels.
        uint height() const {
            return _renderSize.y;
        }

        /// The size (in texels) of the surface to be rendered on.
        /// Changing that value allocate a new texture, so don't do it everytime.
        Vec2i renderSize() const {
            return _renderSize;
        }
        /// Ditto
        Vec2i renderSize(Vec2i renderSize_) {
            if (_isTargetOnStack)
                throw new Exception("attempt to resize canvas while being rendered");
            if (renderSize_.x >= 2048u || renderSize_.y >= 2048u
                    || renderSize_.x <= 0 || renderSize_.y <= 0)
                throw new Exception("canvas render size exceeds limits");
            _renderSize = renderSize_;
            if (_texture !is null)
                SDL_DestroyTexture(_texture);
            if (_isSmooth)
                SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "1");
            _texture = SDL_CreateTexture(_sdlRenderer, SDL_PIXELFORMAT_RGBA8888,
                    SDL_TEXTUREACCESS_TARGET, _renderSize.x, _renderSize.y);
            if (_isSmooth)
                SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "0");
            updateCanvasSettings();
            return _renderSize;
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
    }

    /// The view position inside the canvas.
    Vec2f position = Vec2f.zero, /// The size of the view inside of the canvas.
        size = Vec2f.zero;
    /// The base color when nothing is rendered.
    Color clearColor = Color.black;
    /// The base opacity when nothing is rendered.
    float clearAlpha = 0f;
    /// Mirroring property.
    Flip flip = Flip.none;

    /// Ctor
    this(Vec2f renderSize_, bool isSmooth_ = false) {
        this(to!Vec2i(renderSize_), isSmooth_);
    }

    /// Ctor
    this(Vec2i renderSize_, bool isSmooth_ = false) {
        _isSmooth = isSmooth_;
        if (renderSize_.x >= 2048u || renderSize_.y >= 2048u
                || renderSize_.x <= 0 || renderSize_.y <= 0)
            throw new Exception("Canvas render size exceeds limits.");
        _renderSize = renderSize_;
        if (_isSmooth)
            SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "1");
        _texture = SDL_CreateTexture(_sdlRenderer, SDL_PIXELFORMAT_RGBA8888,
                SDL_TEXTUREACCESS_TARGET, _renderSize.x, _renderSize.y);
        if (_isSmooth)
            SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "0");
        updateCanvasSettings();

        size = cast(Vec2f) _renderSize;
    }

    /// Ctor
    this(const Canvas canvas) {
        _renderSize = canvas._renderSize;
        size = canvas.size;
        position = canvas.position;
        _isSmooth = canvas._isSmooth;
        clearColor = canvas.clearColor;
        clearAlpha = canvas.clearAlpha;
        _blend = canvas._blend;
        _color = canvas._color;
        _alpha = canvas._alpha;

        if (_isSmooth)
            SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "1");
        _texture = SDL_CreateTexture(_sdlRenderer, SDL_PIXELFORMAT_RGBA8888,
                SDL_TEXTUREACCESS_TARGET, _renderSize.x, _renderSize.y);
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
        _renderSize = canvas._renderSize;
        size = canvas.size;
        position = canvas.position;
        _isSmooth = canvas._isSmooth;
        clearColor = canvas.clearColor;
        clearAlpha = canvas.clearAlpha;
        _blend = canvas._blend;
        _color = canvas._color;
        _alpha = canvas._alpha;

        if (_texture !is null)
            SDL_DestroyTexture(_texture);
        if (_isSmooth)
            SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "1");
        _texture = SDL_CreateTexture(_sdlRenderer, SDL_PIXELFORMAT_RGBA8888,
                SDL_TEXTUREACCESS_TARGET, _renderSize.x, _renderSize.y);
        if (_isSmooth)
            SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "0");
        updateCanvasSettings();
        return this;
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
            renderSize(_renderSize);
        }
    }

    /// Draw the texture at the specified location.
    /*void draw(const Vec2f renderPosition) const {
        draw(renderPosition, 0f);
    }

    /// Draw the texture at the specified location.
    void draw(const Vec2f renderPosition, float angle, Vec2f anchor = Vec2f.half) const {
        Vec2f pos = transformRenderSpace(renderPosition);
        const Vec2f scale = transformScale();
        pos -= anchor * (cast(Vec2f) _renderSize) * scale;

        SDL_Rect destRect = {
            cast(uint)(pos.x), cast(uint)(pos.y),
                cast(uint)(_renderSize.x * scale.x), cast(uint)(_renderSize.y * scale.y)
        };

        SDL_RendererFlip rendererFlip = getSDLFlip(flip);
        SDL_RenderCopyEx(_sdlRenderer, cast(SDL_Texture*) _texture, null,
                &destRect, angle, null, rendererFlip);
    }

    /// Draw the texture at the specified location while scaling it.
    void draw(const Vec2f renderPosition, const Vec2f scale) const {
        const Vec2f pos = transformRenderSpace(renderPosition);
        const Vec2f rscale = transformScale() * scale;

        SDL_Rect destRect = {
            cast(uint)(pos.x - (_renderSize.x / 2) * rscale.x),
                cast(uint)(pos.y - (_renderSize.y / 2) * rscale.y),
                cast(uint)(_renderSize.x * rscale.x), cast(uint)(_renderSize.y * rscale.y)
        };

        SDL_RendererFlip rendererFlip = getSDLFlip(flip);
        SDL_RenderCopyEx(cast(SDL_Renderer*) _sdlRenderer,
                cast(SDL_Texture*) _texture, null, &destRect, 0f, null, rendererFlip);
    }

    /// Draw the part of the texture at the specified location.
    void draw(Vec2f pos, Vec2f rsize, Vec4i srcRect, float angle, Vec2f anchor = Vec2f.half) const {
        pos -= anchor * rsize;

        SDL_Rect srcSdlRect = srcRect.toSdlRect();
        SDL_Rect destSdlRect = {
            cast(uint) pos.x, cast(uint) pos.y, cast(uint) rsize.x, cast(uint) rsize.y
        };

        SDL_RendererFlip rendererFlip = getSDLFlip(flip);
        SDL_RenderCopyEx(cast(SDL_Renderer*) _sdlRenderer, cast(SDL_Texture*) _texture,
                &srcSdlRect, &destSdlRect, angle, null, rendererFlip);
    }*/

    /// Render the whole texture here
    void draw(Vec2f pos, Vec2f anchor = Vec2f.half) const {
        pos -= anchor * Vec2f(_renderSize.x, _renderSize.y);

        SDL_Rect destRect = {cast(uint) pos.x, cast(uint) pos.y, _renderSize.x, _renderSize.y};

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
