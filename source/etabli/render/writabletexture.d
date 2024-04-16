/** 
 * Droits d’auteur: Enalye
 * Licence: Zlib
 * Auteur: Enalye
 */
module etabli.render.writabletexture;

import std.conv : to;
import std.string;
import std.exception : enforce;
import std.algorithm.comparison : clamp;

import bindbc.sdl;

import etabli.common;
import etabli.core;
import etabli.render.imagedata;
import etabli.render.renderer;
import etabli.render.texture;
import etabli.render.util;

/// Texture éditable
final class WritableTexture : ImageData {
    private {
        SDL_Texture* _texture = null;
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
        if (_texture)
            SDL_DestroyTexture(_texture);
    }

    void update(void function(uint*, uint, uint, void*) writeFunc, void* data = null) {
        uint* pixels;
        int pitch;
        if (SDL_LockTexture(_texture, null, cast(void**)&pixels, &pitch) == 0) {
            writeFunc(pixels, _width, _height, data);
            SDL_UnlockTexture(_texture);
        }
        else {
            throw new Exception("error while locking texture: " ~ to!string(
                    fromStringz(SDL_GetError())));
        }
    }

    void update(Vec4u clip, uint[] texels) {
        uint* dest;
        int pitch;
        SDL_Rect sdlClip = clip.toSdlRect();

        if (SDL_LockTexture(_texture, &sdlClip, cast(void**)&dest, &pitch) == 0) {
            size_t i, j;
            for (size_t y; y < clip.w; y++) {
                for (size_t x; x < clip.z; x++) {
                    dest[i] = texels[j];
                    ++i;
                    ++j;
                }
                i += (pitch >> 2) - clip.z;
            }
            SDL_UnlockTexture(_texture);
        }
        else {
            throw new Exception("error while locking texture: " ~ to!string(
                    fromStringz(SDL_GetError())));
        }
    }

    private void updateSettings() {
        auto sdlColor = _color.toSDL();
        SDL_SetTextureBlendMode(_texture, getSDLBlend(_blend));
        SDL_SetTextureColorMod(_texture, sdlColor.r, sdlColor.g, sdlColor.b);
        SDL_SetTextureAlphaMod(_texture, cast(ubyte)(clamp(_alpha, 0f, 1f) * 255f));
    }

    /// Render a section of the texture here
    override void draw(Vec2f position, Vec2f size, Vec4u clip, double angle,
        Vec2f pivot = Vec2f.half, bool flipX = false, bool flipY = false) {

        SDL_Rect sdlSrc = clip.toSdlRect();
        SDL_FRect sdlDest = {position.x, position.y, size.x, size.y};
        SDL_FPoint sdlPivot = {size.x * pivot.x, size.y * pivot.y};
        SDL_RendererFlip flip = flipX ? SDL_FLIP_HORIZONTAL : SDL_FLIP_NONE;
        flip |= flipY ? SDL_FLIP_VERTICAL : SDL_FLIP_NONE;

        SDL_RenderCopyExF(Etabli.renderer.sdlRenderer, _texture, &sdlSrc,
            &sdlDest, angle, &sdlPivot, flip);
    }
}
