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

import atelier.render.window;
import atelier.render.texture;
import atelier.render.drawable;
import atelier.render.tileset;

struct Animation {
	private {
		Tileset _tileset;
		Timer _timer;
	}

	@property {
		Vec2f scale() const { return _tileset.scale; }
		Vec2f scale(Vec2f newScale) { return _tileset.scale = newScale; }

		float angle() const { return _tileset.angle; }
		float angle(float newAngle) { return _tileset.angle = newAngle; }

		Flip flip() const { return _tileset.flip; }
		Flip flip(Flip newFlip) { return _tileset.flip = newFlip; }

		Vec2f anchor() const { return _tileset.anchor; }
		Vec2f anchor(Vec2f newAnchor) { return _tileset.anchor = newAnchor; }

		Vec2f tileSize() const { return _tileset.tileSize; }

		bool isRunning() const { return _timer.isRunning; }
		float time() const { return _timer.time; }

		Color color(const Color newColor) { return _tileset.color = newColor; };

		alias duration = _timer.duration;
		alias mode = _timer.mode;
	}

	this(string tilesetName, TimeMode timeMode = TimeMode.Once) {
		_tileset = fetch!Tileset(tilesetName);
		start(1f, timeMode);
	}

	void start(float duration, TimeMode timeMode = TimeMode.Once) {
		_timer.start(duration, timeMode);
	}

	void update(float deltaTime) {
		_timer.update(deltaTime);
	}
	
	void draw(const Vec2f position) {
		_tileset.drawRotated(_timer, position);
	}
}