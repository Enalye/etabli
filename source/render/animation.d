/**
Grimoire
Copyright (c) 2017 Enalye

This software is provided 'as-is', without any express or implied warranty.
In no event will the authors be held liable for any damages arising
from the use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute
it freely, subject to the following restrictions:

	1. The origin of this software must not be misrepresented;
	   you must not claim that you wrote the original software.
	   If you use this software in a product, an acknowledgment
	   in the product documentation would be appreciated but
	   is not required.

	2. Altered source versions must be plainly marked as such,
	   and must not be misrepresented as being the original software.

	3. This notice may not be removed or altered from any source distribution.
*/

module render.animation;

import std.conv;

import derelict.sdl2.sdl;
import derelict.sdl2.image;

import common.all;
import core.all;

import render.window;
import render.texture;
import render.drawable;
import render.tileset;

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
	
	void draw(const Vec2f position) const {
		_tileset.drawRotated(_timer, position);
	}
}