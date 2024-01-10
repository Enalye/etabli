/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module atelier.render.font.glyph;

import atelier.core;
import atelier.render.drawable, atelier.render.window;

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
    void draw(Vec2f, int, Color, float);
    /// Ditto
    void draw(Vec2f, float, Color, float);
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
        /// Coordinates in drawable
        int _packX, _packY, _packWidth, _packHeight;
        /// Drawable
        Drawable _drawable;
    }

    this() {
        _exists = false;
    }

    this(bool exists_, int advance_, int offsetX_, int offsetY_, int width_, int height_, int packX_, int packY_, int packWidth_, int packHeight_, Drawable drawable_) {
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
        _drawable = drawable_;
    }

    /// Render glyph
    void draw(Vec2f position, int scale, Color color, float alpha) {
        const Vec2f finalSize = Vec2f(_width, _height) * scale * transformScale();
        _drawable.color = color;
        _drawable.blend = Blend.alpha;
        _drawable.alpha = alpha;
        _drawable.draw(transformRenderSpace(position), finalSize, Vec4i(_packX,
                _packY, _packWidth, _packHeight), Vec2f.zero);
    }

    /// Ditto
    void draw(Vec2f position, float scale, Color color, float alpha) {
        const Vec2f finalSize = Vec2f(_width, _height) * scale * transformScale();
        _drawable.color = color;
        _drawable.blend = Blend.alpha;
        _drawable.alpha = alpha;
        _drawable.draw(transformRenderSpace(position), finalSize, Vec4i(_packX,
                _packY, _packWidth, _packHeight), Vec2f.zero);
    }
}
