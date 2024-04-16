/** 
 * Droits d’auteur: Enalye
 * Licence: Zlib
 * Auteur: Enalye
 */
module etabli.render.font.glyph;

import etabli.common, etabli.core;

import etabli.render.imagedata;
import etabli.render.util;

/// Information about a single character
interface Glyph {
    @property {
        /// Is the character defined ?
        bool exists() const;
        /// Width to advance cursor from previous position.
        int advance() const;
        /// Offset
        int offsetX() const;
        /// Ditto
        int offsetY() const;
        /// Character size
        int width() const;
        /// Ditto
        int height() const;
    }

    /// Render glyph
    void draw(Vec2f position, float, Color, float);
}

/// Ditto
final class BasicGlyph : Glyph {
    @property {
        /// Is the character defined ?
        bool exists() const {
            return _exists;
        }
        /// Width to advance cursor from previous position.
        int advance() const {
            return _advance;
        }
        /// Offset
        int offsetX() const {
            return _offsetX;
        }
        /// Ditto
        int offsetY() const {
            return _offsetY;
        }
        /// Character size
        int width() const {
            return _width;
        }
        /// Ditto
        int height() const {
            return _height;
        }
    }

    private {
        bool _exists;
        /// Width to advance cursor from previous position.
        int _advance;
        /// Offset
        int _offsetX, _offsetY;
        /// Character size
        int _width, _height;
        /// Coordinates in texture
        int _packX, _packY, _packWidth, _packHeight;
        /// ImageData
        ImageData _imageData;
    }

    this() {
        _exists = false;
    }

    this(bool exists_, int advance_, int offsetX_, int offsetY_, int width_,
        int height_, int packX_, int packY_, int packWidth_, int packHeight_, ImageData imageData_) {
        _exists = exists_;
        _advance = advance_;
        _offsetX = offsetX_;
        _offsetY = offsetY_;
        _width = width_;
        _height = height_;
        _packX = packX_;
        _packY = packY_;
        _packWidth = packWidth_;
        _packHeight = packHeight_;
        _imageData = imageData_;
    }

    /// Render glyph
    void draw(Vec2f position, float scale, Color color, float alpha) {
        _imageData.color = color;
        _imageData.blend = Blend.alpha;
        _imageData.alpha = alpha;
        _imageData.draw(position, Vec2f(_width * scale, _height * scale),
            Vec4u(_packX, _packY, _packWidth, _packHeight), 0f);
    }
}
