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
        SDL_Texture* _renderTexture;
        Vec2u _renderSize;
    }

    package(atelier.render) {
        bool _isTargetOnStack;
    }

    @property {
        package(atelier) const(SDL_Texture*) target() const {
            return _renderTexture;
        }

        /// The size (in texels) of the surface to be rendered on.
        /// Changing that value allocate a new texture, so don't do it everytime.
        Vec2u renderSize() const {
            return _renderSize;
        }
        /// Ditto
        Vec2u renderSize(Vec2u newRenderSize) {
            if (_isTargetOnStack)
                throw new Exception("Attempt to resize canvas while being rendered.");
            if (newRenderSize.x >= 2048u || newRenderSize.y >= 2048u)
                throw new Exception("Canvas render size exceeds limits.");
            _renderSize = newRenderSize;
            if (_renderTexture !is null)
                SDL_DestroyTexture(_renderTexture);
            _renderTexture = SDL_CreateTexture(_sdlRenderer, SDL_PIXELFORMAT_RGBA8888,
                    SDL_TEXTUREACCESS_TARGET, _renderSize.x, _renderSize.y);
            return _renderSize;
        }
    }

    /// The view position inside the canvas.
    Vec2f position = Vec2f.zero, /// The size of the view inside of the canvas.
        size = Vec2f.zero;
    /// Is the Canvas rendered from its center or from the top left corner ? \
    /// (only change the render position, not the view).
    bool isCentered = true;
    /// The base color when nothing is rendered.
    Color color = Color.black;
    /// The base opacity when nothing is rendered.
    float alpha = 0f;
    /// Mirroring property.
    Flip flip = Flip.none;

    /// Ctor
    this(Vec2f newRenderSize) {
        this(to!Vec2u(newRenderSize));
    }

    /// Ctor
    this(Vec2i newRenderSize) {
        this(to!Vec2u(newRenderSize));
    }

    /// Ctor
    this(Vec2u newRenderSize) {
        if (newRenderSize.x >= 2048u || newRenderSize.y >= 2048u)
            throw new Exception("Canvas render size exceeds limits.");
        _renderSize = newRenderSize;
        _renderTexture = SDL_CreateTexture(_sdlRenderer, SDL_PIXELFORMAT_RGBA8888,
                SDL_TEXTUREACCESS_TARGET, _renderSize.x, _renderSize.y);
        setColorMod(Color.white, Blend.alpha);

        size = cast(Vec2f) _renderSize;
        isCentered = false;
    }

    /// Ctor
    this(const Canvas canvas) {
        _renderSize = canvas._renderSize;
        size = canvas.size;
        position = canvas.position;
        isCentered = canvas.isCentered;
        _renderTexture = SDL_CreateTexture(_sdlRenderer, SDL_PIXELFORMAT_RGBA8888,
                SDL_TEXTUREACCESS_TARGET, _renderSize.x, _renderSize.y);
    }

    ~this() {
        if (_renderTexture !is null)
            SDL_DestroyTexture(_renderTexture);
    }

    /// Copy
    Canvas copy(const Canvas v) {
        _renderSize = v._renderSize;
        size = v.size;
        position = v.position;
        isCentered = v.isCentered;

        if (_renderTexture !is null)
            SDL_DestroyTexture(_renderTexture);
        _renderTexture = SDL_CreateTexture(_sdlRenderer, SDL_PIXELFORMAT_RGBA8888,
                SDL_TEXTUREACCESS_TARGET, _renderSize.x, _renderSize.y);
        return this;
    }

    /// Apply a color filter or change its blending algorithm.
    void setColorMod(const Color color, Blend blend = Blend.alpha) {
        SDL_SetTextureBlendMode(_renderTexture, getSDLBlend(blend));

        auto sdlColor = color.toSDL();
        SDL_SetTextureColorMod(_renderTexture, sdlColor.r, sdlColor.g, sdlColor.b);
    }

    /// Change the blending algorithm.
    void setBlend(Blend blend) {
        SDL_SetTextureBlendMode(_renderTexture, getSDLBlend(blend));
    }

    /// Apply a color filter.
    void setColor(const Color color) {
        auto sdlColor = color.toSDL();
        SDL_SetTextureColorMod(_renderTexture, sdlColor.r, sdlColor.g, sdlColor.b);
    }

    /// Transparency (1 = visible, 0 = hidden).
    void setAlpha(float alpha) {
        SDL_SetTextureAlphaMod(_renderTexture, cast(ubyte)(clamp(alpha, 0f, 1f) * 255f));
    }

    void draw(const Vec2f renderPosition) const {
        draw(renderPosition, 0f);
    }

    /// Draw the texture at the specified location.
    void draw(const Vec2f renderPosition, float angle) const {
        const Vec2f pos = transformRenderSpace(renderPosition);
        const Vec2f scale = transformScale();

        SDL_Rect destRect = {
            cast(uint)(pos.x - (_renderSize.x / 2) * scale.x),
                cast(uint)(pos.y - (_renderSize.y / 2) * scale.y),
                cast(uint)(_renderSize.x * scale.x), cast(uint)(_renderSize.y * scale.y)
        };

        SDL_RendererFlip rendererFlip = getSDLFlip(flip);
        SDL_RenderCopyEx(_sdlRenderer, cast(SDL_Texture*) _renderTexture, null,
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
                cast(SDL_Texture*) _renderTexture, null, &destRect, 0f, null, rendererFlip);
    }

    /// Check if a (outside) position is on the canvas rendering area. \
    /// It needs to know where the canvas will be rendered.
    bool isInside(const Vec2f pos, const Vec2f renderPosition) const {
        return (isCentered) ? pos.isBetween(renderPosition - cast(Vec2f)(_renderSize) * 0.5f,
                renderPosition + cast(Vec2f)(_renderSize) * 0.5f) : pos.isBetween(
                renderPosition, renderPosition + cast(Vec2f)(_renderSize));
    }

    /// Draw the part of the texture at the specified location.
    void draw(Vec2f pos, Vec2f rsize, Vec4i srcRect, float angle, Vec2f anchor = Vec2f.half) const {
        pos -= anchor * rsize;

        SDL_Rect srcSdlRect = srcRect.toSdlRect();
        SDL_Rect destSdlRect = {
            cast(uint) pos.x, cast(uint) pos.y, cast(uint) rsize.x, cast(uint) rsize.y
        };

        SDL_RendererFlip rendererFlip = getSDLFlip(flip);
        SDL_RenderCopyEx(cast(SDL_Renderer*) _sdlRenderer, cast(SDL_Texture*) _renderTexture,
                &srcSdlRect, &destSdlRect, angle, null, rendererFlip);
    }
}
