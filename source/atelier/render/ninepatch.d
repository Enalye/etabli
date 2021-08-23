/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module atelier.render.ninepatch;

import std.conv : to;
import std.algorithm.comparison : min;
import atelier.common, atelier.core;
import atelier.render.drawable, atelier.render.canvas, atelier.render.window;

/// Render a resizable repeated sprite with borders. (ex: bubble speech).
final class NinePatch {
    @property {
        /// Size of the render zone. \
        /// Changing the value allocate a new Canvas (don't do it too often).
        Vec2f size() {
            return _size;
        }
        /// Ditto
        Vec2f size(const Vec2f newSize) {
            _size = newSize;
            _cache = new Canvas(_size);
            _isDirty = true;
            return _size;
        }

        /// Drawable's region used.
        Vec4i clip() {
            return _clip;
        }
        /// Ditto
        Vec4i clip(const Vec4i newClip) {
            if (_clip == newClip)
                return _clip;
            _clip = newClip;
            _isDirty = true;
            return _clip;
        }

        /// The top border offset.
        int top() const {
            return _top;
        }
        /// Ditto
        int top(int newTop) {
            if (_top == newTop)
                return _top;
            _top = newTop;
            _isDirty = true;
            return _top;
        }

        /// The bottom border offset.
        int bottom() const {
            return _bottom;
        }
        /// Ditto
        int bottom(int newBottom) {
            if (_bottom == newBottom)
                return _bottom;
            _bottom = newBottom;
            _isDirty = true;
            return _bottom;
        }

        /// The left border offset.
        int left() const {
            return _left;
        }
        /// Ditto
        int left(int newLeft) {
            if (_left == newLeft)
                return _left;
            _left = newLeft;
            _isDirty = true;
            return _left;
        }

        /// The right border offset.
        int right() const {
            return _right;
        }
        /// Ditto
        int right(int newRight) {
            if (_right == newRight)
                return _right;
            _right = newRight;
            _isDirty = true;
            return _right;
        }

        /// The drawable used to render.
        Drawable drawable() {
            return _drawable;
        }
        /// Ditto
        Drawable drawable(Drawable newDrawable) {
            if (_drawable == newDrawable)
                return _drawable;
            _drawable = newDrawable;
            _isDirty = true;
            return _drawable;
        }
    }

    private {
        Canvas _cache;
        Vec2f _size;
        Drawable _drawable;
        Vec4i _clip;
        int _top, _bottom, _left, _right;
        bool _isDirty = true;
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
        _drawable = ninePatch._drawable;
        _clip = ninePatch._clip;
        _top = ninePatch._top;
        _bottom = ninePatch._bottom;
        _left = ninePatch._left;
        _right = ninePatch._right;
        _cache = new Canvas(_size);
        _isDirty = true;
    }

    /// Ctor
    this(Drawable drawable_, Vec4i clip_, int top_, int bottom_, int left_, int right_) {
        _drawable = drawable_;
        _clip = clip_;
        _top = top_;
        _bottom = bottom_;
        _left = left_;
        _right = right_;
        _size = to!Vec2f(_clip.zw);
        _cache = new Canvas(_clip.zw);
        _isDirty = true;
    }

    /// Set the ninepatch's size to fit inside the specified size.
    void fit(Vec2f sz) {
        _size = to!Vec2f(_clip.zw).fit(sz);
        _isDirty = true;
    }

    /// Render to the canvas.
    private void renderToCache() {
        _isDirty = false;
        if (_drawable is null || _clip.z <= (_left + _right) || _clip.w <= (_top + _bottom))
            return;
        pushCanvas(_cache, true);

        Vec4i localClip;
        Vec2i localSize;

        //Center
        if (_top > 0 && _bottom > 0 && _left > 0 && _right > 0) {
            int fillWidth = to!int(_size.x) - _left - _right;
            int fillHeight = to!int(_size.y) - _top - _bottom;
            int filledWidth, filledHeight;

            while (filledHeight < fillHeight) {
                int height = min(_clip.w - _top - _bottom, fillHeight - filledHeight);
                if (height <= 0)
                    break;
                filledWidth = 0;
                while (filledWidth < fillWidth) {
                    const int width = min(_clip.z - _left - _right, fillWidth - filledWidth);
                    if (width <= 0)
                        break;
                    localClip = Vec4i(_clip.x + _left, _clip.y + _top, width, height);
                    _drawable.draw(Vec2f(_left + filledWidth, _top + filledHeight),
                            Vec2f(width, height), localClip, 0f, Flip.none, Vec2f.zero);
                    filledWidth += width;
                }
                filledHeight += height;
            }
        }

        //Edges

        //Top edge
        if (_top > 0) {
            int filled;
            int fillWidth = to!int(_size.x) - _left - _right;
            while (filled < fillWidth) {
                const int width = min(_clip.z - _left - _right, fillWidth - filled);
                if (width < 0)
                    break;
                const int height = _top;
                localClip = Vec4i(_clip.x + _left, _clip.y, width, height);
                _drawable.draw(Vec2f(_left + filled, 0f), Vec2f(width, height),
                        localClip, 0f, Flip.none, Vec2f.zero);
                filled += width;
            }
        }

        //Bottom edge
        if (_bottom > 0) {
            int filled;
            int fillWidth = to!int(_size.x) - _left - _right;
            while (filled < fillWidth) {
                const int width = min(_clip.z - _left - _right, fillWidth - filled);
                if (width < 0)
                    break;
                const int height = _bottom;
                localClip = Vec4i(_clip.x + _left, _clip.y + _clip.w - _bottom, width, height);
                _drawable.draw(Vec2f(_left + filled, to!int(_size.y) - _bottom),
                        Vec2f(width, height), localClip, 0f, Flip.none, Vec2f.zero);
                filled += width;
            }
        }

        //Left edge
        if (_left > 0) {
            int filled;
            int fillHeight = to!int(_size.y) - _top - _bottom;
            while (filled < fillHeight) {
                const int height = min(_clip.w - _top - _bottom, fillHeight - filled);
                if (height < 0)
                    break;
                const int width = _top;
                localClip = Vec4i(_clip.x, _clip.y + _top, width, height);
                _drawable.draw(Vec2f(0f, _top + filled), Vec2f(width, height),
                        localClip, 0f, Flip.none, Vec2f.zero);
                filled += height;
            }
        }

        //Right edge
        if (_left > 0) {
            int filled;
            int fillHeight = to!int(_size.y) - _top - _bottom;
            while (filled < fillHeight) {
                const int height = min(_clip.w - _top - _bottom, fillHeight - filled);
                if (height < 0)
                    break;
                const int width = _top;
                localClip = Vec4i(_clip.x + _clip.z - _right, _clip.y + _top, width, height);
                _drawable.draw(Vec2f(to!int(_size.x) - _right, _top + filled),
                        Vec2f(width, height), localClip, 0f, Flip.none, Vec2f.zero);
                filled += height;
            }
        }

        //Corners

        //Top left corner
        if (_top > 0 && _left > 0) {
            localSize = Vec2i(_left, _top);
            localClip = Vec4i(_clip.xy, localSize);
            _drawable.draw(Vec2f.zero, to!Vec2f(localSize), localClip, 0f, Flip.none, Vec2f.zero);
        }

        //Top right corner
        if (_top > 0 && _right > 0) {
            localSize = Vec2i(_right, _top);
            localClip = Vec4i(_clip.x + _clip.z - _right, _clip.y, localSize.x, localSize.y);
            _drawable.draw(Vec2f(to!int(_size.x) - _right, 0f),
                    to!Vec2f(localSize), localClip, 0f, Flip.none, Vec2f.zero);
        }

        //Bottom left corner
        if (_bottom > 0 && _left > 0) {
            localSize = Vec2i(_left, _top);
            localClip = Vec4i(_clip.x, _clip.y + _clip.w - _bottom, localSize.x, localSize.y);
            _drawable.draw(Vec2f(0f, to!int(_size.y) - _bottom),
                    to!Vec2f(localSize), localClip, 0f, Flip.none, Vec2f.zero);
        }

        //Bottom right corner
        if (_bottom > 0 && _right > 0) {
            localSize = Vec2i(_right, _top);
            localClip = Vec4i(_clip.x + _clip.z - _right,
                    _clip.y + _clip.w - _bottom, localSize.x, localSize.y);
            _drawable.draw(Vec2f(to!int(_size.x) - _right,
                    to!int(_size.y) - _bottom), to!Vec2f(localSize),
                    localClip, 0f, Flip.none, Vec2f.zero);
        }

        popCanvas();
    }

    /// Render the NinePatch in this position.
    void draw(const Vec2f position) {
        if (_isDirty)
            renderToCache();
        Vec2f finalSize = _size * transformScale();
        _cache.color = color;
        _cache.blend = blend;
        _cache.alpha = alpha;
        _cache.draw(transformRenderSpace(position), finalSize, Vec4i(0, 0, _cache.width, _cache.height), angle, flip, anchor);
    }
}
