/** 
 * Droits d’auteur: Enalye
 * Licence: Zlib
 * Auteur: Enalye
 */
module etabli.render.rectangle;

import std.conv : to;

import etabli.common;
import etabli.core;

import etabli.render.image;
import etabli.render.renderer;
import etabli.render.writabletexture;

final class Rectangle : Image {
    private {
        Vec2f _size = Vec2f.zero;
        float _thickness = 1f;
        bool _filled = true;
        bool _isDirty;

        WritableTexture _cache;
    }

    @property {
        Vec2f size() const {
            return _size;
        }

        Vec2f size(Vec2f size_) {
            if (_size != size_) {
                _size = size_;
                _isDirty = true;
            }
            return _size;
        }

        bool filled() const {
            return _filled;
        }

        bool filled(bool filled_) {
            if (_filled != filled_) {
                _filled = filled_;
                _isDirty = true;
            }
            return _filled;
        }

        float thickness() const {
            return _thickness;
        }

        float thickness(float thickness_) {
            if (_thickness != thickness_) {
                _thickness = thickness_;
                _isDirty = true;
            }
            return _thickness;
        }
    }

    static Rectangle fill(Vec2f size_) {
        return new Rectangle(size_, true, 1f);
    }

    static Rectangle outline(Vec2f size_, float thickness_) {
        return new Rectangle(size_, false, thickness_);
    }

    private this(Vec2f size_, bool filled_, float thickness_) {
        _size = size_;
        _filled = filled_;
        _thickness = thickness_;
        _isDirty = true;
    }

    this(Rectangle rect) {
        super(rect);
        _size = rect._size;
        _filled = rect._filled;
        _thickness = rect._thickness;
        _isDirty = true;
    }

    override void update() {
    }

    private void _cacheTexture() {
        _isDirty = false;

        _cache = (_size.x >= 1f && _size.y >= 1f) ? new WritableTexture(cast(uint) _size.x,
            cast(uint) _size.y) : null;

        if (!_cache)
            return;

        struct RasterData {
            float radius;
            float thickness;
            bool filled;
        }

        RasterData rasterData;
        rasterData.filled = _filled;
        rasterData.thickness = _thickness;

        _cache.update(function(uint* dest, uint texWidth, uint texHeight, void* data_) {
            RasterData* data = cast(RasterData*) data_;

            if (data.filled) {
                for (int iy; iy < texHeight; ++iy) {
                    for (int ix; ix < texWidth; ++ix) {
                        dest[iy * texWidth + ix] = 0xFFFFFFFF;
                    }
                }
            }
            else {
                const int thickness = cast(int) data.thickness;

                // Bord supérieur
                for (int iy; iy < thickness; ++iy) {
                    for (int ix; ix < texWidth; ++ix) {
                        dest[iy * texWidth + ix] = 0xFFFFFFFF;
                    }
                }

                // Bord inférieur
                for (int iy = (texHeight - thickness); iy < texHeight; ++iy) {
                    for (int ix; ix < texWidth; ++ix) {
                        dest[iy * texWidth + ix] = 0xFFFFFFFF;
                    }
                }

                // Bords latéraux
                for (int iy = thickness; iy < (texHeight - thickness); ++iy) {
                    // Bord gauche
                    for (int ix; ix < thickness; ++ix) {
                        dest[iy * texWidth + ix] = 0xFFFFFFFF;
                    }

                    // Bord droite
                    for (int ix = (texWidth - thickness); ix < texWidth; ++ix) {
                        dest[iy * texWidth + ix] = 0xFFFFFFFF;
                    }
                }
            }
        }, &rasterData);
    }

    /// Redimensionne l’image pour qu’elle puisse tenir dans une taille donnée
    override void fit(Vec2f size_) {
        size = to!Vec2f(clip.zw).fit(size_);
    }

    /// Redimensionne l’image pour qu’elle puisse contenir une taille donnée
    override void contain(Vec2f size_) {
        size = to!Vec2f(clip.zw).contain(size_);
    }

    override void draw(Vec2f origin = Vec2f.zero) {
        if (_isDirty)
            _cacheTexture();

        if (!_cache)
            return;

        _cache.color = color;
        _cache.blend = blend;
        _cache.alpha = alpha;
        _cache.draw(origin + (position - anchor * size), _size, Vec4u(0, 0,
                _cache.width, _cache.height), angle, pivot, flipX, flipY);
    }
}
