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

module ui.checkbox;

import std.conv: to;

import core.all;
import common.all;
import render.sprite;

import ui.widget;

class Checkbox: Widget {
	bool isChecked = false;

	private {
		Sprite _uncheckedSprite, _checkedSprite;
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
	}

	this() {
		uncheckedSprite(fetch!Sprite("gui_unchecked"));
		checkedSprite(fetch!Sprite("gui_checked"));
	}

	override void update(float deltaTime) {}
	
	override void onEvent(Event event) {
		if(!isLocked) {
			if(event.type == EventType.MouseUp)
				isChecked = !isChecked;
		}
	}

	override void draw() {
		if(isChecked)
			_checkedSprite.draw(_position);
		else
			_uncheckedSprite.draw(_position);
	}

    override void onSize() {
        _uncheckedSprite.fit(_size);
        _checkedSprite.fit(_size);
    }
}