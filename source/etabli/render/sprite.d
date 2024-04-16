/** 
 * Droits d’auteur: Enalye
 * Licence: Zlib
 * Auteur: Enalye
 */
module etabli.render.sprite;

import std.conv : to;

import etabli.common;
import etabli.core;

import etabli.render.image;
import etabli.render.imagedata;
import etabli.render.util;

final class Sprite : Image, Resource!Sprite {
    private {
        ImageData _imageData;
    }

    Vec2f size = Vec2f.zero;

    @property {
        pragma(inline) uint width() const {
            return _imageData.width;
        }

        pragma(inline) uint height() const {
            return _imageData.height;
        }
    }

    this(ImageData imagedata) {
        this(imagedata, Vec4u(0, 0, imagedata.width, imagedata.height));
    }

    this(ImageData imagedata, Vec4u clip_) {
        _imageData = imagedata;
        clip = clip_;
        size = cast(Vec2f) clip_.zw;
    }

    this(Sprite sprite) {
        super(sprite);
        _imageData = sprite._imageData;
        size = sprite.size;
    }

    /// Accès à la ressource
    Sprite fetch() {
        return new Sprite(this);
    }

    override void update() {
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
        _imageData.color = color;
        _imageData.blend = blend;
        _imageData.alpha = alpha;
        _imageData.draw(origin + (position - anchor * size), size, clip,
            angle, pivot, flipX, flipY);
    }
}
