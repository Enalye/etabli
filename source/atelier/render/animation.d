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
}