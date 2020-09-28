/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module atelier.render.sprite;

import std.conv;

import bindbc.sdl, bindbc.sdl.image;

import atelier.core;
import atelier.render.window;
import atelier.render.texture;
import atelier.render.drawable;

/// Renders a **Texture** with its own properties.
final class Sprite: Drawable {
	@property {
		/// Is the texture loaded ?
		bool isValid() const { return texture !is null; }

		/// Get the anchored and scaled center of the sprite.
		Vec2f center() const { return anchor * size * scale; }
	}

	/// Texture being used.
	Texture texture;

	/// Mirroring property.
	Flip flip = Flip.none;

	/// Scale of the sprite.
	Vec2f scale = Vec2f.one;
	
	/// Size of the sprite.
	Vec2f size = Vec2f.zero;

	/// Relative center of the sprite.
	Vec2f anchor = Vec2f.half;

	/// Texture region being rendered (the source size).
	Vec4i clip;

	/// Angle in which the sprite will be rendered.
	float angle = 0f;

	/// Color added to the sprite.
    Color color = Color.white;

	/// Alpha
	float alpha = 1f;

	/// Blending algorithm.
    Blend blend = Blend.alpha;

	/// Default ctor.
    this() {}

	/// Copy another sprite.
    this(Sprite sprite) {
        texture = sprite.texture;
        flip = sprite.flip;
        scale = sprite.scale;
        size = sprite.size;
        anchor = sprite.anchor;
        clip = sprite.clip;
        angle = sprite.angle;
        color = sprite.color;
		alpha = sprite.alpha;
        blend = sprite.blend;
    }

	/// Default sprite that takes the whole Texture.
	this(Texture tex, Flip flip_ = Flip.none) {
		texture = tex;
		if(!texture) {
			clip = Vec4i.zero;
			size = Vec2f.zero;
		}
		else {
			clip = Vec4i(0, 0, texture.width, texture.height);
			size = to!Vec2f(clip.zw);
		}
		flip = flip_;
	}

	/// Sprite that takes a clipped region of a Texture.
	this(Texture tex, Vec4i clip_, Flip flip_ = Flip.none) {
		texture = tex;
		clip = clip_;
		size = to!Vec2f(clip.zw);
		flip = flip_;
	}
	
	/// Reset the sprite to take the whole specified Texture.
	Sprite opAssign(Texture tex) {
		texture = tex;
		if(!texture) {
			clip = Vec4i.zero;
			size = Vec2f.zero;
		}
		else {
			clip = Vec4i(0, 0, texture.width, texture.height);
			size = to!Vec2f(clip.zw);
		}
		return this;
	}

	/// Set the sprite's size to fit inside the specified size.
	void fit(Vec2f size_) {
		size = to!Vec2f(clip.zw).fit(size_);
	}

	/// Set the sprite's size to contain the specified size.
	void contain(Vec2f size_) {
		size = to!Vec2f(clip.zw).contain(size_);
	}

	/// Render the sprite there.
	void draw(const Vec2f position) {
		assert(texture, "Texture is null");
		Vec2f finalSize = size * scale * transformScale();
		//if (isVisible(position, finalSize)) {
		texture.setColorMod(color, blend);
		texture.setAlpha(alpha);
		texture.draw(transformRenderSpace(position), finalSize, clip, angle, flip, anchor);
		texture.setColorMod(Color.white);
		texture.setAlpha(1f);
		//}
	}

	/// Ditto
	void drawUnchecked(const Vec2f position) {
		assert(texture, "Texture is null");
		Vec2f finalSize = size * scale * transformScale();
        texture.setColorMod(color, blend);
		texture.setAlpha(alpha);
		texture.draw(transformRenderSpace(position), finalSize, clip, angle, flip, anchor);
        texture.setColorMod(Color.white);
		texture.setAlpha(1f);
	}
	
	/// Ditto
	void drawRotated(const Vec2f position) {
		assert(texture, "Texture is null");
		Vec2f finalSize = size * scale * transformScale();
		Vec2f dist = (anchor - Vec2f.half) * size * scale;
		dist.rotate(angle);
        texture.setColorMod(color, blend);
		texture.setAlpha(alpha);
		texture.draw(transformRenderSpace(position - dist), finalSize, clip, angle, flip);
        texture.setColorMod(Color.white);
		texture.setAlpha(1f);
	}

	/// Ditto
	void draw(const Vec2f pivot, float pivotDistance, float pivotAngle) {
		assert(texture, "Texture is null");
		Vec2f finalSize = size * scale * transformScale();
        texture.setColorMod(color, blend);
		texture.setAlpha(alpha);
		texture.draw(
			transformRenderSpace(pivot + Vec2f.angled(pivotAngle) * pivotDistance),
			finalSize, clip, angle, flip, anchor);
        texture.setColorMod(Color.white);
		texture.setAlpha(1f);
	}

	/// Ditto
	void draw(const Vec2f pivot, const Vec2f pivotOffset, float pivotAngle) {
		assert(texture, "Texture is null");
		Vec2f finalSize = size * scale * transformScale();
        texture.setColorMod(color, blend);
		texture.setAlpha(alpha);
		texture.draw(
			transformRenderSpace(pivot + pivotOffset.rotated(pivotAngle)),
			finalSize, clip, angle, flip, anchor);
        texture.setColorMod(Color.white);
		texture.setAlpha(1f);
	}

	/// Is this inside the sprite region ? \
	/// Note: Does not take angle into account. may not work properly.
	bool isInside(const Vec2f position) const {
		Vec2f halfSize = size * scale * transformScale() * 0.5f;
		return position.isBetween(-halfSize, halfSize);
	}
}