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
import atelier.core, atelier.common, atelier.render;
import atelier.ui.gui_element, atelier.ui.label;

class Checkbox: GuiElement {
	private {
		Sprite _uncheckedSprite, _checkedSprite;
		bool _isChecked;
	}

	@property {
		Sprite uncheckedSprite() { return _uncheckedSprite; }
		Sprite uncheckedSprite(Sprite newSprite) {
			_uncheckedSprite = newSprite;
			_uncheckedSprite.fit(size);
			return _uncheckedSprite;
		}

		Sprite checkedSprite() { return _checkedSprite; }
		Sprite checkedSprite(Sprite newSprite) {
			_checkedSprite = newSprite;
			_checkedSprite.fit(size);
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

	override void draw() {
		if(_isChecked)
			_checkedSprite.draw(center);
		else
			_uncheckedSprite.draw(center);
	}

	override void onSubmit() {
		if(isLocked)
			return;
		isChecked = !isChecked;
	}

    override void onSize() {
        _uncheckedSprite.fit(size);
        _checkedSprite.fit(size);
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
        label.position = center + Vec2f((size.x - label.size.x) / 2f, 0f);
    }

	override void onSize() {
		super.onSize();
		const Vec2f checkboxSize = Vec2f.one * label.size.y;
		size = label.size + checkboxSize + Vec2f(25f, 0f);
		onPosition();
	}

	override void update(float deltaTime) {}

	override void draw() {
		const Vec2f checkboxPosition = center - Vec2f((size.x - label.size.y) / 2f, 0f);

		label.draw();
		if(_isChecked)
			_checkedSprite.draw(checkboxPosition);
		else
			_uncheckedSprite.draw(checkboxPosition);
	}
}