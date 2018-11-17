module atelier.render.ninepatch;

import std.conv: to;
import std.algorithm.comparison: min;
import atelier.common, atelier.core;
import atelier.render.drawable, atelier.render.canvas, atelier.render.texture, atelier.render.window;

final class NinePatch: IDrawable {
    @property {
        Vec2f size() { return _size; }
        Vec2f size(const Vec2f newSize) {
            _size = newSize;
            _cache = new Canvas(_size);
            _isDirty = true;
            return _size;
        }

        Vec4i clip() { return _clip; }
        Vec4i clip(const Vec4i newClip) {
            if(_clip == newClip)
                return _clip;
            _clip = newClip;
            _isDirty = true;
            return _clip;
        }

        int top() const { return _top; }
        int top(int newTop) {
            if(_top == newTop)
                return _top;
            _top = newTop;
            _isDirty = true;
            return _top;
        }

        int bottom() const { return _bottom; }
        int bottom(int newBottom) {
            if(_bottom == newBottom)
                return _bottom;
            _bottom = newBottom;
            _isDirty = true;
            return _bottom;
        }

        int left() const { return _left; }
        int left(int newLeft) {
            if(_left == newLeft)
                return _left;
            _left = newLeft;
            _isDirty = true;
            return _left;
        }

        int right() const { return _right; }
        int right(int newRight) {
            if(_right == newRight)
                return _right;
            _right = newRight;
            _isDirty = true;        
            return _right;
        }

        Texture texture() { return _texture; }
        Texture texture(Texture newTexture) {
            if(_texture == newTexture)
                return _texture;
            _texture = newTexture;
            _isDirty = true;        
            return _texture;
        }
    }

    private {
        Canvas _cache;
        Vec2f _size;
        Texture _texture;
        Vec4i _clip;
        int _top, _bottom, _left, _right;
        bool _isDirty = true;
    }

    this() {}
	
    this(string _textureId, Vec4i newClip, int newTop, int newBottom, int newLeft, int newRight) {
        this(fetch!Texture(_textureId), newClip, newTop, newBottom, newLeft, newRight);
    }

    this(Texture newTexture, Vec4i newClip, int newTop, int newBottom, int newLeft, int newRight) {
        _texture = newTexture;
        _clip = newClip;
        _top = newTop;
        _bottom = newBottom;
        _left = newLeft;
        _right = newRight;
		_size = to!Vec2f(_clip.zw);
        _cache = new Canvas(_clip.zw);
        _isDirty = true;
    }

    void fit(Vec2f newSize) {
		_size = to!Vec2f(_clip.zw).fit(newSize);
        _isDirty = true;
	}

    private void renderToCache() {
        _isDirty = false;
        if(_texture is null
            || _clip.z <= (_left + _right) || _clip.w <= (_top + _bottom))
            return;
        pushCanvas(_cache, true);

        Vec4i localClip;
        Vec2i localSize;

        //Center
        if(_top > 0 && _bottom > 0 && _left > 0 && _right > 0) {
            int fillWidth = to!int(_size.x) - _left - _right;
            int fillHeight = to!int(_size.y) - _top - _bottom;
            int filledWidth, filledHeight;

            while(filledHeight < fillHeight) {
                int height = min(_clip.w - _top - _bottom, fillHeight - filledHeight);
                if(height <= 0)
                    break;
                filledWidth = 0;
                while(filledWidth < fillWidth) {
                    int width = min(_clip.z - _left - _right, fillWidth - filledWidth);
                    if(width <= 0)
                        break;
                    localClip = Vec4i(_clip.x + _left, _clip.y + _top, width, height);
                    _texture.draw(Vec2f(_left + filledWidth, _top + filledHeight), Vec2f(width, height), localClip, 0f, Flip.NoFlip, Vec2f.zero);
                    filledWidth += width;
                }
                filledHeight += height;
            }
        }

        //Edges

        //Top edge
        if(_top > 0) {
            int filled;
            int fillWidth = to!int(_size.x) - _left - _right;
            while(filled < fillWidth) {
                int width = min(_clip.z - _left - _right, fillWidth - filled);
                if(width < 0)
                    break;
                int height = _top;
                localClip = Vec4i(_clip.x + _left, _clip.y, width, height);
                _texture.draw(Vec2f(_left + filled, 0f), Vec2f(width, height), localClip, 0f, Flip.NoFlip, Vec2f.zero);
                filled += width;
            }
        }

        //Bottom edge
        if(_bottom > 0) {
            int filled;
            int fillWidth = to!int(_size.x) - _left - _right;
            while(filled < fillWidth) {
                int width = min(_clip.z - _left - _right, fillWidth - filled);
                if(width < 0)
                    break;
                int height = _bottom;
                localClip = Vec4i(_clip.x + _left, _clip.y + _clip.w - _bottom, width, height);
                _texture.draw(Vec2f(_left + filled, to!int(_size.y) - _bottom), Vec2f(width, height), localClip, 0f, Flip.NoFlip, Vec2f.zero);
                filled += width;
            }
        }

        //Left edge
        if(_left > 0) {
            int filled;
            int fillHeight = to!int(_size.y) - _top - _bottom;
            while(filled < fillHeight) {
                int height = min(_clip.w - _top - _bottom, fillHeight - filled);
                if(height < 0)
                    break;
                int width = _top;
                localClip = Vec4i(_clip.x, _clip.y + _top, width, height);
                _texture.draw(Vec2f(0f, _top + filled), Vec2f(width, height), localClip, 0f, Flip.NoFlip, Vec2f.zero);
                filled += height;
            }
        }

        //Right edge
        if(_left > 0) {
            int filled;
            int fillHeight = to!int(_size.y) - _top - _bottom;
            while(filled < fillHeight) {
                int height = min(_clip.w - _top - _bottom, fillHeight - filled);
                if(height < 0)
                    break;
                int width = _top;
                localClip = Vec4i(_clip.x + _clip.z - _right, _clip.y + _top, width, height);
                _texture.draw(Vec2f(to!int(_size.x) - _right, _top + filled), Vec2f(width, height), localClip, 0f, Flip.NoFlip, Vec2f.zero);
                filled += height;
            }
        }

        //Corners

        //Top _left corner
        if(_top > 0 && _left > 0) {
            localSize = Vec2i(_left, _top);
            localClip = Vec4i(_clip.xy, localSize);
            _texture.draw(Vec2f.zero, to!Vec2f(localSize), localClip, 0f, Flip.NoFlip, Vec2f.zero);
        }

        //Top _right corner
        if(_top > 0 && _right > 0) {
            localSize = Vec2i(_right, _top);
            localClip = Vec4i(_clip.x + _clip.z - _right, _clip.y, localSize.x, localSize.y);
            _texture.draw(Vec2f(to!int(_size.x) - _right, 0f), to!Vec2f(localSize), localClip, 0f, Flip.NoFlip, Vec2f.zero);
        }

        //Bottom _left corner
        if(_bottom > 0 && _left > 0) {
            localSize = Vec2i(_left, _top);
            localClip = Vec4i(_clip.x, _clip.y + _clip.w - _bottom, localSize.x, localSize.y);
            _texture.draw(Vec2f(0f, to!int(_size.y) - _bottom), to!Vec2f(localSize), localClip, 0f, Flip.NoFlip, Vec2f.zero);
        }

        //Bottom _right corner
        if(_bottom > 0 && _right > 0) {
            localSize = Vec2i(_right, _top);
            localClip = Vec4i(_clip.x + _clip.z - _right, _clip.y + _clip.w - _bottom, localSize.x, localSize.y);
            _texture.draw(Vec2f(to!int(_size.x) - _right, to!int(_size.y) - _bottom), to!Vec2f(localSize), localClip, 0f, Flip.NoFlip, Vec2f.zero);
        }

        popCanvas();
    }

    void draw(const Vec2f position) {
        if(_isDirty)
            renderToCache();
        _cache.draw(transformRenderSpace(position));
    }
}