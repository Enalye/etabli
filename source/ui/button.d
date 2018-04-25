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

module ui.button;

import std.conv: to;

import core.all;
import render.all;
import common.all;

import ui.widget;
import ui.label;

class Button: Widget {
	protected bool _isPressed = false;
	void function() onClick;

	@property {
		bool isPressed() const { return _isPressed; }
	}

	override void update(float deltaTime) {
		if (!_isLocked) {
			if (!isButtonDown(1U))
				_isPressed = false;
		}
	}

	override void onEvent(Event event) {
		if (!_isLocked) {
			if (event.type == EventType.MouseDown)
				_isPressed = true;
			else if(event.type == EventType.MouseUp) {
				if(_isPressed) {
					if(onClick !is null)
						onClick();
					triggerCallback();
				}
				_isPressed = false;
			}
		}
	}
}

class ListButton: Button {
	protected Sprite _sprite;
	Label label;

	@property {
		alias color = label.color;
		alias text = label.text;

		alias position = super.position;
		override Vec2f position(Vec2f newPosition) {
			_position = newPosition;
			reload();
			return _position;
		}

		alias size = super.size;
		override Vec2f size(Vec2f newSize) {
			_size = newSize;
			reload();
			return _position;
		}

		Sprite sprite() { return _sprite; }
		Sprite sprite(Sprite newSprite) {
			_sprite = newSprite;
			reload();
			return _sprite;
		}
	}

	this(string text) {
		label = new Label;
		label.text = text;
		_size = label.size;
	}

	this(Sprite newSprite) {
		label = new Label;
		_sprite = newSprite;
		reload();
	}

	this(string text, Sprite newSprite) {
		label = new Label;
		label.text = text;
		_size = label.size;
		_sprite = newSprite;
		reload();
	}

	override void update(float deltaTime) {
		super.update(deltaTime);
		label.position = _position;
	}

	override void draw() {
		if(_isValidated)
			drawFilledRect(_position - _size / 2f, _size, Color.white * 0.8f);
		else if(_isHovered)
			drawFilledRect(_position - _size / 2f, _size, Color.white * 0.25f);
		else
			drawFilledRect(_position - _size / 2f, _size, Color.white * 0.15f);

		if(sprite.texture)
			sprite.draw(_position);

		if(label.isLoaded)
			label.draw();
	}

	private void reload() {
		label.position = _position;
		if(_sprite.texture) {
			_sprite.fit(_size);
		}
	}
}

class TextButton: Button {
	Label label;

	@property {
		alias color = label.color;
		alias text = label.text;

		alias position = super.position;
		override Vec2f position(Vec2f newPosition) {
			_position = newPosition;
			label.position = _position;
			return _position;
		}
	}

	this(string text) {
		label = new Label;
		label.text = text;
		_size = label.size;
	}

	override void update(float deltaTime) {
		super.update(deltaTime);
		label.position = _position;
	}

	override void draw() {
		if(_isLocked)
			drawFilledRect(_position - _size / 2f, _size, Color.white * 0.055f);
		else if(_isPressed)
			drawFilledRect(_position - _size / 2f + (_isPressed ? 1f : 0f), _size, Color.white * 0.4f);
		else if(_isHovered)
			drawFilledRect(_position - _size / 2f + (_isPressed ? 1f : 0f), _size, Color.white * 0.25f);
		else
			drawFilledRect(_position - _size / 2f + (_isPressed ? 1f : 0f), _size, Color.white * 0.15f);
		if(label.isLoaded)
			label.draw();
	}
}

class ImgButton: Button {
	Label label;

	protected {
		bool _isFixedSize, _isScaleLocked;
		Sprite _idleSprite, _hoveredSprite, _clickedSprite, _lockedSprite;
	}

	@property {
		alias color = label.color;
		alias text = label.text;

		alias size = super.size;
		override Vec2f size(Vec2f newSize) {
			_isFixedSize = true;
			_size = newSize;
			if(_idleSprite.texture)
				setToSize(_idleSprite);
			if(_hoveredSprite.texture)
				setToSize(_hoveredSprite);
			if(_clickedSprite.texture)
				setToSize(_clickedSprite);
			if(_lockedSprite.texture)
				setToSize(_lockedSprite);
			return _size;
		}

		bool isScaleLocked() { return _isScaleLocked; }
		bool isScaleLocked(bool newIsScaleLocked) {
			_isScaleLocked = newIsScaleLocked;
			if(_idleSprite.texture)
				setToSize(_idleSprite);
			if(_hoveredSprite.texture)
				setToSize(_hoveredSprite);
			if(_clickedSprite.texture)
				setToSize(_clickedSprite);
			if(_lockedSprite.texture)
				setToSize(_lockedSprite);
			return _isScaleLocked;
		}

		Sprite idleSprite() { return _idleSprite; }
		Sprite idleSprite(Sprite newSprite) {
			if(_isFixedSize)
				setToSize(newSprite);
			else
				_size = newSprite.size;
			return _idleSprite = newSprite;
		}

		Sprite hoveredSprite() { return _hoveredSprite; }
		Sprite hoveredSprite(Sprite newSprite) {
			if(_isFixedSize)
				setToSize(newSprite);
			else {
				if(_idleSprite.texture is null)
					_size = newSprite.size;
			}
			return _hoveredSprite = newSprite;
		}

		Sprite clickedSprite() { return _clickedSprite; }
		Sprite clickedSprite(Sprite newSprite) {
			if(_isFixedSize)
				setToSize(newSprite);
			else {
				if(_idleSprite.texture is null)
					_size = newSprite.size;
			}
			return _clickedSprite = newSprite;
		}

		Sprite lockedSprite() { return _lockedSprite; }
		Sprite lockedSprite(Sprite newSprite) {
			if(_isFixedSize)
				setToSize(newSprite);
			else {
				if(_idleSprite.texture is null)
					_size = newSprite.size;
			}
			return _lockedSprite = newSprite;
		}
	}

	this() {
		label = new Label;
	}

	this(string text) {
		label = new Label;
		label.text = text;
		_size = label.size;
	}

	private void setToSize(Sprite sprite) {
		if(!_isFixedSize) 
			return;

		if(_isScaleLocked) {
			Vec2f clip = to!Vec2f(sprite.clip.zw);
			float scale;
			if(_size.x / _size.y > clip.x / clip.y)
				scale = _size.y / clip.y;
			else
				scale = _size.x / clip.x;
			sprite.size = clip * scale;
		}
		else
			sprite.size = _size;
	}

	override void update(float deltaTime) {
		super.update(deltaTime);
		label.position = _position;
	}

	override void draw() {
		if(_isLocked) {
			if(_lockedSprite.texture)
				_lockedSprite.drawUnchecked(_position);
			else if(_idleSprite.texture)
				_idleSprite.drawUnchecked(_position);
			else
				drawFilledRect(_position - _size / 2f, _size, Color.gray);
		}
		else if(_isPressed) {
			if(_clickedSprite.texture)
				_clickedSprite.drawUnchecked(_position);
			else if(_idleSprite.texture)
				_idleSprite.drawUnchecked(_position + Vec2f.one);
			else
				drawFilledRect(_position - _size / 2f + Vec2f.one, _size, Color.blue);
		}
		else if(_isHovered) {
			if(_hoveredSprite.texture)
				_hoveredSprite.drawUnchecked(_position);
			else if(_idleSprite.texture)
				_idleSprite.drawUnchecked(_position);
			else
				drawFilledRect(_position - _size / 2f, _size, Color.green);
		}
		else {
			if(_idleSprite.texture)
				_idleSprite.drawUnchecked(_position);
			else
				drawFilledRect(_position - _size / 2f, _size, Color.red);
		}
		if(label.isLoaded)
			label.draw();
	}
}