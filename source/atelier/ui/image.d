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

module atelier.ui.image;

import atelier.core.vec2;
import atelier.render.sprite;
import atelier.common;

import atelier.ui.widget;

class Image: Widget {
	private Sprite _sprite;

	@property {
		Sprite sprite() { return _sprite; }
		Sprite sprite(Sprite newSprite) {
			_sprite = newSprite;
			size = _sprite.size;
			return _sprite;
		}
	}

	this(Sprite newSprite) {
		_sprite = newSprite;
		size = _sprite.size;
		angle = _sprite.angle;
		isInteractable = false;
	}

	override void onEvent(Event event) {}
	override void update(float deltaTime) {}
    
    override void onAngle() {
        _sprite.angle = angle;
    }

    override void onSize() {
        _sprite.size = size;
    }

	override void draw() {
		_sprite.drawUnchecked(pivot);
	}
}