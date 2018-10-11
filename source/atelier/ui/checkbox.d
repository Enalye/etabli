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

module atelier.ui.checkbox;

import std.conv: to;

import atelier.core;
import atelier.common;
import atelier.render.sprite;

import atelier.ui.widget;
import atelier.ui.label;

class Checkbox: Widget {
	private {
		Sprite _uncheckedSprite, _checkedSprite;
		bool _isChecked;
	}

	@property {
		Sprite uncheckedSprite() { return _uncheckedSprite; }
		Sprite uncheckedSprite(Sprite newSprite) {
			_uncheckedSprite = newSprite;
			_uncheckedSprite.fit(_size);
			return _uncheckedSprite;
		}

		Sprite checkedSprite() { return _checkedSprite; }
		Sprite checkedSprite(Sprite newSprite) {
			_checkedSprite = newSprite;
			_checkedSprite.fit(_size);
			return _checkedSprite;
		}

		bool isChecked() const { return _isChecked; }
		bool isChecked(bool newIsChecked) {
			_isChecked = newIsChecked;
			onCheck();
			return _isChecked;
		}
	}

	this() {
		uncheckedSprite(fetch!Sprite("gui_unchecked"));
		checkedSprite(fetch!Sprite("gui_checked"));
	}

	override void update(float deltaTime) {}
	
	override void onEvent(Event event) {}

	override void draw() {
		if(_isChecked)
			_checkedSprite.draw(_position);
		else
			_uncheckedSprite.draw(_position);
	}

	override void onSelect() {
		if(_isSelected || isLocked)
			return;
		isChecked = !_isChecked;
	}

    override void onSize() {
        _uncheckedSprite.fit(_size);
        _checkedSprite.fit(_size);
    }

	protected void onCheck() {}
}

class TextCheckbox: Checkbox {
	Label label;

	@property {
		alias color = label.color;
		alias text = label.text;
	}

	this(string text) {
		label = new Label;
		label.text = text;
		onSize();
	}	

	override void onPosition() {
        label.position = _position + Vec2f((_size.x - label.size.x) / 2f, 0f);
    }

	override void onSize() {
		super.onSize();
		const Vec2f checkboxSize = Vec2f.one * label.size.y;
		_size = label.size + checkboxSize + Vec2f(25f, 0f);
		onPosition();
	}

	override void update(float deltaTime) {}

	override void draw() {
		const Vec2f checkboxPosition = _position - Vec2f((_size.x - label.size.y) / 2f, 0f);

		label.draw();
		if(_isChecked)
			_checkedSprite.draw(checkboxPosition);
		else
			_uncheckedSprite.draw(checkboxPosition);
	}
}