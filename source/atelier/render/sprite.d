/**
    Sprite

    Copyright: (c) Enalye 2017
    License: Zlib
    Authors: Enalye
*/

module atelier.render.sprite;

import std.conv;

import derelict.sdl2.sdl;
import derelict.sdl2.image;

import atelier.core;
import atelier.render.window;
import atelier.render.texture;
import atelier.render.drawable;

struct Sprite {
	@property {
		bool isValid() const { return texture !is null; }
		Vec2f center() const { return anchor * size * scale; }
	}

	Texture texture;
	Flip flip = Flip.NoFlip;
	Vec2f scale = Vec2f.one, size = Vec2f.zero, anchor = Vec2f.half;
	Vec4i clip;
	float angle = 0f;
    Color color = Color.white;
    Blend blend = Blend.AlphaBlending;

	this(Texture newTexture, Flip newFlip = Flip.NoFlip) {
		texture = newTexture;
		clip = Vec4i(0, 0, texture.width, texture.height);
		size = to!Vec2f(clip.zw);
		flip = newFlip;
	}

	this(Texture newTexture, Vec4i newClip, Flip newFlip = Flip.NoFlip) {
		texture = newTexture;
		clip = newClip;
		size = to!Vec2f(clip.zw);
		flip = newFlip;
	}
	
	Sprite opAssign(Texture newTexture) {
		texture = texture;
		clip = Vec4i(0, 0, texture.width, texture.height);
		size = to!Vec2f(clip.zw);
		return this;
	}

	void fit(Vec2f newSize) {
		size = to!Vec2f(clip.zw).fit(newSize);
	}

	void draw(const Vec2f position) {
		Vec2f finalSize = size * scale * getViewScale();
		//if (isVisible(position, finalSize)) {
            texture.setColorMod(color, blend);
			texture.draw(getViewRenderPos(position), finalSize, clip, angle, flip, anchor);
            texture.setColorMod(Color.white);
		//}
	}

	void drawUnchecked(const Vec2f position) {
		Vec2f finalSize = size * scale * getViewScale();
        texture.setColorMod(color, blend);
		texture.draw(getViewRenderPos(position), finalSize, clip, angle, flip, anchor);
        texture.setColorMod(Color.white);
	}
	
	void drawRotated(const Vec2f position) {
		Vec2f finalSize = size * scale * getViewScale();
		Vec2f dist = (anchor - Vec2f.half) * size * scale;
		dist.rotate(angle);
        texture.setColorMod(color, blend);
		texture.draw(getViewRenderPos(position - dist), finalSize, clip, angle, flip);
        texture.setColorMod(Color.white);
	}

	void draw(const Vec2f pivot, float pivotDistance, float pivotAngle) {
		Vec2f finalSize = size * scale * getViewScale();
        texture.setColorMod(color, blend);
		texture.draw(getViewRenderPos(pivot + Vec2f.angled(pivotAngle) * pivotDistance), finalSize, clip, angle, flip, anchor);
        texture.setColorMod(Color.white);
	}

	void draw(const Vec2f pivot, const Vec2f pivotOffset, float pivotAngle) {
		Vec2f finalSize = size * scale * getViewScale();
        texture.setColorMod(color, blend);
		texture.draw(getViewRenderPos(pivot + pivotOffset.rotated(pivotAngle)), finalSize, clip, angle, flip, anchor);
        texture.setColorMod(Color.white);
	}

	bool isInside(const Vec2f position) const {
		Vec2f halfSize = size * scale * getViewScale() * 0.5f;
		return position.isBetween(-halfSize, halfSize);
	}
}