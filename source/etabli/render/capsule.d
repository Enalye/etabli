/** 
 * Droits d’auteur: Enalye
 * Licence: Zlib
 * Auteur: Enalye
 */
module etabli.render.capsule;

import std.conv : to;
import std.algorithm.comparison : min, max;
import std.math : ceil, abs;

import etabli.common;
import etabli.core;

import etabli.render.image;
import etabli.render.renderer;
import etabli.render.writabletexture;

final class Capsule : Image {
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

    static Capsule fill(Vec2f size_) {
        return new Capsule(size_, true, 1f);
    }

    static Capsule outline(Vec2f size_, float thickness_) {
        return new Capsule(size_, false, thickness_);
    }

    private this(Vec2f size_, bool filled_, float thickness_) {
        _size = size_;
        _filled = filled_;
        _thickness = thickness_;
        _isDirty = true;
    }

    this(Capsule capsule) {
        super(capsule);
        _size = capsule._size;
        _filled = capsule._filled;
        _thickness = capsule._thickness;
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
        rasterData.radius = min(_size.x, _size.y) / 2f;
        rasterData.filled = _filled;
        rasterData.thickness = _thickness;

        _cache.update(function(uint* dest, uint texWidth, uint texHeight, void* data_) {
            RasterData* data = cast(RasterData*) data_;
            int corner = cast(int) data.radius;
            const offsetY = (texHeight - corner) * texWidth;
            const texInternalW = texWidth - (corner * 2);

            if (data.filled) {
                // Coins supérieurs
                for (int iy; iy < corner; ++iy) {
                    // Coin haut gauche
                    for (int ix; ix < corner; ++ix) {
                        Vec2f point = Vec2f(ix, iy) + .5f;
                        float dist = point.distance(Vec2f(corner, corner));
                        float value = clamp(dist - corner, 0f, 1f);

                        dest[iy * texWidth + ix] = 0xFFFFFF00 | (cast(ubyte) lerp(255f, 0f, value));
                    }

                    // Coin haut droite
                    for (int ix; ix < corner; ++ix) {
                        Vec2f point = Vec2f(ix, iy) + .5f;
                        float dist = point.distance(Vec2f(0f, corner));
                        float value = clamp(dist - corner, 0f, 1f);

                        dest[(iy + 1) * texWidth + (ix - corner)] = 0xFFFFFF00 | (cast(ubyte) lerp(255f,
                            0f, value));
                    }
                }

                // Coins inférieurs
                for (int iy; iy < corner; ++iy) {
                    // Coin bas gauche
                    for (int ix; ix < corner; ++ix) {
                        Vec2f point = Vec2f(ix, iy) + .5f;
                        float dist = point.distance(Vec2f(corner, 0f));
                        float value = clamp(dist - corner, 0f, 1f);

                        dest[iy * texWidth + ix + offsetY] = 0xFFFFFF00 | (cast(ubyte) lerp(255f,
                            0f, value));
                    }

                    // Coin bas droite
                    for (int ix; ix < corner; ++ix) {
                        Vec2f point = Vec2f(ix, iy) + .5f;
                        float dist = point.distance(Vec2f.zero);
                        float value = clamp(dist - corner, 0f, 1f);

                        dest[(iy + 1) * texWidth + ix + offsetY - corner] = 0xFFFFFF00 | (cast(ubyte) lerp(255f,
                            0f, value));
                    }
                }

                // Bord supérieur
                for (int iy; iy < corner; ++iy) {
                    for (int ix; ix < texInternalW; ++ix) {
                        dest[iy * texWidth + ix + corner] = 0xFFFFFFFF;
                    }
                }

                // Bord inférieur
                for (int iy; iy < corner; ++iy) {
                    for (int ix; ix < texInternalW; ++ix) {
                        dest[iy * texWidth + ix + corner + offsetY] = 0xFFFFFFFF;
                    }
                }

                // Bords latéraux
                for (int iy = corner; iy < (texHeight - corner); ++iy) {
                    // Bord gauche
                    for (int ix; ix < corner; ++ix) {
                        dest[iy * texWidth + ix] = 0xFFFFFFFF;
                    }

                    // Bord droite
                    for (int ix; ix < corner; ++ix) {
                        dest[(iy + 1) * texWidth + (ix - corner)] = 0xFFFFFFFF;
                    }
                }

                // Centre
                for (int iy = corner; iy < (texHeight - corner); ++iy) {
                    for (int ix = corner; ix < (texWidth - corner); ++ix) {
                        dest[iy * texWidth + ix] = 0xFFFFFFFF;
                    }
                }
            }
            else {
                const int thickness = cast(int) data.thickness;
                const float halfThickness = data.thickness / 2f - .5f;

                // Coins supérieurs
                for (int iy; iy < corner; ++iy) {
                    // Coin haut gauche
                    for (int ix; ix < corner; ++ix) {
                        Vec2f point = Vec2f(ix, iy);
                        float dist = point.distance(Vec2f(corner, corner));
                        float value = clamp(abs((dist + halfThickness) - data.radius) - halfThickness,
                            0f, 1f);

                        dest[iy * texWidth + ix] = 0xFFFFFF00 | (cast(ubyte) lerp(255f, 0f, value));
                    }

                    // Coin haut droite
                    for (int ix; ix < corner; ++ix) {
                        Vec2f point = Vec2f(ix + 1f, iy);
                        float dist = point.distance(Vec2f(0f, corner));
                        float value = clamp(abs((dist + halfThickness) - data.radius) - halfThickness,
                            0f, 1f);

                        dest[(iy + 1) * texWidth + (ix - corner)] = 0xFFFFFF00 | (cast(ubyte) lerp(255f,
                            0f, value));
                    }
                }

                // Coins inférieurs
                for (int iy; iy < corner; ++iy) {
                    // Coin bas gauche
                    for (int ix; ix < corner; ++ix) {
                        Vec2f point = Vec2f(ix, iy + 1f);
                        float dist = point.distance(Vec2f(corner, 0f));
                        float value = clamp(abs((dist + halfThickness) - data.radius) - halfThickness,
                            0f, 1f);

                        dest[iy * texWidth + ix + offsetY] = 0xFFFFFF00 | (cast(ubyte) lerp(255f,
                            0f, value));
                    }

                    // Coin bas droite
                    for (int ix; ix < corner; ++ix) {
                        Vec2f point = Vec2f(ix + 1f, iy + 1f);
                        float dist = point.distance(Vec2f.zero);
                        float value = clamp(abs((dist + halfThickness) - data.radius) - halfThickness,
                            0f, 1f);

                        dest[(iy + 1) * texWidth + ix + offsetY - corner] = 0xFFFFFF00 | (cast(ubyte) lerp(255f,
                            0f, value));
                    }
                }

                // Bord supérieur
                for (int iy; iy < thickness; ++iy) {
                    for (int ix; ix < texInternalW; ++ix) {
                        dest[iy * texWidth + ix + corner] = 0xFFFFFFFF;
                    }
                }

                // Bord inférieur
                for (int iy = (corner - thickness); iy < corner; ++iy) {
                    for (int ix; ix < texInternalW; ++ix) {
                        dest[iy * texWidth + ix + corner + offsetY] = 0xFFFFFFFF;
                    }
                }

                // Bords latéraux
                for (int iy = corner; iy < (texHeight - corner); ++iy) {
                    // Bord gauche
                    for (int ix; ix < thickness; ++ix) {
                        dest[iy * texWidth + ix] = 0xFFFFFFFF;
                    }

                    // Bord droite
                    for (int ix = (corner - thickness); ix < corner; ++ix) {
                        dest[(iy + 1) * texWidth + (ix - corner)] = 0xFFFFFFFF;
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
