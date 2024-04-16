/** 
 * Droits d’auteur: Enalye
 * Licence: Zlib
 * Auteur: Enalye
 */
module etabli.render.font.pixelfontbordered;

import std.conv : to;
import etabli.common;
import etabli.render.font.font;
import etabli.render.font.glyph;
import etabli.render.font.pixelfont;
import etabli.render.imagedata;
import etabli.render.util;
import etabli.render.writabletexture;

final class PixelFontBordered : PixelFont {
    private {
        Glyph[dchar] _glyphs;
        Glyph _unknownGlyph;
        int _weight, _ascent, _descent, _lineSkip;
        WritableTexture _texture;
        int _posX, _posY;
        int _surfaceH, _surfaceW;
        int _spacing;
    }

    @property {
        /// Taille de la police
        int size() const {
            return (_ascent - _descent) * _weight + 2;
        }

        /// Où le haut se situe par rapport à la ligne
        int ascent() const {
            return _ascent * _weight + 2;
        }

        /// Où le bas se situe par rapport à la ligne
        int descent() const {
            return _descent * _weight + 2;
        }

        /// Distance entre chaque ligne
        int lineSkip() const {
            return _lineSkip * _weight;
        }

        /// Taille de la bordure
        int outline() const {
            return 0;
        }
    }

    this(int ascent_, int descent_, int lineSkip_, int weight = 1, int spacing_ = 0) {
        _ascent = ascent_;
        _descent = descent_;
        _lineSkip = lineSkip_;
        _weight = weight;
        _spacing = spacing_;

        _unknownGlyph = new PixelGlyphBordered();

        switch (weight) {
        case 1:
            _surfaceW = 256;
            _surfaceH = 128;
            break;
        case 2:
            _surfaceW = 512;
            _surfaceH = 256;
            break;
        case 3:
            _surfaceW = 512;
            _surfaceH = 512;
            break;
        case 4:
            _surfaceW = 1024;
            _surfaceH = 512;
            break;
        case 5:
            _surfaceW = 1024;
            _surfaceH = 1024;
            break;
        default:
            _surfaceW = 1024;
            _surfaceH = 1024;
            break;
        }

        _texture = new WritableTexture(_surfaceW, _surfaceH);
    }

    override void addCharacter(dchar ch, int[] glyphData, int width, int height, int descent) {
        struct RasterData {
            int[] glyph;
            int x, y, w, h;
            int weight, descent;
        }

        RasterData rasterData;
        rasterData.glyph = glyphData;
        rasterData.w = width;
        rasterData.h = height;
        rasterData.descent = descent;

        if (rasterData.glyph.length != rasterData.h)
            throw new Exception("le nombre de ligne du glyphe `" ~ to!string(
                    ch) ~ "` ne correspond pas à la taille indiquée: " ~ to!string(
                    rasterData.glyph.length) ~ " contre " ~ to!string(rasterData.h));

        if (_posX + width * _weight * 2 + 2 >= _surfaceW) {
            _posX = 0;
            _posY += (_ascent - _descent) * _weight * 2 + 2;

            if (_posY + (_ascent - _descent) * _weight * 2 + 2 > _surfaceH) {
                _posY = 0;
                _texture = new WritableTexture(_surfaceW, _surfaceH);
            }
        }

        rasterData.x = _posX;
        rasterData.y = _posY;
        rasterData.weight = _weight;

        _texture.update(function(uint* dest, uint texWidth, uint texHeight, void* rasterData_) {
            RasterData data = *cast(RasterData*) rasterData_;
            for (int iy; iy < data.h; ++iy) {
                ulong mask = 0x1L << (data.w - 1);
                for (int ix; ix < data.w; ++ix) {
                    if (data.glyph[iy] & mask) {
                        for (int ry; ry < data.weight; ++ry) {
                            for (int rx; rx < data.weight; ++rx) {
                                uint index = data.y * texWidth + data.x + (
                                    iy * texWidth + ix) * data.weight + (ry * texWidth + rx);
                                dest[index] = 0xFFFFFFFF;
                                uint indexBorder = index + data.w * data.weight;

                                for (int by; by < 3; ++by) {
                                    for (int bx; bx < 3; ++bx) {
                                        dest[indexBorder + (by * texWidth + bx)] = 0xFFFFFFFF;
                                    }
                                }

                            }
                        }
                    }
                    mask >>= 1;
                }
            }
        }, &rasterData);

        _glyphs[ch] = new PixelGlyphBordered(true, (rasterData.w + 1) + _spacing,
            (rasterData.h + rasterData.descent) - _ascent, rasterData.x,
            rasterData.y, rasterData.w, rasterData.h, _weight, _texture);

        _posX += rasterData.w * _weight * 2 + 2;
    }

    int getKerning(dchar prevChar, dchar currChar) {
        return 0;
    }

    Glyph getGlyph(dchar character) {
        Glyph* p = character in _glyphs;
        return p ? *p : _unknownGlyph;
    }
}

private final class PixelGlyphBordered : Glyph {
    @property {
        /// Is the character defined ?
        bool exists() const {
            return _exists;
        }
        /// Width to advance cursor from previous position.
        int advance() const {
            return _advance + 2;
        }
        /// Offset
        int offsetX() const {
            return 0;
        }
        /// Ditto
        int offsetY() const {
            return _offsetY + 2;
        }
        /// Character size
        int width() const {
            return _width + 2;
        }
        /// Ditto
        int height() const {
            return _height + 2;
        }
    }

    private {
        bool _exists;
        /// Width to advance cursor from previous position.
        int _advance;
        /// Offset
        int _offsetY;
        /// Coordinates in imagedata
        int _x, _y, _width, _height;
        /// ImageData
        ImageData _imageData;
    }

    this() {
        _exists = false;
    }

    this(bool exists_, int advance_, int offsetY_, int x_, int y_, int width_,
        int height_, int weight, ImageData imageData_) {
        _exists = exists_;
        _advance = advance_ * weight;
        _offsetY = offsetY_ * weight;
        _x = x_;
        _y = y_;
        _width = width_ * weight;
        _height = height_ * weight;
        _imageData = imageData_;
    }

    /// Render glyph
    void draw(Vec2f position, float scale, Color color, float alpha) {
        _imageData.color = Color.black;
        _imageData.blend = Blend.alpha;
        _imageData.alpha = alpha;
        _imageData.draw(position, Vec2f((_width + 2) * scale,
                (_height + 2) * scale), Vec4u(_x + _width, _y, _width + 2, _height + 2), 0f);

        _imageData.color = color;
        _imageData.blend = Blend.alpha;
        _imageData.alpha = alpha;
        _imageData.draw(position, Vec2f(_width * scale, _height * scale),
            Vec4u(_x, _y, _width, _height), 0f);
    }
}
