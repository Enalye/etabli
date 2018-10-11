/**
    Image

    Copyright: (c) Enalye 2017
    License: Zlib
    Authors: Enalye
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
    
    override void onAngle() {
        _sprite.angle = _angle;
    }

    override void onSize() {
        _sprite.size = _size;
    }

	override void draw() {
		_sprite.drawUnchecked(anchoredPosition());
	}
}