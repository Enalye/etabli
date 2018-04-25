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

module ui.image;

import core.vec2;
import render.sprite;
import common.all;

import ui.widget;

class Image: Widget {
	private Sprite _sprite;

	@property {
		alias angle = super.angle;
		override float angle(float newAngle) {
			_sprite.angle = newAngle;
			return _angle = newAngle;
		}

		alias size = super.size;
		override Vec2f size(Vec2f newSize) {
			_sprite.size = newSize;
			return _size = newSize;
		}

		Sprite sprite() { return _sprite; }
		Sprite sprite(Sprite newSprite) {
			_sprite = newSprite;
			_size = _sprite.size;
			return _sprite;
		}
	}

	this(Sprite newSprite) {
		_sprite = newSprite;
		_size = _sprite.size;
		_angle = _sprite.angle;
		_isInteractable = false;
	}

	override void onEvent(Event event) {}
	override void update(float deltaTime) {}

	override void draw() {
		_sprite.drawUnchecked(anchoredPosition());
	}
}