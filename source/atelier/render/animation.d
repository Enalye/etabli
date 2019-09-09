/**
    Animation

    Copyright: (c) Enalye 2017
    License: Zlib
    Authors: Enalye
*/

module atelier.render.animation;

import std.conv;

import derelict.sdl2.sdl;
import derelict.sdl2.image;

import atelier.common;
import atelier.core;

import atelier.render.window, atelier.render.texture, atelier.render.drawable;
import atelier.render.tileset, atelier.render.sprite;

final class Animation {
    Tileset tileset;
    Timer timer;

	@property {
		Vec2f scale() const { return tileset.scale; }
		Vec2f scale(Vec2f newScale) { return tileset.scale = newScale; }

		float angle() const { return tileset.angle; }
		float angle(float newAngle) { return tileset.angle = newAngle; }

		Flip flip() const { return tileset.flip; }
		Flip flip(Flip newFlip) { return tileset.flip = newFlip; }

		Vec2f anchor() const { return tileset.anchor; }
		Vec2f anchor(Vec2f newAnchor) { return tileset.anchor = newAnchor; }

		Vec2i tileSize() const { return tileset.clip.zw; }

		bool isRunning() const { return timer.isRunning; }
		float time() const { return timer.time; }

		Color color(const Color newColor) { return tileset.color = newColor; };
		Color color() { return tileset.color; };

		alias duration = timer.duration;
		alias mode = timer.mode;
	}

    this() {}

	this(string tilesetName, TimeMode timeMode = TimeMode.Once) {
		tileset = fetch!Tileset(tilesetName);
		start(1f, timeMode);
	}

	void start(float duration, TimeMode timeMode = TimeMode.Once) {
		timer.start(duration, timeMode);
	}

	void update(float deltaTime) {
		timer.update(deltaTime);
	}
	
	void draw(const Vec2f position) {
		tileset.drawRotated(timer, position);
	}

    Sprite getCurrentSprite() {
        return tileset.getSprite(timer);
    }
}