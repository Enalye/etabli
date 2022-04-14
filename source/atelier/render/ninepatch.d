/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module atelier.render.ninepatch;

import std.conv : to;
import std.algorithm.comparison : min;
import std.exception;

import bindbc.sdl, bindbc.sdl.image;

import atelier.common, atelier.core;
import atelier.render.drawable, atelier.render.texture, atelier.render.writabletexture, atelier
    .render.window;

/// Render a resizable repeated sprite with borders. (ex: bubble speech).
final class NinePatch {
    @property {
        /// Size of the render zone. \
        /// Changing the value allocate a new Canvas (don't do it too often).
        Vec2f size() {
            return _size;
        }
        /// Ditto
        Vec2f size(const Vec2f size_) {
            if ((cast(Vec2i) _size) != (cast(Vec2i) size_))
                _isDirty = true;
            _size = size_;
            return _size;
        }

        /// Texture's region used.
        Vec4i clip() {
            return _clip;
        }
        /// Ditto
        Vec4i clip(const Vec4i clip_) {
            if (_clip == clip_)
                return _clip;
            _clip = clip_;
            _isDirty = true;
            return _clip;
        }

        /// The top border offset.
        int top() const {
            return _top;
        }
        /// Ditto
        int top(int top_) {
            if (_top == top_)
                return _top;
            _top = top_;
            _isDirty = true;
            return _top;
        }

        /// The bottom border offset.
        int bottom() const {
            return _bottom;
        }
        /// Ditto
        int bottom(int bottom_) {
            if (_bottom == bottom_)
                return _bottom;
            _bottom = bottom_;
            _isDirty = true;
            return _bottom;
        }

        /// The left border offset.
        int left() const {
            return _left;
        }
        /// Ditto
        int left(int left_) {
            if (_left == left_)
                return _left;
            _left = left_;
            _isDirty = true;
            return _left;
        }

        /// The right border offset.
        int right() const {
            return _right;
        }
        /// Ditto
        int right(int right_) {
            if (_right == right_)
                return _right;
            _right = right_;
            _isDirty = true;
            return _right;
        }

        /// The texture used to render.
        Texture texture(Texture texture_) {
            if (_ownSurface && _surface)
                SDL_FreeSurface(_surface);

            _surface = SDL_ConvertSurfaceFormat(texture_.surface, SDL_PIXELFORMAT_RGBA8888, 0);
            enforce(null != _surface, "can't format surface");
            _surfaceWidth = texture_.width;
            _surfaceHeight = texture_.height;
            _ownSurface = true;
            _isDirty = true;
            return texture_;
        }
    }

    private {
        SDL_Surface* _surface;
        int _surfaceWidth, _surfaceHeight;
        WritableTexture _cache;
        Vec2f _size;
        Vec4i _clip;
        int _top, _bottom, _left, _right;
        bool _isDirty = true;
        bool _ownSurface;
    }

    /// Mirroring property.
    Flip flip = Flip.none;

    /// Relative center of the ninepatch.
    Vec2f anchor = Vec2f.half;

    /// Angle in which the ninepatch will be rendered.
    float angle = 0f;

    /// Color added to the ninepatch.
    Color color = Color.white;

    /// Alpha
    float alpha = 1f;

    /// Blending algorithm.
    Blend blend = Blend.alpha;

    /// Default ctor
    this() {
    }

    /// Copy ctor
    this(NinePatch ninePatch) {
        _size = ninePatch._size;
        _surface = ninePatch._surface;
        _surfaceWidth = ninePatch._surfaceWidth;
        _surfaceHeight = ninePatch._surfaceHeight;
        _ownSurface = false;
        _clip = ninePatch._clip;
        _top = ninePatch._top;
        _bottom = ninePatch._bottom;
        _left = ninePatch._left;
        _right = ninePatch._right;
        _isDirty = true;
    }

    /// Ctor
    this(Texture texture_, Vec4i clip_, int top_, int bottom_, int left_, int right_) {
        _surface = SDL_ConvertSurfaceFormat(texture_.surface, SDL_PIXELFORMAT_RGBA8888, 0);
        enforce(null != _surface, "can't format surface");
        _surfaceWidth = texture_.width;
        _surfaceHeight = texture_.height;
        _ownSurface = true;
        _clip = clip_;
        _top = top_;
        _bottom = bottom_;
        _left = left_;
        _right = right_;
        _size = to!Vec2f(_clip.zw);
        _isDirty = true;
    }

    ~this() {
        if (_ownSurface && _surface)
            SDL_FreeSurface(_surface);
    }

    /// Set the ninepatch's size to fit inside the specified size.
    void fit(Vec2f sz) {
        _size = to!Vec2f(_clip.zw).fit(sz);
        _isDirty = true;
    }

    /// Render to the canvas.
    private void renderToCache() {
        _isDirty = false;
        if (_surface is null || _clip.z <= (_left + _right) || _clip.w <= (_top + _bottom))
            return;

        _cache = (_size.x >= 1f && _size.y >= 1f) ? new WritableTexture(cast(int) _size.x, cast(int) _size
                .y) : null;

        struct RasterData {
            int top, right, bottom, left;
            int clipX, clipY, clipW, clipH;
            int texW, texH;
            uint* pixels;
        }

        RasterData rasterData;
        rasterData.top = _top;
        rasterData.right = _right;
        rasterData.bottom = _bottom;
        rasterData.left = _left;
        rasterData.clipX = _clip.x;
        rasterData.clipY = _clip.y;
        rasterData.clipW = _clip.w;
        rasterData.clipH = _clip.z;
        rasterData.texW = _surfaceWidth;
        rasterData.texH = _surfaceHeight;
        rasterData.pixels = cast(uint*) _surface.pixels;

        _cache.write(
            function(uint* dest, uint* src, uint texWidth, uint texHeight, void* data_) {
            RasterData* data = cast(RasterData*) data_;
            const offsetY = (texHeight - data.bottom) * texWidth;
            const clipInternalH = data.clipH - (data.top + data.bottom);
            const clipInternalW = data.clipW - (data.left + data.right);
            const texInternalW = texWidth - (data.left + data.right);

            // Top corners
            for (int iy; iy < data.top; ++iy) {
                // Top left corner
                for (int ix; ix < data.left; ++ix) {
                    dest[iy * texWidth + ix] =
                        data.pixels[(data.clipY + iy) * data.texW + data.clipX + ix];
                }

                // Top right corner
                for (int ix; ix < data.right; ++ix) {
                    dest[(iy + 1) * texWidth + (ix - data.right)] =
                        data.pixels[(data.clipY + iy) * data.texW + data.clipX + ix + (
                                data.clipW - data.right)];
                }
            }

            // Bottom corners
            for (int iy; iy < data.bottom; ++iy) {
                // Bottom left corner
                for (int ix; ix < data.left; ++ix) {
                    dest[iy * texWidth + ix + offsetY] =
                        data.pixels[(data.clipY + iy + (
                                data.clipH - data.bottom)) * data.texW + data.clipX + ix];
                }

                // Bottom right corner
                for (int ix; ix < data.right; ++ix) {
                    dest[(iy + 1) * texWidth + ix + offsetY - data.right] =
                        data.pixels[(data.clipY + iy + (
                                data.clipH - data.bottom)) * data.texW + data.clipX + ix + (
                                data.clipW - data.right)];
                }
            }

            // Top edge
            for (int iy; iy < data.top; ++iy) {
                int ix;
                while (ix < texInternalW) {
                    dest[iy * texWidth + ix + data.left] =
                        data.pixels[(data.clipY + iy) * data.texW + data.clipX + (
                                ix % clipInternalW) + data.left];
                    ix++;
                }
            }

            // Bottom edge
            for (int iy; iy < data.bottom; ++iy) {
                int ix;
                while (ix < texInternalW) {
                    dest[iy * texWidth + ix + data.left + offsetY] =
                        data.pixels[(data.clipY + iy + (
                                data.clipH - data.bottom)) * data.texW + data.clipX + (
                                ix % clipInternalW) + data.left];
                    ix++;
                }
            }

            // Left and right edges
            for (int iy; iy < (texHeight - (data.top + data.bottom)); ++iy) {

                // Left edge
                for (int ix; ix < data.left; ++ix) {
                    dest[(iy + data.top) * texWidth + ix] =
                        data.pixels[(data.clipY + (
                                iy % clipInternalH) + data.top) * data.texW + data.clipX + ix];
                }

                // Right edge
                for (int ix; ix < data.right; ++ix) {
                    dest[(iy + data.top + 1) * texWidth + (ix - data.right)] =
                        data.pixels[(data.clipY + (
                                iy % clipInternalH) + data.top) * data.texW + data.clipX + ix + (
                                data.clipW - data.right)];
                }
            }

            // Center
            for (int iy; iy < (texHeight - (data.top + data.bottom)); ++iy) {
                for (int ix; ix < (texWidth - (data.left + data.right)); ++ix) {
                    dest[(iy + data.top) * texWidth + (ix + data.left)] =
                        data.pixels[(data.clipY + (
                                iy % clipInternalH) + data.top) * data.texW + data.clipX + (
                                ix % clipInternalW) + data.left];
                }
            }
        }, &rasterData);
    }

    /// Render the NinePatch in this position.
    void draw(const Vec2f position) {
        if (_isDirty)
            renderToCache();

        if (!_cache)
            return;

        Vec2f finalSize = _size * transformScale();
        _cache.color = color;
        _cache.blend = blend;
        _cache.alpha = alpha;
        _cache.draw(transformRenderSpace(position), finalSize, Vec4i(0, 0,
                _cache.width, _cache.height), angle, flip, anchor);
    }
}
